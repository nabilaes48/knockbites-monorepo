// Supabase Edge Function: scheduled-cleanup
// Runs cleanup tasks on a schedule
// Configure in supabase/config.toml with schedule = "*/15 * * * *"
// Uses shared utilities for consistent behavior

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { jsonResponse, errorResponse } from "../_shared/cors.ts";
import { createServiceClient } from "../_shared/auth.ts";
import { logError, logInfo } from "../_shared/error.ts";

serve(async (_req) => {
  try {
    logInfo("scheduled-cleanup", "Starting cleanup tasks");

    // Create Supabase client with service role for admin access
    const supabase = createServiceClient();

    // Run cleanup function
    const { data, error } = await supabase.rpc("cleanup_expired_verifications");

    if (error) {
      logError("scheduled-cleanup", error);
      return errorResponse(error.message, 500);
    }

    const result = data?.[0] || {
      deleted_verifications: 0,
      deleted_rate_limits: 0,
    };

    logInfo("scheduled-cleanup", "Cleanup completed", result);

    return jsonResponse({
      success: true,
      deleted_verifications: result.deleted_verifications,
      deleted_rate_limits: result.deleted_rate_limits,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    logError("scheduled-cleanup", error);
    return errorResponse(
      error instanceof Error ? error.message : "Unknown error",
      500
    );
  }
});
