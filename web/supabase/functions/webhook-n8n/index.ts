// Supabase Edge Function: webhook-n8n
// Handles n8n automation workflow webhooks
// STUB: To be implemented when n8n integration is ready

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { handleCors, jsonResponse, errorResponse } from "../_shared/cors.ts";
import { hasValidApiKey, createServiceClient } from "../_shared/auth.ts";
import { createLogger } from "../_shared/logger.ts";

const log = createLogger("webhook-n8n");
const N8N_WEBHOOK_SECRET = Deno.env.get("N8N_WEBHOOK_SECRET");

/**
 * Supported n8n workflow triggers
 */
type N8nTriggerType =
  | "new_order"
  | "order_completed"
  | "low_inventory"
  | "daily_report"
  | "custom";

interface N8nWebhookPayload {
  trigger: N8nTriggerType;
  data: Record<string, unknown>;
  workflow_id?: string;
  execution_id?: string;
}

serve(async (req) => {
  // Handle CORS preflight
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  // Only allow POST
  if (req.method !== "POST") {
    return errorResponse("Method not allowed", 405);
  }

  try {
    // Verify API key if configured
    if (N8N_WEBHOOK_SECRET) {
      if (!hasValidApiKey(req, "X-N8N-Webhook-Secret", N8N_WEBHOOK_SECRET)) {
        log.warn("Invalid or missing API key");
        return errorResponse("Unauthorized", 401);
      }
    }

    const body: N8nWebhookPayload = await req.json();

    log.info("n8n webhook received", {
      trigger: body.trigger,
      workflow_id: body.workflow_id,
    });

    // Handle different trigger types
    switch (body.trigger) {
      case "new_order":
        // TODO: Trigger inventory check, notification workflow
        log.info("New order trigger - stub handler");
        break;

      case "order_completed":
        // TODO: Trigger customer follow-up, analytics update
        log.info("Order completed trigger - stub handler");
        break;

      case "low_inventory":
        // TODO: Trigger reorder workflow
        log.info("Low inventory trigger - stub handler");
        break;

      case "daily_report":
        // TODO: Generate and send daily report
        log.info("Daily report trigger - stub handler");
        break;

      case "custom":
        // Handle custom workflows
        log.info("Custom trigger - stub handler", { data: body.data });
        break;

      default:
        log.warn("Unknown trigger type", { trigger: body.trigger });
    }

    return jsonResponse({
      success: true,
      trigger: body.trigger,
      message: "Webhook processed (stub)",
    });
  } catch (error) {
    log.error("Webhook processing failed", error);
    return errorResponse("Webhook processing failed", 500);
  }
});
