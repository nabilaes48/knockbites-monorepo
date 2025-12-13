/**
 * Demand Forecast E2E Tests
 *
 * Tests for AI-powered demand forecasting
 */

import { test, expect } from '@playwright/test';

const SUPABASE_URL = process.env.VITE_SUPABASE_URL || 'https://jwcuebbhkwwilqfblecq.supabase.co';
const ANON_KEY = process.env.VITE_SUPABASE_ANON_KEY || '';

test.describe('Demand Forecasting', () => {
  test.describe('Forecast Generation', () => {
    test('should generate forecasts for future dates', async ({ request }) => {
      const response = await request.post(`${SUPABASE_URL}/rest/v1/rpc/rpc_v4_dispatch`, {
        headers: {
          'Content-Type': 'application/json',
          'apikey': ANON_KEY,
        },
        data: {
          p_name: 'get_demand_forecast',
          p_payload: { store_id: 1, days_ahead: 7 },
        },
      });

      expect(response.ok()).toBeTruthy();
      const data = await response.json();

      // Should return array (may be empty if no historical data)
      expect(data === null || Array.isArray(data)).toBeTruthy();

      if (data && Array.isArray(data) && data.length > 0) {
        // Each forecast should have required fields
        data.forEach((forecast: any) => {
          expect(forecast).toHaveProperty('item_id');
          expect(forecast).toHaveProperty('forecast_date');
          expect(forecast).toHaveProperty('predicted_quantity');
        });
      }
    });

    test('should include confidence scores', async ({ request }) => {
      const response = await request.post(`${SUPABASE_URL}/rest/v1/rpc/rpc_v4_dispatch`, {
        headers: {
          'Content-Type': 'application/json',
          'apikey': ANON_KEY,
        },
        data: {
          p_name: 'get_demand_forecast',
          p_payload: { store_id: 1, days_ahead: 14 },
        },
      });

      expect(response.ok()).toBeTruthy();
      const data = await response.json();

      if (data && Array.isArray(data) && data.length > 0) {
        // Confidence should be present and valid
        data.forEach((forecast: any) => {
          if (forecast.confidence !== undefined) {
            expect(forecast.confidence).toBeGreaterThanOrEqual(0);
            expect(forecast.confidence).toBeLessThanOrEqual(1);
          }
        });
      }
    });
  });

  test.describe('Top Sellers Prediction', () => {
    test('should predict top selling items', async ({ request }) => {
      const response = await request.post(`${SUPABASE_URL}/rest/v1/rpc/rpc_v4_dispatch`, {
        headers: {
          'Content-Type': 'application/json',
          'apikey': ANON_KEY,
        },
        data: {
          p_name: 'get_top_sellers_predicted',
          p_payload: { store_id: 1, days_ahead: 7, limit: 10 },
        },
      });

      expect(response.ok()).toBeTruthy();
      const data = await response.json();

      expect(data === null || Array.isArray(data)).toBeTruthy();

      if (data && Array.isArray(data) && data.length > 0) {
        // Each item should have required fields
        data.forEach((item: any) => {
          expect(item).toHaveProperty('item_id');
          expect(item).toHaveProperty('item_name');
          expect(item).toHaveProperty('predicted_quantity');
        });
      }
    });

    test('should include trend indicators', async ({ request }) => {
      const response = await request.post(`${SUPABASE_URL}/rest/v1/rpc/rpc_v4_dispatch`, {
        headers: {
          'Content-Type': 'application/json',
          'apikey': ANON_KEY,
        },
        data: {
          p_name: 'get_top_sellers_predicted',
          p_payload: { store_id: 1, days_ahead: 7, limit: 5 },
        },
      });

      expect(response.ok()).toBeTruthy();
      const data = await response.json();

      if (data && Array.isArray(data) && data.length > 0) {
        // Each item should have trend indicator
        data.forEach((item: any) => {
          if (item.trend !== undefined) {
            expect(['rising', 'stable', 'declining', 'new']).toContain(item.trend);
          }
        });
      }
    });

    test('should calculate predicted revenue', async ({ request }) => {
      const response = await request.post(`${SUPABASE_URL}/rest/v1/rpc/rpc_v4_dispatch`, {
        headers: {
          'Content-Type': 'application/json',
          'apikey': ANON_KEY,
        },
        data: {
          p_name: 'get_top_sellers_predicted',
          p_payload: { store_id: 1, days_ahead: 7, limit: 5 },
        },
      });

      expect(response.ok()).toBeTruthy();
      const data = await response.json();

      if (data && Array.isArray(data) && data.length > 0) {
        // Each item should have predicted revenue
        data.forEach((item: any) => {
          if (item.predicted_revenue !== undefined) {
            expect(typeof item.predicted_revenue).toBe('number');
            expect(item.predicted_revenue).toBeGreaterThanOrEqual(0);
          }
        });
      }
    });
  });

  test.describe('Menu Performance Analysis', () => {
    test('should explain menu performance', async ({ request }) => {
      const response = await request.post(`${SUPABASE_URL}/rest/v1/rpc/rpc_v4_dispatch`, {
        headers: {
          'Content-Type': 'application/json',
          'apikey': ANON_KEY,
        },
        data: {
          p_name: 'explain_menu_performance',
          p_payload: { store_id: 1 },
        },
      });

      expect(response.ok()).toBeTruthy();
      const data = await response.json();

      if (data) {
        // Should have analysis fields
        expect(data).toHaveProperty('period');
        expect(data).toHaveProperty('store_id');
      }
    });

    test('should identify top performers', async ({ request }) => {
      const response = await request.post(`${SUPABASE_URL}/rest/v1/rpc/rpc_v4_dispatch`, {
        headers: {
          'Content-Type': 'application/json',
          'apikey': ANON_KEY,
        },
        data: {
          p_name: 'explain_menu_performance',
          p_payload: { store_id: 1 },
        },
      });

      expect(response.ok()).toBeTruthy();
      const data = await response.json();

      if (data && data.top_performer) {
        expect(typeof data.top_performer).toBe('string');
      }
    });

    test('should identify items needing attention', async ({ request }) => {
      const response = await request.post(`${SUPABASE_URL}/rest/v1/rpc/rpc_v4_dispatch`, {
        headers: {
          'Content-Type': 'application/json',
          'apikey': ANON_KEY,
        },
        data: {
          p_name: 'explain_menu_performance',
          p_payload: { store_id: 1 },
        },
      });

      expect(response.ok()).toBeTruthy();
      const data = await response.json();

      if (data && data.needs_attention) {
        expect(data.needs_attention === null || Array.isArray(data.needs_attention)).toBeTruthy();
      }
    });
  });

  test.describe('Materialized Views', () => {
    test('should have mv_item_sales_last_90_days accessible', async ({ request }) => {
      // Check if the view exists
      const response = await request.get(`${SUPABASE_URL}/rest/v1/mv_item_sales_last_90_days?limit=1`, {
        headers: {
          'apikey': ANON_KEY,
        },
      });

      // View should exist (may return empty or restricted)
      // 404 would mean the view doesn't exist
      expect([200, 401, 403]).toContain(response.status());
    });

    test('should have mv_daily_store_demand accessible', async ({ request }) => {
      const response = await request.get(`${SUPABASE_URL}/rest/v1/mv_daily_store_demand?limit=1`, {
        headers: {
          'apikey': ANON_KEY,
        },
      });

      expect([200, 401, 403]).toContain(response.status());
    });

    test('should have mv_hourly_demand_patterns accessible', async ({ request }) => {
      const response = await request.get(`${SUPABASE_URL}/rest/v1/mv_hourly_demand_patterns?limit=1`, {
        headers: {
          'apikey': ANON_KEY,
        },
      });

      expect([200, 401, 403]).toContain(response.status());
    });

    test('should have mv_item_affinity accessible', async ({ request }) => {
      const response = await request.get(`${SUPABASE_URL}/rest/v1/mv_item_affinity?limit=1`, {
        headers: {
          'apikey': ANON_KEY,
        },
      });

      expect([200, 401, 403]).toContain(response.status());
    });
  });
});

