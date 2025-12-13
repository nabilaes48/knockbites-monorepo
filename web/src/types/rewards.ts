export interface UserRewards {
  userId: string;
  points: number;
  lifetimePoints: number;
  tier: RewardsTier;
  transactions: RewardsTransaction[];
}

export type RewardsTier = "bronze" | "silver" | "gold";

export interface RewardsTransaction {
  id: string;
  userId: string;
  orderId?: string;
  points: number;
  type: "earned" | "redeemed" | "expired" | "bonus" | "referral";
  description: string;
  createdAt: string;
}

export interface Coupon {
  id: string;
  code: string;
  discountType: "percentage" | "fixed" | "bogo" | "free_item";
  discountValue: number;
  minOrderValue: number;
  maxUses: number;
  currentUses: number;
  validFrom: string;
  validUntil: string;
  active: boolean;
  description: string;
}

export interface AppliedDiscount {
  type: "coupon" | "points";
  code?: string;
  pointsUsed?: number;
  discountAmount: number;
  description: string;
}

// Tier configuration
export const TIER_THRESHOLDS = {
  bronze: { min: 0, max: 499, name: "Bronze", color: "#CD7F32" },
  silver: { min: 500, max: 1499, name: "Silver", color: "#C0C0C0" },
  gold: { min: 1500, max: Infinity, name: "Gold", color: "#FFD700" },
} as const;

// Points configuration
export const POINTS_PER_DOLLAR = 1;
export const POINTS_TO_DOLLAR = 0.01; // 100 points = $1

// Calculate tier based on lifetime points
export function calculateTier(lifetimePoints: number): RewardsTier {
  if (lifetimePoints >= TIER_THRESHOLDS.gold.min) return "gold";
  if (lifetimePoints >= TIER_THRESHOLDS.silver.min) return "silver";
  return "bronze";
}

// Calculate points for order
export function calculatePointsEarned(orderTotal: number): number {
  return Math.floor(orderTotal * POINTS_PER_DOLLAR);
}

// Calculate discount from points
export function calculatePointsDiscount(pointsToUse: number): number {
  return pointsToUse * POINTS_TO_DOLLAR;
}

// Validate coupon
export function validateCoupon(code: string, orderTotal: number): { valid: boolean; coupon?: Coupon; error?: string } {
  // TODO: Implement coupon validation from Supabase database
  const coupons: Coupon[] = [];

  const coupon = coupons.find(c => c.code === code.toUpperCase());
  
  if (!coupon) {
    return { valid: false, error: "Invalid coupon code" };
  }

  if (!coupon.active) {
    return { valid: false, error: "This coupon is no longer active" };
  }

  if (coupon.currentUses >= coupon.maxUses) {
    return { valid: false, error: "This coupon has reached its usage limit" };
  }

  if (orderTotal < coupon.minOrderValue) {
    return { valid: false, error: `Minimum order value of $${coupon.minOrderValue} required` };
  }

  const now = new Date();
  const validFrom = new Date(coupon.validFrom);
  const validUntil = new Date(coupon.validUntil);

  if (now < validFrom) {
    return { valid: false, error: "This coupon is not yet valid" };
  }

  if (now > validUntil) {
    return { valid: false, error: "This coupon has expired" };
  }

  return { valid: true, coupon };
}
