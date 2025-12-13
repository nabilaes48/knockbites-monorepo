// Supabase Edge Function: webhook-stripe
// Handles Stripe webhook events for payment processing
// STUB: To be implemented when Stripe integration is ready

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { jsonResponse, errorResponse } from "../_shared/cors.ts";
import { validateWebhookSignature } from "../_shared/auth.ts";
import { createLogger } from "../_shared/logger.ts";

const log = createLogger("webhook-stripe");
const STRIPE_WEBHOOK_SECRET = Deno.env.get("STRIPE_WEBHOOK_SECRET");

/**
 * Stripe webhook event types we care about
 */
type StripeEventType =
  | "checkout.session.completed"
  | "payment_intent.succeeded"
  | "payment_intent.payment_failed"
  | "charge.refunded";

interface StripeWebhookPayload {
  id: string;
  type: StripeEventType;
  data: {
    object: Record<string, unknown>;
  };
}

serve(async (req) => {
  // Only allow POST
  if (req.method !== "POST") {
    return errorResponse("Method not allowed", 405);
  }

  try {
    // Get the raw body for signature verification
    const body = await req.text();
    const signature = req.headers.get("stripe-signature");

    // Verify webhook signature
    if (!STRIPE_WEBHOOK_SECRET) {
      log.error("STRIPE_WEBHOOK_SECRET not configured");
      return errorResponse("Webhook not configured", 500);
    }

    if (!signature) {
      log.warn("Missing stripe-signature header");
      return errorResponse("Missing signature", 400);
    }

    // TODO: Implement proper Stripe signature verification
    // For now, return stub response
    log.info("Webhook received (stub)", { signature: signature.slice(0, 20) + "..." });

    // Parse the event
    const event: StripeWebhookPayload = JSON.parse(body);

    log.info("Processing Stripe event", {
      id: event.id,
      type: event.type,
    });

    // Handle different event types
    switch (event.type) {
      case "checkout.session.completed":
        // TODO: Mark order as paid
        log.info("Checkout completed - stub handler");
        break;

      case "payment_intent.succeeded":
        // TODO: Update payment status
        log.info("Payment succeeded - stub handler");
        break;

      case "payment_intent.payment_failed":
        // TODO: Handle failed payment
        log.warn("Payment failed - stub handler");
        break;

      case "charge.refunded":
        // TODO: Handle refund
        log.info("Charge refunded - stub handler");
        break;

      default:
        log.info("Unhandled event type", { type: event.type });
    }

    return jsonResponse({ received: true });
  } catch (error) {
    log.error("Webhook processing failed", error);
    return errorResponse("Webhook processing failed", 500);
  }
});
