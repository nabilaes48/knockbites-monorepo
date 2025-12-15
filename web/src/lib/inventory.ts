/**
 * Inventory Management Library
 *
 * Provides frontend utilities for inventory tracking:
 * - Stock level monitoring
 * - Low stock alerts
 * - Restock recommendations
 * - Inventory updates
 */

import { supabase } from './supabase';
import { createLogger } from './logger';

const log = createLogger('Inventory');

// Types
export interface InventoryItem {
  id: number;
  store_id: number;
  item_id: number;
  item_name?: string;
  ingredient_name?: string;
  current_stock: number;
  minimum_stock: number;
  maximum_stock: number;
  unit_type: 'units' | 'lbs' | 'oz' | 'gallons' | 'each';
  cost_per_unit?: number;
  supplier_name?: string;
  reorder_point: number;
  auto_reorder: boolean;
  last_restock_at?: string;
  updated_at: string;
}

export interface InventoryAlert {
  id: number;
  store_id: number;
  item_id: number;
  item_name: string;
  alert_type: 'low_stock' | 'out_of_stock' | 'expiring_soon' | 'overstock';
  current_level: number;
  threshold_level: number;
  severity: 'info' | 'warning' | 'critical';
  is_resolved: boolean;
  notes?: string;
  created_at: string;
}

export interface StockUpdate {
  item_id: number;
  store_id: number;
  quantity: number;
  type: 'add' | 'remove' | 'set';
  reason?: string;
}

export interface RestockRecommendation {
  item_id: number;
  item_name: string;
  current_stock: number;
  predicted_demand: number;
  recommended_quantity: number;
  priority: 'critical' | 'high' | 'medium' | 'low';
  estimated_cost?: number;
  days_until_stockout: number;
}

export interface InventorySummary {
  total_items: number;
  low_stock_count: number;
  out_of_stock_count: number;
  overstock_count: number;
  total_value: number;
  alerts_count: number;
}

// Fetch inventory for a store
export async function getStoreInventory(storeId: number): Promise<InventoryItem[]> {
  try {
    const { data, error } = await supabase
      .from('inventory_levels')
      .select(`
        *,
        menu_items!inner(name)
      `)
      .eq('store_id', storeId)
      .order('current_stock', { ascending: true });

    if (error) throw error;

    return (data || []).map(item => ({
      ...item,
      item_name: item.menu_items?.name,
    }));
  } catch (error) {
    log.error('Failed to fetch inventory', error instanceof Error ? error : new Error(String(error)));
    throw error;
  }
}

// Get low stock items
export async function getLowStockItems(storeId: number): Promise<InventoryItem[]> {
  try {
    const { data, error } = await supabase
      .from('inventory_levels')
      .select(`
        *,
        menu_items!inner(name)
      `)
      .eq('store_id', storeId)
      .lte('current_stock', supabase.rpc('get_column', { column: 'minimum_stock' }));

    if (error) {
      // Fallback query without RPC
      const { data: fallbackData, error: fallbackError } = await supabase
        .from('inventory_levels')
        .select(`
          *,
          menu_items(name)
        `)
        .eq('store_id', storeId);

      if (fallbackError) throw fallbackError;

      return (fallbackData || [])
        .filter(item => item.current_stock <= item.minimum_stock)
        .map(item => ({
          ...item,
          item_name: item.menu_items?.name,
        }));
    }

    return (data || []).map(item => ({
      ...item,
      item_name: item.menu_items?.name,
    }));
  } catch (error) {
    log.error('Failed to fetch low stock items', error instanceof Error ? error : new Error(String(error)));
    throw error;
  }
}

