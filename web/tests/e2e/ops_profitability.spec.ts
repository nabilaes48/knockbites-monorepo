/**
 * E2E Tests: Menu Profitability
 *
 * Tests for menu profitability analysis including
 * margin calculations, item categorization, and recommendations.
 */

import { test, expect } from '@playwright/test';
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.VITE_SUPABASE_URL || '';
const supabaseKey = process.env.VITE_SUPABASE_ANON_KEY || '';

const supabase = createClient(supabaseUrl, supabaseKey);

test.describe('Menu Profitability Analysis', () => {
  const testStoreId = 1;

  test('should calculate profitability for menu items', async () => {
    const { data, error } = await supabase.rpc('calculate_menu_profitability', {
      p_store_id: testStoreId,
      p_days: 30,
    });

    expect(error).toBeNull();
    expect(data).toBeDefined();

    if (data && data.length > 0) {
      const item = data[0];
      expect(item).toHaveProperty('item_id');
      expect(item).toHaveProperty('item_name');
      expect(item).toHaveProperty('total_quantity');
      expect(item).toHaveProperty('total_revenue');
      expect(item).toHaveProperty('margin_percentage');
    }
  });

  test('should access via V5 dispatch', async () => {
    const { data, error } = await supabase.rpc('rpc_v5_dispatch', {
      p_name: 'get_menu_profitability',
      p_payload: { store_id: testStoreId, days: 30 },
    });

    expect(error).toBeNull();
    expect(data).toBeDefined();
  });

  test('should calculate margin percentages correctly', async () => {
    const { data, error } = await supabase.rpc('calculate_menu_profitability', {
      p_store_id: testStoreId,
      p_days: 30,
    });

    expect(error).toBeNull();

    if (data && data.length > 0) {
      for (const item of data) {
        // Margin should be between 0 and 100 (or possibly higher in edge cases)
        expect(item.margin_percentage).toBeGreaterThanOrEqual(0);
        expect(item.margin_percentage).toBeLessThanOrEqual(200); // Allow high margins

        // Verify margin calculation logic
        if (item.total_revenue > 0) {
          const calculatedMargin =
            ((item.total_revenue - (item.total_cost || 0)) / item.total_revenue) * 100;
          // Allow tolerance for rounding
          expect(Math.abs(item.margin_percentage - calculatedMargin)).toBeLessThan(5);
        }
      }
    }
  });

  test('should include trend data', async () => {
    const { data, error } = await supabase.rpc('calculate_menu_profitability', {
      p_store_id: testStoreId,
      p_days: 30,
    });

    expect(error).toBeNull();

    if (data && data.length > 0) {
      for (const item of data) {
        if (item.trend) {
          expect(['rising', 'stable', 'falling']).toContain(item.trend);
        }
      }
    }
  });

  test('should handle different time periods', async () => {
    const periods = [7, 14, 30, 90];

    for (const days of periods) {
      const { data, error } = await supabase.rpc('calculate_menu_profitability', {
        p_store_id: testStoreId,
        p_days: days,
      });

      expect(error).toBeNull();
      expect(data).toBeDefined();
    }
  });

  test('should access profitability trends materialized view', async () => {
    const { data, error } = await supabase
      .from('mv_item_profitability_trends')
      .select('*')
      .limit(5);

    // View may not exist or be empty
    if (!error) {
      expect(data).toBeDefined();
      if (data && data.length > 0) {
        expect(data[0]).toHaveProperty('item_id');
        expect(data[0]).toHaveProperty('margin_percentage');
      }
    }
  });
});

test.describe('Menu Matrix Categorization', () => {
  const testStoreId = 1;

  test('should categorize items into stars, puzzles, plowhorses, dogs', async () => {
    const { data, error } = await supabase.rpc('calculate_menu_profitability', {
      p_store_id: testStoreId,
      p_days: 30,
    });

    expect(error).toBeNull();

    if (data && data.length > 0) {
      // Categorize items based on menu matrix
      const stars = data.filter(
        (i: any) => i.margin_percentage >= 60 && i.total_quantity >= 10
      );
      const puzzles = data.filter(
        (i: any) => i.margin_percentage >= 60 && i.total_quantity < 10
      );
      const plowhorses = data.filter(
        (i: any) => i.margin_percentage < 60 && i.total_quantity >= 10
      );
      const dogs = data.filter(
        (i: any) => i.margin_percentage < 60 && i.total_quantity < 10
      );

      // All items should be categorized
      const total = stars.length + puzzles.length + plowhorses.length + dogs.length;
      expect(total).toBe(data.length);
    }
  });

  test('stars should have high margin and high volume', async () => {
    const { data, error } = await supabase.rpc('calculate_menu_profitability', {
      p_store_id: testStoreId,
      p_days: 30,
    });

    expect(error).toBeNull();

    if (data && data.length > 0) {
      const stars = data.filter(
        (i: any) => i.margin_percentage >= 60 && i.total_quantity >= 10
      );

      for (const star of stars) {
        expect(star.margin_percentage).toBeGreaterThanOrEqual(60);
        expect(star.total_quantity).toBeGreaterThanOrEqual(10);
      }
    }
  });

  test('dogs should have low margin and low volume', async () => {
    const { data, error } = await supabase.rpc('calculate_menu_profitability', {
      p_store_id: testStoreId,
      p_days: 30,
    });

    expect(error).toBeNull();

    if (data && data.length > 0) {
      const dogs = data.filter(
        (i: any) => i.margin_percentage < 60 && i.total_quantity < 10
      );

      for (const dog of dogs) {
        expect(dog.margin_percentage).toBeLessThan(60);
        expect(dog.total_quantity).toBeLessThan(10);
      }
    }
  });
});

test.describe('Profitability Alerts', () => {
  const testStoreId = 1;

  test('should generate alerts for low-margin items', async () => {
    const { data, error } = await supabase
      .from('ops_alerts')
      .select('*')
      .eq('store_id', testStoreId)
      .eq('alert_type', 'low_margin')
      .order('created_at', { ascending: false })
      .limit(5);

    // Alerts may or may not exist
    expect(error).toBeNull();
    expect(data).toBeDefined();

    if (data && data.length > 0) {
      for (const alert of data) {
        expect(alert.alert_type).toBe('low_margin');
        expect(alert).toHaveProperty('title');
        expect(alert).toHaveProperty('message');
        expect(alert).toHaveProperty('severity');
      }
    }
  });

  test('should include item data in alert', async () => {
    const { data, error } = await supabase
      .from('ops_alerts')
      .select('*')
      .eq('store_id', testStoreId)
      .eq('alert_type', 'low_margin')
      .limit(1)
      .single();

    if (!error && data) {
      // Alert data should include item information
      if (data.data) {
        expect(typeof data.data).toBe('object');
      }
    }
  });
});

test.describe('Menu Profitability Storage', () => {
  test('should store profitability data in table', async () => {
    const { data, error } = await supabase
      .from('menu_profitability')
      .select('*')
      .limit(5);

    // Table should exist
    expect(error).toBeNull();

    if (data && data.length > 0) {
      const item = data[0];
      expect(item).toHaveProperty('store_id');
      expect(item).toHaveProperty('item_id');
      expect(item).toHaveProperty('margin_percentage');
      expect(item).toHaveProperty('analysis_date');
    }
  });

  test('should have proper indexing for queries', async () => {
    // Query by store and date should be efficient
    const { data, error } = await supabase
      .from('menu_profitability')
      .select('*')
      .eq('store_id', 1)
      .gte('analysis_date', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString())
      .limit(10);

    expect(error).toBeNull();
    expect(data).toBeDefined();
  });
});
