import { cn } from "@/lib/utils";
import { forwardRef, HTMLAttributes } from "react";

export interface GlassCardProps extends HTMLAttributes<HTMLDivElement> {
  glowColor?: "primary" | "purple" | "accent" | "cyan" | "orange" | "pink" | "none";
  gradient?: "blue" | "purple" | "green" | "orange" | "pink" | "cyan" | "rainbow" | "none";
  hoverable?: boolean;
  animated?: boolean;
  variant?: "default" | "elevated" | "outline" | "solid";
  intensity?: "subtle" | "medium" | "strong";
}

const GlassCard = forwardRef<HTMLDivElement, GlassCardProps>(
  (
    {
      className,
      children,
      glowColor = "none",
      gradient = "none",
      hoverable = false,
      animated = false,
      variant = "default",
      intensity = "medium",
      ...props
    },
    ref
  ) => {
    const glowClasses = {
      primary: "shadow-[0_0_25px_rgba(0,122,255,0.15)] dark:shadow-[0_0_30px_rgba(0,255,255,0.2)]",
      purple: "shadow-[0_0_25px_rgba(175,82,222,0.15)] dark:shadow-[0_0_30px_rgba(168,85,247,0.25)]",
      accent: "shadow-[0_0_25px_rgba(52,199,89,0.15)] dark:shadow-[0_0_30px_rgba(0,255,136,0.2)]",
      cyan: "shadow-[0_0_25px_rgba(50,173,230,0.15)] dark:shadow-[0_0_30px_rgba(0,255,255,0.25)]",
      orange: "shadow-[0_0_25px_rgba(255,149,0,0.15)] dark:shadow-[0_0_30px_rgba(255,136,0,0.25)]",
      pink: "shadow-[0_0_25px_rgba(255,45,85,0.15)] dark:shadow-[0_0_30px_rgba(255,0,128,0.25)]",
      none: "",
    };

    const gradientClasses = {
      blue: "bg-gradient-to-br from-ios-blue/5 via-transparent to-ios-teal/5 dark:from-neon-cyan/10 dark:via-transparent dark:to-neon-blue/10",
      purple: "bg-gradient-to-br from-ios-purple/5 via-transparent to-ios-pink/5 dark:from-neon-purple/10 dark:via-transparent dark:to-neon-pink/10",
      green: "bg-gradient-to-br from-ios-green/5 via-transparent to-ios-teal/5 dark:from-neon-green/10 dark:via-transparent dark:to-neon-cyan/10",
      orange: "bg-gradient-to-br from-ios-orange/5 via-transparent to-ios-yellow/5 dark:from-neon-orange/10 dark:via-transparent dark:to-amber-500/10",
      pink: "bg-gradient-to-br from-ios-pink/5 via-transparent to-ios-purple/5 dark:from-neon-pink/10 dark:via-transparent dark:to-neon-purple/10",
      cyan: "bg-gradient-to-br from-ios-teal/5 via-transparent to-ios-blue/5 dark:from-neon-cyan/10 dark:via-transparent dark:to-neon-blue/10",
      rainbow: "bg-gradient-to-br from-ios-purple/5 via-ios-pink/5 to-ios-orange/5 dark:from-neon-purple/10 dark:via-neon-pink/10 dark:to-neon-orange/10",
      none: "",
    };

    const intensityBorder = {
      subtle: "border-gray-200/50 dark:border-white/5",
      medium: "border-gray-200/80 dark:border-white/10",
      strong: "border-gray-300 dark:border-white/20",
    };

    return (
      <div
        ref={ref}
        className={cn(
          // Base styles
          "relative rounded-2xl overflow-hidden",
          "transition-all duration-300 ease-out",

          // Light mode - Clean Apple style with soft shadow
          "bg-white/80 backdrop-blur-sm",
          "shadow-[0_2px_15px_-3px_rgba(0,0,0,0.07),0_10px_20px_-2px_rgba(0,0,0,0.04)]",

          // Dark mode - Glassmorphism with gradient
          "dark:bg-gray-900/60 dark:backdrop-blur-xl",

          // Border based on intensity
          "border",
          intensityBorder[intensity],

          // Variant styles
          variant === "elevated" && [
            "shadow-[0_4px_25px_-5px_rgba(0,0,0,0.1),0_15px_30px_-5px_rgba(0,0,0,0.08)]",
            "dark:bg-gray-900/70",
            "dark:shadow-[0_4px_30px_rgba(0,0,0,0.3)]",
          ],
          variant === "outline" && [
            "bg-transparent shadow-none backdrop-blur-none",
            "border-2",
            "dark:bg-transparent",
          ],
          variant === "solid" && [
            "bg-white dark:bg-gray-900",
            "backdrop-blur-none",
          ],

          // Hoverable
          hoverable && [
            "cursor-pointer",
            "hover:shadow-[0_8px_30px_-5px_rgba(0,0,0,0.12),0_20px_40px_-10px_rgba(0,0,0,0.1)]",
            "hover:-translate-y-1 hover:scale-[1.01]",
            "dark:hover:border-white/20",
            "dark:hover:shadow-[0_8px_40px_rgba(0,0,0,0.4)]",
          ],

          // Glow effect
          glowClasses[glowColor],

          // Animation
          animated && "animate-fade-in",

          className
        )}
        {...props}
      >
        {/* Gradient overlay */}
        {gradient !== "none" && (
          <div
            className={cn(
              "absolute inset-0 rounded-2xl pointer-events-none",
              gradientClasses[gradient]
            )}
          />
        )}

        {/* Subtle inner highlight for depth */}
        <div
          className={cn(
            "absolute inset-0 rounded-2xl pointer-events-none",
            "bg-gradient-to-b from-white/50 via-transparent to-transparent",
            "dark:from-white/5 dark:via-transparent dark:to-transparent",
            "opacity-60"
          )}
        />

        {/* Animated border glow for dark mode */}
        {glowColor !== "none" && (
          <div
            className={cn(
              "absolute inset-0 rounded-2xl pointer-events-none opacity-0 dark:opacity-100",
              "bg-gradient-to-r",
              glowColor === "primary" && "from-neon-cyan/20 via-neon-blue/20 to-neon-cyan/20",
              glowColor === "purple" && "from-neon-purple/20 via-neon-pink/20 to-neon-purple/20",
              glowColor === "accent" && "from-neon-green/20 via-neon-cyan/20 to-neon-green/20",
              glowColor === "cyan" && "from-neon-cyan/20 via-neon-blue/20 to-neon-cyan/20",
              glowColor === "orange" && "from-neon-orange/20 via-amber-500/20 to-neon-orange/20",
              glowColor === "pink" && "from-neon-pink/20 via-neon-purple/20 to-neon-pink/20",
              )}
            style={{ filter: "blur(20px)", transform: "scale(0.95)" }}
          />
        )}

        {/* Content */}
        <div className="relative z-10 h-full">{children}</div>
      </div>
    );
  }
);

GlassCard.displayName = "GlassCard";

export { GlassCard };
