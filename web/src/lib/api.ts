/**
 * API Utilities with Instrumentation
 *
 * Wraps Supabase client operations with:
 * - Logging and timing
 * - Retry logic for transient failures
 * - Error normalization
 */

import { supabase } from './supabase';
import { createLogger, logApiCall } from './logger';
import type { PostgrestError, PostgrestSingleResponse, PostgrestResponse } from '@supabase/supabase-js';

const log = createLogger('API');

// Retry configuration
const DEFAULT_RETRY_COUNT = 3;
const RETRY_DELAY_MS = 1000;
const RETRYABLE_STATUS_CODES = [408, 429, 500, 502, 503, 504];

interface RetryOptions {
  maxRetries?: number;
  delayMs?: number;
  shouldRetry?: (error: PostgrestError | null) => boolean;
}

/**
 * Check if an error is retryable
 */
function isRetryableError(error: PostgrestError | null): boolean {
  if (!error) return false;

  // Network errors
  if (error.message?.includes('network') || error.message?.includes('fetch')) {
    return true;
  }

  // Rate limiting or server errors
  const code = parseInt(error.code || '0', 10);
  if (RETRYABLE_STATUS_CODES.includes(code)) {
    return true;
  }

  return false;
}

/**
 * Sleep utility
 */
function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Execute a function with retry logic
 */
async function withRetry<T>(
  operation: string,
  fn: () => Promise<T>,
  options: RetryOptions = {}
): Promise<T> {
  const {
    maxRetries = DEFAULT_RETRY_COUNT,
    delayMs = RETRY_DELAY_MS,
    shouldRetry = isRetryableError,
  } = options;

  let lastError: Error | null = null;

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (err) {
      lastError = err instanceof Error ? err : new Error(String(err));

      const postgrestError = (err as { error?: PostgrestError })?.error;
      const isRetryable = shouldRetry(postgrestError || null);

      if (!isRetryable || attempt === maxRetries) {
        log.error(`${operation} failed after ${attempt} attempts`, lastError);
        throw lastError;
      }

      const backoffDelay = delayMs * Math.pow(2, attempt - 1);
      log.warn(`${operation} failed, retrying in ${backoffDelay}ms`, {
        attempt,
        maxRetries,
        error: lastError.message,
      });

      await sleep(backoffDelay);
    }
  }

  throw lastError;
}

/**
 * Normalize Supabase response to throw on error
 */
function handleResponse<T>(
  response: PostgrestSingleResponse<T> | PostgrestResponse<T>,
  operation: string
): T {
  if (response.error) {
    log.error(`${operation} returned error`, new Error(response.error.message), {
      code: response.error.code,
      details: response.error.details,
      hint: response.error.hint,
    });
    throw new Error(response.error.message);
  }
  return response.data as T;
}

/**
 * Instrumented query wrapper
 *
 * @example
 * const orders = await query('fetchOrders', () =>
 *   supabase.from('orders').select('*').eq('store_id', 1)
 * );
 */
export async function query<T>(
  operation: string,
  fn: () => PromiseLike<PostgrestResponse<T> | PostgrestSingleResponse<T>>,
  options?: RetryOptions
): Promise<T> {
  return withRetry(operation, async () => {
    const result = await logApiCall(operation, () => Promise.resolve(fn()));
    return handleResponse(result, operation);
  }, options);
}

/**
 * Instrumented RPC wrapper
 *
 * @example
 * const metrics = await rpc('getStoreMetrics', 'get_store_metrics', {
 *   p_store_id: 1,
 *   p_date_range: 'today'
 * });
 */
export async function rpc<T>(
  operation: string,
  functionName: string,
  params?: Record<string, unknown>,
  options?: RetryOptions
): Promise<T> {
  return withRetry(operation, async () => {
    const result = await logApiCall(
      `RPC:${functionName}`,
      () => supabase.rpc(functionName, params) as Promise<PostgrestSingleResponse<T>>,
      { params: Object.keys(params || {}) }
    );
    return handleResponse(result, operation);
  }, options);
}

/**
 * Instrumented mutation wrapper (insert/update/delete)
 *
 * @example
 * const order = await mutate('createOrder', () =>
 *   supabase.from('orders').insert({ ... }).select().single()
 * );
 */
export async function mutate<T>(
  operation: string,
  fn: () => PromiseLike<PostgrestSingleResponse<T>>,
  options?: RetryOptions
): Promise<T> {
  // Mutations should not retry by default (could cause duplicates)
  const mutationOptions = {
    maxRetries: 1,
    ...options,
  };

  return withRetry(operation, async () => {
    const result = await logApiCall(operation, () => Promise.resolve(fn()));
    return handleResponse(result, operation);
  }, mutationOptions);
}

/**
 * Health check for Supabase connection
 */
export async function healthCheck(): Promise<boolean> {
  try {
    const { error } = await supabase.from('stores').select('id').limit(1);
    return !error;
  } catch {
    return false;
  }
}

/**
 * Get request ID for tracing (if available)
 */
export function generateRequestId(): string {
  return `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
}

export { supabase };
