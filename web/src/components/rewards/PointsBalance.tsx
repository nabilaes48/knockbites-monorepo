import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { TierBadge } from "./TierBadge";
import { UserRewards, POINTS_TO_DOLLAR } from "@/types/rewards";
import { Coins, TrendingUp } from "lucide-react";

interface PointsBalanceProps {
  rewards: UserRewards;
}

export const PointsBalance = ({ rewards }: PointsBalanceProps) => {
  const pointsValue = rewards.points * POINTS_TO_DOLLAR;

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center justify-between">
          <span>Points Balance</span>
          <TierBadge tier={rewards.tier} />
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {/* Current Points */}
          <div className="flex items-center justify-between p-4 bg-primary/5 rounded-lg">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-primary/10 rounded-full">
                <Coins className="h-5 w-5 text-primary" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Available Points</p>
                <p className="text-2xl font-bold">{rewards.points.toLocaleString()}</p>
              </div>
            </div>
            <div className="text-right">
              <p className="text-sm text-muted-foreground">Cash Value</p>
              <p className="text-xl font-semibold text-primary">
                ${pointsValue.toFixed(2)}
              </p>
            </div>
          </div>

          {/* Lifetime Points */}
          <div className="flex items-center justify-between p-4 border rounded-lg">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-secondary rounded-full">
                <TrendingUp className="h-5 w-5 text-secondary-foreground" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Lifetime Points</p>
                <p className="text-xl font-bold">{rewards.lifetimePoints.toLocaleString()}</p>
              </div>
            </div>
          </div>

          {/* Points Info */}
          <div className="pt-2 space-y-1 text-sm text-muted-foreground">
            <p>• Earn 1 point per $1 spent</p>
            <p>• 100 points = $1 discount</p>
            <p>• Points never expire</p>
          </div>
        </div>
      </CardContent>
    </Card>
  );
};
