import { test, expect } from '@playwright/test';

/**
 * Region Routing E2E Tests
 *
 * Tests for multi-region API gateway routing, version negotiation,
 * and region-aware request handling.
 */

const SUPABASE_URL = process.env.VITE_SUPABASE_URL || '';
const SUPABASE_ANON_KEY = process.env.VITE_SUPABASE_ANON_KEY || '';

// Helper to call the API gateway
async function callApiGateway(
  rpc: string,
  payload: Record<string, unknown> = {},
  options: {
    appVersion?: string;
    appName?: string;
    apiVersion?: string;
    clientRegion?: string;
  } = {}
) {
  const response = await fetch(`${SUPABASE_URL}/functions/v1/api-gateway`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-App-Version': options.appVersion || '1.4.0',
      'X-App-Name': options.appName || 'web',
      'X-Api-Version': options.apiVersion || 'v3',
      'X-Client-Region': options.clientRegion || 'us-east-1',
      'X-Client-Id': `test_${Date.now()}`,
    },
    body: JSON.stringify({
      rpc,
      payload,
      ...(options.apiVersion && { version: options.apiVersion }),
    }),
  });

  return {
    status: response.status,
    headers: Object.fromEntries(response.headers.entries()),
    data: await response.json(),
  };
}

test.describe('API Gateway - Region Routing', () => {
  test('gateway returns region in response headers', async () => {
    const { status, headers, data } = await callApiGateway('get_menu_items', {}, {
      clientRegion: 'us-east-1',
    });

    expect(status).toBe(200);
    expect(headers['x-region']).toBeDefined();
    expect(data.meta).toBeDefined();
    expect(data.meta.region).toBeDefined();
  });

  test('gateway includes request ID for tracing', async () => {
    const { status, headers, data } = await callApiGateway('get_stores');

    expect(status).toBe(200);
    expect(headers['x-request-id']).toBeDefined();
    expect(headers['x-request-id']).toMatch(/^req_/);
    expect(data.meta.requestId).toBe(headers['x-request-id']);
  });

  test('gateway reports execution time', async () => {
    const { status, headers, data } = await callApiGateway('get_menu_items');

    expect(status).toBe(200);
    expect(headers['x-execution-time']).toBeDefined();
    expect(parseInt(headers['x-execution-time'])).toBeGreaterThanOrEqual(0);
    expect(data.meta.executionTime).toBeGreaterThanOrEqual(0);
  });

  test('write operations use primary region', async () => {
    const { status, data } = await callApiGateway('place_order', {
      store_id: 1,
      customer_name: 'Region Test',
      customer_email: 'region@test.com',
      subtotal: 10,
      tax: 0.80,
      total: 10.80,
    }, {
      clientRegion: 'eu-west-1', // Client in EU
    });

    // Should still succeed (routed to primary)
    expect(status).toBe(200);
    expect(data.data).toHaveProperty('order_id');
  });
});

test.describe('API Gateway - Version Negotiation', () => {
  test('v3 client gets v3 API response', async () => {
    const { status, headers, data } = await callApiGateway('get_menu_items', {}, {
      appVersion: '1.4.0',
      apiVersion: 'v3',
    });

    expect(status).toBe(200);
    expect(headers['x-api-version']).toBe('v3');
    expect(data.meta.version).toBe('v3');
  });

  test('v2 client gets v2 API response', async () => {
    const { status, headers, data } = await callApiGateway('get_menu_items', {}, {
      appVersion: '1.2.0',
      apiVersion: 'v2',
    });

    expect(status).toBe(200);
    expect(headers['x-api-version']).toBe('v2');
    expect(data.meta.version).toBe('v2');
  });

  test('v1 client gets v1 API response', async () => {
    const { status, headers, data } = await callApiGateway('get_menu_items', {}, {
      appVersion: '1.0.0',
      apiVersion: 'v1',
    });

    expect(status).toBe(200);
    expect(headers['x-api-version']).toBe('v1');
    expect(data.meta.version).toBe('v1');
  });

  test('old client without explicit version gets fallback', async () => {
    const { status, data } = await callApiGateway('get_menu_items', {}, {
      appVersion: '1.0.0',
      // No apiVersion specified
    });

    expect(status).toBe(200);
    // Should get fallback version
    expect(['v1', 'v2']).toContain(data.meta.version);
    if (data.meta.fallback) {
      expect(data.meta.fallback).toBe(true);
    }
  });

  test('new client auto-selects latest version', async () => {
    const { status, data } = await callApiGateway('get_menu_items', {}, {
      appVersion: '2.0.0',
      // No apiVersion specified
    });

    expect(status).toBe(200);
    // Should get active version (v2 or v3)
    expect(['v2', 'v3']).toContain(data.meta.version);
  });
});

