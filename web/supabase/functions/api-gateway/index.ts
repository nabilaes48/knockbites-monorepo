/**
 * Global API Gateway Edge Function
 *
 * Central entry point for all API calls across Cameron's Connect platform.
 * Features:
 * - Multi-region routing
 * - Version negotiation (v1/v2/v3)
 * - Intelligent fallback for older clients
 * - Request telemetry and metrics
 * - Zero-downtime version switching
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// Types
interface GatewayRequest {
  rpc: string;
  payload?: Record<string, unknown>;
  version?: 'v1' | 'v2' | 'v3';
  region?: string;
}

interface GatewayResponse {
  data: unknown;
  meta: {
    rpc: string;
    version: string;
    region: string;
    executionTime: number;
    requestId: string;
    fallback?: boolean;
  };
}

interface ClientContext {
  appVersion: string;
  appName: string;
  apiVersion: string;
  clientRegion: string;
  clientId: string;
}

// Constants
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || '';
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';
const DEFAULT_VERSION = 'v2';
const SUPPORTED_VERSIONS = ['v1', 'v2', 'v3'];

// Region configuration
const REGIONS: Record<string, string> = {
  'us-east-1': SUPABASE_URL,
  'us-west-2': Deno.env.get('SUPABASE_URL_US_WEST') || SUPABASE_URL,
  'eu-west-1': Deno.env.get('SUPABASE_URL_EU') || SUPABASE_URL,
  'ap-southeast-1': Deno.env.get('SUPABASE_URL_AP') || SUPABASE_URL,
};

const PRIMARY_REGION = 'us-east-1';

// CORS headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-app-version, x-app-name, x-api-version, x-client-region, x-client-id',
};

// Generate unique request ID
function generateRequestId(): string {
  return `req_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
}

// Parse client context from headers
function parseClientContext(req: Request): ClientContext {
  return {
    appVersion: req.headers.get('X-App-Version') || '1.0.0',
    appName: req.headers.get('X-App-Name') || 'web',
    apiVersion: req.headers.get('X-Api-Version') || DEFAULT_VERSION,
    clientRegion: req.headers.get('X-Client-Region') || PRIMARY_REGION,
    clientId: req.headers.get('X-Client-Id') || 'unknown',
  };
}

// Parse semantic version to comparable number
function parseVersion(version: string): number {
  const parts = version.replace(/^v/, '').split('.');
  const major = parseInt(parts[0] || '0', 10);
  const minor = parseInt(parts[1] || '0', 10);
  const patch = parseInt(parts[2] || '0', 10);
  return major * 10000 + minor * 100 + patch;
}

// Check if client version meets minimum
function meetsMinVersion(current: string, minimum: string): boolean {
  return parseVersion(current) >= parseVersion(minimum);
}

// Determine optimal API version for client
async function determineApiVersion(
  supabase: ReturnType<typeof createClient>,
  context: ClientContext,
  requestedVersion?: string
): Promise<{ version: string; fallback: boolean }> {
  // If client explicitly requested a version, validate it
  if (requestedVersion && SUPPORTED_VERSIONS.includes(requestedVersion)) {
    return { version: requestedVersion, fallback: false };
  }

  // Get active version from database
  try {
    const { data } = await supabase.rpc('get_active_api_version');
    const activeVersion = data?.current || DEFAULT_VERSION;
    const fallbackVersion = data?.fallback || 'v1';

    // Check client compatibility
    const versionRequirements: Record<string, string> = {
      v3: '1.4.0',
      v2: '1.2.0',
      v1: '1.0.0',
    };

    // Can client use active version?
    const minRequired = versionRequirements[activeVersion] || '1.0.0';
    if (meetsMinVersion(context.appVersion, minRequired)) {
      return { version: activeVersion, fallback: false };
    }

    // Fall back to older version
    return { version: fallbackVersion, fallback: true };
  } catch {
    // Default to v2 on error
    return { version: DEFAULT_VERSION, fallback: false };
  }
}

// Get Supabase client for region
function getRegionClient(region: string): ReturnType<typeof createClient> {
  const url = REGIONS[region] || SUPABASE_URL;
  return createClient(url, SUPABASE_SERVICE_KEY, {
    auth: { persistSession: false },
  });
}

// Determine target region for request
function determineRegion(context: ClientContext, isWriteOperation: boolean): string {
  // Write operations always go to primary
  if (isWriteOperation) {
    return PRIMARY_REGION;
  }

  // Read operations can use client's region if available
  if (context.clientRegion && REGIONS[context.clientRegion]) {
    return context.clientRegion;
  }

  return PRIMARY_REGION;
}

// Check if RPC is a write operation
function isWriteRpc(rpcName: string): boolean {
  const writeRpcs = [
    'place_order',
    'update_order',
    'update_order_status',
    'cancel_order',
    'create_menu_item',
    'update_menu_item',
    'delete_menu_item',
    'register_client_region',
    'switch_api_version',
  ];
  return writeRpcs.includes(rpcName);
}

// Set client context in Postgres session
async function setClientContext(
  supabase: ReturnType<typeof createClient>,
  context: ClientContext,
  targetVersion: string
): Promise<void> {
  await supabase.rpc('set_client_context', {
    p_app_version: context.appVersion,
    p_app_name: context.appName,
    p_api_version: targetVersion,
  });
}

// Log request metrics
async function logMetrics(
  supabase: ReturnType<typeof createClient>,
  rpc: string,
  version: string,
  region: string,
  executionMs: number,
  success: boolean,
  context: ClientContext
): Promise<void> {
  try {
    await supabase.from('runtime_metrics').insert({
      metric_name: `gateway_${rpc}`,
      metric_value: executionMs,
      metadata: {
        version,
        region,
        success,
        app_name: context.appName,
        app_version: context.appVersion,
        client_id: context.clientId,
      },
    });
  } catch {
    // Silent failure - metrics are non-critical
  }
}

// Update client telemetry
async function updateClientTelemetry(
  supabase: ReturnType<typeof createClient>,
  context: ClientContext,
  version: string
): Promise<void> {
  try {
    await supabase.rpc('register_client_region', {
      p_region: context.clientRegion,
      p_client_id: context.clientId,
      p_app_name: context.appName,
      p_app_version: context.appVersion,
      p_api_version: version,
    });
  } catch {
    // Silent failure
  }
}

// Main handler
serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  const requestId = generateRequestId();
  const startTime = Date.now();

  try {
    // Parse request
    const body: GatewayRequest = await req.json();
    const { rpc, payload = {}, version: requestedVersion, region: requestedRegion } = body;

    if (!rpc) {
      return new Response(
        JSON.stringify({ error: 'Missing required field: rpc' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    // Parse client context
    const context = parseClientContext(req);

    // Determine target region
    const isWrite = isWriteRpc(rpc);
    const targetRegion = requestedRegion || determineRegion(context, isWrite);

    // Get Supabase client for region
    const supabase = getRegionClient(targetRegion);

    // Determine API version
    const { version: targetVersion, fallback } = await determineApiVersion(
      supabase,
      context,
      requestedVersion
    );

    // Set client context in session
    await setClientContext(supabase, context, targetVersion);

    // Route to appropriate dispatcher
    const { data, error } = await supabase.rpc('route_api_call', {
      p_name: rpc,
      p_payload: payload,
      p_requested_version: targetVersion,
    });

    const executionTime = Date.now() - startTime;

    if (error) {
      // Log failure metrics
      await logMetrics(supabase, rpc, targetVersion, targetRegion, executionTime, false, context);

      return new Response(
        JSON.stringify({
          error: error.message,
          code: error.code,
          meta: {
            requestId,
            version: targetVersion,
            region: targetRegion,
          },
        }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    // Log success metrics and update telemetry in parallel
    Promise.all([
      logMetrics(supabase, rpc, targetVersion, targetRegion, executionTime, true, context),
      updateClientTelemetry(supabase, context, targetVersion),
    ]).catch(() => {});

    // Build response
    const response: GatewayResponse = {
      data,
      meta: {
        rpc,
        version: targetVersion,
        region: targetRegion,
        executionTime,
        requestId,
        ...(fallback && { fallback: true }),
      },
    };

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json',
        'X-Request-ID': requestId,
        'X-API-Version': targetVersion,
        'X-Region': targetRegion,
        'X-Execution-Time': executionTime.toString(),
      },
    });
  } catch (err) {
    const executionTime = Date.now() - startTime;

    console.error('Gateway error:', err);

    return new Response(
      JSON.stringify({
        error: err instanceof Error ? err.message : 'Internal gateway error',
        meta: {
          requestId,
          executionTime,
        },
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
});
