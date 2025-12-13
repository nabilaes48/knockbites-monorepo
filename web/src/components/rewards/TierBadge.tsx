import { Badge } from "@/components/ui/badge";
import { RewardsTier, TIER_THRESHOLDS } from "@/types/rewards";
import { Award } from "lucide-react";

interface TierBadgeProps {
  tier: RewardsTier;
  showIcon?: boolean;
  size?: "sm" | "md" | "lg";
}

export const TierBadge = ({ tier, showIcon = true, size = "md" }: TierBadgeProps) => {
  const tierInfo = TIER_THRESHOLDS[tier];

  const sizeClasses = {
    sm: "text-xs py-0.5 px-2",
    md: "text-sm py-1 px-3",
    lg: "text-base py-1.5 px-4",
  };

  const iconSizes = {
    sm: "h-3 w-3",
    md: "h-4 w-4",
    lg: "h-5 w-5",
  };

  return (
    <Badge
      variant="secondary"
      className={`${sizeClasses[size]} font-semibold flex items-center gap-1.5`}
      style={{
        backgroundColor: `${tierInfo.color}20`,
        color: tierInfo.color,
        borderColor: `${tierInfo.color}40`,
      }}
    >
      {showIcon && <Award className={iconSizes[size]} />}
      {tierInfo.name} Tier
    </Badge>
  );
};
