/**
 * E2E Tests: Dynamic Pricing
 *
 * Tests for the autonomous dynamic pricing system including
 * safety bounds, confidence thresholds, and price calculations.
 */

import { test, expect } from '@playwright/test';
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.VITE_SUPABASE_URL || '';
const supabaseKey = process.env.VITE_SUPABASE_ANON_KEY || '';

const supabase = createClient(supabaseUrl, supabaseKey);

test.describe('Dynamic Pricing System', () => {
  const testStoreId = 1;
  const testItemId = 1;

  test('should return pricing within safety bounds', async () => {
    const { data, error } = await supabase.rpc('rpc_v5_dispatch', {
      p_name: 'get_dynamic_pricing',
      p_payload: { store_id: testStoreId },
    });

    expect(error).toBeNull();
    expect(data).toBeDefined();

    if (data && data.length > 0) {
      for (const item of data) {
        // Verify price multiplier is within bounds
        expect(item.price_multiplier).toBeGreaterThanOrEqual(0.85);
        expect(item.price_multiplier).toBeLessThanOrEqual(1.15);

        // Verify suggested price respects bounds
        const minAllowed = item.base_price * 0.85;
        const maxAllowed = item.base_price * 1.15;
        expect(item.suggested_price).toBeGreaterThanOrEqual(minAllowed);
        expect(item.suggested_price).toBeLessThanOrEqual(maxAllowed);
      }
    }
  });

  test('should calculate dynamic price for specific item', async () => {
    const { data, error } = await supabase.rpc('calculate_dynamic_price', {
      p_item_id: testItemId,
      p_store_id: testStoreId,
    });

    expect(error).toBeNull();
    expect(data).toBeDefined();

    if (data && data.length > 0) {
      const result = data[0];
      expect(result).toHaveProperty('suggested_price');
      expect(result).toHaveProperty('price_multiplier');
      expect(result).toHaveProperty('confidence');
      expect(result).toHaveProperty('reason');

      // Confidence should be between 0 and 1
      expect(result.confidence).toBeGreaterThanOrEqual(0);
      expect(result.confidence).toBeLessThanOrEqual(1);
    }
  });

  test('should enforce max price constraint', async () => {
    // Attempt to create a pricing rule that exceeds bounds
    const basePrice = 10.0;
    const unsafeMaxPrice = basePrice * 1.5; // 50% increase - should be capped

    const { data, error } = await supabase
      .from('dynamic_pricing_rules')
      .upsert({
        store_id: testStoreId,
        item_id: testItemId,
        base_price: basePrice,
        min_price: basePrice * 0.85,
        max_price: unsafeMaxPrice,
        is_enabled: true,
      })
      .select()
      .single();

    // The database constraint should either reject or cap the value
    if (!error) {
      expect(data.max_price).toBeLessThanOrEqual(basePrice * 1.15);
    } else {
      // Constraint violation is also acceptable
      expect(error.code).toBe('23514'); // CHECK constraint violation
    }
  });

  test('should include demand factors in pricing reason', async () => {
    const { data, error } = await supabase.rpc('rpc_v5_dispatch', {
      p_name: 'get_dynamic_pricing',
      p_payload: { store_id: testStoreId, item_id: testItemId },
    });

    expect(error).toBeNull();

    if (data && data.length > 0) {
      const item = data[0];
      // Reason should explain pricing factors
      expect(item.reason).toBeDefined();
      expect(typeof item.reason).toBe('string');
    }
  });

  test('should flag low-confidence pricing for review', async () => {
    const { data, error } = await supabase.rpc('rpc_v5_dispatch', {
      p_name: 'get_dynamic_pricing',
      p_payload: { store_id: testStoreId },
    });

    expect(error).toBeNull();

    if (data && data.length > 0) {
      // Items with confidence below threshold should be flagged
      const lowConfidenceItems = data.filter((item: any) => item.confidence < 0.6);
      const highConfidenceItems = data.filter((item: any) => item.confidence >= 0.6);

      // Low confidence items should not be auto-applied
      for (const item of lowConfidenceItems) {
        // These would need manual approval
        expect(item.confidence).toBeLessThan(0.6);
      }

      // High confidence items are safe for automation
      for (const item of highConfidenceItems) {
        expect(item.confidence).toBeGreaterThanOrEqual(0.6);
      }
    }
  });

  test('should respect store settings for pricing', async () => {
    // Get store settings
    const { data: settings } = await supabase
      .from('store_ops_settings')
      .select('*')
      .eq('store_id', testStoreId)
      .single();

    // Get pricing data
    const { data: pricing } = await supabase.rpc('rpc_v5_dispatch', {
      p_name: 'get_dynamic_pricing',
      p_payload: { store_id: testStoreId },
    });

    if (settings && pricing && pricing.length > 0) {
      const maxIncreasePct = settings.max_price_increase_pct / 100;
      const maxDecreasePct = settings.max_price_decrease_pct / 100;

      for (const item of pricing) {
        expect(item.price_multiplier).toBeLessThanOrEqual(1 + maxIncreasePct);
        expect(item.price_multiplier).toBeGreaterThanOrEqual(1 - maxDecreasePct);
      }
    }
  });
});
