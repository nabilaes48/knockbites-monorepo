/**
 * Realtime Fanout Edge Function
 *
 * Handles cross-region synchronization of real-time events.
 * Features:
 * - Order status updates fanout to all regions
 * - Edge-based event distribution
 * - Delivery status tracking
 * - Retry logic for failed deliveries
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// Types
interface FanoutEvent {
  type: 'order_status' | 'order_created' | 'menu_updated' | 'store_status' | 'custom';
  payload: Record<string, unknown>;
  sourceRegion?: string;
  targetRegions?: string[];
  priority?: 'high' | 'normal' | 'low';
}

interface DeliveryResult {
  region: string;
  success: boolean;
  latencyMs: number;
  error?: string;
}

interface FanoutResponse {
  success: boolean;
  eventId: number;
  deliveries: DeliveryResult[];
  totalLatencyMs: number;
}

// Constants
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || '';
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';

// Region endpoints
const REGION_ENDPOINTS: Record<string, string> = {
  'us-east-1': SUPABASE_URL,
  'us-west-2': Deno.env.get('SUPABASE_URL_US_WEST') || SUPABASE_URL,
  'eu-west-1': Deno.env.get('SUPABASE_URL_EU') || SUPABASE_URL,
  'ap-southeast-1': Deno.env.get('SUPABASE_URL_AP') || SUPABASE_URL,
};

const PRIMARY_REGION = 'us-east-1';
const MAX_RETRIES = 3;
const RETRY_DELAY_MS = 1000;

// CORS headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// Create Supabase client for a region
function getRegionClient(region: string): ReturnType<typeof createClient> {
  const url = REGION_ENDPOINTS[region] || SUPABASE_URL;
  return createClient(url, SUPABASE_SERVICE_KEY, {
    auth: { persistSession: false },
  });
}

// Get all target regions (excluding source)
function getTargetRegions(sourceRegion: string, specifiedTargets?: string[]): string[] {
  if (specifiedTargets && specifiedTargets.length > 0) {
    return specifiedTargets.filter(r => r !== sourceRegion && REGION_ENDPOINTS[r]);
  }
  return Object.keys(REGION_ENDPOINTS).filter(r => r !== sourceRegion);
}

// Deliver event to a single region with retry
async function deliverToRegion(
  region: string,
  event: FanoutEvent,
  retries = 0
): Promise<DeliveryResult> {
  const startTime = Date.now();

  try {
    const client = getRegionClient(region);

    // Broadcast event through Supabase Realtime
    const channel = client.channel(`fanout_${region}`);

    await new Promise<void>((resolve, reject) => {
      channel.subscribe((status) => {
        if (status === 'SUBSCRIBED') {
          channel.send({
            type: 'broadcast',
            event: event.type,
            payload: {
              ...event.payload,
              _fanout: {
                sourceRegion: event.sourceRegion,
                timestamp: new Date().toISOString(),
              },
            },
          });
          resolve();
        } else if (status === 'CHANNEL_ERROR') {
          reject(new Error('Channel error'));
        }
      });

      // Timeout after 5 seconds
      setTimeout(() => reject(new Error('Timeout')), 5000);
    });

    await client.removeChannel(channel);

    return {
      region,
      success: true,
      latencyMs: Date.now() - startTime,
    };
  } catch (err) {
    const error = err instanceof Error ? err.message : 'Unknown error';

    // Retry if not exhausted
    if (retries < MAX_RETRIES) {
      await new Promise(resolve => setTimeout(resolve, RETRY_DELAY_MS * (retries + 1)));
      return deliverToRegion(region, event, retries + 1);
    }

    return {
      region,
      success: false,
      latencyMs: Date.now() - startTime,
      error,
    };
  }
}

// Log fanout event to database
async function logFanoutEvent(
  client: ReturnType<typeof createClient>,
  event: FanoutEvent,
  targetRegions: string[],
  deliveries: DeliveryResult[]
): Promise<number> {
  try {
    const { data } = await client.rpc('log_realtime_fanout', {
      p_event_type: event.type,
      p_source_region: event.sourceRegion || PRIMARY_REGION,
      p_target_regions: targetRegions,
      p_payload_size: JSON.stringify(event.payload).length,
    });

    // Update delivery status
    const deliveryStatus: Record<string, { success: boolean; latencyMs: number; error?: string }> = {};
    for (const d of deliveries) {
      deliveryStatus[d.region] = {
        success: d.success,
        latencyMs: d.latencyMs,
        ...(d.error && { error: d.error }),
      };
    }

    if (data) {
      await client
        .from('realtime_fanout_log')
        .update({ delivery_status: deliveryStatus })
        .eq('id', data);
    }

    return data || 0;
  } catch {
    return 0;
  }
}

// Handle order status update fanout
async function handleOrderStatusFanout(
  event: FanoutEvent,
  sourceRegion: string,
  targetRegions: string[]
): Promise<DeliveryResult[]> {
  const orderId = event.payload.order_id;
  const newStatus = event.payload.status;

  // Enhance payload with order details
  const enhancedEvent: FanoutEvent = {
    ...event,
    payload: {
      ...event.payload,
      _type: 'order_status_update',
      timestamp: new Date().toISOString(),
    },
  };

  // Deliver to all target regions in parallel
  const deliveries = await Promise.all(
    targetRegions.map(region => deliverToRegion(region, enhancedEvent))
  );

  return deliveries;
}

// Handle order created fanout
async function handleOrderCreatedFanout(
  event: FanoutEvent,
  sourceRegion: string,
  targetRegions: string[]
): Promise<DeliveryResult[]> {
  // For new orders, only notify regions relevant to the store
  // In a full implementation, we'd check store-region mapping

  const enhancedEvent: FanoutEvent = {
    ...event,
    payload: {
      ...event.payload,
      _type: 'order_created',
      timestamp: new Date().toISOString(),
    },
  };

  // Deliver to all target regions
  const deliveries = await Promise.all(
    targetRegions.map(region => deliverToRegion(region, enhancedEvent))
  );

  return deliveries;
}

// Handle menu update fanout (propagate to all replicas)
async function handleMenuUpdateFanout(
  event: FanoutEvent,
  sourceRegion: string,
  targetRegions: string[]
): Promise<DeliveryResult[]> {
  const enhancedEvent: FanoutEvent = {
    ...event,
    priority: 'normal',
    payload: {
      ...event.payload,
      _type: 'menu_update',
      timestamp: new Date().toISOString(),
    },
  };

  // Deliver to all replicas
  const deliveries = await Promise.all(
    targetRegions.map(region => deliverToRegion(region, enhancedEvent))
  );

  return deliveries;
}

// Handle store status update (open/closed, etc.)
async function handleStoreStatusFanout(
  event: FanoutEvent,
  sourceRegion: string,
  targetRegions: string[]
): Promise<DeliveryResult[]> {
  const enhancedEvent: FanoutEvent = {
    ...event,
    priority: 'high',
    payload: {
      ...event.payload,
      _type: 'store_status',
      timestamp: new Date().toISOString(),
    },
  };

  // Deliver to all regions
  const deliveries = await Promise.all(
    targetRegions.map(region => deliverToRegion(region, enhancedEvent))
  );

  return deliveries;
}

// Main handler
serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  const startTime = Date.now();

  try {
    const event: FanoutEvent = await req.json();

    if (!event.type || !event.payload) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: type, payload' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    const sourceRegion = event.sourceRegion || PRIMARY_REGION;
    const targetRegions = getTargetRegions(sourceRegion, event.targetRegions);

    let deliveries: DeliveryResult[];

    // Route to appropriate handler
    switch (event.type) {
      case 'order_status':
        deliveries = await handleOrderStatusFanout(event, sourceRegion, targetRegions);
        break;

      case 'order_created':
        deliveries = await handleOrderCreatedFanout(event, sourceRegion, targetRegions);
        break;

      case 'menu_updated':
        deliveries = await handleMenuUpdateFanout(event, sourceRegion, targetRegions);
        break;

      case 'store_status':
        deliveries = await handleStoreStatusFanout(event, sourceRegion, targetRegions);
        break;

      case 'custom':
      default:
        // Generic fanout
        deliveries = await Promise.all(
          targetRegions.map(region => deliverToRegion(region, event))
        );
        break;
    }

    // Log the fanout event
    const primaryClient = getRegionClient(PRIMARY_REGION);
    const eventId = await logFanoutEvent(primaryClient, event, targetRegions, deliveries);

    const totalLatencyMs = Date.now() - startTime;
    const successCount = deliveries.filter(d => d.success).length;

    const response: FanoutResponse = {
      success: successCount === deliveries.length,
      eventId,
      deliveries,
      totalLatencyMs,
    };

    return new Response(JSON.stringify(response), {
      status: successCount > 0 ? 200 : 500,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json',
        'X-Fanout-Regions': targetRegions.join(','),
        'X-Fanout-Success': successCount.toString(),
        'X-Fanout-Total': deliveries.length.toString(),
      },
    });
  } catch (err) {
    console.error('Fanout error:', err);

    return new Response(
      JSON.stringify({
        error: err instanceof Error ? err.message : 'Fanout failed',
        totalLatencyMs: Date.now() - startTime,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
});
