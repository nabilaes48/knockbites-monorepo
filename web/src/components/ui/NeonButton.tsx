import { cn } from "@/lib/utils";
import { ButtonHTMLAttributes, forwardRef } from "react";

export type NeonButtonVariant = "primary" | "secondary" | "success" | "danger" | "ghost" | "outline";
export type NeonButtonSize = "sm" | "md" | "lg" | "icon";

export interface NeonButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: NeonButtonVariant;
  size?: NeonButtonSize;
  glow?: boolean;
  loading?: boolean;
}

const variantStyles: Record<NeonButtonVariant, { base: string; light: string; dark: string }> = {
  primary: {
    base: "text-primary-foreground",
    light: "bg-primary hover:bg-primary/90 active:bg-primary/80",
    dark: "bg-primary hover:bg-primary/90 shadow-glow-primary/50 hover:shadow-glow-primary",
  },
  secondary: {
    base: "text-secondary-foreground",
    light: "bg-secondary hover:bg-secondary/80 active:bg-secondary/70",
    dark: "bg-secondary/80 hover:bg-secondary border border-primary/10 hover:border-primary/20",
  },
  success: {
    base: "text-accent-foreground",
    light: "bg-accent hover:bg-accent/90 active:bg-accent/80",
    dark: "bg-neon-green hover:bg-neon-green/90 shadow-glow-accent/50 hover:shadow-glow-accent",
  },
  danger: {
    base: "text-destructive-foreground",
    light: "bg-destructive hover:bg-destructive/90 active:bg-destructive/80",
    dark: "bg-destructive hover:bg-destructive/90 shadow-[0_0_20px_hsla(0,84%,60%,0.3)] hover:shadow-[0_0_30px_hsla(0,84%,60%,0.5)]",
  },
  ghost: {
    base: "text-foreground",
    light: "bg-transparent hover:bg-secondary active:bg-secondary/80",
    dark: "bg-transparent hover:bg-white/5 active:bg-white/10",
  },
  outline: {
    base: "text-foreground bg-transparent",
    light: "border-2 border-border hover:bg-secondary active:bg-secondary/80",
    dark: "border border-primary/30 hover:border-primary/50 hover:bg-primary/5 hover:shadow-glow-subtle",
  },
};

const sizeStyles: Record<NeonButtonSize, string> = {
  sm: "h-8 px-3 text-xs rounded-lg gap-1.5",
  md: "h-10 px-4 text-sm rounded-xl gap-2",
  lg: "h-12 px-6 text-base rounded-xl gap-2.5",
  icon: "h-10 w-10 rounded-xl",
};

const NeonButton = forwardRef<HTMLButtonElement, NeonButtonProps>(
  (
    {
      className,
      variant = "primary",
      size = "md",
      glow = false,
      loading = false,
      disabled,
      children,
      ...props
    },
    ref
  ) => {
    const styles = variantStyles[variant];

    return (
      <button
        ref={ref}
        disabled={disabled || loading}
        className={cn(
          // Base
          "relative inline-flex items-center justify-center font-medium",
          "transition-all duration-200 ease-smooth",
          "focus:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background",

          // Size
          sizeStyles[size],

          // Variant base
          styles.base,

          // Light mode
          styles.light,

          // Dark mode
          `dark:${styles.dark}`,

          // Extra glow on hover (dark mode)
          glow && "dark:hover:shadow-glow-primary",

          // Disabled state
          (disabled || loading) && "opacity-50 cursor-not-allowed pointer-events-none",

          className
        )}
        {...props}
      >
        {/* Loading spinner */}
        {loading && (
          <svg
            className="absolute h-4 w-4 animate-spin"
            fill="none"
            viewBox="0 0 24 24"
          >
            <circle
              className="opacity-25"
              cx="12"
              cy="12"
              r="10"
              stroke="currentColor"
              strokeWidth="4"
            />
            <path
              className="opacity-75"
              fill="currentColor"
              d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
            />
          </svg>
        )}

        {/* Content */}
        <span className={cn("inline-flex items-center", loading && "invisible")}>{children}</span>
      </button>
    );
  }
);

NeonButton.displayName = "NeonButton";

export { NeonButton };
