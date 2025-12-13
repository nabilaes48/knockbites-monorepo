/**
 * Centralized Logging Utility for KnockBites
 *
 * Provides structured logging with:
 * - Timestamps
 * - Build version
 * - User context when available
 * - Environment-aware output
 */

type LogLevel = 'debug' | 'info' | 'warn' | 'error';

interface LogContext {
  userId?: string;
  component?: string;
  action?: string;
  [key: string]: unknown;
}

interface LogEntry {
  level: LogLevel;
  message: string;
  timestamp: string;
  version: string;
  environment: string;
  context?: LogContext;
  error?: {
    name: string;
    message: string;
    stack?: string;
  };
}

const APP_VERSION = import.meta.env.VITE_APP_VERSION || '0.0.0';
const APP_ENV = import.meta.env.VITE_APP_ENV || 'development';
const IS_DEV = import.meta.env.DEV;

// In-memory buffer for batched logging (future: send to analytics)
const logBuffer: LogEntry[] = [];
const MAX_BUFFER_SIZE = 100;

/**
 * Format and output a log entry
 */
function formatLog(entry: LogEntry): void {
  const prefix = `[${entry.timestamp}] [${entry.level.toUpperCase()}]`;
  const contextStr = entry.context
    ? ` ${JSON.stringify(entry.context)}`
    : '';

  // In development, use console methods for better DevTools experience
  if (IS_DEV) {
    const method = entry.level === 'debug' ? 'log' : entry.level;
    if (entry.error) {
      console[method](`${prefix} ${entry.message}${contextStr}`, entry.error);
    } else {
      console[method](`${prefix} ${entry.message}${contextStr}`);
    }
  } else {
    // In production, output structured JSON for log aggregators
    console.log(JSON.stringify(entry));
  }

  // Add to buffer
  logBuffer.push(entry);
  if (logBuffer.length > MAX_BUFFER_SIZE) {
    logBuffer.shift();
  }
}

/**
 * Create a log entry
 */
function createLogEntry(
  level: LogLevel,
  message: string,
  context?: LogContext,
  error?: Error
): LogEntry {
  const entry: LogEntry = {
    level,
    message,
    timestamp: new Date().toISOString(),
    version: APP_VERSION,
    environment: APP_ENV,
  };

  if (context) {
    entry.context = context;
  }

  if (error) {
    entry.error = {
      name: error.name,
      message: error.message,
      stack: error.stack,
    };
  }

  return entry;
}

/**
 * Logger instance with context binding
 */
class Logger {
  private baseContext: LogContext;

  constructor(context: LogContext = {}) {
    this.baseContext = context;
  }

  /**
   * Create a child logger with additional context
   */
  child(context: LogContext): Logger {
    return new Logger({ ...this.baseContext, ...context });
  }

  /**
   * Set user context (call after authentication)
   */
  setUser(userId: string): void {
    this.baseContext.userId = userId;
  }

  /**
   * Clear user context (call on logout)
   */
  clearUser(): void {
    delete this.baseContext.userId;
  }

  /**
   * Debug level - only in development
   */
  debug(message: string, context?: LogContext): void {
    if (!IS_DEV) return;
    const entry = createLogEntry('debug', message, { ...this.baseContext, ...context });
    formatLog(entry);
  }

  /**
   * Info level - general information
   */
  info(message: string, context?: LogContext): void {
    const entry = createLogEntry('info', message, { ...this.baseContext, ...context });
    formatLog(entry);
  }

  /**
   * Warn level - potential issues
   */
  warn(message: string, context?: LogContext): void {
    const entry = createLogEntry('warn', message, { ...this.baseContext, ...context });
    formatLog(entry);
  }

  /**
   * Error level - errors and exceptions
   */
  error(message: string, error?: Error | unknown, context?: LogContext): void {
    const err = error instanceof Error ? error : new Error(String(error));
    const entry = createLogEntry('error', message, { ...this.baseContext, ...context }, err);
    formatLog(entry);
  }

  /**
   * Time an operation
   */
  time(label: string): () => void {
    const start = performance.now();
    return () => {
      const duration = Math.round(performance.now() - start);
      this.debug(`${label} completed`, { durationMs: duration });
    };
  }

  /**
   * Get buffered logs (for debugging/export)
   */
  getBuffer(): LogEntry[] {
    return [...logBuffer];
  }

  /**
   * Clear the log buffer
   */
  clearBuffer(): void {
    logBuffer.length = 0;
  }
}

// Default logger instance
const logger = new Logger();

// Named exports for convenience
export const debug = logger.debug.bind(logger);
export const info = logger.info.bind(logger);
export const warn = logger.warn.bind(logger);
export const error = logger.error.bind(logger);

// Export Logger class and default instance
export { Logger };
export default logger;

/**
 * Create a component-scoped logger
 *
 * @example
 * const log = createLogger('OrderCheckout');
 * log.info('Order submitted', { orderId: '123' });
 */
export function createLogger(component: string): Logger {
  return new Logger({ component });
}

/**
 * Log API call with timing
 *
 * @example
 * const result = await logApiCall('fetchOrders', () => supabase.from('orders').select());
 */
export async function logApiCall<T>(
  operation: string,
  fn: () => Promise<T>,
  context?: LogContext
): Promise<T> {
  const start = performance.now();
  const log = createLogger('API');

  try {
    log.debug(`${operation} started`, context);
    const result = await fn();
    const duration = Math.round(performance.now() - start);
    log.info(`${operation} completed`, { ...context, durationMs: duration });
    return result;
  } catch (err) {
    const duration = Math.round(performance.now() - start);
    log.error(`${operation} failed`, err, { ...context, durationMs: duration });
    throw err;
  }
}
