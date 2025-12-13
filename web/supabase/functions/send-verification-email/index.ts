// Supabase Edge Function: send-verification-email
// Sends order verification codes via email (Resend/SendGrid)
// Uses shared utilities for consistent behavior

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { handleCors, jsonResponse, errorResponse } from "../_shared/cors.ts";
import { sendEmail } from "../_shared/email.ts";
import { logError, logInfo } from "../_shared/error.ts";

interface VerificationRequest {
  email: string;
  code: string;
  phone?: string;
  expiresAt: string;
}

/**
 * Generate verification email HTML template
 */
function getEmailTemplate(code: string): string {
  return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Order Verification Code</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f4f4f5;">
  <table role="presentation" style="width: 100%; border-collapse: collapse;">
    <tr>
      <td align="center" style="padding: 40px 20px;">
        <table role="presentation" style="width: 100%; max-width: 600px; border-collapse: collapse; background-color: #ffffff; border-radius: 12px; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);">
          <!-- Header -->
          <tr>
            <td style="padding: 40px 40px 20px; text-align: center; background: linear-gradient(135deg, #2196F3 0%, #FF8C42 100%); border-radius: 12px 12px 0 0;">
              <h1 style="margin: 0; font-size: 28px; font-weight: bold; color: #ffffff;">
                Cameron's 24-7 Deli
              </h1>
              <p style="margin: 10px 0 0; font-size: 14px; color: rgba(255,255,255,0.9);">
                Order Verification
              </p>
            </td>
          </tr>

          <!-- Content -->
          <tr>
            <td style="padding: 40px;">
              <p style="margin: 0 0 20px; font-size: 16px; color: #374151; line-height: 1.6;">
                You're almost ready to place your order! Enter this verification code to continue:
              </p>

              <!-- Code Box -->
              <div style="background-color: #f3f4f6; border-radius: 8px; padding: 24px; text-align: center; margin: 30px 0;">
                <p style="margin: 0; font-size: 36px; font-weight: bold; letter-spacing: 8px; color: #1f2937; font-family: 'Courier New', monospace;">
                  ${code}
                </p>
              </div>

              <p style="margin: 0 0 10px; font-size: 14px; color: #6b7280; text-align: center;">
                This code expires in <strong>10 minutes</strong>.
              </p>

              <p style="margin: 20px 0 0; font-size: 14px; color: #6b7280; line-height: 1.6;">
                If you didn't request this code, you can safely ignore this email.
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="padding: 20px 40px 30px; text-align: center; border-top: 1px solid #e5e7eb;">
              <p style="margin: 0; font-size: 12px; color: #9ca3af;">
                Cameron's 24-7 Deli - Fresh deli favorites, 24/7
              </p>
              <p style="margin: 10px 0 0; font-size: 12px; color: #9ca3af;">
                29 locations across New York
              </p>
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

serve(async (req) => {
  // Handle CORS preflight
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  // Only allow POST
  if (req.method !== "POST") {
    return errorResponse("Method not allowed", 405);
  }

  try {
    const body: VerificationRequest = await req.json();

    // Validate required fields
    if (!body.email || !body.code) {
      return errorResponse("Missing required fields: email, code", 400);
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(body.email)) {
      return errorResponse("Invalid email format", 400);
    }

    // Validate code format (6 digits)
    if (!/^\d{6}$/.test(body.code)) {
      return errorResponse("Invalid code format (must be 6 digits)", 400);
    }

    logInfo("send-verification-email", "Sending verification code", {
      email: body.email.replace(/(.{2}).*(@.*)/, "$1***$2"), // Mask email
    });

    // Send email using shared utility
    const result = await sendEmail({
      to: body.email,
      subject: `Your Order Verification Code: ${body.code}`,
      html: getEmailTemplate(body.code),
      text: `Your Cameron's 24-7 Deli verification code is: ${body.code}. This code expires in 10 minutes.`,
    });

    if (!result.success) {
      // In development, return success anyway (code can be found in logs/DB)
      const isDev = Deno.env.get("ENVIRONMENT") === "development";
      if (isDev) {
        logInfo("send-verification-email", "DEV MODE - code logged", {
          code: body.code,
        });
        return jsonResponse({
          success: true,
          message: "Email sent (dev mode - check logs)",
          dev_code: body.code,
        });
      }

      return errorResponse(
        "Failed to send verification email. Please try again.",
        500
      );
    }

    logInfo("send-verification-email", "Verification email sent", {
      provider: result.provider,
    });

    return jsonResponse({
      success: true,
      message: "Verification code sent to your email",
    });
  } catch (error) {
    logError("send-verification-email", error);
    return errorResponse("Internal server error", 500);
  }
});
