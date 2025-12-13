/**
 * Autonomous Operations Library
 *
 * Frontend integration for dynamic pricing, kitchen load prediction,
 * staffing optimization, and menu profitability analysis.
 */

import { supabase } from './supabase';

// ============================================================================
// TYPE DEFINITIONS
// ============================================================================

export interface DynamicPricingItem {
  item_id: number;
  item_name: string;
  base_price: number;
  suggested_price: number;
  price_multiplier: number;
  confidence: number;
  reason: string;
  is_safe: boolean;
  demand_score: number;
  inventory_factor: number;
  time_factor: number;
}

export interface PriceCalculation {
  suggested_price: number;
  price_multiplier: number;
  confidence: number;
  reason: string;
  is_within_bounds: boolean;
}

export interface KitchenLoad {
  predicted_orders: number;
  predicted_prep_time: number;
  load_level: 'low' | 'moderate' | 'high' | 'critical';
  capacity_percentage: number;
  bottleneck_items: number[];
  recommendation: string;
  is_critical: boolean;
  color: string;
  icon: string;
  action_required: boolean;
}

export interface WaitTimePrediction {
  estimated_minutes: number;
  range_min: number;
  range_max: number;
  load_level: string;
  confidence: number;
  message: string;
}

export interface StaffingRecommendation {
  hour_of_day: number;
  hour_label: string;
  current_staff: number;
  recommended_staff: number;
  predicted_orders: number;
  confidence: number;
  reason: string;
  staff_delta: number;
  is_understaffed: boolean;
  is_overstaffed: boolean;
  cost_impact: {
    amount: number;
    label: string;
  };
}

export interface MenuProfitabilityItem {
  item_id: number;
  item_name: string;
  category: string;
  total_quantity: number;
  total_revenue: number;
  total_cost: number;
  total_profit: number;
  margin_percentage: number;
  avg_daily_sales: number;
  trend: 'rising' | 'stable' | 'falling';
}

export interface MenuProfitability {
  stars: MenuProfitabilityItem[];
  puzzles: MenuProfitabilityItem[];
  plowhorses: MenuProfitabilityItem[];
  dogs: MenuProfitabilityItem[];
  all: MenuProfitabilityItem[];
  recommendations: string[];
  summary: {
    total_items: number;
    avg_margin: number;
    total_profit: number;
    top_performers: string[];
  };
}

export interface OperationalHealth {
  overall_score: number;
  kitchen_score: number;
  inventory_score: number;
  staff_score: number;
  pricing_score: number;
  active_alerts: number;
  recommendations: string[];
  grade: string;
  grade_color: string;
  status: 'healthy' | 'attention' | 'critical';
  breakdown: {
    name: string;
    score: number;
    icon: string;
  }[];
}

export interface OpsAlert {
  id: number;
  store_id: number;
  alert_type: string;
  severity: 'info' | 'warning' | 'critical';
  title: string;
  message: string;
  data: Record<string, unknown>;
  is_resolved: boolean;
  resolved_at: string | null;
  created_at: string;
}

export interface OpsAlerts {
  critical: OpsAlert[];
  warning: OpsAlert[];
  info: OpsAlert[];
  all: OpsAlert[];
  total_unresolved: number;
}

export interface StoreOpsSettings {
  store_id: number;
  dynamic_pricing_enabled: boolean;
  auto_hide_slow_items: boolean;
  kitchen_capacity_per_hour: number;
  max_price_increase_pct: number;
  max_price_decrease_pct: number;
  min_confidence_threshold: number;
  alert_on_critical_load: boolean;
  auto_staffing_suggestions: boolean;
}

export interface AutonomousCycleResult {
  timestamp: string;
  store_id: number;
  dry_run: boolean;
  actions: {
    type: string;
    description: string;
    applied: boolean;
  }[];
  errors: string[];
}

// ============================================================================
// EDGE FUNCTION CALLER
// ============================================================================

async function callOpsEngine<T>(action: string, payload: Record<string, unknown>): Promise<T> {
  const { data, error } = await supabase.functions.invoke('autonomous-ops-engine', {
    body: { action, payload },
  });

  if (error) throw error;
  if (!data.success) throw new Error(data.error || 'Unknown error');
  return data.data as T;
}

