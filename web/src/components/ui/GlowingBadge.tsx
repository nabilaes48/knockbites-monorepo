import { cn } from "@/lib/utils";
import { HTMLAttributes, forwardRef } from "react";

export type BadgeVariant =
  | "pending"
  | "preparing"
  | "ready"
  | "completed"
  | "cancelled"
  | "vip"
  | "info"
  | "success"
  | "warning"
  | "danger"
  | "default";

export interface GlowingBadgeProps extends HTMLAttributes<HTMLSpanElement> {
  variant?: BadgeVariant;
  pulse?: boolean;
  size?: "sm" | "md" | "lg";
}

const variantStyles: Record<
  BadgeVariant,
  { light: string; dark: string; glow: string }
> = {
  pending: {
    light: "bg-ios-orange/10 text-ios-orange border-ios-orange/20",
    dark: "bg-neon-orange/10 text-neon-orange border-neon-orange/30",
    glow: "shadow-[0_0_12px_hsla(24,100%,55%,0.4)]",
  },
  preparing: {
    light: "bg-ios-blue/10 text-ios-blue border-ios-blue/20",
    dark: "bg-neon-blue/10 text-neon-blue border-neon-blue/30",
    glow: "shadow-[0_0_12px_hsla(217,91%,60%,0.4)]",
  },
  ready: {
    light: "bg-accent/10 text-accent border-accent/20",
    dark: "bg-neon-green/10 text-neon-green border-neon-green/30",
    glow: "shadow-[0_0_12px_hsla(142,76%,50%,0.4)]",
  },
  completed: {
    light: "bg-muted text-muted-foreground border-border",
    dark: "bg-muted/50 text-muted-foreground border-border/50",
    glow: "",
  },
  cancelled: {
    light: "bg-destructive/10 text-destructive border-destructive/20",
    dark: "bg-destructive/10 text-destructive border-destructive/30",
    glow: "shadow-[0_0_12px_hsla(0,84%,60%,0.3)]",
  },
  vip: {
    light: "bg-ios-purple/10 text-ios-purple border-ios-purple/20",
    dark: "bg-neon-purple/10 text-neon-purple border-neon-purple/30",
    glow: "shadow-[0_0_12px_hsla(265,89%,66%,0.4)]",
  },
  info: {
    light: "bg-primary/10 text-primary border-primary/20",
    dark: "bg-primary/10 text-primary border-primary/30",
    glow: "shadow-[0_0_12px_hsla(187,100%,50%,0.4)]",
  },
  success: {
    light: "bg-accent/10 text-accent border-accent/20",
    dark: "bg-neon-green/10 text-neon-green border-neon-green/30",
    glow: "shadow-[0_0_12px_hsla(142,76%,50%,0.4)]",
  },
  warning: {
    light: "bg-ios-yellow/10 text-ios-yellow border-ios-yellow/20",
    dark: "bg-neon-orange/10 text-neon-orange border-neon-orange/30",
    glow: "shadow-[0_0_12px_hsla(24,100%,55%,0.4)]",
  },
  danger: {
    light: "bg-destructive/10 text-destructive border-destructive/20",
    dark: "bg-neon-pink/10 text-neon-pink border-neon-pink/30",
    glow: "shadow-[0_0_12px_hsla(330,100%,65%,0.4)]",
  },
  default: {
    light: "bg-secondary text-secondary-foreground border-border",
    dark: "bg-secondary/50 text-secondary-foreground border-border/50",
    glow: "",
  },
};

const sizeStyles = {
  sm: "px-2 py-0.5 text-xs",
  md: "px-2.5 py-1 text-xs",
  lg: "px-3 py-1.5 text-sm",
};

const GlowingBadge = forwardRef<HTMLSpanElement, GlowingBadgeProps>(
  ({ className, variant = "default", pulse = false, size = "md", children, ...props }, ref) => {
    // Fallback to default if variant doesn't exist
    const styles = variantStyles[variant] || variantStyles.default;

    return (
      <span
        ref={ref}
        className={cn(
          // Base
          "inline-flex items-center justify-center gap-1.5",
          "font-medium rounded-full border",
          "transition-all duration-200",

          // Size
          sizeStyles[size],

          // Light mode
          styles.light,

          // Dark mode
          `dark:${styles.dark}`,

          // Glow effect (dark mode only)
          styles.glow && `dark:${styles.glow}`,

          // Pulse animation
          pulse && "animate-pulse-glow",

          className
        )}
        {...props}
      >
        {/* Pulse dot for active states */}
        {pulse && (
          <span
            className={cn(
              "w-1.5 h-1.5 rounded-full",
              "animate-pulse",
              variant === "pending" && "bg-ios-orange dark:bg-neon-orange",
              variant === "preparing" && "bg-ios-blue dark:bg-neon-blue",
              variant === "ready" && "bg-accent dark:bg-neon-green",
              variant === "vip" && "bg-ios-purple dark:bg-neon-purple",
              variant === "info" && "bg-primary",
              variant === "success" && "bg-accent dark:bg-neon-green",
              variant === "warning" && "bg-ios-yellow dark:bg-neon-orange",
              variant === "danger" && "bg-destructive dark:bg-neon-pink"
            )}
          />
        )}
        {children}
      </span>
    );
  }
);

GlowingBadge.displayName = "GlowingBadge";

export { GlowingBadge };
