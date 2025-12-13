/**
 * Error handling utilities for Supabase Edge Functions
 * Provides consistent error formatting and logging
 */

/**
 * Standard error response format
 */
export interface ErrorInfo {
  error: string;
  code?: string;
  details?: unknown;
}

/**
 * Format an error for API response
 * Safely extracts message from various error types
 *
 * @example
 * try {
 *   // some operation
 * } catch (err) {
 *   return jsonResponse(formatError(err), 500);
 * }
 */
export function formatError(error: unknown): ErrorInfo {
  if (error instanceof Error) {
    return {
      error: error.message,
      code: error.name,
    };
  }

  if (typeof error === "string") {
    return { error };
  }

  if (typeof error === "object" && error !== null) {
    const err = error as Record<string, unknown>;
    return {
      error: String(err.message || err.error || "Unknown error"),
      code: String(err.code || err.name || "UNKNOWN"),
      details: err.details,
    };
  }

  return { error: "An unexpected error occurred" };
}

/**
 * Log error with consistent format
 *
 * @example
 * catch (err) {
 *   logError("Failed to process order", err, { orderId: "123" });
 * }
 */
export function logError(
  context: string,
  error: unknown,
  metadata?: Record<string, unknown>
): void {
  const errorInfo = formatError(error);
  console.error(
    JSON.stringify({
      level: "error",
      context,
      ...errorInfo,
      metadata,
      timestamp: new Date().toISOString(),
    })
  );
}

/**
 * Log warning with consistent format
 */
export function logWarning(
  context: string,
  message: string,
  metadata?: Record<string, unknown>
): void {
  console.warn(
    JSON.stringify({
      level: "warn",
      context,
      message,
      metadata,
      timestamp: new Date().toISOString(),
    })
  );
}

/**
 * Log info with consistent format
 */
export function logInfo(
  context: string,
  message: string,
  metadata?: Record<string, unknown>
): void {
  console.log(
    JSON.stringify({
      level: "info",
      context,
      message,
      metadata,
      timestamp: new Date().toISOString(),
    })
  );
}

/**
 * Create a validation error
 */
export function validationError(
  field: string,
  message: string
): ErrorInfo {
  return {
    error: message,
    code: "VALIDATION_ERROR",
    details: { field },
  };
}

/**
 * Check if error is a specific type
 */
export function isErrorType(error: unknown, code: string): boolean {
  if (error instanceof Error && error.name === code) return true;
  if (typeof error === "object" && error !== null) {
    const err = error as Record<string, unknown>;
    return err.code === code || err.name === code;
  }
  return false;
}
