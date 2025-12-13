"use client";

import { useTheme } from "next-themes";
import { useEffect, useState } from "react";
import { cn } from "@/lib/utils";

export function ThemeToggle() {
  const { theme, setTheme, resolvedTheme } = useTheme();
  const [mounted, setMounted] = useState(false);

  // Avoid hydration mismatch
  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) {
    return (
      <button
        className="relative h-9 w-9 rounded-full bg-secondary flex items-center justify-center"
        aria-label="Toggle theme"
      >
        <div className="h-5 w-5 rounded-full bg-muted animate-pulse" />
      </button>
    );
  }

  const isDark = resolvedTheme === "dark";

  const toggleTheme = () => {
    // Add transitioning class for smooth theme switch
    document.documentElement.classList.add("transitioning");
    setTheme(isDark ? "light" : "dark");

    // Remove transitioning class after animation completes
    setTimeout(() => {
      document.documentElement.classList.remove("transitioning");
    }, 300);
  };

  return (
    <button
      onClick={toggleTheme}
      className={cn(
        "relative h-9 w-9 rounded-full flex items-center justify-center",
        "transition-all duration-300 ease-smooth",
        // Light mode
        "bg-secondary hover:bg-secondary/80",
        // Dark mode - glassmorphism with glow
        "dark:bg-white/5 dark:hover:bg-white/10",
        "dark:border dark:border-primary/20 dark:hover:border-primary/40",
        "dark:shadow-glow-subtle dark:hover:shadow-glow-primary",
        "focus:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
      )}
      aria-label={`Switch to ${isDark ? "light" : "dark"} mode`}
    >
      {/* Sun icon - shown in dark mode */}
      <svg
        className={cn(
          "absolute h-5 w-5 transition-all duration-300",
          isDark
            ? "rotate-0 scale-100 text-primary"
            : "rotate-90 scale-0 text-foreground"
        )}
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
        strokeWidth={2}
      >
        <circle cx="12" cy="12" r="4" />
        <path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M6.34 17.66l-1.41 1.41M19.07 4.93l-1.41 1.41" />
      </svg>

      {/* Moon icon - shown in light mode */}
      <svg
        className={cn(
          "absolute h-5 w-5 transition-all duration-300",
          isDark
            ? "-rotate-90 scale-0 text-foreground"
            : "rotate-0 scale-100 text-foreground"
        )}
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
        strokeWidth={2}
      >
        <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" />
      </svg>
    </button>
  );
}
