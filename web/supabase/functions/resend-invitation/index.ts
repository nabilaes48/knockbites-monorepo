// Supabase Edge Function: resend-invitation
// Resends invitation email to pending staff members
// Can be called manually or by the scheduled reminder

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { handleCors, jsonResponse, errorResponse } from "../_shared/cors.ts";
import { sendEmail } from "../_shared/email.ts";
import { logError, logInfo } from "../_shared/error.ts";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;

interface ResendRequest {
  user_id?: string;
  email?: string;
  send_all_pending?: boolean;
}

/**
 * Get invitation email HTML template
 */
function getInviteEmailTemplate(name: string, role: string, inviteLink: string, isReminder: boolean): string {
  const roleLabels: Record<string, string> = {
    admin: "Administrator",
    manager: "Store Manager",
    staff: "Team Member",
  };

  const reminderText = isReminder
    ? `<p style="margin: 0 0 20px; font-size: 14px; color: #6b7280; background-color: #FEF3C7; padding: 12px; border-radius: 8px;">
        This is a reminder that your invitation is still pending. Please complete your account setup.
      </p>`
    : "";

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
                ${isReminder ? "Reminder: Complete Your Account Setup" : "You're Invited to Join Our Team!"}
              </p>
            </td>
          </tr>

          <!-- Content -->
          <tr>
            <td style="padding: 40px;">
              ${reminderText}

              <p style="margin: 0 0 20px; font-size: 18px; color: #374151; font-weight: 600;">
                Hello ${name},
              </p>

              <p style="margin: 0 0 20px; font-size: 16px; color: #374151; line-height: 1.6;">
                You've been invited to join KnockBites as a <strong>${roleLabels[role] || role}</strong>!
              </p>

              <p style="margin: 0 0 30px; font-size: 16px; color: #374151; line-height: 1.6;">
                Click the button below to set up your password and access the Business Dashboard:
              </p>

              <!-- CTA Button -->
              <div style="text-align: center; margin: 30px 0;">
                <a href="${inviteLink}" style="display: inline-block; padding: 16px 40px; background: linear-gradient(135deg, #FBBF24 0%, #F59E0B 100%); color: #ffffff; text-decoration: none; font-weight: bold; font-size: 16px; border-radius: 8px; box-shadow: 0 4px 12px rgba(251, 191, 36, 0.4);">
                  ${isReminder ? "Complete Setup Now" : "Accept Invitation"}
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
      return errorResponse("Only admins can resend invitations", 403);
    }

    // Parse request body
    const body: ResendRequest = await req.json();

    // Create service client for admin operations
    const adminClient = createClient(supabaseUrl, supabaseServiceKey);

    const siteUrl = Deno.env.get("SITE_URL") || "https://knockbites.com";
    const results: { email: string; success: boolean; error?: string }[] = [];

    // Get pending invites to resend
    let pendingUsers: any[] = [];

    if (body.send_all_pending) {
      // Get all users who haven't confirmed their email (pending invites)
      const { data: users, error: usersError } = await adminClient.auth.admin.listUsers();

      if (usersError) {
        throw new Error(`Failed to list users: ${usersError.message}`);
      }

      // Filter to users who haven't confirmed and have a user_profile
      const pendingAuthUsers = users.users.filter(u => !u.email_confirmed_at);

      for (const authUser of pendingAuthUsers) {
        const { data: profile } = await adminClient
          .from("user_profiles")
          .select("*")
          .eq("id", authUser.id)
          .single();

        if (profile) {
          pendingUsers.push({
            id: authUser.id,
            email: authUser.email,
            full_name: profile.full_name,
            role: profile.role,
          });
        }
      }
    } else if (body.user_id) {
      // Get specific user
      const { data: { user: authUser }, error: authError } = await adminClient.auth.admin.getUserById(body.user_id);

      if (authError || !authUser) {
        return errorResponse("User not found", 404);
      }

      const { data: profile, error: profileErr } = await adminClient
        .from("user_profiles")
        .select("*")
        .eq("id", body.user_id)
        .single();

      if (profileErr || !profile) {
        return errorResponse("User profile not found", 404);
      }

      pendingUsers.push({
        id: authUser.id,
        email: authUser.email,
        full_name: profile.full_name,
        role: profile.role,
      });
    } else if (body.email) {
      // Find user by email
      const { data: users } = await adminClient.auth.admin.listUsers();
      const authUser = users?.users?.find(u => u.email?.toLowerCase() === body.email?.toLowerCase());

      if (!authUser) {
        return errorResponse("User not found", 404);
      }

      const { data: profile } = await adminClient
        .from("user_profiles")
        .select("*")
        .eq("id", authUser.id)
        .single();

      if (!profile) {
        return errorResponse("User profile not found", 404);
      }

      pendingUsers.push({
        id: authUser.id,
        email: authUser.email,
        full_name: profile.full_name,
        role: profile.role,
      });
    } else {
      return errorResponse("Must provide user_id, email, or send_all_pending", 400);
    }

    // Send invitations
    for (const user of pendingUsers) {
      try {
        // Generate a new invite link using Supabase magic link
        const { data: linkData, error: linkError } = await adminClient.auth.admin.generateLink({
          type: "magiclink",
          email: user.email,
          options: {
            redirectTo: `${siteUrl}/dashboard/login?invited=true`,
          },
        });

        if (linkError) {
          throw new Error(linkError.message);
        }

        // Send custom email with the invite link
        const inviteLink = linkData.properties?.action_link || `${siteUrl}/dashboard/login?email=${encodeURIComponent(user.email)}`;

        const emailResult = await sendEmail({
          to: user.email,
          subject: `Reminder: Complete Your KnockBites Account Setup`,
          html: getInviteEmailTemplate(user.full_name, user.role, inviteLink, true),
          text: `Hello ${user.full_name}, this is a reminder to complete your KnockBites account setup. Visit ${inviteLink} to set your password.`,
        });

        if (emailResult.success) {
          logInfo("resend-invitation", "Invitation resent", {
            userId: user.id,
            email: user.email.replace(/(.{2}).*(@.*)/, "$1***$2"),
          });

          // Update last_reminder_sent timestamp
          await adminClient
            .from("user_profiles")
            .update({
              last_reminder_sent: new Date().toISOString(),
              updated_at: new Date().toISOString(),
            })
            .eq("id", user.id);

          results.push({ email: user.email, success: true });
        } else {
          results.push({ email: user.email, success: false, error: emailResult.error });
        }
      } catch (err: any) {
        logError("resend-invitation", err);
        results.push({ email: user.email, success: false, error: err.message });
      }
    }

    const successCount = results.filter(r => r.success).length;
    const failCount = results.filter(r => !r.success).length;

    return jsonResponse({
      success: true,
      message: `Sent ${successCount} invitation(s)${failCount > 0 ? `, ${failCount} failed` : ""}`,
      results,
    });
  } catch (error) {
    logError("resend-invitation", error);
    return errorResponse("Internal server error", 500);
  }
});
