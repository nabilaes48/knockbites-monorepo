import { useState } from "react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Slider } from "@/components/ui/slider";
import { calculatePointsDiscount, POINTS_TO_DOLLAR } from "@/types/rewards";
import { Coins } from "lucide-react";

interface RedeemModalProps {
  isOpen: boolean;
  onClose: () => void;
  availablePoints: number;
  orderTotal: number;
  onRedeem: (pointsToUse: number) => void;
}

export const RedeemModal = ({
  isOpen,
  onClose,
  availablePoints,
  orderTotal,
  onRedeem,
}: RedeemModalProps) => {
  const minPoints = 100; // Minimum 100 points to redeem
  const maxPoints = Math.min(availablePoints, Math.floor(orderTotal / POINTS_TO_DOLLAR));
  const [pointsToUse, setPointsToUse] = useState(minPoints);

  const discountAmount = calculatePointsDiscount(pointsToUse);
  const newTotal = Math.max(0, orderTotal - discountAmount);

  const handleRedeem = () => {
    if (pointsToUse >= minPoints && pointsToUse <= maxPoints) {
      onRedeem(pointsToUse);
      onClose();
    }
  };

  const canRedeem = availablePoints >= minPoints && maxPoints >= minPoints;

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Coins className="h-5 w-5 text-primary" />
            Redeem Points
          </DialogTitle>
          <DialogDescription>
            Use your points to get a discount on this order
          </DialogDescription>
        </DialogHeader>

        {!canRedeem ? (
          <div className="py-6 text-center">
            <p className="text-muted-foreground">
              {availablePoints < minPoints
                ? `You need at least ${minPoints} points to redeem. You currently have ${availablePoints} points.`
                : "The discount amount would exceed your order total."}
            </p>
          </div>
        ) : (
          <div className="space-y-6 py-4">
            {/* Available Points */}
            <div className="flex items-center justify-between p-3 bg-accent rounded-lg">
              <span className="text-sm font-medium">Available Points</span>
              <span className="text-lg font-bold">{availablePoints.toLocaleString()}</span>
            </div>

            {/* Points Slider */}
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <Label htmlFor="points">Points to Use</Label>
                <span className="text-sm font-medium">{pointsToUse}</span>
              </div>
              <Slider
                id="points"
                min={minPoints}
                max={maxPoints}
                step={50}
                value={[pointsToUse]}
                onValueChange={([value]) => setPointsToUse(value)}
                className="w-full"
              />
              <div className="flex justify-between text-xs text-muted-foreground">
                <span>{minPoints}</span>
                <span>{maxPoints}</span>
              </div>
            </div>

            {/* Manual Input */}
            <div className="space-y-2">
              <Label htmlFor="points-input">Or enter amount</Label>
              <Input
                id="points-input"
                type="number"
                min={minPoints}
                max={maxPoints}
                step={50}
                value={pointsToUse}
                onChange={(e) => {
                  const value = parseInt(e.target.value) || minPoints;
                  setPointsToUse(Math.min(maxPoints, Math.max(minPoints, value)));
                }}
              />
            </div>

            {/* Summary */}
            <div className="space-y-2 p-4 bg-primary/5 rounded-lg border border-primary/20">
              <div className="flex justify-between text-sm">
                <span>Order Total</span>
                <span className="font-medium">${orderTotal.toFixed(2)}</span>
              </div>
              <div className="flex justify-between text-sm text-primary">
                <span>Points Discount</span>
                <span className="font-medium">-${discountAmount.toFixed(2)}</span>
              </div>
              <div className="h-px bg-border my-2" />
              <div className="flex justify-between font-bold">
                <span>New Total</span>
                <span className="text-primary">${newTotal.toFixed(2)}</span>
              </div>
            </div>
          </div>
        )}

        <DialogFooter>
          <Button variant="outline" onClick={onClose}>
            Cancel
          </Button>
          {canRedeem && (
            <Button onClick={handleRedeem} className="gap-2">
              <Coins className="h-4 w-4" />
              Redeem {pointsToUse} Points
            </Button>
          )}
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};
