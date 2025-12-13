/**
 * Runtime Metrics Collector for KnockBites
 *
 * Captures and submits runtime metrics to Supabase for monitoring,
 * alerting, and system health analysis.
 */

import { supabase } from './supabase';

// Session ID persists across page navigation
const SESSION_ID = `session_${Date.now()}_${Math.random().toString(36).slice(2, 11)}`;

// Metrics buffer for batching
interface MetricEntry {
  event_type: string;
  event_data: Record<string, unknown>;
  timestamp: string;
}

const metricsBuffer: MetricEntry[] = [];
let flushTimeout: ReturnType<typeof setTimeout> | null = null;
const FLUSH_INTERVAL = 5000; // 5 seconds
const MAX_BUFFER_SIZE = 20;

/**
 * Get current user ID if authenticated
 */
async function getCurrentUserId(): Promise<string | null> {
  try {
    const { data: { user } } = await supabase.auth.getUser();
    return user?.id || null;
  } catch {
    return null;
  }
}

/**
 * Queue a metric for submission
 */
function queueMetric(eventType: string, eventData: Record<string, unknown>): void {
  metricsBuffer.push({
    event_type: eventType,
    event_data: {
      ...eventData,
      url: typeof window !== 'undefined' ? window.location.pathname : undefined,
      userAgent: typeof navigator !== 'undefined' ? navigator.userAgent : undefined,
    },
    timestamp: new Date().toISOString(),
  });

  // Flush if buffer is full
  if (metricsBuffer.length >= MAX_BUFFER_SIZE) {
    flushMetrics();
  } else if (!flushTimeout) {
    // Schedule flush
    flushTimeout = setTimeout(flushMetrics, FLUSH_INTERVAL);
  }
}

/**
 * Flush metrics buffer to database
 */
