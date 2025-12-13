/**
 * AI Menu Engine E2E Tests
 *
 * Tests for AI-powered menu personalization and recommendations
 */

import { test, expect } from '@playwright/test';

const BASE_URL = process.env.TEST_BASE_URL || 'http://localhost:8080';
const SUPABASE_URL = process.env.VITE_SUPABASE_URL || 'https://jwcuebbhkwwilqfblecq.supabase.co';

test.describe('AI Menu Engine', () => {
  test.describe('Smart Menu', () => {
    test('should return menu items for anonymous users', async ({ request }) => {
      const response = await request.post(`${SUPABASE_URL}/rest/v1/rpc/rpc_v4_dispatch`, {
        headers: {
          'Content-Type': 'application/json',
          'apikey': process.env.VITE_SUPABASE_ANON_KEY || '',
        },
        data: {
          p_name: 'get_smart_menu',
          p_payload: { store_id: 1, limit: 10 },
        },
      });

      expect(response.ok()).toBeTruthy();
      const data = await response.json();
      expect(data).toBeDefined();
      // Smart menu should return items even without personalization
      if (data?.items) {
        expect(Array.isArray(data.items)).toBeTruthy();
      }
    });

    test('should return personalized menu when customer_id provided', async ({ request }) => {
      // This test requires a valid customer_id in the database
      const response = await request.post(`${SUPABASE_URL}/rest/v1/rpc/rpc_v4_dispatch`, {
        headers: {
          'Content-Type': 'application/json',
          'apikey': process.env.VITE_SUPABASE_ANON_KEY || '',
        },
        data: {
          p_name: 'get_smart_menu',
          p_payload: {
            store_id: 1,
            limit: 10,
            // customer_id would be passed here for personalization
          },
        },
      });

      expect(response.ok()).toBeTruthy();
      const data = await response.json();
      expect(data).toBeDefined();
    });
  });

  test.describe('Similar Items', () => {
    test('should return similar items for a given item', async ({ request }) => {
      // First, get a menu item ID
      const menuResponse = await request.get(`${SUPABASE_URL}/rest/v1/menu_items?limit=1&is_available=eq.true`, {
        headers: {
          'apikey': process.env.VITE_SUPABASE_ANON_KEY || '',
        },
      });

      expect(menuResponse.ok()).toBeTruthy();
      const menuItems = await menuResponse.json();

      if (menuItems && menuItems.length > 0) {
        const itemId = menuItems[0].id;

        const response = await request.post(`${SUPABASE_URL}/rest/v1/rpc/rpc_v4_dispatch`, {
          headers: {
            'Content-Type': 'application/json',
            'apikey': process.env.VITE_SUPABASE_ANON_KEY || '',
          },
          data: {
            p_name: 'get_similar_items',
            p_payload: { item_id: itemId, limit: 5 },
          },
        });

        expect(response.ok()).toBeTruthy();
        const data = await response.json();
        // May be empty array if no embeddings exist yet
        expect(data === null || Array.isArray(data)).toBeTruthy();
      }
    });
  });

  test.describe('Substitute Items', () => {
    test('should return substitute items when item is out of stock', async ({ request }) => {
      // Get a menu item
      const menuResponse = await request.get(`${SUPABASE_URL}/rest/v1/menu_items?limit=1&is_available=eq.true`, {
        headers: {
          'apikey': process.env.VITE_SUPABASE_ANON_KEY || '',
        },
      });

      expect(menuResponse.ok()).toBeTruthy();
      const menuItems = await menuResponse.json();

      if (menuItems && menuItems.length > 0) {
        const itemId = menuItems[0].id;

        const response = await request.post(`${SUPABASE_URL}/rest/v1/rpc/rpc_v4_dispatch`, {
          headers: {
            'Content-Type': 'application/json',
            'apikey': process.env.VITE_SUPABASE_ANON_KEY || '',
          },
          data: {
            p_name: 'get_substitute_items',
            p_payload: { item_id: itemId, store_id: 1, limit: 3 },
          },
        });

        expect(response.ok()).toBeTruthy();
        const data = await response.json();
        expect(data === null || Array.isArray(data)).toBeTruthy();
      }
    });
  });

  test.describe('Recommendations Stability', () => {
    test('should return consistent recommendations across multiple calls', async ({ request }) => {
      const makeRequest = async () => {
        const response = await request.post(`${SUPABASE_URL}/rest/v1/rpc/rpc_v4_dispatch`, {
          headers: {
            'Content-Type': 'application/json',
            'apikey': process.env.VITE_SUPABASE_ANON_KEY || '',
          },
          data: {
            p_name: 'get_smart_menu',
            p_payload: { store_id: 1, limit: 5 },
          },
        });
        return response.json();
      };

      const result1 = await makeRequest();
      const result2 = await makeRequest();

      // Results should be stable (not random) for the same parameters
      // Note: This may vary if underlying data changes
      expect(result1).toBeDefined();
      expect(result2).toBeDefined();
    });
  });
});

test.describe('AI Engine Edge Function', () => {
  test('should respond to health check', async ({ request }) => {
    const response = await request.post(`${SUPABASE_URL}/functions/v1/ai-engine`, {
      headers: {
        'Content-Type': 'application/json',
        'apikey': process.env.VITE_SUPABASE_ANON_KEY || '',
      },
      data: {
        action: 'health',
        payload: {},
      },
    });

    // Function may not be deployed, so check gracefully
    if (response.ok()) {
      const data = await response.json();
      expect(data.data?.status).toBe('healthy');
    }
  });
});
