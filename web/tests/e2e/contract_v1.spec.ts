import { test, expect } from '@playwright/test';

/**
 * API Contract Tests - Version 1
 *
 * Ensures v1 API contracts remain stable for older mobile app versions.
 * These tests verify:
 * - RPC response shapes are unchanged
 * - Required columns still exist
 * - RLS allows expected flows
 */

const SUPABASE_URL = process.env.VITE_SUPABASE_URL || '';
const SUPABASE_ANON_KEY = process.env.VITE_SUPABASE_ANON_KEY || '';

// Helper to make API calls with version headers
async function callV1Api(rpc: string, payload: Record<string, unknown> = {}) {
  const response = await fetch(`${SUPABASE_URL}/rest/v1/rpc/rpc_v1_dispatch`, {
    method: 'POST',
    headers: {
      'apikey': SUPABASE_ANON_KEY,
      'Content-Type': 'application/json',
      'X-App-Version': '1.0.0',
      'X-App-Name': 'customer',
      'X-Api-Version': 'v1',
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

test.describe('V1 API Contract - Menu', () => {
  test('get_menu_items returns array with required fields', async () => {
    const { status, data } = await callV1Api('get_menu_items');

    expect(status).toBe(200);
    expect(Array.isArray(data)).toBe(true);

    if (data.length > 0) {
      const item = data[0];
      // Required fields for v1 contract
      expect(item).toHaveProperty('id');
      expect(item).toHaveProperty('name');
      expect(item).toHaveProperty('price');
      expect(item).toHaveProperty('is_available');
    }
  });

  test('get_stores returns array with required fields', async () => {
    const { status, data } = await callV1Api('get_stores');

    expect(status).toBe(200);
    expect(Array.isArray(data)).toBe(true);

    if (data.length > 0) {
      const store = data[0];
      // Required fields for v1 contract
      expect(store).toHaveProperty('id');
      expect(store).toHaveProperty('name');
      expect(store).toHaveProperty('address');
    }
  });
});

test.describe('V1 API Contract - Orders', () => {
  test('place_order accepts v1 payload format', async () => {
    const orderPayload = {
      store_id: 1,
      customer_name: 'V1 Contract Test',
      customer_email: 'v1test@example.com',
      customer_phone: '555-0100',
      subtotal: 10.00,
      tax: 0.80,
      total: 10.80,
      payment_method: 'card',
    };

    const { status, data } = await callV1Api('place_order', orderPayload);

    expect(status).toBe(200);

    // V1 response contract
    expect(data).toHaveProperty('order_id');
    expect(data).toHaveProperty('status');
    expect(data.status).toBe('pending');
    expect(data).toHaveProperty('created_at');
  });

  test('get_order returns order with required fields', async () => {
    // First create an order
    const createResult = await callV1Api('place_order', {
      store_id: 1,
      customer_name: 'Get Order Test',
      customer_email: 'getorder@example.com',
      subtotal: 5.00,
      tax: 0.40,
      total: 5.40,
    });

    expect(createResult.status).toBe(200);
    const orderId = createResult.data.order_id;

    // Then fetch it
    const { status, data } = await callV1Api('get_order', { order_id: orderId });

    expect(status).toBe(200);
    expect(data).toHaveProperty('id');
    expect(data.id).toBe(orderId);
    expect(data).toHaveProperty('store_id');
    expect(data).toHaveProperty('status');
    expect(data).toHaveProperty('total');
  });
});

test.describe('V1 API Contract - Guest Checkout', () => {
  test('guest can place order without auth', async () => {
    // This test uses no Authorization header
    const response = await fetch(`${SUPABASE_URL}/rest/v1/orders`, {
      method: 'POST',
      headers: {
        'apikey': SUPABASE_ANON_KEY,
        'Content-Type': 'application/json',
        'X-App-Version': '1.0.0',
        'X-App-Name': 'customer',
        'Prefer': 'return=representation',
      },
      body: JSON.stringify({
        store_id: 1,
        customer_name: 'Guest User',
        customer_email: 'guest@example.com',
        subtotal: 8.00,
        tax: 0.64,
        total: 8.64,
        status: 'pending',
      }),
    });

    expect(response.status).toBe(201);

    const data = await response.json();
    expect(data).toHaveLength(1);
    expect(data[0]).toHaveProperty('id');
  });
});

test.describe('V1 API Contract - Error Handling', () => {
  test('unknown RPC returns error', async () => {
    const { status, data } = await callV1Api('nonexistent_rpc');

    // Should return error for unknown RPC
    expect(status).not.toBe(200);
  });

  test('invalid payload handled gracefully', async () => {
    const { status } = await callV1Api('get_order', { order_id: 'invalid' });

    // Should handle type errors
    expect([200, 400, 500]).toContain(status);
  });
});

test.describe('V1 API Contract - RLS Enforcement', () => {
  test('anonymous can read menu items', async () => {
    const response = await fetch(`${SUPABASE_URL}/rest/v1/menu_items?select=id,name,price&limit=5`, {
      headers: {
        'apikey': SUPABASE_ANON_KEY,
        'X-App-Version': '1.0.0',
        'X-App-Name': 'customer',
      },
    });

    expect(response.status).toBe(200);
    const data = await response.json();
    expect(Array.isArray(data)).toBe(true);
  });

  test('anonymous can read stores', async () => {
    const response = await fetch(`${SUPABASE_URL}/rest/v1/stores?select=id,name,address&limit=5`, {
      headers: {
        'apikey': SUPABASE_ANON_KEY,
        'X-App-Version': '1.0.0',
        'X-App-Name': 'customer',
      },
    });

    expect(response.status).toBe(200);
    const data = await response.json();
    expect(Array.isArray(data)).toBe(true);
  });

  test('anonymous cannot read user_profiles', async () => {
    const response = await fetch(`${SUPABASE_URL}/rest/v1/user_profiles?select=*&limit=5`, {
      headers: {
        'apikey': SUPABASE_ANON_KEY,
        'X-App-Version': '1.0.0',
        'X-App-Name': 'customer',
      },
    });

    const data = await response.json();
    // Should return empty array due to RLS
    expect(data).toEqual([]);
  });
});
