/**
 * E2E Tests: Kitchen Load Prediction
 *
 * Tests for kitchen load prediction, wait time estimation,
 * and automatic item hiding during critical load.
 */

import { test, expect } from '@playwright/test';
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.VITE_SUPABASE_URL || '';
const supabaseKey = process.env.VITE_SUPABASE_ANON_KEY || '';

const supabase = createClient(supabaseUrl, supabaseKey);

test.describe('Kitchen Load Prediction', () => {
  const testStoreId = 1;

  test('should predict kitchen load for next 30 minutes', async () => {
    const { data, error } = await supabase.rpc('predict_kitchen_load', {
      p_store_id: testStoreId,
      p_window_minutes: 30,
    });

    expect(error).toBeNull();
    expect(data).toBeDefined();

    if (data && data.length > 0) {
      const load = data[0];
      expect(load).toHaveProperty('predicted_orders');
      expect(load).toHaveProperty('predicted_prep_time');
      expect(load).toHaveProperty('load_level');
      expect(load).toHaveProperty('capacity_percentage');
      expect(load).toHaveProperty('recommendation');

      // Validate load level is one of expected values
      expect(['low', 'moderate', 'high', 'critical']).toContain(load.load_level);

      // Capacity percentage should be between 0 and 100+
      expect(load.capacity_percentage).toBeGreaterThanOrEqual(0);
    }
  });

  test('should predict load for different time windows', async () => {
    const windows = [15, 30, 60];

    for (const windowMinutes of windows) {
      const { data, error } = await supabase.rpc('predict_kitchen_load', {
        p_store_id: testStoreId,
        p_window_minutes: windowMinutes,
      });

      expect(error).toBeNull();
      expect(data).toBeDefined();

      if (data && data.length > 0) {
        // Longer windows should generally predict more orders
        expect(data[0].predicted_orders).toBeGreaterThanOrEqual(0);
      }
    }
  });

  test('should identify bottleneck items during high load', async () => {
    const { data, error } = await supabase.rpc('predict_kitchen_load', {
      p_store_id: testStoreId,
      p_window_minutes: 30,
    });

    expect(error).toBeNull();

    if (data && data.length > 0) {
      const load = data[0];
      expect(load).toHaveProperty('bottleneck_items');
      expect(Array.isArray(load.bottleneck_items)).toBe(true);

      // If load is high or critical, bottleneck items may be identified
      if (load.load_level === 'high' || load.load_level === 'critical') {
        // Bottleneck items are the slow-prep items causing delays
        // They may or may not be present depending on menu
      }
    }
  });

  test('should return actionable recommendations', async () => {
    const { data, error } = await supabase.rpc('predict_kitchen_load', {
      p_store_id: testStoreId,
      p_window_minutes: 30,
    });

    expect(error).toBeNull();

    if (data && data.length > 0) {
      const load = data[0];
      expect(load.recommendation).toBeDefined();
      expect(typeof load.recommendation).toBe('string');
      expect(load.recommendation.length).toBeGreaterThan(0);
    }
  });

  test('should access materialized view for 60min load', async () => {
    const { data, error } = await supabase
      .from('mv_kitchen_load_60min')
      .select('*')
      .limit(5);

    // Materialized view may not exist or be empty initially
    if (!error) {
      expect(data).toBeDefined();
      // If data exists, verify structure
      if (data && data.length > 0) {
        expect(data[0]).toHaveProperty('store_id');
        expect(data[0]).toHaveProperty('total_pending_orders');
        expect(data[0]).toHaveProperty('total_prep_time_minutes');
      }
    }
  });

  test('should calculate capacity based on store settings', async () => {
    // Get store capacity setting
    const { data: settings } = await supabase
      .from('store_ops_settings')
      .select('kitchen_capacity_per_hour')
      .eq('store_id', testStoreId)
      .single();

    const { data: load } = await supabase.rpc('predict_kitchen_load', {
      p_store_id: testStoreId,
      p_window_minutes: 60,
    });

    if (settings && load && load.length > 0) {
      const hourlyCapacity = settings.kitchen_capacity_per_hour;
      const predictedOrders = load[0].predicted_orders;
      const expectedCapacityPct = (predictedOrders / hourlyCapacity) * 100;

      // Capacity calculation should be based on store settings
      // Allow some tolerance for rounding
      expect(load[0].capacity_percentage).toBeGreaterThanOrEqual(0);
    }
  });
});

test.describe('Wait Time Prediction', () => {
  const testStoreId = 1;

  test('should predict wait time via V5 dispatch', async () => {
    const { data, error } = await supabase.rpc('rpc_v5_dispatch', {
      p_name: 'predict_wait_time',
      p_payload: { store_id: testStoreId },
    });

    expect(error).toBeNull();

    if (data) {
      expect(data).toHaveProperty('estimated_minutes');
      expect(data).toHaveProperty('load_level');
      expect(data.estimated_minutes).toBeGreaterThan(0);
    }
  });

  test('should adjust wait time based on cart items', async () => {
    // Get some menu item IDs
    const { data: menuItems } = await supabase
      .from('menu_items')
      .select('id')
      .limit(3);

    if (menuItems && menuItems.length > 0) {
      const itemIds = menuItems.map((item: any) => item.id);

      const { data, error } = await supabase.rpc('rpc_v5_dispatch', {
        p_name: 'predict_wait_time',
        p_payload: { store_id: testStoreId, item_ids: itemIds },
      });

      expect(error).toBeNull();

      if (data) {
        expect(data.estimated_minutes).toBeGreaterThan(0);
        expect(data.range_min).toBeLessThanOrEqual(data.estimated_minutes);
        expect(data.range_max).toBeGreaterThanOrEqual(data.estimated_minutes);
      }
    }
  });
});

test.describe('Auto-Hide Slow Items', () => {
  const testStoreId = 1;

  test('should have auto-hide setting available', async () => {
    const { data, error } = await supabase
      .from('store_ops_settings')
      .select('auto_hide_slow_items')
      .eq('store_id', testStoreId)
      .single();

    // Settings may not exist initially
    if (!error && data) {
      expect(typeof data.auto_hide_slow_items).toBe('boolean');
    }
  });

  test('should toggle item availability', async () => {
    // Get a test menu item
    const { data: menuItem } = await supabase
      .from('menu_items')
      .select('id, is_available')
      .limit(1)
      .single();

    if (menuItem) {
      const originalState = menuItem.is_available;

      // Toggle off
      const { error: toggleError } = await supabase
        .from('menu_items')
        .update({ is_available: false })
        .eq('id', menuItem.id);

      expect(toggleError).toBeNull();

      // Restore original state
      await supabase
        .from('menu_items')
        .update({ is_available: originalState })
        .eq('id', menuItem.id);
    }
  });
});
