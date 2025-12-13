/**
 * Deploy Rollback Edge Function
 *
 * Handles deployment rollback operations:
 * - Receives rollback request from CI/CD pipeline
 * - Logs rollback to deployment_log
 * - Triggers alert for rollback event
 * - Returns rollback target information
 *
 * This function coordinates with Vercel/Netlify APIs for actual rollback.
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { createLogger, createTracedResponse } from '../_shared/logger.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-request-id',
};

interface RollbackRequest {
  deployment_id: string;
  environment?: string;
  reason?: string;
  triggered_by?: string;
}

interface VercelRollbackResponse {
  id: string;
  url: string;
  readyState: string;
}

Deno.serve(async (req) => {
  const requestId = req.headers.get('X-Request-ID') || crypto.randomUUID();
  const log = createLogger('deploy-rollback', requestId);

  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    log.info('Processing rollback request');

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    const payload: RollbackRequest = await req.json();
    const {
      deployment_id,
      environment = 'production',
      reason = 'Automated rollback',
      triggered_by = 'system',
    } = payload;

    // Get the last successful deployment to roll back to
    const { data: lastSuccessful, error: fetchError } = await supabase
      .rpc('get_last_successful_deployment', { p_environment: environment });

    if (fetchError || !lastSuccessful || lastSuccessful.length === 0) {
      log.error('No successful deployment to roll back to', { fetchError });
      return createTracedResponse(
        {
          error: 'No successful deployment found for rollback',
          details: fetchError?.message,
        },
        requestId,
        404
      );
    }

    const target = lastSuccessful[0];
    log.info('Found rollback target', { target });

    // Attempt Vercel rollback if configured
    let vercelResult: VercelRollbackResponse | null = null;
    const vercelToken = Deno.env.get('VERCEL_TOKEN');
    const vercelProjectId = Deno.env.get('VERCEL_PROJECT_ID');
    const vercelTeamId = Deno.env.get('VERCEL_TEAM_ID');

    if (vercelToken && vercelProjectId && target.deployment_id) {
      try {
        vercelResult = await triggerVercelRollback(
          vercelToken,
          vercelProjectId,
          target.deployment_id,
          vercelTeamId,
          log
        );
      } catch (err) {
        log.error('Vercel rollback failed', err);
        // Continue - we still log the rollback attempt
      }
    }

    // Generate new deployment ID for the rollback
    const rollbackDeploymentId = `rollback_${Date.now()}_${target.deployment_id}`;

    // Log the rollback
    const { data: rollbackLog, error: logError } = await supabase
      .rpc('log_rollback', {
        p_new_deployment_id: rollbackDeploymentId,
        p_target_deployment_id: target.deployment_id,
        p_environment: environment,
        p_rolled_back_by: triggered_by,
      });

    if (logError) {
      log.error('Failed to log rollback', { logError });
    }

    // Send alert about rollback
    try {
      await fetch(`${Deno.env.get('SUPABASE_URL')}/functions/v1/send-alert`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
          'Content-Type': 'application/json',
          'X-Request-ID': requestId,
        },
        body: JSON.stringify({
          severity: 'warning',
          rule_name: 'Deployment Rollback',
          message: `Rollback triggered for ${environment}. Rolling back from ${deployment_id} to ${target.deployment_id} (${target.version || 'unknown version'}). Reason: ${reason}`,
          channels: ['email', 'slack'],
          metadata: {
            failed_deployment: deployment_id,
            rollback_target: target.deployment_id,
            target_version: target.version,
            target_commit: target.commit_sha,
            environment,
            reason,
            triggered_by,
            vercel_result: vercelResult,
          },
        }),
      });
    } catch (alertErr) {
      log.error('Failed to send rollback alert', alertErr);
    }

    // Log to metrics
    await supabase.from('runtime_metrics').insert({
      session_id: 'system',
      event_type: 'deployment',
      event_data: {
        action: 'rollback_executed',
        failed_deployment: deployment_id,
        rollback_target: target.deployment_id,
        target_version: target.version,
        environment,
        reason,
        triggered_by,
        vercel_success: !!vercelResult,
      },
    });

    log.info('Rollback completed', {
      rollbackDeploymentId,
      target: target.deployment_id,
    });

    return createTracedResponse(
      {
        success: true,
        rollback_id: rollbackDeploymentId,
        rolled_back_to: {
          deployment_id: target.deployment_id,
          version: target.version,
          commit_sha: target.commit_sha,
          deployed_at: target.deployed_at,
        },
        vercel_result: vercelResult,
      },
      requestId,
      200
    );
  } catch (error) {
    log.error('Rollback failed', error);

    return createTracedResponse(
      { error: 'Rollback failed', details: String(error) },
      requestId,
      500
    );
  }
});

/**
 * Trigger Vercel deployment rollback
 */
async function triggerVercelRollback(
  token: string,
  projectId: string,
  deploymentId: string,
  teamId: string | undefined,
  log: ReturnType<typeof createLogger>
): Promise<VercelRollbackResponse> {
  const baseUrl = 'https://api.vercel.com';
  const teamQuery = teamId ? `?teamId=${teamId}` : '';

  // First, get the deployment details
  const deploymentResponse = await fetch(
    `${baseUrl}/v13/deployments/${deploymentId}${teamQuery}`,
    {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    }
  );

  if (!deploymentResponse.ok) {
    throw new Error(`Failed to fetch deployment: ${deploymentResponse.status}`);
  }

  const deployment = await deploymentResponse.json();
  log.info('Found target deployment', { url: deployment.url });

  // Create a new deployment from the target's source
  // This effectively "rolls back" by redeploying the previous version
  const rollbackResponse = await fetch(
    `${baseUrl}/v13/deployments${teamQuery}`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        name: projectId,
        gitSource: deployment.gitSource,
        target: 'production',
        // Use the same configuration as the target deployment
      }),
    }
  );

  if (!rollbackResponse.ok) {
    const error = await rollbackResponse.text();
    throw new Error(`Vercel rollback failed: ${rollbackResponse.status} - ${error}`);
  }

  const result = await rollbackResponse.json();
  log.info('Vercel rollback initiated', { newDeploymentId: result.id });

  return {
    id: result.id,
    url: result.url,
    readyState: result.readyState,
  };
}
