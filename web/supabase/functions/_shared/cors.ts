/**
 * CORS utilities for Supabase Edge Functions
 * Provides standard CORS headers and preflight handling
 */

/**
 * Standard CORS headers for browser requests
 */
export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
};

/**
 * Handle CORS preflight requests
 * Returns a Response for OPTIONS requests, null otherwise
 *
 * @example
 * const corsResponse = handleCors(req);
 * if (corsResponse) return corsResponse;
 */
export function handleCors(req: Request): Response | null {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  return null;
}

/**
 * Create a JSON response with CORS headers
 *
 * @example
 * return jsonResponse({ success: true }, 200);
 * return jsonResponse({ error: "Not found" }, 404);
 */
export function jsonResponse(
  data: unknown,
  status: number = 200
): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

/**
 * Create an error response with CORS headers
 *
 * @example
 * return errorResponse("Invalid input", 400);
 * return errorResponse("Server error", 500);
 */
export function errorResponse(
  message: string,
  status: number = 500
): Response {
  return jsonResponse({ error: message }, status);
}
