/**
 * Email utilities for Supabase Edge Functions
 * Supports Resend and SendGrid providers with automatic fallback
 */

export interface EmailOptions {
  to: string;
  subject: string;
  html: string;
  text?: string;
}

export interface EmailResult {
  success: boolean;
  provider?: "resend" | "sendgrid";
  error?: string;
}

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
const SENDGRID_API_KEY = Deno.env.get("SENDGRID_API_KEY");
const FROM_EMAIL = Deno.env.get("FROM_EMAIL") || "noreply@camerons247deli.com";
const FROM_NAME = Deno.env.get("FROM_NAME") || "Cameron's 24-7 Deli";

/**
 * Send email via Resend API
 */
async function sendViaResend(options: EmailOptions): Promise<boolean> {
  if (!RESEND_API_KEY) {
    console.error("RESEND_API_KEY not configured");
    return false;
  }

  try {
    const response = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${RESEND_API_KEY}`,
      },
      body: JSON.stringify({
        from: `${FROM_NAME} <${FROM_EMAIL}>`,
        to: [options.to],
        subject: options.subject,
        html: options.html,
        text: options.text || stripHtml(options.html),
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      console.error("Resend error:", error);
      return false;
    }

    return true;
  } catch (error) {
    console.error("Resend exception:", error);
    return false;
  }
}

/**
 * Send email via SendGrid API
 */
async function sendViaSendGrid(options: EmailOptions): Promise<boolean> {
  if (!SENDGRID_API_KEY) {
    console.error("SENDGRID_API_KEY not configured");
    return false;
  }

  try {
    const response = await fetch("https://api.sendgrid.com/v3/mail/send", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${SENDGRID_API_KEY}`,
      },
      body: JSON.stringify({
        personalizations: [{ to: [{ email: options.to }] }],
        from: { email: FROM_EMAIL, name: FROM_NAME },
        subject: options.subject,
        content: [
          {
            type: "text/plain",
            value: options.text || stripHtml(options.html),
          },
          {
            type: "text/html",
            value: options.html,
          },
        ],
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      console.error("SendGrid error:", error);
      return false;
    }

    return true;
  } catch (error) {
    console.error("SendGrid exception:", error);
    return false;
  }
}

/**
 * Send email with automatic provider fallback
 * Tries Resend first, falls back to SendGrid
 *
 * @example
 * const result = await sendEmail({
 *   to: "user@example.com",
 *   subject: "Hello",
 *   html: "<h1>Hello World</h1>",
 * });
 */
export async function sendEmail(options: EmailOptions): Promise<EmailResult> {
  // Validate email format
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(options.to)) {
    return { success: false, error: "Invalid email format" };
  }

  // Try Resend first
  if (RESEND_API_KEY) {
    console.log("Attempting to send via Resend...");
    const sent = await sendViaResend(options);
    if (sent) {
      return { success: true, provider: "resend" };
    }
  }

  // Fall back to SendGrid
  if (SENDGRID_API_KEY) {
    console.log("Attempting to send via SendGrid...");
    const sent = await sendViaSendGrid(options);
    if (sent) {
      return { success: true, provider: "sendgrid" };
    }
  }

  // No provider available or all failed
  console.error("No email provider configured or all providers failed");
  return {
    success: false,
    error: "Failed to send email. No provider available.",
  };
}

/**
 * Check if any email provider is configured
 */
export function isEmailConfigured(): boolean {
  return !!(RESEND_API_KEY || SENDGRID_API_KEY);
}

/**
 * Get configured email providers
 */
export function getConfiguredProviders(): string[] {
  const providers: string[] = [];
  if (RESEND_API_KEY) providers.push("resend");
  if (SENDGRID_API_KEY) providers.push("sendgrid");
  return providers;
}

/**
 * Simple HTML tag stripper for plain text fallback
 */
function stripHtml(html: string): string {
  return html
    .replace(/<[^>]*>/g, "")
    .replace(/\s+/g, " ")
    .trim();
}
