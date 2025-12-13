/**
 * Send Alert Edge Function
 *
 * Dispatches alerts to multiple channels:
 * - Email (via Resend)
 * - Slack (via Webhook)
 * - SMS (via Twilio) - optional
 *
 * Triggered by:
 * - Alert rule evaluation (cron job)
 * - Direct API call for immediate alerts
 * - Deployment failures
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { createLogger, createTracedResponse } from '../_shared/logger.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-request-id',
};

interface AlertPayload {
  alert_id?: number;
  rule_name?: string;
  severity: 'info' | 'warning' | 'critical';
  message: string;
  channels: string[];
  metadata?: Record<string, unknown>;
}

interface SlackMessage {
  text: string;
  blocks?: Array<{
    type: string;
    text?: { type: string; text: string; emoji?: boolean };
    elements?: Array<{ type: string; text: string }>;
  }>;
}

Deno.serve(async (req) => {
  const requestId = req.headers.get('X-Request-ID') || crypto.randomUUID();
  const log = createLogger('send-alert', requestId);

  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    log.info('Processing alert request');

    const payload: AlertPayload = await req.json();
    const { severity, message, channels, metadata, rule_name, alert_id } = payload;

    if (!message || !channels || channels.length === 0) {
      return createTracedResponse(
        { error: 'Missing required fields: message, channels' },
        requestId,
        400
      );
    }

    const results: Record<string, { success: boolean; error?: string }> = {};

    // Send to each channel
    for (const channel of channels) {
      try {
        switch (channel) {
          case 'email':
            results.email = await sendEmail(payload, log);
            break;
          case 'slack':
            results.slack = await sendSlack(payload, log);
            break;
          case 'sms':
            results.sms = await sendSMS(payload, log);
            break;
          default:
            results[channel] = { success: false, error: `Unknown channel: ${channel}` };
        }
      } catch (err) {
        results[channel] = { success: false, error: String(err) };
        log.error(`Failed to send to ${channel}`, err);
      }
    }

    // Log alert dispatch to metrics
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    await supabase.from('runtime_metrics').insert({
      session_id: 'system',
      event_type: 'alert_triggered',
      event_data: {
        alert_id,
        rule_name,
        severity,
        message,
        channels,
        results,
        metadata,
      },
    });

    log.info('Alert dispatched', { results });

    return createTracedResponse(
      {
        success: true,
        results,
        alert_id,
      },
      requestId,
      200
    );
  } catch (error) {
    log.error('Alert dispatch failed', error);

    return createTracedResponse(
      { error: 'Internal server error', details: String(error) },
      requestId,
      500
    );
  }
});

/**
 * Send email alert via Resend
 */
async function sendEmail(
  payload: AlertPayload,
  log: ReturnType<typeof createLogger>
): Promise<{ success: boolean; error?: string }> {
  const resendApiKey = Deno.env.get('RESEND_API_KEY');
  const alertEmail = Deno.env.get('ALERT_EMAIL') || 'alerts@cameronsconnect.com';

  if (!resendApiKey) {
    return { success: false, error: 'RESEND_API_KEY not configured' };
  }

  const severityEmoji = {
    info: 'ℹ️',
    warning: '⚠️',
    critical: '🚨',
  };

  const subject = `${severityEmoji[payload.severity]} [${payload.severity.toUpperCase()}] ${payload.rule_name || 'Alert'} - Cameron's Connect`;

  const htmlBody = `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
      <div style="background: ${payload.severity === 'critical' ? '#dc2626' : payload.severity === 'warning' ? '#f59e0b' : '#3b82f6'}; color: white; padding: 20px; border-radius: 8px 8px 0 0;">
        <h1 style="margin: 0; font-size: 24px;">${severityEmoji[payload.severity]} ${payload.severity.toUpperCase()} Alert</h1>
      </div>
      <div style="background: #f9fafb; padding: 20px; border: 1px solid #e5e7eb; border-top: 0; border-radius: 0 0 8px 8px;">
        <h2 style="margin-top: 0; color: #1f2937;">${payload.rule_name || 'System Alert'}</h2>
        <p style="color: #4b5563; font-size: 16px; line-height: 1.6;">${payload.message}</p>

        ${payload.metadata ? `
          <div style="margin-top: 20px; background: white; padding: 15px; border-radius: 4px; border: 1px solid #e5e7eb;">
            <h3 style="margin-top: 0; color: #6b7280; font-size: 14px; text-transform: uppercase;">Details</h3>
            <pre style="background: #f3f4f6; padding: 10px; border-radius: 4px; overflow-x: auto; font-size: 12px;">${JSON.stringify(payload.metadata, null, 2)}</pre>
          </div>
        ` : ''}

        <p style="color: #9ca3af; font-size: 12px; margin-top: 20px;">
          Sent at ${new Date().toISOString()}<br>
          Cameron's Connect Monitoring System
        </p>
      </div>
    </div>
  `;

  try {
    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${resendApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: 'Cameron\'s Connect Alerts <alerts@cameronsconnect.com>',
        to: [alertEmail],
        subject,
        html: htmlBody,
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      log.error('Resend API error', { status: response.status, error });
      return { success: false, error: `Resend API error: ${response.status}` };
    }

    log.info('Email sent successfully');
    return { success: true };
  } catch (err) {
    return { success: false, error: String(err) };
  }
}