// ============================================================================
// RPC CALLERS
// ============================================================================

async function callV5Rpc<T>(name: string, payload: Record<string, unknown>): Promise<T> {
  const { data, error } = await supabase.rpc('rpc_v5_dispatch', {
    p_name: name,
    p_payload: payload,
  });

  if (error) throw error;
  return data as T;
}

// ============================================================================
// DYNAMIC PRICING FUNCTIONS
// ============================================================================

/**
 * Get dynamic pricing suggestions for all items at a store
 */
export async function getDynamicPricing(storeId: number, itemId?: number): Promise<DynamicPricingItem[]> {
  return callOpsEngine<DynamicPricingItem[]>('get_dynamic_pricing', {
    store_id: storeId,
    item_id: itemId,
  });
}

/**
 * Calculate dynamic price for a specific item
 */
export async function calculateItemPrice(itemId: number, storeId: number): Promise<PriceCalculation> {
  return callOpsEngine<PriceCalculation>('calculate_item_price', {
    item_id: itemId,
    store_id: storeId,
  });
}

/**
 * Update a pricing rule with safety bounds
 */
export async function updatePricingRule(
  storeId: number,
  itemId: number,
  basePrice: number,
  minPrice: number,
  maxPrice: number,
  isEnabled: boolean = true
): Promise<void> {
  await callOpsEngine('update_pricing_rule', {
    store_id: storeId,
    item_id: itemId,
    base_price: basePrice,
    min_price: minPrice,
    max_price: maxPrice,
    is_enabled: isEnabled,
  });
}

/**
 * Approve a pricing change (manager action)
 */
export async function approvePricingChange(
  storeId: number,
  itemId: number,
  approvedPrice: number,
  approvedBy: string
): Promise<void> {
  await callOpsEngine('approve_pricing_change', {
    store_id: storeId,
    item_id: itemId,
    approved_price: approvedPrice,
    approved_by: approvedBy,
  });
}

// ============================================================================
// KITCHEN LOAD FUNCTIONS
// ============================================================================

/**
 * Get current kitchen load prediction
 */
export async function getKitchenLoad(storeId: number, windowMinutes: number = 30): Promise<KitchenLoad> {
  return callOpsEngine<KitchenLoad>('get_kitchen_load', {
    store_id: storeId,
    window_minutes: windowMinutes,
  });
}

/**
 * Predict wait time for customer order
 */
export async function predictWaitTime(storeId: number, itemIds?: number[]): Promise<WaitTimePrediction> {
  return callOpsEngine<WaitTimePrediction>('predict_wait_time', {
    store_id: storeId,
    item_ids: itemIds,
  });
}

// ============================================================================
// STAFFING FUNCTIONS
// ============================================================================

/**
 * Get staffing recommendations for a date
 */
export async function getStaffingRecommendations(
  storeId: number,
  date?: string
): Promise<StaffingRecommendation[]> {
  return callOpsEngine<StaffingRecommendation[]>('get_staffing_recommendations', {
    store_id: storeId,
    date: date || new Date().toISOString().split('T')[0],
  });
}

// ============================================================================
// PROFITABILITY FUNCTIONS
// ============================================================================

/**
 * Get menu profitability analysis
 */
export async function getMenuProfitability(storeId: number, days: number = 30): Promise<MenuProfitability> {
  return callOpsEngine<MenuProfitability>('get_menu_profitability', {
    store_id: storeId,
    days,
  });
}

// ============================================================================
// OPERATIONAL HEALTH FUNCTIONS
// ============================================================================

/**
 * Get overall operational health score
 */
export async function getOperationalHealth(storeId: number): Promise<OperationalHealth> {
  return callOpsEngine<OperationalHealth>('get_operational_health', {
    store_id: storeId,
  });
}

/**
 * Get operations alerts
 */
export async function getOpsAlerts(storeId: number, includeResolved: boolean = false): Promise<OpsAlerts> {
  return callOpsEngine<OpsAlerts>('get_ops_alerts', {
    store_id: storeId,
    include_resolved: includeResolved,
  });
}

