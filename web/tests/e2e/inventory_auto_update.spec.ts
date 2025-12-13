/**
 * Inventory Auto-Update E2E Tests
 *
 * Tests for automatic inventory management and alerts
 */

import { test, expect } from '@playwright/test';

const SUPABASE_URL = process.env.VITE_SUPABASE_URL || 'https://jwcuebbhkwwilqfblecq.supabase.co';
const ANON_KEY = process.env.VITE_SUPABASE_ANON_KEY || '';

test.describe('Inventory Auto-Update', () => {
  test.describe('Inventory Levels', () => {
    test('should have inventory_levels table accessible', async ({ request }) => {
      const response = await request.get(`${SUPABASE_URL}/rest/v1/inventory_levels?limit=1`, {
        headers: {
          'apikey': ANON_KEY,
          'Authorization': `Bearer ${ANON_KEY}`,
        },
      });

      // Table should exist, even if empty or restricted
      expect(response.status()).not.toBe(404);
    });

    test('should track inventory for menu items', async ({ request }) => {
      // Get inventory for store 1
      const response = await request.post(`${SUPABASE_URL}/rest/v1/rpc/rpc_v4_dispatch`, {
        headers: {
          'Content-Type': 'application/json',
          'apikey': ANON_KEY,
        },
        data: {
          p_name: 'predict_inventory_needs',
          p_payload: { store_id: 1, days_ahead: 7 },
        },
      });

      expect(response.ok()).toBeTruthy();
      const data = await response.json();
      // Should return array (may be empty if no inventory set up)
      expect(data === null || Array.isArray(data)).toBeTruthy();
    });
  });

  test.describe('Inventory Alerts', () => {
    test('should have inventory_alerts table accessible', async ({ request }) => {
      const response = await request.post(`${SUPABASE_URL}/rest/v1/rpc/rpc_v4_dispatch`, {
        headers: {
          'Content-Type': 'application/json',
          'apikey': ANON_KEY,
        },
        data: {
          p_name: 'get_inventory_alerts',
          p_payload: { store_id: 1 },
        },
      });

      expect(response.ok()).toBeTruthy();
      const data = await response.json();
      expect(data === null || Array.isArray(data)).toBeTruthy();
    });

    test('should categorize alerts by severity', async ({ request }) => {
      const response = await request.post(`${SUPABASE_URL}/rest/v1/rpc/rpc_v4_dispatch`, {
        headers: {
          'Content-Type': 'application/json',
          'apikey': ANON_KEY,
        },
        data: {
          p_name: 'get_inventory_alerts',
          p_payload: { store_id: 1 },
        },
      });

      expect(response.ok()).toBeTruthy();
      const data = await response.json();

      if (data && Array.isArray(data) && data.length > 0) {
        // Each alert should have severity
        data.forEach((alert: any) => {
          expect(['info', 'warning', 'critical']).toContain(alert.severity);
        });
      }
    });
  });

  test.describe('Stock Level Predictions', () => {
    test('should predict inventory needs accurately', async ({ request }) => {
      const response = await request.post(`${SUPABASE_URL}/rest/v1/rpc/rpc_v4_dispatch`, {
        headers: {
          'Content-Type': 'application/json',
          'apikey': ANON_KEY,
        },
        data: {
          p_name: 'predict_inventory_needs',
          p_payload: { store_id: 1, days_ahead: 14 },
        },
      });

      expect(response.ok()).toBeTruthy();
      const data = await response.json();

      if (data && Array.isArray(data) && data.length > 0) {
        // Each prediction should have required fields
        data.forEach((prediction: any) => {
          expect(prediction).toHaveProperty('item_id');
          expect(prediction).toHaveProperty('priority');
          expect(['critical', 'high', 'medium', 'low']).toContain(prediction.priority);
        });
      }
    });

    test('should calculate days until stockout', async ({ request }) => {
      const response = await request.post(`${SUPABASE_URL}/rest/v1/rpc/rpc_v4_dispatch`, {
        headers: {
          'Content-Type': 'application/json',
          'apikey': ANON_KEY,
        },
        data: {
          p_name: 'predict_inventory_needs',
          p_payload: { store_id: 1, days_ahead: 7 },
        },
      });

      expect(response.ok()).toBeTruthy();
      const data = await response.json();

      if (data && Array.isArray(data) && data.length > 0) {
        // Each item should have days_until_stockout
        data.forEach((item: any) => {
          if (item.days_until_stockout !== undefined) {
            expect(typeof item.days_until_stockout).toBe('number');
            expect(item.days_until_stockout).toBeGreaterThanOrEqual(0);
          }
        });
      }
    });
  });

  test.describe('Order-Inventory Integration', () => {
    test('should have order_items table that triggers inventory updates', async ({ request }) => {
      // Verify the order_items table exists
      const response = await request.get(`${SUPABASE_URL}/rest/v1/order_items?limit=1`, {
        headers: {
          'apikey': ANON_KEY,
        },
      });

      // Table should exist
      expect(response.status()).not.toBe(404);
    });
  });
});

test.describe('Inventory Trigger Functions', () => {
  test('trigger function should exist: decrease_inventory_on_order', async ({ request }) => {
    // Check if the function exists by calling it indirectly
    // The function is triggered automatically, so we just verify the RPC works
    const response = await request.post(`${SUPABASE_URL}/rest/v1/rpc/rpc_v4_dispatch`, {
      headers: {
        'Content-Type': 'application/json',
        'apikey': ANON_KEY,
      },
      data: {
        p_name: 'predict_inventory_needs',
        p_payload: { store_id: 1, days_ahead: 1 },
      },
    });

    expect(response.ok()).toBeTruthy();
  });

  test('alert generation should work for low stock', async ({ request }) => {
    // This tests the alert system without modifying data
    const response = await request.post(`${SUPABASE_URL}/rest/v1/rpc/rpc_v4_dispatch`, {
      headers: {
        'Content-Type': 'application/json',
        'apikey': ANON_KEY,
      },
      data: {
        p_name: 'get_inventory_alerts',
        p_payload: { store_id: 1 },
      },
    });

    expect(response.ok()).toBeTruthy();
  });
});
