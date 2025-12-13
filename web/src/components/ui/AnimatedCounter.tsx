import { useEffect, useRef, useState } from "react";
import { cn } from "@/lib/utils";

export interface AnimatedCounterProps {
  value: number;
  duration?: number;
  prefix?: string;
  suffix?: string;
  decimals?: number;
  className?: string;
  valueClassName?: string;
}

export function AnimatedCounter({
  value,
  duration = 1000,
  prefix = "",
  suffix = "",
  decimals = 0,
  className,
  valueClassName,
}: AnimatedCounterProps) {
  const [displayValue, setDisplayValue] = useState(0);
  const previousValue = useRef(0);
  const animationRef = useRef<number>();

  useEffect(() => {
    const startValue = previousValue.current;
    const endValue = value;
    const startTime = performance.now();

    const animate = (currentTime: number) => {
      const elapsed = currentTime - startTime;
      const progress = Math.min(elapsed / duration, 1);

      // Easing function (ease-out-cubic)
      const easeOut = 1 - Math.pow(1 - progress, 3);

      const currentValue = startValue + (endValue - startValue) * easeOut;
      setDisplayValue(currentValue);

      if (progress < 1) {
        animationRef.current = requestAnimationFrame(animate);
      } else {
        previousValue.current = endValue;
      }
    };

    animationRef.current = requestAnimationFrame(animate);

    return () => {
      if (animationRef.current) {
        cancelAnimationFrame(animationRef.current);
      }
    };
  }, [value, duration]);

  const formattedValue = displayValue.toFixed(decimals);

  // Format with thousand separators
  const formatWithSeparators = (num: string) => {
    const parts = num.split(".");
    parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    return parts.join(".");
  };

  return (
    <span className={cn("tabular-nums", className)}>
      {prefix}
      <span
        className={cn(
          "inline-block",
          // Light mode
          "text-foreground",
          // Dark mode - subtle glow on value change
          "dark:text-foreground",
          valueClassName
        )}
      >
        {formatWithSeparators(formattedValue)}
      </span>
      {suffix}
    </span>
  );
}

// Currency variant
export function AnimatedCurrency({
  value,
  duration = 1000,
  className,
}: {
  value: number;
  duration?: number;
  className?: string;
}) {
  return (
    <AnimatedCounter
      value={value}
      duration={duration}
      prefix="$"
      decimals={2}
      className={className}
    />
  );
}

// Percentage variant
export function AnimatedPercentage({
  value,
  duration = 1000,
  className,
}: {
  value: number;
  duration?: number;
  className?: string;
}) {
  return (
    <AnimatedCounter
      value={value}
      duration={duration}
      suffix="%"
      decimals={1}
      className={className}
    />
  );
}