/**
 * Send Slack alert via webhook
 */
async function sendSlack(
  payload: AlertPayload,
  log: ReturnType<typeof createLogger>
): Promise<{ success: boolean; error?: string }> {
  const webhookUrl = Deno.env.get('SLACK_WEBHOOK_URL');

  if (!webhookUrl) {
    return { success: false, error: 'SLACK_WEBHOOK_URL not configured' };
  }

  const severityColor = {
    info: '#3b82f6',
    warning: '#f59e0b',
    critical: '#dc2626',
  };

  const severityEmoji = {
    info: ':information_source:',
    warning: ':warning:',
    critical: ':rotating_light:',
  };

  const slackMessage: SlackMessage = {
    text: `${severityEmoji[payload.severity]} [${payload.severity.toUpperCase()}] ${payload.rule_name || 'Alert'}`,
    blocks: [
      {
        type: 'header',
        text: {
          type: 'plain_text',
          text: `${severityEmoji[payload.severity]} ${payload.rule_name || 'System Alert'}`,
          emoji: true,
        },
      },
      {
        type: 'section',
        text: {
          type: 'mrkdwn',
          text: payload.message,
        },
      },
      {
        type: 'context',
        elements: [
          {
            type: 'mrkdwn',
            text: `*Severity:* ${payload.severity} | *Time:* ${new Date().toISOString()}`,
          },
        ],
      },
    ],
  };

  if (payload.metadata) {
    slackMessage.blocks?.push({
      type: 'section',
      text: {
        type: 'mrkdwn',
        text: `\`\`\`${JSON.stringify(payload.metadata, null, 2)}\`\`\``,
      },
    });
  }

  try {
    const response = await fetch(webhookUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(slackMessage),
    });

    if (!response.ok) {
      const error = await response.text();
      log.error('Slack webhook error', { status: response.status, error });
      return { success: false, error: `Slack error: ${response.status}` };
    }

    log.info('Slack notification sent');
    return { success: true };
  } catch (err) {
    return { success: false, error: String(err) };
  }
}

/**
 * Send SMS alert via Twilio
 */
async function sendSMS(
  payload: AlertPayload,
  log: ReturnType<typeof createLogger>
): Promise<{ success: boolean; error?: string }> {
  const accountSid = Deno.env.get('TWILIO_ACCOUNT_SID');
  const authToken = Deno.env.get('TWILIO_AUTH_TOKEN');
  const fromNumber = Deno.env.get('TWILIO_FROM_NUMBER');
  const toNumber = Deno.env.get('ALERT_SMS_NUMBER');

  if (!accountSid || !authToken || !fromNumber || !toNumber) {
    return { success: false, error: 'Twilio credentials not configured' };
  }

  const severityPrefix = {
    info: '[INFO]',
    warning: '[WARN]',
    critical: '[CRITICAL]',
  };

  const smsBody = `${severityPrefix[payload.severity]} Cameron's Connect: ${payload.rule_name || 'Alert'} - ${payload.message.substring(0, 140)}`;

  try {
    const response = await fetch(
      `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Basic ${btoa(`${accountSid}:${authToken}`)}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: new URLSearchParams({
          To: toNumber,
          From: fromNumber,
          Body: smsBody,
        }),
      }
    );

    if (!response.ok) {
      const error = await response.text();
      log.error('Twilio API error', { status: response.status, error });
      return { success: false, error: `Twilio error: ${response.status}` };
    }

    log.info('SMS sent successfully');
    return { success: true };
  } catch (err) {
    return { success: false, error: String(err) };
  }
}
