/**
 * API Dispatch Edge Function
 *
 * Central gateway for all versioned API calls:
 * 1. Reads X-App-Version and X-App-Name headers
 * 2. Sets Postgres session variables for RLS
 * 3. Routes to correct RPC version (v1 or v2)
 * 4. Logs request to runtime_metrics
 *
 * This centralizes ALL Supabase traffic for version negotiation.
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { createMetricsLogger, createTracedResponse } from '../_shared/logger.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type, x-request-id, x-app-version, x-app-name, x-api-version',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

// Supported API versions
const SUPPORTED_VERSIONS = ['v1', 'v2'];
const DEFAULT_VERSION = 'v2';

// Minimum versions for breaking features
const VERSION_REQUIREMENTS: Record<string, string> = {
  portion_customization: '1.1.0',
  analytics_advanced: '1.3.0',
  system_health: '1.3.0',
};

interface DispatchRequest {
  rpc: string;
  payload?: Record<string, unknown>;
  version?: 'v1' | 'v2';
}

Deno.serve(async (req) => {
  const requestId = req.headers.get('X-Request-ID') || crypto.randomUUID();
  const log = createMetricsLogger('api-dispatch', requestId);

  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  const startTime = Date.now();

  try {
    // Extract version headers
    const appVersion = req.headers.get('X-App-Version') || '1.0.0';
    const appName = req.headers.get('X-App-Name') || 'web';
    const apiVersion = req.headers.get('X-Api-Version') || DEFAULT_VERSION;

    log.info('API dispatch request', {
      appVersion,
      appName,
      apiVersion,
    });

    // Validate API version
    if (!SUPPORTED_VERSIONS.includes(apiVersion)) {
      await log.fail(new Error(`Unsupported API version: ${apiVersion}`));
      return createTracedResponse(
        {
          error: 'Unsupported API version',
          supported: SUPPORTED_VERSIONS,
        },
        requestId,
        400
      );
    }

    // Parse request body
    const body: DispatchRequest = await req.json();
    const { rpc, payload = {}, version } = body;

    if (!rpc) {
      await log.fail(new Error('Missing RPC name'));
      return createTracedResponse(
        { error: 'Missing required field: rpc' },
        requestId,
        400
      );
    }

    // Determine which version to use
    const targetVersion = version || apiVersion;

    // Create Supabase client with service role
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // Set client context in Postgres session
    const { error: contextError } = await supabase.rpc('set_client_context', {
      p_app_version: appVersion,
      p_app_name: appName,
      p_api_version: targetVersion,
    });

    if (contextError) {
      log.warn('Failed to set client context', { error: contextError.message });
    }

    // Dispatch to versioned RPC
    const dispatchFn = targetVersion === 'v1' ? 'rpc_v1_dispatch' : 'rpc_v2_dispatch';

    const { data, error } = await supabase.rpc(dispatchFn, {
      p_name: rpc,
      p_payload: payload,
    });

    const executionTime = Date.now() - startTime;

    if (error) {
      log.error('RPC dispatch failed', error, {
        rpc,
        version: targetVersion,
        executionTime,
      });

      await log.complete(500, {
        rpc,
        version: targetVersion,
        success: false,
      });

      return createTracedResponse(
        {
          error: error.message,
          code: error.code,
          rpc,
          version: targetVersion,
        },
        requestId,
        500
      );
    }

    // Log success to metrics
    await log.complete(200, {
      rpc,
      version: targetVersion,
      executionTime,
      success: true,
    });

    return createTracedResponse(
      {
        data,
        meta: {
          rpc,
          version: targetVersion,
          executionTime,
          requestId,
        },
      },
      requestId,
      200
    );
  } catch (error) {
    log.error('API dispatch error', error);

    await log.fail(error, {
      executionTime: Date.now() - startTime,
    });

    return createTracedResponse(
      {
        error: 'Internal server error',
        details: error instanceof Error ? error.message : String(error),
      },
      requestId,
      500
    );
  }
});