async function flushMetrics(): Promise<void> {
  if (flushTimeout) {
    clearTimeout(flushTimeout);
    flushTimeout = null;
  }

  if (metricsBuffer.length === 0) return;

  const metricsToSend = [...metricsBuffer];
  metricsBuffer.length = 0;

  try {
    const userId = await getCurrentUserId();

    const records = metricsToSend.map((metric) => ({
      user_id: userId,
      session_id: SESSION_ID,
      event_type: metric.event_type,
      event_data: metric.event_data,
      created_at: metric.timestamp,
    }));

    const { error } = await supabase
      .from('runtime_metrics')
      .insert(records);

    if (error) {
      // Re-queue on failure (but don't infinitely retry)
      if (metricsBuffer.length < MAX_BUFFER_SIZE * 2) {
        metricsBuffer.push(...metricsToSend);
      }
      console.warn('[Metrics] Failed to flush metrics:', error.message);
    }
  } catch (err) {
    console.warn('[Metrics] Error flushing metrics:', err);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PUBLIC API
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Record a page view event
 */
export function recordPageView(page: string, metadata?: Record<string, unknown>): void {
  queueMetric('page_view', {
    page,
    referrer: typeof document !== 'undefined' ? document.referrer : undefined,
    ...metadata,
  });
}

/**
 * Record API latency
 */
export function recordAPILatency(
  endpoint: string,
  latencyMs: number,
  status?: number,
  metadata?: Record<string, unknown>
): void {
  queueMetric('api_latency', {
    endpoint,
    latency_ms: latencyMs,
    status,
    ...metadata,
  });
}

/**
 * Record an error event
 */
export function recordError(
  errorType: string,
  message: string,
  metadata?: Record<string, unknown>
): void {
  queueMetric('error', {
    error_type: errorType,
    message,
    stack: metadata?.stack,
    ...metadata,
  });
}

/**
 * Record a user action
 */
export function recordUserAction(
  actionName: string,
  metadata?: Record<string, unknown>
): void {
  queueMetric('user_action', {
    action: actionName,
    ...metadata,
  });
}

/**
 * Record order-related events
 */
export function recordOrderEvent(
  eventName: string,
  orderId: number | string,
  metadata?: Record<string, unknown>
): void {
  queueMetric('order_event', {
    event: eventName,
    order_id: orderId,
    ...metadata,
  });
}

/**
 * Record performance metrics (Web Vitals)
 */
export function recordPerformance(
  metricName: string,
  value: number,
  metadata?: Record<string, unknown>
): void {
  queueMetric('performance', {
    metric: metricName,
    value,
    ...metadata,
  });
}

/**
 * Record custom metric
 */
export function recordCustomMetric(
  eventType: string,
  data: Record<string, unknown>
): void {
  queueMetric(eventType, data);
}

/**
 * Force flush all pending metrics (e.g., on page unload)
 */
export function forceFlush(): void {
  flushMetrics();
}

/**
 * Get current session ID
 */
export function getSessionId(): string {
  return SESSION_ID;
}

// ─────────────────────────────────────────────────────────────────────────────
// AUTO-INSTRUMENTATION
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Initialize metrics collection with auto-instrumentation
 */
export function initMetrics(): void {
  if (typeof window === 'undefined') return;

  // Record page view on load
  recordPageView(window.location.pathname);

  // Track route changes (for SPAs)
  const originalPushState = history.pushState;
  history.pushState = function (...args) {
    originalPushState.apply(this, args);
    recordPageView(window.location.pathname);
  };

  const originalReplaceState = history.replaceState;
  history.replaceState = function (...args) {
    originalReplaceState.apply(this, args);
    recordPageView(window.location.pathname);
  };

  window.addEventListener('popstate', () => {
    recordPageView(window.location.pathname);
  });

  // Track unhandled errors
  window.addEventListener('error', (event) => {
    recordError('unhandled_error', event.message, {
      filename: event.filename,
      lineno: event.lineno,
      colno: event.colno,
    });
  });

  // Track unhandled promise rejections
  window.addEventListener('unhandledrejection', (event) => {
    recordError('unhandled_rejection', String(event.reason), {
      reason: event.reason?.toString(),
    });
  });

  // Flush on page unload
  window.addEventListener('beforeunload', () => {
    forceFlush();
  });

  // Track visibility changes
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'hidden') {
      forceFlush();
    }
  });

  // Track Web Vitals if available
  if ('PerformanceObserver' in window) {
    try {
      // Largest Contentful Paint
      const lcpObserver = new PerformanceObserver((list) => {
        const entries = list.getEntries();
        const lastEntry = entries[entries.length - 1];
        if (lastEntry) {
          recordPerformance('LCP', lastEntry.startTime);
        }
      });
      lcpObserver.observe({ type: 'largest-contentful-paint', buffered: true });

      // First Input Delay
      const fidObserver = new PerformanceObserver((list) => {
        const entries = list.getEntries();
        entries.forEach((entry) => {
          if ('processingStart' in entry) {
            const fidEntry = entry as PerformanceEventTiming;
            recordPerformance('FID', fidEntry.processingStart - fidEntry.startTime);
          }
        });
      });
      fidObserver.observe({ type: 'first-input', buffered: true });

      // Cumulative Layout Shift
      let clsValue = 0;
      const clsObserver = new PerformanceObserver((list) => {
        for (const entry of list.getEntries()) {
          if ('hadRecentInput' in entry && !(entry as LayoutShift).hadRecentInput) {
            clsValue += (entry as LayoutShift).value;
          }
        }
        recordPerformance('CLS', clsValue);
      });
      clsObserver.observe({ type: 'layout-shift', buffered: true });
    } catch {
      // Performance observers not supported
    }
  }
}

// TypeScript interfaces for Performance entries
interface PerformanceEventTiming extends PerformanceEntry {
  processingStart: number;
}

interface LayoutShift extends PerformanceEntry {
  hadRecentInput: boolean;
  value: number;
}

// Default export for convenience
const metrics = {
  recordPageView,
  recordAPILatency,
  recordError,
  recordUserAction,
  recordOrderEvent,
  recordPerformance,
  recordCustomMetric,
  forceFlush,
  getSessionId,
  initMetrics,
};

export default metrics;