// Get inventory alerts
export async function getInventoryAlerts(
  storeId: number,
  unresolvedOnly: boolean = true
): Promise<InventoryAlert[]> {
  try {
    let query = supabase
      .from('inventory_alerts')
      .select(`
        *,
        menu_items!inner(name)
      `)
      .eq('store_id', storeId)
      .order('created_at', { ascending: false });

    if (unresolvedOnly) {
      query = query.eq('is_resolved', false);
    }

    const { data, error } = await query;

    // Return empty array if table doesn't exist
    if (error) {
      if (error.code === '42P01' || error.message?.includes('does not exist')) {
        return [];
      }
      throw error;
    }

    return (data || []).map(alert => ({
      ...alert,
      item_name: alert.menu_items?.name,
    }));
  } catch (error) {
    // Return empty array for missing tables
    return [];
  }
}

// Update stock level
export async function updateStock(update: StockUpdate): Promise<InventoryItem> {
  try {
    const { item_id, store_id, quantity, type } = update;

    // Get current stock
    const { data: current, error: fetchError } = await supabase
      .from('inventory_levels')
      .select('*')
      .eq('store_id', store_id)
      .eq('item_id', item_id)
      .single();

    if (fetchError && fetchError.code !== 'PGRST116') {
      throw fetchError;
    }

    let newStock: number;
    const currentStock = current?.current_stock || 0;

    switch (type) {
      case 'add':
        newStock = currentStock + quantity;
        break;
      case 'remove':
        newStock = Math.max(0, currentStock - quantity);
        break;
      case 'set':
        newStock = Math.max(0, quantity);
        break;
      default:
        newStock = currentStock;
    }

    // Upsert inventory
    const { data, error } = await supabase
      .from('inventory_levels')
      .upsert({
        store_id,
        item_id,
        current_stock: newStock,
        updated_at: new Date().toISOString(),
        ...(current ? {} : { minimum_stock: 10, reorder_point: 15 }),
      })
      .select()
      .single();

    if (error) throw error;

    log.info('Stock updated', { item_id, store_id, type, oldStock: currentStock, newStock });

    return data;
  } catch (error) {
    log.error('Failed to update stock', error instanceof Error ? error : new Error(String(error)));
    throw error;
  }
}

// Batch update stock levels
export async function batchUpdateStock(updates: StockUpdate[]): Promise<InventoryItem[]> {
  const results = await Promise.allSettled(updates.map(u => updateStock(u)));

  const successful = results
    .filter((r): r is PromiseFulfilledResult<InventoryItem> => r.status === 'fulfilled')
    .map(r => r.value);

  const failed = results.filter(r => r.status === 'rejected').length;

  if (failed > 0) {
    log.warn(`Batch update: ${successful.length} succeeded, ${failed} failed`);
  }

  return successful;
}

// Resolve an alert
export async function resolveAlert(
  alertId: number,
  notes?: string
): Promise<boolean> {
  try {
    const { error } = await supabase
      .from('inventory_alerts')
      .update({
        is_resolved: true,
        resolved_at: new Date().toISOString(),
        notes,
      })
      .eq('id', alertId);

    if (error) throw error;

    log.info('Alert resolved', { alertId });
    return true;
  } catch (error) {
    log.error('Failed to resolve alert', error instanceof Error ? error : new Error(String(error)));
    throw error;
  }
}

// Get restock recommendations
export async function getRestockRecommendations(storeId: number): Promise<RestockRecommendation[]> {
  try {
    // Call V4 RPC for AI-powered recommendations
    const { data, error } = await supabase.rpc('rpc_v4_dispatch', {
      p_name: 'predict_inventory_needs',
      p_payload: { store_id: storeId, days_ahead: 7 },
    });

    // Silently return empty array if function doesn't exist
    if (error) {
      if (error.code === '42883' || error.message?.includes('404')) {
        return [];
      }
      throw error;
    }

    return (data || []).map((item: any) => ({
      item_id: item.item_id,
      item_name: item.item_name,
      current_stock: item.current_stock,
      predicted_demand: item.predicted_demand,
      recommended_quantity: item.recommended_reorder,
      priority: item.priority,
      days_until_stockout: item.days_until_stockout,
    }));
  } catch (error) {
    // Return empty array instead of throwing for missing AI functions
    return [];
  }
}

