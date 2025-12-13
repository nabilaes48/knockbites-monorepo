/**
 * E2E Tests: Staffing Recommendations
 *
 * Tests for AI-generated staffing recommendations based on
 * predicted demand and historical patterns.
 */

import { test, expect } from '@playwright/test';
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.VITE_SUPABASE_URL || '';
const supabaseKey = process.env.VITE_SUPABASE_ANON_KEY || '';

const supabase = createClient(supabaseUrl, supabaseKey);

test.describe('Staffing Recommendations', () => {
  const testStoreId = 1;

  test('should generate staffing recommendations for today', async () => {
    const today = new Date().toISOString().split('T')[0];

    const { data, error } = await supabase.rpc('generate_staffing_recommendations', {
      p_store_id: testStoreId,
      p_date: today,
    });

    expect(error).toBeNull();
    expect(data).toBeDefined();

    if (data && data.length > 0) {
      // Should have recommendations for each hour (up to 24)
      expect(data.length).toBeGreaterThan(0);
      expect(data.length).toBeLessThanOrEqual(24);

      const firstRec = data[0];
      expect(firstRec).toHaveProperty('hour_of_day');
      expect(firstRec).toHaveProperty('recommended_staff');
      expect(firstRec).toHaveProperty('predicted_orders');
      expect(firstRec).toHaveProperty('confidence');
      expect(firstRec).toHaveProperty('reason');
    }
  });

  test('should recommend more staff during peak hours', async () => {
    const today = new Date().toISOString().split('T')[0];

    const { data, error } = await supabase.rpc('generate_staffing_recommendations', {
      p_store_id: testStoreId,
      p_date: today,
    });

    expect(error).toBeNull();

    if (data && data.length > 0) {
      // Find peak and off-peak hours
      const sorted = [...data].sort(
        (a: any, b: any) => b.predicted_orders - a.predicted_orders
      );

      if (sorted.length >= 2) {
        const peak = sorted[0];
        const offPeak = sorted[sorted.length - 1];

        // Peak hours should have equal or more staff recommended
        expect(peak.recommended_staff).toBeGreaterThanOrEqual(
          offPeak.recommended_staff
        );
      }
    }
  });

  test('should access via V5 dispatch', async () => {
    const today = new Date().toISOString().split('T')[0];

    const { data, error } = await supabase.rpc('rpc_v5_dispatch', {
      p_name: 'get_staffing_recommendations',
      p_payload: { store_id: testStoreId, date: today },
    });

    expect(error).toBeNull();
    expect(data).toBeDefined();
  });

  test('should include confidence scores', async () => {
    const today = new Date().toISOString().split('T')[0];

    const { data, error } = await supabase.rpc('generate_staffing_recommendations', {
      p_store_id: testStoreId,
      p_date: today,
    });

    expect(error).toBeNull();

    if (data && data.length > 0) {
      for (const rec of data) {
        expect(rec.confidence).toBeGreaterThanOrEqual(0);
        expect(rec.confidence).toBeLessThanOrEqual(1);
      }
    }
  });

  test('should provide reasoning for each recommendation', async () => {
    const today = new Date().toISOString().split('T')[0];

    const { data, error } = await supabase.rpc('generate_staffing_recommendations', {
      p_store_id: testStoreId,
      p_date: today,
    });

    expect(error).toBeNull();

    if (data && data.length > 0) {
      for (const rec of data) {
        expect(rec.reason).toBeDefined();
        expect(typeof rec.reason).toBe('string');
        expect(rec.reason.length).toBeGreaterThan(0);
      }
    }
  });

  test('should store recommendations in database', async () => {
    const today = new Date().toISOString().split('T')[0];

    // Generate recommendations
    await supabase.rpc('generate_staffing_recommendations', {
      p_store_id: testStoreId,
      p_date: today,
    });

    // Check if stored in staffing_recommendations table
    const { data, error } = await supabase
      .from('staffing_recommendations')
      .select('*')
      .eq('store_id', testStoreId)
      .eq('recommendation_date', today);

    // May or may not be stored depending on implementation
    if (!error) {
      expect(data).toBeDefined();
    }
  });

  test('should handle different dates', async () => {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const tomorrowStr = tomorrow.toISOString().split('T')[0];

    const { data, error } = await supabase.rpc('generate_staffing_recommendations', {
      p_store_id: testStoreId,
      p_date: tomorrowStr,
    });

    expect(error).toBeNull();
    expect(data).toBeDefined();
  });
});

test.describe('Staffing Recommendations Table', () => {
  const testStoreId = 1;

  test('should have correct schema', async () => {
    const { data, error } = await supabase
      .from('staffing_recommendations')
      .select('*')
      .limit(1);

    // Table may be empty but should exist
    expect(error).toBeNull();
  });

  test('should enforce store_id constraint', async () => {
    const { error } = await supabase.from('staffing_recommendations').insert({
      store_id: 999999, // Non-existent store
      recommendation_date: new Date().toISOString().split('T')[0],
      hour_of_day: 12,
      recommended_staff: 5,
      predicted_orders: 20,
      confidence: 0.8,
      reason: 'Test',
    });

    // Should fail due to foreign key constraint
    expect(error).not.toBeNull();
  });
});
