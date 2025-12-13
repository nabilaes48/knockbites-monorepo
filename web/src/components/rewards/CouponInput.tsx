import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { validateCoupon, Coupon } from "@/types/rewards";
import { Tag, Check, X, Loader2 } from "lucide-react";

interface CouponInputProps {
  orderTotal: number;
  onApplyCoupon: (coupon: Coupon) => void;
  onRemoveCoupon: () => void;
  appliedCoupon?: Coupon;
}

export const CouponInput = ({
  orderTotal,
  onApplyCoupon,
  onRemoveCoupon,
  appliedCoupon,
}: CouponInputProps) => {
  const [couponCode, setCouponCode] = useState("");
  const [error, setError] = useState("");
  const [isValidating, setIsValidating] = useState(false);

  const handleApplyCoupon = () => {
    if (!couponCode.trim()) {
      setError("Please enter a coupon code");
      return;
    }

    setIsValidating(true);
    setError("");

    // Simulate validation delay for better UX
    setTimeout(() => {
      const result = validateCoupon(couponCode, orderTotal);

      if (result.valid && result.coupon) {
        onApplyCoupon(result.coupon);
        setCouponCode("");
        setError("");
      } else {
        setError(result.error || "Invalid coupon");
      }

      setIsValidating(false);
    }, 300);
  };

  const handleRemoveCoupon = () => {
    onRemoveCoupon();
    setCouponCode("");
    setError("");
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === "Enter") {
      handleApplyCoupon();
    }
  };

  if (appliedCoupon) {
    return (
      <div className="space-y-2">
        <div className="flex items-center gap-2 p-3 bg-green-50 dark:bg-green-950/20 border border-green-200 dark:border-green-900 rounded-lg">
          <Check className="h-4 w-4 text-green-600 dark:text-green-400 flex-shrink-0" />
          <div className="flex-1 min-w-0">
            <p className="text-sm font-medium text-green-900 dark:text-green-100">
              Coupon Applied: {appliedCoupon.code}
            </p>
            <p className="text-xs text-green-700 dark:text-green-300">
              {appliedCoupon.description}
            </p>
          </div>
          <Button
            variant="ghost"
            size="sm"
            onClick={handleRemoveCoupon}
            className="text-green-700 hover:text-green-900 dark:text-green-300 dark:hover:text-green-100 flex-shrink-0"
          >
            <X className="h-4 w-4" />
          </Button>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-2">
      <div className="flex gap-2">
        <div className="relative flex-1">
          <Tag className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <Input
            type="text"
            placeholder="Enter coupon code"
            value={couponCode}
            onChange={(e) => {
              setCouponCode(e.target.value.toUpperCase());
              setError("");
            }}
            onKeyPress={handleKeyPress}
            className="pl-9"
            disabled={isValidating}
          />
        </div>
        <Button
          onClick={handleApplyCoupon}
          disabled={!couponCode.trim() || isValidating}
          className="px-6"
        >
          {isValidating ? (
            <>
              <Loader2 className="h-4 w-4 mr-2 animate-spin" />
              Applying...
            </>
          ) : (
            "Apply"
          )}
        </Button>
      </div>

      {error && (
        <div className="flex items-center gap-2 text-sm text-red-600 dark:text-red-400">
          <X className="h-4 w-4" />
          {error}
        </div>
      )}

      {/* Coupon system will be implemented in Phase 2 */}
    </div>
  );
};