// Get inventory summary
export async function getInventorySummary(storeId: number): Promise<InventorySummary> {
  try {
    const [inventory, alerts] = await Promise.all([
      getStoreInventory(storeId),
      getInventoryAlerts(storeId, true),
    ]);

    const lowStock = inventory.filter(i => i.current_stock <= i.minimum_stock && i.current_stock > 0);
    const outOfStock = inventory.filter(i => i.current_stock === 0);
    const overstock = inventory.filter(i => i.current_stock > i.maximum_stock);

    const totalValue = inventory.reduce(
      (sum, item) => sum + (item.current_stock * (item.cost_per_unit || 0)),
      0
    );

    return {
      total_items: inventory.length,
      low_stock_count: lowStock.length,
      out_of_stock_count: outOfStock.length,
      overstock_count: overstock.length,
      total_value: totalValue,
      alerts_count: alerts.length,
    };
  } catch (error) {
    log.error('Failed to get inventory summary', error instanceof Error ? error : new Error(String(error)));
    throw error;
  }
}

// Set up real-time subscription for inventory alerts
export function subscribeToInventoryAlerts(
  storeId: number,
  callback: (alert: InventoryAlert) => void
): () => void {
  const channel = supabase
    .channel(`inventory-alerts-${storeId}`)
    .on(
      'postgres_changes',
      {
        event: 'INSERT',
        schema: 'public',
        table: 'inventory_alerts',
        filter: `store_id=eq.${storeId}`,
      },
      async (payload) => {
        // Fetch the full alert with item name
        const { data } = await supabase
          .from('inventory_alerts')
          .select(`
            *,
            menu_items!inner(name)
          `)
          .eq('id', payload.new.id)
          .single();

        if (data) {
          callback({
            ...data,
            item_name: data.menu_items?.name,
          });
        }
      }
    )
    .subscribe();

  // Return unsubscribe function
  return () => {
    supabase.removeChannel(channel);
  };
}

// Set up real-time subscription for inventory changes
export function subscribeToInventoryChanges(
  storeId: number,
  callback: (item: InventoryItem) => void
): () => void {
  const channel = supabase
    .channel(`inventory-${storeId}`)
    .on(
      'postgres_changes',
      {
        event: '*',
        schema: 'public',
        table: 'inventory_levels',
        filter: `store_id=eq.${storeId}`,
      },
      async (payload) => {
        if (payload.eventType === 'DELETE') return;

        // Fetch the full item with menu item name
        const { data } = await supabase
          .from('inventory_levels')
          .select(`
            *,
            menu_items(name)
          `)
          .eq('store_id', payload.new.store_id)
          .eq('item_id', payload.new.item_id)
          .single();

        if (data) {
          callback({
            ...data,
            item_name: data.menu_items?.name,
          });
        }
      }
    )
    .subscribe();

  // Return unsubscribe function
  return () => {
    supabase.removeChannel(channel);
  };
}

// Hook for using inventory features
export function useInventory(storeId: number) {
  return {
    getInventory: () => getStoreInventory(storeId),
    getLowStock: () => getLowStockItems(storeId),
    getAlerts: (unresolvedOnly?: boolean) => getInventoryAlerts(storeId, unresolvedOnly),
    updateStock: (itemId: number, quantity: number, type: StockUpdate['type']) =>
      updateStock({ item_id: itemId, store_id: storeId, quantity, type }),
    resolveAlert: (alertId: number, notes?: string) => resolveAlert(alertId, notes),
    getRecommendations: () => getRestockRecommendations(storeId),
    getSummary: () => getInventorySummary(storeId),
    subscribeAlerts: (callback: (alert: InventoryAlert) => void) =>
      subscribeToInventoryAlerts(storeId, callback),
    subscribeChanges: (callback: (item: InventoryItem) => void) =>
      subscribeToInventoryChanges(storeId, callback),
  };
}

// Export types
export type { StockUpdate as InventoryStockUpdate };
