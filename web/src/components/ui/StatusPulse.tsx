import { cn } from "@/lib/utils";

export type StatusPulseVariant =
  | "online"
  | "offline"
  | "busy"
  | "away"
  | "pending"
  | "success"
  | "warning"
  | "error";

export interface StatusPulseProps {
  variant?: StatusPulseVariant;
  size?: "sm" | "md" | "lg";
  animate?: boolean;
  className?: string;
}

const variantColors: Record<StatusPulseVariant, { dot: string; ring: string; glow: string }> = {
  online: {
    dot: "bg-accent dark:bg-neon-green",
    ring: "bg-accent/30 dark:bg-neon-green/30",
    glow: "dark:shadow-[0_0_8px_hsla(142,76%,50%,0.6)]",
  },
  offline: {
    dot: "bg-muted-foreground/50 dark:bg-muted-foreground/30",
    ring: "bg-muted-foreground/20 dark:bg-muted-foreground/10",
    glow: "",
  },
  busy: {
    dot: "bg-destructive dark:bg-neon-pink",
    ring: "bg-destructive/30 dark:bg-neon-pink/30",
    glow: "dark:shadow-[0_0_8px_hsla(330,100%,65%,0.6)]",
  },
  away: {
    dot: "bg-ios-yellow dark:bg-neon-orange",
    ring: "bg-ios-yellow/30 dark:bg-neon-orange/30",
    glow: "dark:shadow-[0_0_8px_hsla(24,100%,55%,0.6)]",
  },
  pending: {
    dot: "bg-ios-orange dark:bg-neon-orange",
    ring: "bg-ios-orange/30 dark:bg-neon-orange/30",
    glow: "dark:shadow-[0_0_8px_hsla(24,100%,55%,0.6)]",
  },
  success: {
    dot: "bg-accent dark:bg-neon-green",
    ring: "bg-accent/30 dark:bg-neon-green/30",
    glow: "dark:shadow-[0_0_8px_hsla(142,76%,50%,0.6)]",
  },
  warning: {
    dot: "bg-ios-yellow dark:bg-neon-orange",
    ring: "bg-ios-yellow/30 dark:bg-neon-orange/30",
    glow: "dark:shadow-[0_0_8px_hsla(24,100%,55%,0.6)]",
  },
  error: {
    dot: "bg-destructive dark:bg-destructive",
    ring: "bg-destructive/30 dark:bg-destructive/30",
    glow: "dark:shadow-[0_0_8px_hsla(0,84%,60%,0.6)]",
  },
};

const sizeStyles = {
  sm: { container: "w-2 h-2", ring: "w-3 h-3" },
  md: { container: "w-2.5 h-2.5", ring: "w-4 h-4" },
  lg: { container: "w-3 h-3", ring: "w-5 h-5" },
};

export function StatusPulse({
  variant = "online",
  size = "md",
  animate = true,
  className,
}: StatusPulseProps) {
  const colors = variantColors[variant];
  const sizes = sizeStyles[size];

  return (
    <span
      className={cn(
        "relative inline-flex items-center justify-center",
        sizes.ring,
        className
      )}
    >
      {/* Pulse ring (only for active/animating states) */}
      {animate && variant !== "offline" && (
        <span
          className={cn(
            "absolute rounded-full animate-ping",
            sizes.ring,
            colors.ring
          )}
        />
      )}

      {/* Main dot */}
      <span
        className={cn(
          "relative rounded-full",
          sizes.container,
          colors.dot,
          colors.glow,
          "transition-colors duration-200"
        )}
      />
    </span>
  );
}

// Convenient wrapper for showing status with label
export function StatusIndicator({
  variant = "online",
  label,
  size = "md",
  animate = true,
  className,
}: StatusPulseProps & { label?: string }) {
  return (
    <span className={cn("inline-flex items-center gap-2", className)}>
      <StatusPulse variant={variant} size={size} animate={animate} />
      {label && (
        <span className="text-sm text-muted-foreground capitalize">
          {label || variant}
        </span>
      )}
    </span>
  );
}
