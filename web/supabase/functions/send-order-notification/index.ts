// Supabase Edge Function: send-order-notification
// Sends notifications when order status changes (email, SMS, push)
// STUB: To be implemented when notification system is ready

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { handleCors, jsonResponse, errorResponse } from "../_shared/cors.ts";
import { createServiceClient } from "../_shared/auth.ts";
import { sendEmail } from "../_shared/email.ts";
import { createLogger, maskEmail, maskPhone } from "../_shared/logger.ts";

const log = createLogger("send-order-notification");

/**
 * Notification request payload
 */
interface NotificationRequest {
  order_id: string;
  notification_type: "order_confirmed" | "order_preparing" | "order_ready" | "order_completed" | "order_cancelled";
  channels?: ("email" | "sms" | "push")[];
}

/**
 * Order data from database
 */
interface OrderData {
  id: string;
  order_number: string;
  customer_name: string;
  customer_email: string | null;
  customer_phone: string | null;
  status: string;
  total: number;
  store_id: number;
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
    const body: NotificationRequest = await req.json();

    // Validate request
    if (!body.order_id || !body.notification_type) {
      return errorResponse("Missing order_id or notification_type", 400);
    }

    log.info("Processing notification request", {
      order_id: body.order_id,
      type: body.notification_type,
      channels: body.channels || ["email"],
    });

    // Fetch order details
    const supabase = createServiceClient();
    const { data: order, error: orderError } = await supabase
      .from("orders")
      .select("id, order_number, customer_name, customer_email, customer_phone, status, total, store_id")
      .eq("id", body.order_id)
      .single();

    if (orderError || !order) {
      log.error("Order not found", orderError);
      return errorResponse("Order not found", 404);
    }

    const orderData = order as OrderData;
    const channels = body.channels || ["email"];
    const results: Record<string, boolean> = {};

    // Send email notification
    if (channels.includes("email") && orderData.customer_email) {
      log.info("Sending email notification", {
        email: maskEmail(orderData.customer_email),
      });

      // TODO: Implement proper email templates per notification type
      const result = await sendEmail({
        to: orderData.customer_email,
        subject: getEmailSubject(body.notification_type, orderData.order_number),
        html: getEmailBody(body.notification_type, orderData),
      });

      results.email = result.success;
    }

    // SMS notification (stub)
    if (channels.includes("sms") && orderData.customer_phone) {
      log.info("SMS notification - stub", {
        phone: maskPhone(orderData.customer_phone),
      });
      // TODO: Implement Twilio SMS
      results.sms = false;
    }

    // Push notification (stub)
    if (channels.includes("push")) {
      log.info("Push notification - stub");
      // TODO: Implement push notifications
      results.push = false;
    }

    return jsonResponse({
      success: true,
      order_id: body.order_id,
      notification_type: body.notification_type,
      results,
    });
  } catch (error) {
    log.error("Notification failed", error);
    return errorResponse("Notification failed", 500);
  }
});

/**
 * Get email subject based on notification type
 */
function getEmailSubject(type: string, orderNumber: string): string {
  switch (type) {
    case "order_confirmed":
      return `Order #${orderNumber} Confirmed!`;
    case "order_preparing":
      return `Order #${orderNumber} is Being Prepared`;
    case "order_ready":
      return `Order #${orderNumber} is Ready for Pickup!`;
    case "order_completed":
      return `Thank You for Your Order #${orderNumber}`;
    case "order_cancelled":
      return `Order #${orderNumber} Has Been Cancelled`;
    default:
      return `Update on Order #${orderNumber}`;
  }
}

/**
 * Get email body based on notification type
 * TODO: Replace with proper HTML templates
 */
function getEmailBody(type: string, order: OrderData): string {
  const statusMessages: Record<string, string> = {
    order_confirmed: "Your order has been confirmed and will be ready soon!",
    order_preparing: "Good news! We've started preparing your order.",
    order_ready: "Your order is ready for pickup! Come get it while it's fresh.",
    order_completed: "Thank you for your order! We hope you enjoyed it.",
    order_cancelled: "Your order has been cancelled. If you didn't request this, please contact us.",
  };

  return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Order Update - KnockBites</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f4f4f5;">
  <table role="presentation" style="width: 100%; border-collapse: collapse;">
    <tr>
      <td align="center" style="padding: 40px 20px;">
        <table role="presentation" style="width: 100%; max-width: 600px; border-collapse: collapse; background-color: #ffffff; border-radius: 12px; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);">
          <!-- Header -->
          <tr>
            <td style="padding: 40px 40px 20px; text-align: center; background: linear-gradient(135deg, #FBBF24 0%, #F59E0B 100%); border-radius: 12px 12px 0 0;">
              <img src="https://knockbites.com/email-logo.png" alt="KnockBites" style="width: 80px; height: 80px; margin-bottom: 16px; border-radius: 12px;" />
              <h1 style="margin: 0; font-size: 28px; font-weight: bold; color: #ffffff;">KnockBites</h1>
              <p style="margin: 10px 0 0; font-size: 14px; color: rgba(255,255,255,0.9);">Order Update</p>
            </td>
          </tr>
          <!-- Content -->
          <tr>
            <td style="padding: 40px;">
              <h2 style="margin: 0 0 20px; font-size: 24px; color: #1f2937;">Order #${order.order_number}</h2>
              <p style="margin: 0 0 20px; font-size: 16px; color: #374151; line-height: 1.6;">${statusMessages[type] || "Your order status has been updated."}</p>
              <p style="margin: 0 0 10px; font-size: 16px; color: #374151;"><strong>Total:</strong> $${order.total.toFixed(2)}</p>
            </td>
          </tr>
          <!-- Footer -->
          <tr>
            <td style="padding: 20px 40px 30px; text-align: center; border-top: 1px solid #e5e7eb;">
              <p style="margin: 0; font-size: 14px; color: #6b7280;">Thank you for choosing KnockBites!</p>
              <p style="margin: 10px 0 0; font-size: 12px; color: #9ca3af;">Fresh Food, Fast Service</p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
`;
}
