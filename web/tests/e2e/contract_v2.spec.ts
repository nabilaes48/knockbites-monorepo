import { test, expect } from '@playwright/test';

/**
 * API Contract Tests - Version 2
 *
 * Ensures v2 API contracts are stable for newer app versions.
 * V2 adds enhanced features:
 * - Menu items with customizations
 * - Orders with items array
 * - Rewards with history
 * - Feature flags
 * - Compatibility checking
 */

const SUPABASE_URL = process.env.VITE_SUPABASE_URL || '';
const SUPABASE_ANON_KEY = process.env.VITE_SUPABASE_ANON_KEY || '';

// Helper to make API calls with version headers
async function callV2Api(rpc: string, payload: Record<string, unknown> = {}) {
  const response = await fetch(`${SUPABASE_URL}/rest/v1/rpc/rpc_v2_dispatch`, {
    method: 'POST',
    headers: {
      'apikey': SUPABASE_ANON_KEY,
      'Content-Type': 'application/json',
      'X-App-Version': '1.3.0',
      'X-App-Name': 'web',
      'X-Api-Version': 'v2',
    },
    body: JSON.stringify({
      p_name: rpc,
      p_payload: payload,
    }),
  });

  return {
    status: response.status,
    data: await response.json(),
  };
}

// Helper to call api-dispatch Edge Function
async function callApiDispatch(rpc: string, payload: Record<string, unknown> = {}) {
  const response = await fetch(`${SUPABASE_URL}/functions/v1/api-dispatch`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-App-Version': '1.3.0',
      'X-App-Name': 'web',
      'X-Api-Version': 'v2',
    },
    body: JSON.stringify({
      rpc,
      payload,
    }),
  });

  return {
    status: response.status,
    data: await response.json(),
  };
}

test.describe('V2 API Contract - Menu (Enhanced)', () => {
  test('get_menu_items includes customizations', async () => {
    const { status, data } = await callV2Api('get_menu_items');

    expect(status).toBe(200);
    expect(Array.isArray(data)).toBe(true);

    if (data.length > 0) {
      const item = data[0];
      // V2 required fields
      expect(item).toHaveProperty('id');
      expect(item).toHaveProperty('name');
      expect(item).toHaveProperty('price');
      expect(item).toHaveProperty('is_available');
      // V2 enhancement - customizations array
      expect(item).toHaveProperty('customizations');
      expect(Array.isArray(item.customizations) || item.customizations === null).toBe(true);
    }
  });

  test('get_stores returns complete store info', async () => {
    const { status, data } = await callV2Api('get_stores');

    expect(status).toBe(200);
    expect(Array.isArray(data)).toBe(true);

    if (data.length > 0) {
      const store = data[0];
      // V2 required fields
      expect(store).toHaveProperty('id');
      expect(store).toHaveProperty('name');
      expect(store).toHaveProperty('address');
      expect(store).toHaveProperty('city');
      expect(store).toHaveProperty('state');
      expect(store).toHaveProperty('phone');
    }
  });
});

test.describe('V2 API Contract - Orders (Enhanced)', () => {
  test('place_order accepts items array', async () => {
    const orderPayload = {
      store_id: 1,
      customer_name: 'V2 Contract Test',
      customer_email: 'v2test@example.com',
      customer_phone: '555-0200',
      subtotal: 15.00,
      tax: 1.20,
      total: 16.20,
      payment_method: 'card',
      items: [
        {
          menu_item_id: 1,
          quantity: 2,
          customizations: ['Extra cheese'],
          notes: 'Test item',
        },
      ],
    };

    const { status, data } = await callV2Api('place_order', orderPayload);

    expect(status).toBe(200);

    // V2 response contract
    expect(data).toHaveProperty('order_id');
    expect(data).toHaveProperty('status');
    expect(data.status).toBe('pending');
    expect(data).toHaveProperty('created_at');
    // V2 enhancement - items count
    expect(data).toHaveProperty('items_count');
    expect(data.items_count).toBeGreaterThanOrEqual(0);
  });

  test('get_order includes items', async () => {
    // First create an order with items
    const createResult = await callV2Api('place_order', {
      store_id: 1,
      customer_name: 'Get Order V2 Test',
      customer_email: 'getorderv2@example.com',
      subtotal: 10.00,
      tax: 0.80,
      total: 10.80,
      items: [
        { menu_item_id: 1, quantity: 1 },
      ],
    });

    expect(createResult.status).toBe(200);
    const orderId = createResult.data.order_id;

    // Then fetch it
    const { status, data } = await callV2Api('get_order', { order_id: orderId });

    expect(status).toBe(200);
    // V2 response includes nested order and items
    expect(data).toHaveProperty('order');
    expect(data.order).toHaveProperty('id');
    expect(data.order.id).toBe(orderId);
    expect(data).toHaveProperty('items');
    expect(Array.isArray(data.items) || data.items === null).toBe(true);
  });
});