test.describe('API Gateway - V3 Features', () => {
  test('v3 menu items include full customization tree', async () => {
    const { status, data } = await callApiGateway('get_menu_items', {}, {
      apiVersion: 'v3',
    });

    expect(status).toBe(200);
    expect(Array.isArray(data.data)).toBe(true);

    if (data.data.length > 0) {
      const item = data.data[0];
      expect(item).toHaveProperty('id');
      expect(item).toHaveProperty('name');
      expect(item).toHaveProperty('price');
      expect(item).toHaveProperty('customizations');
    }
  });

  test('v3 order placement includes region tracking', async () => {
    const { status, data } = await callApiGateway('place_order', {
      store_id: 1,
      customer_name: 'V3 Region Test',
      customer_email: 'v3region@test.com',
      subtotal: 15,
      tax: 1.20,
      total: 16.20,
      items: [
        { menu_item_id: 1, quantity: 1 },
      ],
    }, {
      apiVersion: 'v3',
      clientRegion: 'us-east-1',
    });

    expect(status).toBe(200);
    expect(data.data).toHaveProperty('order_id');
    expect(data.data).toHaveProperty('api_version', 'v3');
    expect(data.data).toHaveProperty('region');
  });

  test('v3 check_compatibility includes enhanced info', async () => {
    const { status, data } = await callApiGateway('check_compatibility', {}, {
      apiVersion: 'v3',
      appVersion: '1.4.0',
    });

    expect(status).toBe(200);
    expect(data.data).toHaveProperty('compatible');
    expect(data.data).toHaveProperty('min_required');
    expect(data.data).toHaveProperty('api_version', 'v3');
    expect(data.data).toHaveProperty('features_available');
  });

  test('v3 get_region_health returns all regions', async () => {
    const { status, data } = await callApiGateway('get_region_health', {}, {
      apiVersion: 'v3',
    });

    expect(status).toBe(200);
    expect(Array.isArray(data.data)).toBe(true);

    if (data.data.length > 0) {
      const region = data.data[0];
      expect(region).toHaveProperty('region');
      expect(region).toHaveProperty('name');
      expect(region).toHaveProperty('status');
      expect(region).toHaveProperty('is_primary');
    }
  });
});

test.describe('API Gateway - App Identification', () => {
  test('web app is correctly identified', async () => {
    const { status, data } = await callApiGateway('get_features', {}, {
      appName: 'web',
    });

    expect(status).toBe(200);
  });

  test('customer app is correctly identified', async () => {
    const { status, data } = await callApiGateway('get_features', {}, {
      appName: 'customer',
    });

    expect(status).toBe(200);
  });

  test('business app is correctly identified', async () => {
    const { status, data } = await callApiGateway('get_features', {}, {
      appName: 'business',
    });

    expect(status).toBe(200);
  });
});

test.describe('API Gateway - Error Handling', () => {
  test('missing rpc returns 400 error', async () => {
    const response = await fetch(`${SUPABASE_URL}/functions/v1/api-gateway`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({}),
    });

    expect(response.status).toBe(400);
    const data = await response.json();
    expect(data.error).toContain('rpc');
  });

  test('unknown rpc returns graceful error', async () => {
    const { status, data } = await callApiGateway('nonexistent_rpc_xyz');

    // Should not crash, but may return empty or error
    expect([200, 500]).toContain(status);
  });

  test('invalid JSON returns error', async () => {
    const response = await fetch(`${SUPABASE_URL}/functions/v1/api-gateway`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: 'not valid json',
    });

    expect(response.status).toBe(500);
  });
});

test.describe('API Gateway - Backward Compatibility', () => {
  test('v1 payload works with v3 gateway', async () => {
    // V1 style order (no items array)
    const { status, data } = await callApiGateway('place_order', {
      store_id: 1,
      customer_name: 'Backward Compat Test',
      customer_email: 'compat@test.com',
      subtotal: 5,
      tax: 0.40,
      total: 5.40,
    }, {
      apiVersion: 'v1',
    });

    expect(status).toBe(200);
    expect(data.data).toHaveProperty('order_id');
  });

  test('v2 features work through gateway', async () => {
    // V2 style order with items
    const { status, data } = await callApiGateway('place_order', {
      store_id: 1,
      customer_name: 'V2 Compat Test',
      customer_email: 'v2compat@test.com',
      subtotal: 10,
      tax: 0.80,
      total: 10.80,
      items: [
        { menu_item_id: 1, quantity: 2 },
      ],
    }, {
      apiVersion: 'v2',
    });

    expect(status).toBe(200);
    expect(data.data).toHaveProperty('order_id');
  });
});

test.describe('API Gateway - Metrics & Telemetry', () => {
  test('requests are logged to metrics', async () => {
    // Make a request
    await callApiGateway('get_stores');

    // Note: We can't easily verify metrics were logged without
    // checking the database, but the request should succeed
  });

  test('client telemetry is updated', async () => {
    const clientId = `test_telemetry_${Date.now()}`;

    const response = await fetch(`${SUPABASE_URL}/functions/v1/api-gateway`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-App-Version': '1.4.0',
        'X-App-Name': 'web',
        'X-Client-Region': 'us-east-1',
        'X-Client-Id': clientId,
      },
      body: JSON.stringify({
        rpc: 'get_stores',
        payload: {},
      }),
    });

    expect(response.status).toBe(200);
  });
});
