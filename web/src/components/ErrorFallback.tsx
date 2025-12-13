import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { AlertCircle, RefreshCw } from "lucide-react";

interface ErrorFallbackProps {
  error?: Error;
  resetError?: () => void;
  title?: string;
  message?: string;
}

export const ErrorFallback = ({
  error,
  resetError,
  title = "Something went wrong",
  message = "We're having trouble loading this content. Please try again.",
}: ErrorFallbackProps) => {
  return (
    <Card className="max-w-md mx-auto my-8">
      <CardHeader className="text-center">
        <div className="inline-flex items-center justify-center w-12 h-12 bg-destructive/10 rounded-full mx-auto mb-3">
          <AlertCircle className="h-6 w-6 text-destructive" />
        </div>
        <CardTitle className="text-lg">{title}</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4 text-center">
        <p className="text-sm text-muted-foreground">{message}</p>

        {import.meta.env.DEV && error && (
          <details className="text-left bg-muted p-3 rounded text-xs">
            <summary className="cursor-pointer font-semibold">Error Details</summary>
            <pre className="mt-2 overflow-x-auto whitespace-pre-wrap">
              {error.toString()}
            </pre>
          </details>
        )}

        {resetError && (
          <Button onClick={resetError} variant="default" size="sm" className="gap-2">
            <RefreshCw className="h-4 w-4" />
            Try Again
          </Button>
        )}
      </CardContent>
    </Card>
  );
};

// Simplified error fallback for smaller components
export const SimpleErrorFallback = ({ resetError }: { resetError?: () => void }) => {
  return (
    <div className="flex flex-col items-center justify-center p-8 text-center">
      <AlertCircle className="h-12 w-12 text-destructive mb-4" />
      <p className="text-sm text-muted-foreground mb-4">
        Failed to load this content
      </p>
      {resetError && (
        <Button onClick={resetError} variant="outline" size="sm">
          Retry
        </Button>
      )}
    </div>
  );
};
