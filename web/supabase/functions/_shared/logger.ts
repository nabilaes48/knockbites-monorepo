/**
 * Structured logging utilities for Supabase Edge Functions
 * Provides consistent log formatting across all functions
 *
 * Features:
 * - Request tracing with X-Request-ID
 * - Execution timing
 * - Safe body snapshots (no sensitive data)
 * - Structured JSON output for log aggregators
 */

export type LogLevel = 'debug' | 'info' | 'warn' | 'error';

export interface LogEntry {
  level: LogLevel;
  context: string;
  message: string;
  timestamp: string;
  requestId?: string;
  executionTimeMs?: number;
  metadata?: Record<string, unknown>;
  error?: {
    name: string;
    message: string;
    stack?: string;
  };
}

// Sensitive headers to exclude from logs
const SENSITIVE_HEADERS = [
  'authorization',
  'cookie',
  'x-api-key',
  'x-n8n-webhook-secret',
  'stripe-signature',
];

// Sensitive body fields to mask
const SENSITIVE_FIELDS = [
  'password',
  'token',
  'secret',
  'api_key',
  'apiKey',
  'credit_card',
  'creditCard',
  'ssn',
  'cvv',
];

/**
 * Generate a unique request ID
 */
export function generateRequestId(): string {
  return `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
}

/**
 * Get request ID from headers or generate new one
 */
export function getRequestId(req: Request): string {
  return req.headers.get('x-request-id') || generateRequestId();
}

/**
 * Format a log entry as JSON string
 */
function formatLog(entry: LogEntry): string {
  return JSON.stringify(entry);
}

/**
 * Mask sensitive values in an object
 */
function maskSensitiveData(obj: Record<string, unknown>): Record<string, unknown> {
  const masked: Record<string, unknown> = {};

  for (const [key, value] of Object.entries(obj)) {
    const lowerKey = key.toLowerCase();
    if (SENSITIVE_FIELDS.some((field) => lowerKey.includes(field.toLowerCase()))) {
      masked[key] = '***REDACTED***';
    } else if (typeof value === 'object' && value !== null) {
      masked[key] = maskSensitiveData(value as Record<string, unknown>);
    } else {
      masked[key] = value;
    }
  }

  return masked;
}

/**
 * Get safe headers snapshot (excludes sensitive headers)
 */
function getSafeHeaders(req: Request): Record<string, string> {
  const headers: Record<string, string> = {};
  req.headers.forEach((value, key) => {
    if (!SENSITIVE_HEADERS.includes(key.toLowerCase())) {
      headers[key] = value;
    } else {
      headers[key] = '***REDACTED***';
    }
  });
  return headers;
}

/**
 * Get safe body snapshot
 */
async function getSafeBody(req: Request): Promise<Record<string, unknown> | null> {
  try {
    const contentType = req.headers.get('content-type') || '';
    if (!contentType.includes('application/json')) {
      return null;
    }

    const clonedReq = req.clone();
    const body = await clonedReq.json();

    if (typeof body === 'object' && body !== null) {
      return maskSensitiveData(body as Record<string, unknown>);
    }

    return null;
  } catch {
    return null;
  }
}

/**
 * Logger instance with request context
 */
interface LoggerInstance {
  debug: (message: string, metadata?: Record<string, unknown>) => void;
  info: (message: string, metadata?: Record<string, unknown>) => void;
  warn: (message: string, metadata?: Record<string, unknown>) => void;
  error: (message: string, error?: unknown, metadata?: Record<string, unknown>) => void;
  getRequestId: () => string;
  getExecutionTime: () => number;
}

/**
 * Create a logger instance for a specific context (function name)
 *
 * @example
 * const log = createLogger('send-verification-email');
 * log.info('Starting email send', { to: 'user@example.com' });
 * log.error('Failed to send', error);
 */
export function createLogger(context: string, requestId?: string): LoggerInstance {
  const startTime = Date.now();
  const reqId = requestId || generateRequestId();

  const makeEntry = (
    level: LogLevel,
    message: string,
    metadata?: Record<string, unknown>,
    error?: unknown
  ): LogEntry => {
    const entry: LogEntry = {
      level,
      context,
      message,
      timestamp: new Date().toISOString(),
      requestId: reqId,
      executionTimeMs: Date.now() - startTime,
      metadata,
    };

    if (error instanceof Error) {
      entry.error = {
        name: error.name,
        message: error.message,
        stack: error.stack,
      };
    } else if (error) {
      entry.error = {
        name: 'UnknownError',
        message: String(error),
      };
    }

    return entry;
  };

  return {
    debug: (message: string, metadata?: Record<string, unknown>) => {
      if (Deno.env.get('LOG_LEVEL') === 'debug') {
        console.debug(formatLog(makeEntry('debug', message, metadata)));
      }
    },

    info: (message: string, metadata?: Record<string, unknown>) => {
      console.log(formatLog(makeEntry('info', message, metadata)));
    },

    warn: (message: string, metadata?: Record<string, unknown>) => {
      console.warn(formatLog(makeEntry('warn', message, metadata)));
    },

    error: (message: string, error?: unknown, metadata?: Record<string, unknown>) => {
      console.error(formatLog(makeEntry('error', message, metadata, error)));
    },

    getRequestId: () => reqId,

    getExecutionTime: () => Date.now() - startTime,
  };
}

/**
 * Log incoming request details (useful for debugging)
 */
export async function logRequest(
  logger: LoggerInstance,
  req: Request
): Promise<void> {
  const safeBody = await getSafeBody(req);

  logger.debug('Incoming request', {
    method: req.method,
    url: req.url,
    headers: getSafeHeaders(req),
    body: safeBody,
  });
}

/**
 * Log response details with execution time
 */
export function logResponse(
  logger: LoggerInstance,
  status: number
): void {
  const level = status >= 500 ? 'error' : status >= 400 ? 'warn' : 'info';
  logger[level]('Request completed', {
    status,
    executionTimeMs: logger.getExecutionTime(),
  });
}

/**
 * Time an async operation and log the result
 *
 * @example
 * const result = await timeAsync(logger, 'database_query', async () => {
 *   return await supabase.from('orders').select();
 * });
 */
export async function timeAsync<T>(
  logger: LoggerInstance,
  operation: string,
  fn: () => Promise<T>
): Promise<T> {
  const start = Date.now();
  try {
    const result = await fn();
    logger.debug(`${operation} completed`, {
      operationDurationMs: Date.now() - start,
    });
    return result;
  } catch (error) {
    logger.error(`${operation} failed`, error, {
      operationDurationMs: Date.now() - start,
    });
    throw error;
  }
}

/**
 * Mask sensitive data in logs
 */
export function maskSensitive(value: string, visibleChars: number = 4): string {
  if (value.length <= visibleChars) return '***';
  return value.slice(0, visibleChars) + '***';
}

/**
 * Mask email for logging
 */
export function maskEmail(email: string): string {
  const [local, domain] = email.split('@');
  if (!domain) return '***';
  return `${maskSensitive(local, 2)}@${domain}`;
}

/**
 * Mask phone number for logging
 */
export function maskPhone(phone: string): string {
  return phone.replace(/\d(?=\d{4})/g, '*');
}

/**
 * Create response with X-Request-ID header
 */
export function createTracedResponse(
  body: unknown,
  requestId: string,
  status: number = 200,
  headers: Record<string, string> = {}
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'X-Request-ID': requestId,
      ...headers,
    },
  });
}

/**
 * Submit metrics to the runtime_metrics table
 * Called at the end of Edge Function execution
 */
export async function submitMetrics(
  context: string,
  requestId: string,
  executionTimeMs: number,
  metadata?: Record<string, unknown>
): Promise<void> {
  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!supabaseUrl || !serviceKey) {
      return; // Skip if not configured
    }

    await fetch(`${supabaseUrl}/rest/v1/runtime_metrics`, {
      method: 'POST',
      headers: {
        'apikey': serviceKey,
        'Authorization': `Bearer ${serviceKey}`,
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal',
      },
      body: JSON.stringify({
        session_id: requestId,
        event_type: 'edge_function',
        event_data: {
          function_name: context,
          execution_time_ms: executionTimeMs,
          ...metadata,
        },
      }),
    });
  } catch {
    // Silently fail - don't let metrics break the function
  }
}

/**
 * Submit an error metric
 */
export async function submitErrorMetric(
  context: string,
  requestId: string,
  error: unknown,
  metadata?: Record<string, unknown>
): Promise<void> {
  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!supabaseUrl || !serviceKey) {
      return;
    }

    const errorData = error instanceof Error
      ? { name: error.name, message: error.message }
      : { message: String(error) };

    await fetch(`${supabaseUrl}/rest/v1/runtime_metrics`, {
      method: 'POST',
      headers: {
        'apikey': serviceKey,
        'Authorization': `Bearer ${serviceKey}`,
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal',
      },
      body: JSON.stringify({
        session_id: requestId,
        event_type: 'error',
        event_data: {
          error_type: 'edge_function_error',
          function_name: context,
          ...errorData,
          ...metadata,
        },
      }),
    });
  } catch {
    // Silently fail
  }
}

/**
 * Create a logger with automatic metrics submission
 */
export function createMetricsLogger(context: string, requestId?: string) {
  const logger = createLogger(context, requestId);
  const reqId = logger.getRequestId();

  return {
    ...logger,

    /**
     * Complete the request and submit metrics
     */
    async complete(status: number, metadata?: Record<string, unknown>): Promise<void> {
      logResponse(logger, status);
      await submitMetrics(context, reqId, logger.getExecutionTime(), {
        status,
        ...metadata,
      });
    },

    /**
     * Log and submit an error
     */
    async fail(error: unknown, metadata?: Record<string, unknown>): Promise<void> {
      logger.error('Function failed', error, metadata);
      await submitErrorMetric(context, reqId, error, metadata);
    },
  };
}
