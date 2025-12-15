// Supabase Edge Function: invite-staff
// Invites new staff members by email and creates their profile
// Requires admin/super_admin authentication

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { handleCors, jsonResponse, errorResponse } from "../_shared/cors.ts";
import { sendEmail } from "../_shared/email.ts";
import { logError, logInfo } from "../_shared/error.ts";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;

interface InviteStaffRequest {
  email: string;
  full_name: string;
  phone?: string;
  role: "admin" | "manager" | "staff";
  store_id?: number;
  assigned_stores?: number[];
}

/**
 * Get staff invitation email HTML template
 */
function getInviteEmailTemplate(name: string, role: string, inviteLink: string): string {
  const roleLabels: Record<string, string> = {
    admin: "Administrator",
    manager: "Store Manager",
    staff: "Team Member",
  };

  return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Welcome to KnockBites</title>
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
              <h1 style="margin: 0; font-size: 28px; font-weight: bold; color: #ffffff;">
                KnockBites
              </h1>
              <p style="margin: 10px 0 0; font-size: 14px; color: rgba(255,255,255,0.9);">
                You're Invited to Join Our Team!
              </p>
            </td>
          </tr>

          <!-- Content -->
          <tr>
            <td style="padding: 40px;">
              <p style="margin: 0 0 20px; font-size: 18px; color: #374151; font-weight: 600;">
                Hello ${name},
              </p>

              <p style="margin: 0 0 20px; font-size: 16px; color: #374151; line-height: 1.6;">
                You've been invited to join KnockBites as a <strong>${roleLabels[role] || role}</strong>!
              </p>

              <p style="margin: 0 0 30px; font-size: 16px; color: #374151; line-height: 1.6;">
                Click the button below to set up your account and access the Business Dashboard:
              </p>

              <!-- CTA Button -->
              <div style="text-align: center; margin: 30px 0;">
                <a href="${inviteLink}" style="display: inline-block; padding: 16px 40px; background: linear-gradient(135deg, #FBBF24 0%, #F59E0B 100%); color: #ffffff; text-decoration: none; font-weight: bold; font-size: 16px; border-radius: 8px; box-shadow: 0 4px 12px rgba(251, 191, 36, 0.4);">
                  Accept Invitation
                </a>
              </div>

              <p style="margin: 30px 0 10px; font-size: 14px; color: #6b7280; text-align: center;">
                This invitation expires in <strong>7 days</strong>.
              </p>

              <p style="margin: 20px 0 0; font-size: 14px; color: #6b7280; line-height: 1.6;">
                If you didn't expect this invitation, you can safely ignore this email.
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="padding: 20px 40px 30px; text-align: center; border-top: 1px solid #e5e7eb;">
              <p style="margin: 0; font-size: 12px; color: #9ca3af;">
                KnockBites - Fresh Food, Fast Service
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
    // Get the authorization header
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return errorResponse("Authorization required", 401);
    }

    // Create authenticated client to check caller's permissions
    const token = authHeader.replace("Bearer ", "");
    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: `Bearer ${token}` } },
    });

    // Get the calling user
    const { data: { user: callingUser }, error: userError } = await userClient.auth.getUser();
    if (userError || !callingUser) {
      return errorResponse("Invalid authentication", 401);
    }

    // Check if caller is admin or super_admin
    const { data: callerProfile, error: profileError } = await userClient
      .from("user_profiles")
      .select("role, is_system_admin")
      .eq("id", callingUser.id)
      .single();

    if (profileError || !callerProfile) {
      return errorResponse("User profile not found", 403);
    }

    const allowedRoles = ["super_admin", "admin"];
    if (!allowedRoles.includes(callerProfile.role) && !callerProfile.is_system_admin) {
      return errorResponse("Only admins can invite staff", 403);
    }

    // Parse request body
    const body: InviteStaffRequest = await req.json();

    // Validate required fields
    if (!body.email || !body.full_name || !body.role) {
      return errorResponse("Missing required fields: email, full_name, role", 400);
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(body.email)) {
      return errorResponse("Invalid email format", 400);
    }

    // Validate role
    const validRoles = ["admin", "manager", "staff"];
    if (!validRoles.includes(body.role)) {
      return errorResponse("Invalid role. Must be: admin, manager, or staff", 400);
    }

    logInfo("invite-staff", "Inviting new staff member", {
      email: body.email.replace(/(.{2}).*(@.*)/, "$1***$2"),
      role: body.role,
    });

    // Create service client for admin operations
    const adminClient = createClient(supabaseUrl, supabaseServiceKey);

    // Check if user already exists in auth.users
    const { data: existingUsers } = await adminClient.auth.admin.listUsers();
    const existingUser = existingUsers?.users?.find(
      (u) => u.email?.toLowerCase() === body.email.toLowerCase()
    );

    const siteUrl = Deno.env.get("SITE_URL") || "https://knockbites.com";
    let userId: string;
    let isExistingCustomer = false;

    if (existingUser) {
      // User already exists - check if they're already staff
      const { data: existingProfile } = await adminClient
        .from("user_profiles")
        .select("id, role")
        .eq("id", existingUser.id)
        .single();

      if (existingProfile) {
        return errorResponse("This user already has a staff account", 400);
      }

      // User exists (probably as customer) - upgrade them to staff
      userId = existingUser.id;
      isExistingCustomer = true;

      logInfo("invite-staff", "Upgrading existing customer to staff", {
        userId,
        role: body.role,
      });

      // Send notification email about their new staff role
      try {
        const upgradeLink = `${siteUrl}/dashboard/login`;
        await sendEmail({
          to: body.email,
          subject: `You've been added as ${body.role} at KnockBites!`,
          html: getInviteEmailTemplate(body.full_name, body.role, upgradeLink),
          text: `Hello ${body.full_name}, you've been added as a ${body.role} at KnockBites. Log in at ${upgradeLink} using your existing password.`,
        });
      } catch (emailError) {
        console.warn("Email notification failed:", emailError);
      }
    } else {
      // New user - send invitation via Supabase Auth
      const { data: inviteData, error: inviteError } = await adminClient.auth.admin.inviteUserByEmail(
        body.email,
        {
          redirectTo: `${siteUrl}/dashboard/login?invited=true`,
          data: {
            full_name: body.full_name,
            role: body.role,
            invited_by: callingUser.id,
          },
        }
      );

      if (inviteError) {
        logError("invite-staff", inviteError);
        return errorResponse(`Failed to send invitation: ${inviteError.message}`, 500);
      }

      if (!inviteData.user) {
        return errorResponse("Failed to create invitation", 500);
      }

      userId = inviteData.user.id;

      // Send custom welcome email (optional - Supabase also sends one)
      try {
        const inviteLink = `${siteUrl}/dashboard/login?email=${encodeURIComponent(body.email)}`;
        await sendEmail({
          to: body.email,
          subject: `Welcome to KnockBites - You're Invited!`,
          html: getInviteEmailTemplate(body.full_name, body.role, inviteLink),
          text: `Hello ${body.full_name}, you've been invited to join KnockBites as a ${body.role}. Visit ${inviteLink} to set up your account.`,
        });
      } catch (emailError) {
        console.warn("Custom email failed, but Supabase invite was sent:", emailError);
      }
    }

    // Create the user_profiles record
    const { error: profileCreateError } = await adminClient.from("user_profiles").insert({
      id: userId,
      email: body.email,
      full_name: body.full_name,
      phone: body.phone || null,
      role: body.role,
      store_id: body.store_id || null,
      assigned_stores: body.assigned_stores || (body.store_id ? [body.store_id] : []),
      is_active: true,
      permissions: getDefaultPermissions(body.role),
      invite_status: isExistingCustomer ? "accepted" : "pending",
      invited_at: new Date().toISOString(),
    });

    if (profileCreateError) {
      logError("invite-staff", profileCreateError);
      // Don't fail completely - the auth user was created
      console.error("Failed to create user profile:", profileCreateError);
    }

    logInfo("invite-staff", "Staff member added successfully", {
      userId,
      role: body.role,
      isExistingCustomer,
    });

    return jsonResponse({
      success: true,
      message: isExistingCustomer
        ? `${body.full_name} has been upgraded to ${body.role}. They can log in with their existing password.`
        : `Invitation sent to ${body.email}`,
      user: {
        id: userId,
        email: body.email,
        full_name: body.full_name,
        role: body.role,
        status: isExistingCustomer ? "active" : "invited",
        isExistingCustomer,
      },
    });
  } catch (error) {
    logError("invite-staff", error);
    return errorResponse("Internal server error", 500);
  }
});

/**
 * Get default permissions based on role
 */
function getDefaultPermissions(role: string): string[] {
  switch (role) {
    case "super_admin":
      return ["orders", "menu", "analytics", "settings", "staff", "all-stores"];
    case "admin":
      return ["orders", "menu", "analytics", "settings", "staff"];
    case "manager":
      return ["orders", "menu", "analytics", "settings"];
    case "staff":
      return ["orders"];
    default:
      return ["orders"];
  }
}
