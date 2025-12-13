import { UserRewards, RewardsTransaction, Coupon } from "@/types/rewards";
import { calculateTier } from "@/types/rewards";

const REWARDS_STORAGE_KEY = "userRewards";
const COUPONS_STORAGE_KEY = "availableCoupons";

// Initialize default rewards for a user
export function initializeUserRewards(userId: string): UserRewards {
  const rewards: UserRewards = {
    userId,
    points: 0,
    lifetimePoints: 0,
    tier: "bronze",
    transactions: [],
  };
  saveUserRewards(rewards);
  return rewards;
}

// Get user rewards from localStorage
export function getUserRewards(userId: string): UserRewards {
  const stored = localStorage.getItem(`${REWARDS_STORAGE_KEY}_${userId}`);
  if (stored) {
    return JSON.parse(stored);
  }
  return initializeUserRewards(userId);
}

// Save user rewards to localStorage
export function saveUserRewards(rewards: UserRewards): void {
  localStorage.setItem(`${REWARDS_STORAGE_KEY}_${rewards.userId}`, JSON.stringify(rewards));
}

// Add points transaction
export function addPointsTransaction(
  userId: string,
  transaction: Omit<RewardsTransaction, "id" | "userId" | "createdAt">
): UserRewards {
  const rewards = getUserRewards(userId);

  const newTransaction: RewardsTransaction = {
    ...transaction,
    id: `txn_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
    userId,
    createdAt: new Date().toISOString(),
  };

  rewards.transactions.unshift(newTransaction);

  // Update points
  if (transaction.type === "earned" || transaction.type === "bonus" || transaction.type === "referral") {
    rewards.points += transaction.points;
    rewards.lifetimePoints += transaction.points;
  } else if (transaction.type === "redeemed") {
    rewards.points -= Math.abs(transaction.points);
  }

  // Update tier
  rewards.tier = calculateTier(rewards.lifetimePoints);

  saveUserRewards(rewards);
  return rewards;
}

// Redeem points
export function redeemPoints(userId: string, pointsToRedeem: number, orderId: string): UserRewards {
  const rewards = getUserRewards(userId);

  if (rewards.points < pointsToRedeem) {
    throw new Error("Insufficient points");
  }

  return addPointsTransaction(userId, {
    orderId,
    points: pointsToRedeem,
    type: "redeemed",
    description: `Redeemed ${pointsToRedeem} points for discount`,
  });
}

// Award points for order
export function awardPointsForOrder(userId: string, orderId: string, orderTotal: number, pointsEarned: number): UserRewards {
  return addPointsTransaction(userId, {
    orderId,
    points: pointsEarned,
    type: "earned",
    description: `Earned from order #${orderId.slice(-6)}`,
  });
}

// Get available coupons
export function getAvailableCoupons(): Coupon[] {
  const stored = localStorage.getItem(COUPONS_STORAGE_KEY);
  if (stored) {
    return JSON.parse(stored);
  }

  // No default coupons - implement coupon system in Supabase if needed
  const defaultCoupons: Coupon[] = [];

  localStorage.setItem(COUPONS_STORAGE_KEY, JSON.stringify(defaultCoupons));
  return defaultCoupons;
}

// Validate coupon
export function validateCoupon(code: string, orderTotal: number): { valid: boolean; coupon?: Coupon; error?: string } {
  const coupons = getAvailableCoupons();
  const coupon = coupons.find((c) => c.code.toLowerCase() === code.toLowerCase());

  if (!coupon) {
    return { valid: false, error: "Invalid coupon code" };
  }

  if (!coupon.active) {
    return { valid: false, error: "This coupon is no longer active" };
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

  if (coupon.currentUses >= coupon.maxUses) {
    return { valid: false, error: "This coupon has reached its usage limit" };
  }

  if (orderTotal < coupon.minOrderValue) {
    return { valid: false, error: `Minimum order value is $${coupon.minOrderValue.toFixed(2)}` };
  }

  return { valid: true, coupon };
}

// Calculate discount from coupon
export function calculateCouponDiscount(coupon: Coupon, orderTotal: number): number {
  switch (coupon.discountType) {
    case "percentage":
      return orderTotal * (coupon.discountValue / 100);
    case "fixed":
      return Math.min(coupon.discountValue, orderTotal);
    case "bogo":
    case "free_item":
      // For now, just return 0 - would need item-level logic
      return 0;
    default:
      return 0;
  }
}

// Apply coupon (increment usage)
export function applyCoupon(code: string): void {
  const coupons = getAvailableCoupons();
  const couponIndex = coupons.findIndex((c) => c.code.toLowerCase() === code.toLowerCase());

  if (couponIndex !== -1) {
    coupons[couponIndex].currentUses += 1;
    localStorage.setItem(COUPONS_STORAGE_KEY, JSON.stringify(coupons));
  }
}