// ============================================================================
// STORE SETTINGS FUNCTIONS
// ============================================================================

/**
 * Get store operations settings
 */
export async function getStoreOpsSettings(storeId: number): Promise<StoreOpsSettings> {
  return callOpsEngine<StoreOpsSettings>('get_store_settings', {
    store_id: storeId,
  });
}

/**
 * Update store operations settings
 */
export async function updateStoreOpsSettings(
  storeId: number,
  settings: Partial<StoreOpsSettings>
): Promise<StoreOpsSettings> {
  return callOpsEngine<StoreOpsSettings>('update_store_settings', {
    store_id: storeId,
    settings,
  });
}

// ============================================================================
// ITEM AVAILABILITY FUNCTIONS
// ============================================================================

/**
 * Toggle item availability (auto-hide/restore)
 */
export async function toggleItemAvailability(
  itemId: number,
  isAvailable: boolean,
  reason: string
): Promise<void> {
  await callOpsEngine('toggle_item_availability', {
    item_id: itemId,
    is_available: isAvailable,
    reason,
  });
}

// ============================================================================
// AUTONOMOUS CYCLE FUNCTIONS
// ============================================================================

/**
 * Run a full autonomous operations cycle
 * @param dryRun If true, only simulate actions without applying them
 */
export async function runAutonomousCycle(
  storeId: number,
  dryRun: boolean = true
): Promise<AutonomousCycleResult> {
  return callOpsEngine<AutonomousCycleResult>('run_autonomous_cycle', {
    store_id: storeId,
    dry_run: dryRun,
  });
}

// ============================================================================
// REAL-TIME SUBSCRIPTIONS
// ============================================================================

/**
 * Subscribe to operations alerts in real-time
 */
export function subscribeToOpsAlerts(
  storeId: number,
  callback: (alert: OpsAlert) => void
): () => void {
  const channel = supabase
    .channel(`ops-alerts-${storeId}`)
    .on(
      'postgres_changes',
      {
        event: 'INSERT',
        schema: 'public',
        table: 'ops_alerts',
        filter: `store_id=eq.${storeId}`,
      },
      (payload) => {
        callback(payload.new as OpsAlert);
      }
    )
    .subscribe();

  return () => {
    supabase.removeChannel(channel);
  };
}

/**
 * Subscribe to kitchen load predictions in real-time
 */
export function subscribeToKitchenLoad(
  storeId: number,
  callback: (load: KitchenLoad) => void
): () => void {
  const channel = supabase
    .channel(`kitchen-load-${storeId}`)
    .on(
      'postgres_changes',
      {
        event: '*',
        schema: 'public',
        table: 'kitchen_load_predictions',
        filter: `store_id=eq.${storeId}`,
      },
      async () => {
        // Fetch the latest load prediction
        const load = await getKitchenLoad(storeId);
        callback(load);
      }
    )
    .subscribe();

  return () => {
    supabase.removeChannel(channel);
  };
}

/**
 * Subscribe to pricing changes in real-time
 */
export function subscribeToPricingChanges(
  storeId: number,
  callback: (pricing: DynamicPricingItem) => void
): () => void {
  const channel = supabase
    .channel(`pricing-${storeId}`)
    .on(
      'postgres_changes',
      {
        event: '*',
        schema: 'public',
        table: 'dynamic_pricing_rules',
        filter: `store_id=eq.${storeId}`,
      },
      (payload) => {
        callback(payload.new as unknown as DynamicPricingItem);
      }
    )
    .subscribe();

  return () => {
    supabase.removeChannel(channel);
  };
}

// ============================================================================
// REACT HOOKS
// ============================================================================

import { useState, useEffect, useCallback } from 'react';

/**
 * Hook for autonomous operations data
 */
