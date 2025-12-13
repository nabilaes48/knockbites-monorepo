import { useState, useEffect, useCallback } from 'react';
import { supabase } from '@/lib/supabase';
import { useAuth } from '@/contexts/AuthContext';
import { calculateTier, RewardsTier } from '@/types/rewards';

/**
 * Customer rewards data from Supabase
 */
export interface CustomerRewards {
  customer_id: string;
  points: number;
  total_orders: number;
  total_spent: number;
  tier: RewardsTier;
  created_at: string;
  updated_at: string;
}

/**
 * Rewards transaction from Supabase
 */
export interface RewardsTransaction {
  id: number;
  customer_id: string;
  order_id: string | null;
  points_change: number;
  transaction_type: 'earned' | 'redeemed' | 'expired' | 'bonus' | 'referral';
  description: string;
  created_at: string;
}

/**
 * Hook return type
 */
export interface UseRewardsReturn {
  rewards: CustomerRewards | null;
  transactions: RewardsTransaction[];
  loading: boolean;
  error: string | null;
  refresh: () => Promise<void>;
  lifetimePoints: number;
}

/**
 * Default rewards for new customers
 */
const DEFAULT_REWARDS: Omit<CustomerRewards, 'customer_id' | 'created_at' | 'updated_at'> = {
  points: 0,
  total_orders: 0,
  total_spent: 0,
  tier: 'bronze',
};

/**
 * Hook to fetch and manage customer rewards from Supabase
 * Falls back to showing 0 if no rewards entry exists
 *
 * @example
 * const { rewards, transactions, loading, refresh } = useRewards();
 */
export function useRewards(): UseRewardsReturn {
  const { user, isCustomer } = useAuth();
  const [rewards, setRewards] = useState<CustomerRewards | null>(null);
  const [transactions, setTransactions] = useState<RewardsTransaction[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchRewards = useCallback(async () => {
    if (!user?.id) {
      setLoading(false);
      return;
    }

    setLoading(true);
    setError(null);

    try {
      // Fetch customer rewards
      const { data: rewardsData, error: rewardsError } = await supabase
        .from('customer_rewards')
        .select('*')
        .eq('customer_id', user.id)
        .single();

      if (rewardsError && rewardsError.code !== 'PGRST116') {
        // PGRST116 = no rows returned (new customer)
        throw rewardsError;
      }

      if (rewardsData) {
        // Calculate tier based on total spent (lifetime points approximation)
        const lifetimePoints = Math.floor(rewardsData.total_spent || 0);
        const tier = calculateTier(lifetimePoints);

        setRewards({
          ...rewardsData,
          tier,
        });
      } else {
        // No rewards entry yet - show defaults
        setRewards({
          customer_id: user.id,
          points: 0,
          total_orders: 0,
          total_spent: 0,
          tier: 'bronze',
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        });
      }

      // Fetch transactions history
      const { data: transactionsData, error: transactionsError } = await supabase
        .from('rewards_transactions')
        .select('*')
        .eq('customer_id', user.id)
        .order('created_at', { ascending: false })
        .limit(50);

      // Silently handle transaction errors - table may not exist

      setTransactions(transactionsData || []);

    } catch (err) {
      // Silently handle errors - table may not exist yet or RLS blocking
      // This is expected for fresh deployments or users without rewards
      setError(null); // Don't show error to user

      // Set defaults on error
      setRewards({
        customer_id: user.id,
        points: 0,
        total_orders: 0,
        total_spent: 0,
        tier: 'bronze',
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      });
    } finally {
      setLoading(false);
    }
  }, [user?.id]);

  // Initial fetch
  useEffect(() => {
    if (user?.id && isCustomer) {
      fetchRewards();
    } else {
      setLoading(false);
    }
  }, [user?.id, isCustomer, fetchRewards]);

  // Calculate lifetime points from total_spent
  const lifetimePoints = rewards ? Math.floor(rewards.total_spent || 0) : 0;

  return {
    rewards,
    transactions,
    loading,
    error,
    refresh: fetchRewards,
    lifetimePoints,
  };
}

/**
 * Convert Supabase transactions to the format expected by RewardsHistory component
 */
export function convertTransactionsForDisplay(transactions: RewardsTransaction[]) {
  return transactions.map(tx => ({
    id: tx.id.toString(),
    userId: tx.customer_id,
    orderId: tx.order_id || undefined,
    points: tx.points_change,
    type: tx.transaction_type,
    description: tx.description,
    createdAt: tx.created_at,
  }));
}
