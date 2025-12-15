import { useState, useEffect } from 'react';
import { supabase } from '@/lib/supabase';

export interface StoreMetrics {
  total_revenue: number;
  total_orders: number;
  avg_order_value: number;
  unique_customers: number;
  revenue_change: number;
  orders_change: number;
}

export interface RevenueChartData {
  time_label: string;
  revenue: number;
  orders: number;
}

export interface TimeDistribution {
  time_period: string;
  order_count: number;
  revenue: number;
}

export interface CategoryDistribution {
  category_id: number;
  category: string;
  order_count: number;
  items_sold: number;
  total_revenue: number;
}

export interface PopularItem {
  menu_item_id: number;
  item_name: string;
  times_ordered: number;
  total_quantity: number;
  total_revenue: number;
  avg_price: number;
}

export interface CustomerInsights {
  total_customers: number;
  repeat_customers: number;
  repeat_rate: number;
  avg_spent_per_customer: number;
  highest_order: number;
  lowest_order: number;
}

export interface PeakHour {
  hour: number;
  order_count: number;
  revenue: number;
  avg_order_value: number;
}

export interface DayOfWeekStats {
  day_name: string;
  day_number: number;
  order_count: number;
  total_revenue: number;
  avg_order_value: number;
}

export interface RevenueGoals {
  avg_daily_revenue: number;
  best_day_revenue: number;
  worst_day_revenue: number;
  avg_daily_orders: number;
  revenue_goal: number;
  orders_goal: number;
}

export interface TopCustomer {
  customer_name: string;
  customer_phone: string;
  total_orders: number;
  total_spent: number;
  avg_order_value: number;
  last_order_date: string;
}

export interface BusinessInsights {
  peak_hour: number;
  busiest_day: string;
  top_category: string;
  customer_retention: number;
  avg_wait_time: number;
}

export function useAnalytics(storeId: number, dateRange: string = 'today') {
  const [metrics, setMetrics] = useState<StoreMetrics | null>(null);
  const [revenueData, setRevenueData] = useState<RevenueChartData[]>([]);
  const [timeDistribution, setTimeDistribution] = useState<TimeDistribution[]>([]);
  const [categoryDistribution, setCategoryDistribution] = useState<CategoryDistribution[]>([]);
  const [popularItems, setPopularItems] = useState<PopularItem[]>([]);
  const [customerInsights, setCustomerInsights] = useState<CustomerInsights | null>(null);
  const [peakHours, setPeakHours] = useState<PeakHour[]>([]);
  const [dayOfWeekStats, setDayOfWeekStats] = useState<DayOfWeekStats[]>([]);
  const [revenueGoals, setRevenueGoals] = useState<RevenueGoals | null>(null);
  const [topCustomers, setTopCustomers] = useState<TopCustomer[]>([]);
  const [businessInsights, setBusinessInsights] = useState<BusinessInsights | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchAnalytics();
  }, [storeId, dateRange]);

  const fetchAnalytics = async () => {
    try {
      setLoading(true);
      setError(null);

      // Fetch store metrics (KPIs)
      const { data: metricsData, error: metricsError } = await supabase
        .rpc('get_store_metrics', {
          p_store_id: storeId,
          p_date_range: dateRange
        });

      if (metricsError) throw metricsError;
      if (metricsData && metricsData.length > 0) {
        setMetrics(metricsData[0]);
      }

      // Fetch revenue chart data
      const { data: revenueChartData, error: revenueError } = await supabase
        .rpc('get_revenue_chart_data', {
          p_store_id: storeId,
          p_date_range: dateRange
        });

      if (revenueError) throw revenueError;
      setRevenueData(revenueChartData || []);

      // Fetch time distribution
      const { data: timeData, error: timeError } = await supabase
        .from('analytics_time_distribution')
        .select('*')
        .eq('store_id', storeId);

      if (timeError) throw timeError;
      setTimeDistribution(timeData || []);

      // Fetch category distribution
      const { data: categoryData, error: categoryError } = await supabase
        .from('analytics_category_distribution')
        .select('*')
        .limit(10);

      if (categoryError) throw categoryError;
      setCategoryDistribution(categoryData || []);

      // Fetch popular items
      const { data: popularData, error: popularError } = await supabase
        .from('analytics_popular_items')
        .select('*')
        .eq('store_id', storeId)
        .limit(5);

      if (popularError) throw popularError;
      setPopularItems(popularData || []);

      // Fetch customer insights
      const { data: customerData, error: customerError } = await supabase
        .from('analytics_customer_insights')
        .select('*')
        .eq('store_id', storeId)
        .single();

      if (customerError) throw customerError;
      setCustomerInsights(customerData);

      // Fetch peak hours
      const { data: peakData, error: peakError } = await supabase
        .from('analytics_peak_hours')
        .select('*')
        .eq('store_id', storeId)
        .order('hour');

      if (peakError) throw peakError;
      setPeakHours(peakData || []);

      // Fetch day of week stats
      const { data: dayData, error: dayError } = await supabase
        .from('analytics_day_of_week')
        .select('*')
        .eq('store_id', storeId)
        .order('day_number');

      if (dayError) throw dayError;
      setDayOfWeekStats(dayData || []);

      // Fetch revenue goals
      const { data: goalsData, error: goalsError } = await supabase
        .from('analytics_revenue_goals')
        .select('*')
        .eq('store_id', storeId)
        .single();

      if (goalsError) throw goalsError;
      setRevenueGoals(goalsData);

      // Fetch top customers
      const { data: topCustomersData, error: topCustomersError } = await supabase
        .from('analytics_top_customers')
        .select('*')
        .eq('store_id', storeId)
        .limit(10);

      if (topCustomersError) throw topCustomersError;
      setTopCustomers(topCustomersData || []);

      // Fetch business insights
      const { data: insightsData, error: insightsError } = await supabase
        .rpc('get_business_insights', {
          p_store_id: storeId
        });

      if (insightsError) throw insightsError;
      setBusinessInsights(insightsData);

    } catch (err) {
      console.error('Analytics fetch error:', err);
      setError(err instanceof Error ? err.message : 'Failed to load analytics');
    } finally {
      setLoading(false);
    }
  };

  const refresh = () => {
    fetchAnalytics();
  };

  return {
    metrics,
    revenueData,
    timeDistribution,
    categoryDistribution,
    popularItems,
    customerInsights,
    peakHours,
    dayOfWeekStats,
    revenueGoals,
    topCustomers,
    businessInsights,
    loading,
    error,
    refresh
  };
}
