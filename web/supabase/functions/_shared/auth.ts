/**
 * Authentication utilities for Supabase Edge Functions
 * Provides JWT verification and user context extraction
 */

import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

/**
 * User context extracted from JWT
 */
export interface UserContext {
  id: string;
  email?: string;
  role?: string;
  isAuthenticated: boolean;
}

/**
 * Create a Supabase client with anonymous key (for public operations)
 */
export function createAnonClient(): SupabaseClient {
  return createClient(supabaseUrl, supabaseAnonKey);
}

/**
 * Create a Supabase client with service role key (for admin operations)
 * USE WITH CAUTION - bypasses RLS
 */
export function createServiceClient(): SupabaseClient {
  return createClient(supabaseUrl, supabaseServiceKey);
}

/**
 * Create a Supabase client with user's JWT (respects RLS)
 *
 * @example
 * const authHeader = req.headers.get("Authorization");
 * const client = createAuthenticatedClient(authHeader);
 */
export function createAuthenticatedClient(
  authHeader: string | null
): SupabaseClient {
  if (!authHeader) {
    return createAnonClient();
  }

  const token = authHeader.replace("Bearer ", "");
  return createClient(supabaseUrl, supabaseAnonKey, {
    global: {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    },
  });
}

/**
 * Extract user context from request
 * Returns user info if authenticated, guest context otherwise
 *
 * @example
 * const user = await getUserFromRequest(req);
 * if (!user.isAuthenticated) {
 *   return errorResponse("Unauthorized", 401);
 * }
 */
export async function getUserFromRequest(
  req: Request
): Promise<UserContext> {
  const authHeader = req.headers.get("Authorization");

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return { id: "", isAuthenticated: false };
  }

  const token = authHeader.replace("Bearer ", "");
  const supabase = createClient(supabaseUrl, supabaseAnonKey, {
    global: {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    },
  });

  try {
    const {
      data: { user },
      error,
    } = await supabase.auth.getUser();

    if (error || !user) {
      return { id: "", isAuthenticated: false };
    }

    return {
      id: user.id,
      email: user.email,
      role: user.role,
      isAuthenticated: true,
    };
  } catch {
    return { id: "", isAuthenticated: false };
  }
}

/**
 * Require authentication - throws if not authenticated
 *
 * @example
 * const user = await requireAuth(req);
 * // user is guaranteed to be authenticated here
 */
export async function requireAuth(req: Request): Promise<UserContext> {
  const user = await getUserFromRequest(req);
  if (!user.isAuthenticated) {
    throw new Error("Authentication required");
  }
  return user;
}

/**
 * Check if request has valid API key in header
 * Useful for webhook authentication
 *
 * @example
 * if (!hasValidApiKey(req, "X-Webhook-Secret", expectedSecret)) {
 *   return errorResponse("Invalid API key", 401);
 * }
 */
export function hasValidApiKey(
  req: Request,
  headerName: string,
  expectedKey: string
): boolean {
  const providedKey = req.headers.get(headerName);
  if (!providedKey || !expectedKey) return false;

  // Constant-time comparison to prevent timing attacks
  if (providedKey.length !== expectedKey.length) return false;

  let result = 0;
  for (let i = 0; i < providedKey.length; i++) {
    result |= providedKey.charCodeAt(i) ^ expectedKey.charCodeAt(i);
  }
  return result === 0;
}

/**
 * Validate webhook signature (for Stripe, etc.)
 * Returns true if signature is valid
 */
export async function validateWebhookSignature(
  payload: string,
  signature: string,
  secret: string
): Promise<boolean> {
  try {
    const encoder = new TextEncoder();
    const key = await crypto.subtle.importKey(
      "raw",
      encoder.encode(secret),
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["sign"]
    );

    const signatureBuffer = await crypto.subtle.sign(
      "HMAC",
      key,
      encoder.encode(payload)
    );

    const expectedSignature = Array.from(new Uint8Array(signatureBuffer))
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("");

    return signature === expectedSignature;
  } catch {
    return false;
  }
}