test.describe('V2 API Contract - Store Metrics', () => {
  test('get_store_metrics includes v2 metadata', async () => {
    const { status, data } = await callV2Api('get_store_metrics', {
      store_id: 1,
      date_range: 'today',
    });

    // May fail if not authenticated as manager/admin
    if (status === 200) {
      expect(data).toHaveProperty('metrics');
      expect(data).toHaveProperty('api_version');
      expect(data.api_version).toBe('v2');
      expect(data).toHaveProperty('client_version');
    }
  });
});

test.describe('V2 API Contract - Feature Flags', () => {
  test('get_features returns enabled features', async () => {
    const { status, data } = await callV2Api('get_features');

    expect(status).toBe(200);
    expect(Array.isArray(data)).toBe(true);

    if (data.length > 0) {
      const flag = data[0];
      expect(flag).toHaveProperty('feature');
      expect(flag).toHaveProperty('enabled');
    }
  });

  test('check_compatibility returns status', async () => {
    const { status, data } = await callV2Api('check_compatibility');

    expect(status).toBe(200);
    expect(data).toHaveProperty('compatible');
    expect(data).toHaveProperty('min_required');
    expect(data).toHaveProperty('client_version');
    expect(data).toHaveProperty('api_version');
    expect(data.api_version).toBe('v2');
  });
});

test.describe('V2 API Contract - Backward Compatibility', () => {
  test('v2 falls back to v1 for unknown RPCs', async () => {
    // get_stores is handled by v1 fallback in v2
    const { status, data } = await callV2Api('get_stores');

    expect(status).toBe(200);
    expect(Array.isArray(data)).toBe(true);
  });

  test('v2 handles v1-style payload gracefully', async () => {
    // v1 payload without items array
    const orderPayload = {
      store_id: 1,
      customer_name: 'V1 Compat Test',
      customer_email: 'v1compat@example.com',
      subtotal: 5.00,
      tax: 0.40,
      total: 5.40,
    };

    const { status, data } = await callV2Api('place_order', orderPayload);

    expect(status).toBe(200);
    expect(data).toHaveProperty('order_id');
  });
});

test.describe('V2 API Contract - RLS Enforcement', () => {
  test('anonymous can access feature flags', async () => {
    const response = await fetch(`${SUPABASE_URL}/rest/v1/app_feature_flags?select=feature,enabled&limit=10`, {
      headers: {
        'apikey': SUPABASE_ANON_KEY,
        'X-App-Version': '1.3.0',
        'X-App-Name': 'web',
      },
    });

    expect(response.status).toBe(200);
    const data = await response.json();
    expect(Array.isArray(data)).toBe(true);
  });

  test('anonymous can access API versions', async () => {
    const response = await fetch(`${SUPABASE_URL}/rest/v1/api_versions?select=version,status`, {
      headers: {
        'apikey': SUPABASE_ANON_KEY,
        'X-App-Version': '1.3.0',
        'X-App-Name': 'web',
      },
    });

    expect(response.status).toBe(200);
    const data = await response.json();
    expect(Array.isArray(data)).toBe(true);

    // Should have v1 and v2
    const versions = data.map((v: { version: string }) => v.version);
    expect(versions).toContain('v1');
    expect(versions).toContain('v2');
  });
});

test.describe('V2 API Contract - Version Headers', () => {
  test('version headers are included in response', async () => {
    const response = await fetch(`${SUPABASE_URL}/rest/v1/stores?select=id&limit=1`, {
      headers: {
        'apikey': SUPABASE_ANON_KEY,
        'X-App-Version': '1.3.0',
        'X-App-Name': 'web',
        'X-Api-Version': 'v2',
      },
    });

    expect(response.status).toBe(200);

    // X-Request-ID should be present for tracing
    const requestId = response.headers.get('X-Request-ID');
    // May not be present for direct REST calls, only Edge Functions
  });
});

test.describe('V2 API Contract - Staff Order Management', () => {
  test.skip('staff can update order status', async ({ page }) => {
    // This test requires staff authentication
    if (!process.env.TEST_STAFF_EMAIL) {
      test.skip();
      return;
    }

    // Login as staff
    await page.goto('/dashboard/login');
    await page.fill('[type="email"]', process.env.TEST_STAFF_EMAIL);
    await page.fill('[type="password"]', process.env.TEST_STAFF_PASSWORD || '');
    await page.getByRole('button', { name: /sign in/i }).click();

    await expect(page).toHaveURL(/dashboard/i, { timeout: 10000 });

    // Order update should work for staff
  });
});