export function useAutonomousOps(storeId: number) {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [health, setHealth] = useState<OperationalHealth | null>(null);
  const [alerts, setAlerts] = useState<OpsAlerts | null>(null);
  const [kitchenLoad, setKitchenLoad] = useState<KitchenLoad | null>(null);

  const refresh = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [healthData, alertsData, loadData] = await Promise.all([
        getOperationalHealth(storeId),
        getOpsAlerts(storeId),
        getKitchenLoad(storeId),
      ]);
      setHealth(healthData);
      setAlerts(alertsData);
      setKitchenLoad(loadData);
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Unknown error'));
    } finally {
      setLoading(false);
    }
  }, [storeId]);

  useEffect(() => {
    refresh();

    // Subscribe to real-time updates
    const unsubAlerts = subscribeToOpsAlerts(storeId, (alert) => {
      setAlerts((prev) =>
        prev
          ? {
              ...prev,
              all: [alert, ...prev.all],
              [alert.severity]: [alert, ...prev[alert.severity]],
              total_unresolved: prev.total_unresolved + 1,
            }
          : null
      );
    });

    const unsubLoad = subscribeToKitchenLoad(storeId, (load) => {
      setKitchenLoad(load);
    });

    return () => {
      unsubAlerts();
      unsubLoad();
    };
  }, [storeId, refresh]);

  return {
    loading,
    error,
    health,
    alerts,
    kitchenLoad,
    refresh,
    // Convenience methods
    getHealth: () => getOperationalHealth(storeId),
    getAlerts: () => getOpsAlerts(storeId),
    getLoad: () => getKitchenLoad(storeId),
    getProfitability: (days?: number) => getMenuProfitability(storeId, days),
    getStaffing: (date?: string) => getStaffingRecommendations(storeId, date),
    getPricing: (itemId?: number) => getDynamicPricing(storeId, itemId),
    getSettings: () => getStoreOpsSettings(storeId),
    updateSettings: (settings: Partial<StoreOpsSettings>) => updateStoreOpsSettings(storeId, settings),
    runCycle: (dryRun?: boolean) => runAutonomousCycle(storeId, dryRun),
  };
}

/**
 * Hook for customer-facing wait time prediction
 */
export function useWaitTime(storeId: number, itemIds?: number[]) {
  const [waitTime, setWaitTime] = useState<WaitTimePrediction | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    const fetch = async () => {
      setLoading(true);
      try {
        const data = await predictWaitTime(storeId, itemIds);
        setWaitTime(data);
      } catch (err) {
        setError(err instanceof Error ? err : new Error('Unknown error'));
      } finally {
        setLoading(false);
      }
    };

    fetch();
  }, [storeId, JSON.stringify(itemIds)]);

  return { waitTime, loading, error };
}

/**
 * Hook for dynamic pricing display
 */
export function useDynamicPricing(storeId: number, itemId?: number) {
  const [pricing, setPricing] = useState<DynamicPricingItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const refresh = useCallback(async () => {
    setLoading(true);
    try {
      const data = await getDynamicPricing(storeId, itemId);
      setPricing(data);
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Unknown error'));
    } finally {
      setLoading(false);
    }
  }, [storeId, itemId]);

  useEffect(() => {
    refresh();

    const unsub = subscribeToPricingChanges(storeId, () => {
      refresh();
    });

    return unsub;
  }, [storeId, itemId, refresh]);

  return { pricing, loading, error, refresh };
}

/**
 * Hook for menu profitability analysis
 */
export function useMenuProfitability(storeId: number, days: number = 30) {
  const [profitability, setProfitability] = useState<MenuProfitability | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    const fetch = async () => {
      setLoading(true);
      try {
        const data = await getMenuProfitability(storeId, days);
        setProfitability(data);
      } catch (err) {
        setError(err instanceof Error ? err : new Error('Unknown error'));
      } finally {
        setLoading(false);
      }
    };

    fetch();
  }, [storeId, days]);

  return { profitability, loading, error };
}

/**
 * Hook for staffing recommendations
 */
export function useStaffingRecommendations(storeId: number, date?: string) {
  const [recommendations, setRecommendations] = useState<StaffingRecommendation[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    const fetch = async () => {
      setLoading(true);
      try {
        const data = await getStaffingRecommendations(storeId, date);
        setRecommendations(data);
      } catch (err) {
        setError(err instanceof Error ? err : new Error('Unknown error'));
      } finally {
        setLoading(false);
      }
    };

    fetch();
  }, [storeId, date]);

  return { recommendations, loading, error };
}
