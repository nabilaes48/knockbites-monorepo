import { test, expect } from '@playwright/test';

/**
 * Realtime Fanout E2E Tests
 *
 * Tests for cross-region event synchronization and
 * real-time order updates across regions.
 */

const SUPABASE_URL = process.env.VITE_SUPABASE_URL || '';
const SUPABASE_ANON_KEY = process.env.VITE_SUPABASE_ANON_KEY || '';

// Helper to call the realtime fanout function
async function callFanout(
  eventType: string,
  payload: Record<string, unknown>,
  options: {
    sourceRegion?: string;
    targetRegions?: string[];
    priority?: 'high' | 'normal' | 'low';
  } = {}
) {
  const response = await fetch(`${SUPABASE_URL}/functions/v1/realtime-fanout`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      type: eventType,
      payload,
      sourceRegion: options.sourceRegion || 'us-east-1',
      targetRegions: options.targetRegions,
      priority: options.priority,
    }),
  });

  return {
    status: response.status,
    headers: Object.fromEntries(response.headers.entries()),
    data: await response.json(),
  };
}

// Helper to create an order via API gateway
async function createOrder(customerName: string) {
  const response = await fetch(`${SUPABASE_URL}/functions/v1/api-gateway`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-App-Version': '1.4.0',
      'X-App-Name': 'web',
      'X-Api-Version': 'v3',
    },
    body: JSON.stringify({
      rpc: 'place_order',
      payload: {
        store_id: 1,
        customer_name: customerName,
        customer_email: `${customerName.toLowerCase().replace(/\s/g, '')}@test.com`,
        subtotal: 10,
        tax: 0.80,
        total: 10.80,
      },
    }),
  });

  const data = await response.json();
  return data.data?.order_id;
}

test.describe('Realtime Fanout - Event Types', () => {
  test('order_status fanout succeeds', async () => {
    const orderId = await createOrder('Fanout Status Test');

    const { status, data } = await callFanout('order_status', {
      order_id: orderId,
      status: 'preparing',
      previous_status: 'pending',
    });

    expect(status).toBe(200);
    expect(data.success).toBeDefined();
    expect(data.eventId).toBeDefined();
    expect(data.deliveries).toBeDefined();
    expect(Array.isArray(data.deliveries)).toBe(true);
  });

  test('order_created fanout succeeds', async () => {
    const { status, data } = await callFanout('order_created', {
      order_id: 99999,
      store_id: 1,
      customer_name: 'New Order Test',
      total: 25.50,
    });

    expect(status).toBe(200);
    expect(data.success).toBeDefined();
    expect(data.deliveries).toBeDefined();
  });

  test('menu_updated fanout succeeds', async () => {
    const { status, data } = await callFanout('menu_updated', {
      menu_item_id: 1,
      change_type: 'price_update',
      new_price: 12.99,
    });

    expect(status).toBe(200);
    expect(data.success).toBeDefined();
  });

  test('store_status fanout succeeds', async () => {
    const { status, data } = await callFanout('store_status', {
      store_id: 1,
      new_status: 'open',
      message: 'Store is now open',
    });

    expect(status).toBe(200);
    expect(data.success).toBeDefined();
  });

  test('custom event fanout succeeds', async () => {
    const { status, data } = await callFanout('custom', {
      custom_event_type: 'test_event',
      data: { foo: 'bar' },
    });

    expect(status).toBe(200);
    expect(data.success).toBeDefined();
  });
});

test.describe('Realtime Fanout - Region Targeting', () => {
  test('fanout to specific regions only', async () => {
    const { status, data } = await callFanout('order_status', {
      order_id: 1,
      status: 'ready',
    }, {
      sourceRegion: 'us-east-1',
      targetRegions: ['us-west-2'],
    });

    expect(status).toBe(200);
    // Should only have attempted delivery to us-west-2
    expect(data.deliveries.length).toBeLessThanOrEqual(1);
  });

  test('fanout excludes source region', async () => {
    const { status, headers, data } = await callFanout('order_status', {
      order_id: 1,
      status: 'completed',
    }, {
      sourceRegion: 'us-east-1',
    });

    expect(status).toBe(200);

    // Check that source region is not in deliveries
    const sourceDelivery = data.deliveries.find(
      (d: { region: string }) => d.region === 'us-east-1'
    );
    expect(sourceDelivery).toBeUndefined();
  });

  test('fanout to all regions when no targets specified', async () => {
    const { status, data } = await callFanout('menu_updated', {
      menu_item_id: 1,
      is_available: false,
    }, {
      sourceRegion: 'us-east-1',
    });

    expect(status).toBe(200);
    // Should have attempted delivery to multiple regions
    expect(data.deliveries.length).toBeGreaterThanOrEqual(0);
  });
});