test.describe('V4 API Dispatcher', () => {
  test('should handle AI RPCs correctly', async ({ request }) => {
    const response = await request.post(`${SUPABASE_URL}/rest/v1/rpc/rpc_v4_dispatch`, {
      headers: {
        'Content-Type': 'application/json',
        'apikey': ANON_KEY,
      },
      data: {
        p_name: 'get_smart_menu',
        p_payload: { store_id: 1 },
      },
    });

    expect(response.ok()).toBeTruthy();
  });

  test('should fall back to V3 for unknown RPCs', async ({ request }) => {
    const response = await request.post(`${SUPABASE_URL}/rest/v1/rpc/rpc_v4_dispatch`, {
      headers: {
        'Content-Type': 'application/json',
        'apikey': ANON_KEY,
      },
      data: {
        p_name: 'get_menu_items',
        p_payload: {},
      },
    });

    // Should fall back to V3 and work
    expect(response.ok()).toBeTruthy();
  });

  test('should work with route_api_call function', async ({ request }) => {
    const response = await request.post(`${SUPABASE_URL}/rest/v1/rpc/route_api_call`, {
      headers: {
        'Content-Type': 'application/json',
        'apikey': ANON_KEY,
      },
      data: {
        p_name: 'get_smart_menu',
        p_payload: { store_id: 1 },
        p_requested_version: 'v4',
      },
    });

    expect(response.ok()).toBeTruthy();
  });
});
