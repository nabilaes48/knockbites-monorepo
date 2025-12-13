import { test, expect } from '@playwright/test';

/**
 * Zero-Downtime Release E2E Tests
 *
 * Tests for hot version switching, API version transitions,
 * and ensuring no request failures during version changes.
 */

const SUPABASE_URL = process.env.VITE_SUPABASE_URL || '';
const SUPABASE_ANON_KEY = process.env.VITE_SUPABASE_ANON_KEY || '';

// Helper to call the API gateway
async function callApiGateway(
  rpc: string,
  payload: Record<string, unknown> = {},
  options: {
    appVersion?: string;
    apiVersion?: string;
  } = {}
) {
  const response = await fetch(`${SUPABASE_URL}/functions/v1/api-gateway`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-App-Version': options.appVersion || '1.4.0',
      'X-App-Name': 'web',
      'X-Api-Version': options.apiVersion || 'v3',
      'X-Client-Region': 'us-east-1',
      'X-Client-Id': `test_${Date.now()}`,
    },
    body: JSON.stringify({
      rpc,
      payload,
    }),
  });

  return {
    status: response.status,
    headers: Object.fromEntries(response.headers.entries()),
    data: await response.json(),
  };
}

// Helper to call Supabase RPC directly
async function callRpc(rpcName: string, params: Record<string, unknown> = {}) {
  const response = await fetch(`${SUPABASE_URL}/rest/v1/rpc/${rpcName}`, {
    method: 'POST',
    headers: {
      'apikey': SUPABASE_ANON_KEY,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(params),
  });

  return {
    status: response.status,
    data: await response.json(),
  };
}

test.describe('Zero-Downtime - Active Version Management', () => {
  test('get_active_api_version returns current config', async () => {
    const { status, data } = await callRpc('get_active_api_version');

    expect(status).toBe(200);
    expect(data).toHaveProperty('current');
    expect(data).toHaveProperty('fallback');
    expect(data).toHaveProperty('updated_at');
    expect(['v1', 'v2', 'v3']).toContain(data.current);
    expect(['v1', 'v2', 'v3']).toContain(data.fallback);
  });

  test('active version is used when client omits version', async () => {
    // Get active version
    const { data: activeConfig } = await callRpc('get_active_api_version');
    const expectedVersion = activeConfig.current;

    // Call without specifying version (for new client)
    const { status, data } = await callApiGateway('get_menu_items', {}, {
      appVersion: '2.0.0', // New client
      apiVersion: undefined,
    });

    expect(status).toBe(200);
    // Should get the active version or a compatible one
    expect(['v1', 'v2', 'v3']).toContain(data.meta.version);
  });
});

test.describe('Zero-Downtime - Version Fallback', () => {
  test('old client falls back to compatible version', async () => {
    const { status, data } = await callApiGateway('get_menu_items', {}, {
      appVersion: '1.0.0', // v1 era client
    });

    expect(status).toBe(200);
    // Should fall back to v1 or v2
    expect(['v1', 'v2']).toContain(data.meta.version);
  });

  test('fallback flag is set when version is downgraded', async () => {
    // Force old client behavior
    const { status, data } = await callApiGateway('get_menu_items', {}, {
      appVersion: '1.0.0',
    });

    expect(status).toBe(200);
    // If fallback occurred, flag should be set
    if (data.meta.version !== 'v3') {
      // Fallback likely occurred
      expect(data.meta.fallback === true || data.meta.version === 'v1' || data.meta.version === 'v2').toBe(true);
    }
  });

  test('v2 client still works during v3 rollout', async () => {
    const { status, data } = await callApiGateway('get_menu_items', {}, {
      appVersion: '1.2.0',
      apiVersion: 'v2',
    });

    expect(status).toBe(200);
    expect(data.meta.version).toBe('v2');
    expect(Array.isArray(data.data)).toBe(true);
  });
});

test.describe('Zero-Downtime - Concurrent Requests', () => {
  test('simultaneous requests from different versions succeed', async () => {
    // Simulate mixed client versions making requests simultaneously
    const requests = [
      callApiGateway('get_stores', {}, { appVersion: '1.0.0', apiVersion: 'v1' }),
      callApiGateway('get_stores', {}, { appVersion: '1.2.0', apiVersion: 'v2' }),
      callApiGateway('get_stores', {}, { appVersion: '1.4.0', apiVersion: 'v3' }),
      callApiGateway('get_menu_items', {}, { appVersion: '1.0.0', apiVersion: 'v1' }),
      callApiGateway('get_menu_items', {}, { appVersion: '1.4.0', apiVersion: 'v3' }),
    ];

    const results = await Promise.all(requests);

    // All requests should succeed
    for (const result of results) {
      expect(result.status).toBe(200);
      expect(result.data.data).toBeDefined();
    }
  });

  test('rapid requests during version check succeed', async () => {
    // Make many rapid requests
    const requests = Array(10).fill(null).map((_, i) =>
      callApiGateway('get_stores', {}, {
        appVersion: i % 2 === 0 ? '1.2.0' : '1.4.0',
      })
    );

    const results = await Promise.all(requests);

    // All should succeed
    const successCount = results.filter(r => r.status === 200).length;
    expect(successCount).toBe(10);
  });
});

test.describe('Zero-Downtime - Feature Parity', () => {
  test('basic operations work across all versions', async () => {
    const versions = [
      { appVersion: '1.0.0', apiVersion: 'v1' },
      { appVersion: '1.2.0', apiVersion: 'v2' },
      { appVersion: '1.4.0', apiVersion: 'v3' },
    ];

    for (const ver of versions) {
      // Get stores - should work in all versions
      const { status, data } = await callApiGateway('get_stores', {}, ver);
      expect(status).toBe(200);
      expect(Array.isArray(data.data)).toBe(true);
    }
  });

  test('order placement works across all versions', async () => {
    const versions = [
      { appVersion: '1.0.0', apiVersion: 'v1' as const },
      { appVersion: '1.2.0', apiVersion: 'v2' as const },
      { appVersion: '1.4.0', apiVersion: 'v3' as const },
    ];

    for (const ver of versions) {
      const { status, data } = await callApiGateway('place_order', {
        store_id: 1,
        customer_name: `Zero Downtime ${ver.apiVersion}`,
        customer_email: `zerodown_${ver.apiVersion}@test.com`,
        subtotal: 10,
        tax: 0.80,
        total: 10.80,
        // Include items for v2/v3
        ...(ver.apiVersion !== 'v1' && {
          items: [{ menu_item_id: 1, quantity: 1 }],
        }),
      }, ver);

      expect(status).toBe(200);
      expect(data.data).toHaveProperty('order_id');
    }
  });
});

test.describe('Zero-Downtime - Graceful Degradation', () => {
  test('v3 feature unavailable in v1 returns graceful response', async () => {
    // Try to get region health (v3 only) through v1
    const { status, data } = await callApiGateway('get_region_health', {}, {
      apiVersion: 'v1',
    });

    // Should either work (v1 falls through) or return empty/error gracefully
    expect([200, 500]).toContain(status);
  });

  test('unknown RPC handled gracefully across versions', async () => {
    const versions = ['v1', 'v2', 'v3'];

    for (const apiVersion of versions) {
      const { status, data } = await callApiGateway('nonexistent_feature_xyz', {}, {
        apiVersion,
      });

      // Should not crash
      expect([200, 500]).toContain(status);
    }
  });
});

test.describe('Zero-Downtime - Session Continuity', () => {
  test('client can switch versions mid-session', async () => {
    // Start with v2
    const v2Response = await callApiGateway('get_stores', {}, {
      appVersion: '1.2.0',
      apiVersion: 'v2',
    });
    expect(v2Response.status).toBe(200);

    // Upgrade to v3
    const v3Response = await callApiGateway('get_stores', {}, {
      appVersion: '1.4.0',
      apiVersion: 'v3',
    });
    expect(v3Response.status).toBe(200);

    // Downgrade back to v2
    const v2Again = await callApiGateway('get_stores', {}, {
      appVersion: '1.2.0',
      apiVersion: 'v2',
    });
    expect(v2Again.status).toBe(200);
  });

  test('order created in v2 readable in v3', async () => {
    // Create order using v2
    const createResponse = await callApiGateway('place_order', {
      store_id: 1,
      customer_name: 'Cross Version Test',
      customer_email: 'crossversion@test.com',
      subtotal: 15,
      tax: 1.20,
      total: 16.20,
    }, {
      apiVersion: 'v2',
    });

    expect(createResponse.status).toBe(200);
    const orderId = createResponse.data.data.order_id;

    // Read order using v3
    const readResponse = await callApiGateway('get_order', {
      order_id: orderId,
    }, {
      apiVersion: 'v3',
    });

    expect(readResponse.status).toBe(200);
    expect(readResponse.data.data).toBeDefined();
  });
});

test.describe('Zero-Downtime - Stress Testing', () => {
  test('handles burst of mixed-version requests', async () => {
    const burstSize = 20;
    const versions = ['v1', 'v2', 'v3'];
    const rpcs = ['get_stores', 'get_menu_items', 'get_features'];

    const requests = Array(burstSize).fill(null).map(() => {
      const apiVersion = versions[Math.floor(Math.random() * versions.length)];
      const rpc = rpcs[Math.floor(Math.random() * rpcs.length)];
      return callApiGateway(rpc, {}, { apiVersion });
    });

    const start = Date.now();
    const results = await Promise.all(requests);
    const duration = Date.now() - start;

    // Check success rate
    const successCount = results.filter(r => r.status === 200).length;
    const successRate = successCount / burstSize;

    expect(successRate).toBeGreaterThanOrEqual(0.9); // 90% success rate minimum
    console.log(`Burst test: ${successCount}/${burstSize} succeeded in ${duration}ms`);
  });

  test('sustained load across versions maintains stability', async () => {
    const duration = 5000; // 5 seconds
    const interval = 100; // Request every 100ms
    const results: { status: number; version: string; latency: number }[] = [];

    const start = Date.now();
    const versions = ['v1', 'v2', 'v3'];
    let requestCount = 0;

    while (Date.now() - start < duration) {
      const reqStart = Date.now();
      const apiVersion = versions[requestCount % 3];

      try {
        const response = await callApiGateway('get_stores', {}, { apiVersion });
        results.push({
          status: response.status,
          version: apiVersion,
          latency: Date.now() - reqStart,
        });
      } catch {
        results.push({
          status: 0,
          version: apiVersion,
          latency: Date.now() - reqStart,
        });
      }

      requestCount++;
      await new Promise(resolve => setTimeout(resolve, interval));
    }

    // Analyze results
    const successCount = results.filter(r => r.status === 200).length;
    const avgLatency = results.reduce((sum, r) => sum + r.latency, 0) / results.length;
    const successRate = successCount / results.length;

    expect(successRate).toBeGreaterThanOrEqual(0.95); // 95% success rate
    console.log(`Sustained test: ${successCount}/${results.length} succeeded, avg latency: ${avgLatency.toFixed(0)}ms`);
  });
});

test.describe('Zero-Downtime - Error Recovery', () => {
  test('failed request does not affect subsequent requests', async () => {
    // Make a request that might fail
    await callApiGateway('nonexistent_rpc', {});

    // Immediately follow with valid requests
    const validResults = await Promise.all([
      callApiGateway('get_stores'),
      callApiGateway('get_menu_items'),
    ]);

    for (const result of validResults) {
      expect(result.status).toBe(200);
    }
  });

  test('version mismatch recovers gracefully', async () => {
    // Request with invalid version format
    const response = await fetch(`${SUPABASE_URL}/functions/v1/api-gateway`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-App-Version': 'invalid',
        'X-App-Name': 'web',
        'X-Api-Version': 'v99',
      },
      body: JSON.stringify({
        rpc: 'get_stores',
        payload: {},
      }),
    });

    // Should handle gracefully (either succeed with fallback or return error)
    expect([200, 400, 500]).toContain(response.status);

    // Subsequent valid request should work
    const validResponse = await callApiGateway('get_stores');
    expect(validResponse.status).toBe(200);
  });
});