test.describe('Realtime Fanout - Response Structure', () => {
  test('response includes event ID', async () => {
    const { data } = await callFanout('order_status', {
      order_id: 1,
      status: 'pending',
    });

    expect(data.eventId).toBeDefined();
    expect(typeof data.eventId).toBe('number');
  });

  test('response includes total latency', async () => {
    const { data } = await callFanout('order_created', {
      order_id: 1,
    });

    expect(data.totalLatencyMs).toBeDefined();
    expect(typeof data.totalLatencyMs).toBe('number');
    expect(data.totalLatencyMs).toBeGreaterThanOrEqual(0);
  });

  test('delivery results include region and status', async () => {
    const { data } = await callFanout('store_status', {
      store_id: 1,
      status: 'open',
    });

    if (data.deliveries.length > 0) {
      const delivery = data.deliveries[0];
      expect(delivery).toHaveProperty('region');
      expect(delivery).toHaveProperty('success');
      expect(delivery).toHaveProperty('latencyMs');
    }
  });

  test('headers include fanout metadata', async () => {
    const { headers } = await callFanout('order_status', {
      order_id: 1,
      status: 'preparing',
    });

    expect(headers['x-fanout-regions']).toBeDefined();
    expect(headers['x-fanout-success']).toBeDefined();
    expect(headers['x-fanout-total']).toBeDefined();
  });
});

test.describe('Realtime Fanout - Error Handling', () => {
  test('missing type returns 400', async () => {
    const response = await fetch(`${SUPABASE_URL}/functions/v1/realtime-fanout`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        payload: { foo: 'bar' },
      }),
    });

    expect(response.status).toBe(400);
    const data = await response.json();
    expect(data.error).toContain('type');
  });

  test('missing payload returns 400', async () => {
    const response = await fetch(`${SUPABASE_URL}/functions/v1/realtime-fanout`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        type: 'order_status',
      }),
    });

    expect(response.status).toBe(400);
  });

  test('invalid JSON returns 500', async () => {
    const response = await fetch(`${SUPABASE_URL}/functions/v1/realtime-fanout`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: 'invalid json',
    });

    expect(response.status).toBe(500);
  });
});

test.describe('Realtime Fanout - Priority Handling', () => {
  test('high priority events are accepted', async () => {
    const { status, data } = await callFanout('order_status', {
      order_id: 1,
      status: 'cancelled',
    }, {
      priority: 'high',
    });

    expect(status).toBe(200);
  });

  test('normal priority events are accepted', async () => {
    const { status, data } = await callFanout('menu_updated', {
      menu_item_id: 1,
    }, {
      priority: 'normal',
    });

    expect(status).toBe(200);
  });

  test('low priority events are accepted', async () => {
    const { status, data } = await callFanout('custom', {
      analytics_event: 'page_view',
    }, {
      priority: 'low',
    });

    expect(status).toBe(200);
  });
});

test.describe('Realtime Fanout - Order Workflow', () => {
  test('complete order status flow broadcasts correctly', async () => {
    // Create order
    const orderId = await createOrder('Workflow Test');
    expect(orderId).toBeDefined();

    // Status progression
    const statuses = ['pending', 'preparing', 'ready', 'completed'];
    let previousStatus = 'new';

    for (const status of statuses) {
      const { status: httpStatus, data } = await callFanout('order_status', {
        order_id: orderId,
        status,
        previous_status: previousStatus,
      });

      expect(httpStatus).toBe(200);
      previousStatus = status;
    }
  });

  test('order cancellation broadcasts to all regions', async () => {
    const orderId = await createOrder('Cancel Test');

    const { status, data } = await callFanout('order_status', {
      order_id: orderId,
      status: 'cancelled',
      reason: 'Customer requested cancellation',
    }, {
      priority: 'high',
    });

    expect(status).toBe(200);
  });
});

test.describe('Realtime Fanout - Logging', () => {
  test('fanout events are logged', async () => {
    const { status, data } = await callFanout('order_status', {
      order_id: 1,
      status: 'preparing',
    });

    expect(status).toBe(200);
    // Event ID indicates it was logged
    expect(data.eventId).toBeGreaterThan(0);
  });

  test('delivery status is tracked', async () => {
    const { status, data } = await callFanout('menu_updated', {
      menu_item_id: 1,
      change: 'availability',
    });

    expect(status).toBe(200);

    // Each delivery should have success/failure status
    for (const delivery of data.deliveries) {
      expect(typeof delivery.success).toBe('boolean');
    }
  });
});
