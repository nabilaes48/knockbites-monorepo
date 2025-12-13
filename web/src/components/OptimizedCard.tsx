import { memo } from "react";
import { Card } from "@/components/ui/card";

// Memoized card component to prevent unnecessary re-renders
export const OptimizedCard = memo(Card);
OptimizedCard.displayName = "OptimizedCard";
