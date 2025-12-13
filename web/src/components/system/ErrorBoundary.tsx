import React, { Component, ErrorInfo, ReactNode } from 'react';
import { AlertTriangle, RefreshCw, Home, WifiOff } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { createLogger } from '@/lib/logger';

const log = createLogger('ErrorBoundary');

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
  onError?: (error: Error, errorInfo: ErrorInfo) => void;
}

interface State {
  hasError: boolean;
  error: Error | null;
  errorInfo: ErrorInfo | null;
  isOffline: boolean;
}

/**
 * Global Error Boundary
 *
 * Catches React errors and displays friendly recovery UI
 */
class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = {
      hasError: false,
      error: null,
      errorInfo: null,
      isOffline: !navigator.onLine,
    };
  }

  static getDerivedStateFromError(error: Error): Partial<State> {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    log.error('React error caught', error, {
      componentStack: errorInfo.componentStack,
    });

    this.setState({ errorInfo });
    this.props.onError?.(error, errorInfo);
  }

  componentDidMount() {
    window.addEventListener('online', this.handleOnline);
    window.addEventListener('offline', this.handleOffline);
  }

  componentWillUnmount() {
    window.removeEventListener('online', this.handleOnline);
    window.removeEventListener('offline', this.handleOffline);
  }

  handleOnline = () => {
    this.setState({ isOffline: false });
    if (this.state.hasError) {
      this.handleRetry();
    }
  };

  handleOffline = () => {
    this.setState({ isOffline: true });
  };

  handleRetry = () => {
    this.setState({
      hasError: false,
      error: null,
      errorInfo: null,
    });
  };

  handleGoHome = () => {
    window.location.href = '/';
  };

  render() {
    const { hasError, error, isOffline } = this.state;
    const { children, fallback } = this.props;

    // Show offline screen if network is down
    if (isOffline) {
      return <OfflineScreen onRetry={this.handleRetry} />;
    }

    // Show error screen if there's an error
    if (hasError) {
      if (fallback) {
        return fallback;
      }

      return (
        <ErrorScreen
          error={error}
          onRetry={this.handleRetry}
          onGoHome={this.handleGoHome}
        />
      );
    }

    return children;
  }
}

/**
 * Main Error Screen
 */
function ErrorScreen({
  error,
  onRetry,
  onGoHome,
}: {
  error: Error | null;
  onRetry: () => void;
  onGoHome: () => void;
}) {
  const isDev = import.meta.env.DEV;

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
      <Card className="max-w-md w-full">
        <CardHeader className="text-center">
          <div className="mx-auto mb-4 w-12 h-12 rounded-full bg-red-100 flex items-center justify-center">
            <AlertTriangle className="w-6 h-6 text-red-600" />
          </div>
          <CardTitle className="text-xl">Something went wrong</CardTitle>
          <CardDescription>
            We encountered an unexpected error. Please try again.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {isDev && error && (
            <div className="p-3 bg-gray-100 rounded-md text-xs font-mono overflow-auto max-h-32">
              <p className="font-semibold text-red-600">{error.name}</p>
              <p className="text-gray-600">{error.message}</p>
            </div>
          )}

          <div className="flex flex-col gap-2">
            <Button onClick={onRetry} className="w-full">
              <RefreshCw className="w-4 h-4 mr-2" />
              Try Again
            </Button>
            <Button variant="outline" onClick={onGoHome} className="w-full">
              <Home className="w-4 h-4 mr-2" />
              Go to Home
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

/**
 * Offline Screen
 */
function OfflineScreen({ onRetry }: { onRetry: () => void }) {
  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
      <Card className="max-w-md w-full">
        <CardHeader className="text-center">
          <div className="mx-auto mb-4 w-12 h-12 rounded-full bg-yellow-100 flex items-center justify-center">
            <WifiOff className="w-6 h-6 text-yellow-600" />
          </div>
          <CardTitle className="text-xl">You're offline</CardTitle>
          <CardDescription>
            Please check your internet connection and try again.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Button onClick={onRetry} className="w-full">
            <RefreshCw className="w-4 h-4 mr-2" />
            Retry Connection
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}

export default ErrorBoundary;

/**
 * Analytics Fallback Component
 * Use when analytics RPC fails
 */
export function AnalyticsFallback({
  onRetry,
  error,
}: {
  onRetry?: () => void;
  error?: Error | null;
}) {
  return (
    <Card className="w-full">
      <CardHeader className="text-center">
        <CardTitle className="text-lg">Unable to load analytics</CardTitle>
        <CardDescription>
          There was a problem loading the analytics data.
        </CardDescription>
      </CardHeader>
      <CardContent className="text-center">
        {error && (
          <p className="text-sm text-red-500 mb-4">{error.message}</p>
        )}
        {onRetry && (
          <Button onClick={onRetry} variant="outline" size="sm">
            <RefreshCw className="w-4 h-4 mr-2" />
            Retry
          </Button>
        )}
      </CardContent>
    </Card>
  );
}

/**
 * Order Tracking Fallback Component
 * Use when order UUID is invalid or not found
 */
export function OrderTrackingFallback({
  orderId,
  onGoHome,
}: {
  orderId?: string;
  onGoHome?: () => void;
}) {
  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
      <Card className="max-w-md w-full">
        <CardHeader className="text-center">
          <CardTitle className="text-xl">Order Not Found</CardTitle>
          <CardDescription>
            We couldn't find an order with that ID.
            {orderId && (
              <span className="block mt-1 font-mono text-xs">{orderId}</span>
            )}
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <p className="text-sm text-gray-500 text-center">
            Please check your order confirmation email for the correct tracking link,
            or contact us for assistance.
          </p>
          {onGoHome && (
            <Button onClick={onGoHome} className="w-full">
              <Home className="w-4 h-4 mr-2" />
              Return to Home
            </Button>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

/**
 * Loading Skeleton for page transitions
 */
export function PageLoadingSkeleton() {
  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center">
      <div className="animate-pulse flex flex-col items-center gap-4">
        <div className="w-12 h-12 bg-gray-200 rounded-full" />
        <div className="w-32 h-4 bg-gray-200 rounded" />
      </div>
    </div>
  );
}
