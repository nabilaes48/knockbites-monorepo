// Autonomous Operations Engine - Edge Function
// Handles dynamic pricing, kitchen load prediction, staffing optimization, and profitability analysis

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-app-version, x-app-name, x-store-id',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

// Simple in-memory cache with TTL
const cache = new Map<string, { data: unknown; expires: number }>();
const CACHE_TTL = 60 * 1000; // 1 minute cache for operational data (shorter than AI due to time-sensitivity)

function getCached<T>(key: string): T | null {
  const cached = cache.get(key);
  if (cached && cached.expires > Date.now()) {
    return cached.data as T;
  }
  cache.delete(key);
  return null;
}

function setCache(key: string, data: unknown, ttl = CACHE_TTL): void {
  cache.set(key, { data, expires: Date.now() + ttl });
}

// Safety constants
const MAX_PRICE_MULTIPLIER = 1.15; // Maximum 15% price increase
const MIN_PRICE_MULTIPLIER = 0.85; // Maximum 15% price decrease
const MIN_CONFIDENCE_THRESHOLD = 0.6; // Minimum confidence for autonomous actions
const CRITICAL_LOAD_THRESHOLD = 0.85; // 85% capacity = critical

interface RequestPayload {
  action: string;
  payload: Record<string, unknown>;
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const { action, payload } = await req.json() as RequestPayload;

    let result: unknown;

    switch (action) {
      case 'get_dynamic_pricing':
        result = await getDynamicPricing(supabase, payload);
        break;

      case 'calculate_item_price':
        result = await calculateItemPrice(supabase, payload);
        break;

      case 'get_kitchen_load':
        result = await getKitchenLoad(supabase, payload);
        break;

      case 'predict_wait_time':
        result = await predictWaitTime(supabase, payload);
        break;

      case 'get_staffing_recommendations':
        result = await getStaffingRecommendations(supabase, payload);
        break;

      case 'get_menu_profitability':
        result = await getMenuProfitability(supabase, payload);
        break;

      case 'get_operational_health':
        result = await getOperationalHealth(supabase, payload);
        break;

      case 'get_ops_alerts':
        result = await getOpsAlerts(supabase, payload);
        break;

      case 'update_pricing_rule':
        result = await updatePricingRule(supabase, payload);
        break;

      case 'approve_pricing_change':
        result = await approvePricingChange(supabase, payload);
        break;

      case 'toggle_item_availability':
        result = await toggleItemAvailability(supabase, payload);
        break;

      case 'get_store_settings':
        result = await getStoreSettings(supabase, payload);
        break;

      case 'update_store_settings':
        result = await updateStoreSettings(supabase, payload);
        break;

      case 'run_autonomous_cycle':
        result = await runAutonomousCycle(supabase, payload);
        break;

      default:
        throw new Error(`Unknown action: ${action}`);
    }

    return new Response(JSON.stringify({ success: true, data: result }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });
  } catch (error) {
    console.error('Autonomous Ops Engine Error:', error);
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    );
  }
});

// ============================================================================
// DYNAMIC PRICING FUNCTIONS
// ============================================================================

async function getDynamicPricing(supabase: any, payload: Record<string, unknown>) {
  const storeId = payload.store_id as number;
  const itemId = payload.item_id as number | undefined;

  const cacheKey = `pricing:${storeId}:${itemId || 'all'}`;
  const cached = getCached(cacheKey);
  if (cached) return cached;

  // Call the database RPC for pricing calculations
  const { data, error } = await supabase.rpc('rpc_v5_dispatch', {
    p_name: 'get_dynamic_pricing',
    p_payload: { store_id: storeId, item_id: itemId },
  });

  if (error) throw error;

  // Add safety validation
  const validatedPricing = (data || []).map((item: any) => ({
    ...item,
    suggested_price: Math.min(
      Math.max(item.suggested_price, item.base_price * MIN_PRICE_MULTIPLIER),
      item.base_price * MAX_PRICE_MULTIPLIER
    ),
    is_safe: item.confidence >= MIN_CONFIDENCE_THRESHOLD,
  }));

  setCache(cacheKey, validatedPricing);
  return validatedPricing;
}

async function calculateItemPrice(supabase: any, payload: Record<string, unknown>) {
  const itemId = payload.item_id as number;
  const storeId = payload.store_id as number;

  // Get real-time price calculation
  const { data, error } = await supabase.rpc('calculate_dynamic_price', {
    p_item_id: itemId,
    p_store_id: storeId,
  });

  if (error) throw error;

  const result = data?.[0] || {
    suggested_price: null,
    price_multiplier: 1.0,
    confidence: 0,
    reason: 'No pricing data available',
  };

  // Apply safety bounds
  return {
    ...result,
    price_multiplier: Math.min(
      Math.max(result.price_multiplier, MIN_PRICE_MULTIPLIER),
      MAX_PRICE_MULTIPLIER
    ),
    is_within_bounds: result.price_multiplier >= MIN_PRICE_MULTIPLIER &&
                      result.price_multiplier <= MAX_PRICE_MULTIPLIER,
  };
}

async function updatePricingRule(supabase: any, payload: Record<string, unknown>) {
  const { store_id, item_id, base_price, min_price, max_price, is_enabled } = payload;

  // Validate safety bounds
  const safeMaxPrice = Math.min(max_price as number, (base_price as number) * MAX_PRICE_MULTIPLIER);
  const safeMinPrice = Math.max(min_price as number, (base_price as number) * MIN_PRICE_MULTIPLIER);

  const { data, error } = await supabase
    .from('dynamic_pricing_rules')
    .upsert({
      store_id,
      item_id,
      base_price,
      min_price: safeMinPrice,
      max_price: safeMaxPrice,
      is_enabled: is_enabled ?? true,
      updated_at: new Date().toISOString(),
    })
    .select()
    .single();

  if (error) throw error;
  return data;
}

async function approvePricingChange(supabase: any, payload: Record<string, unknown>) {
  const { store_id, item_id, approved_price, approved_by } = payload;

  // Log the approval
  const { error: logError } = await supabase
    .from('ops_alerts')
    .insert({
      store_id,
      alert_type: 'pricing_approved',
      severity: 'info',
      title: 'Price Change Approved',
      message: `Price for item ${item_id} approved at $${approved_price}`,
      data: { item_id, approved_price, approved_by },
      is_resolved: true,
      resolved_at: new Date().toISOString(),
    });

  if (logError) console.error('Failed to log approval:', logError);

  // Update the menu item price if needed
  // Note: Actual price update should go through menu management
  return { success: true, approved_price };
}

// ============================================================================
// KITCHEN LOAD FUNCTIONS
// ============================================================================

async function getKitchenLoad(supabase: any, payload: Record<string, unknown>) {
  const storeId = payload.store_id as number;
  const windowMinutes = (payload.window_minutes as number) || 30;

  const cacheKey = `kitchen:${storeId}:${windowMinutes}`;
  const cached = getCached(cacheKey);
  if (cached) return cached;

  // Call the prediction function
  const { data, error } = await supabase.rpc('predict_kitchen_load', {
    p_store_id: storeId,
    p_window_minutes: windowMinutes,
  });

  if (error) throw error;

  const result = data?.[0] || {
    predicted_orders: 0,
    predicted_prep_time: 0,
    load_level: 'low',
    capacity_percentage: 0,
    bottleneck_items: [],
    recommendation: 'Normal operations',
  };

  // Add visual indicators
  const enhanced = {
    ...result,
    is_critical: result.load_level === 'critical',
    color: getLoadColor(result.load_level),
    icon: getLoadIcon(result.load_level),
    action_required: result.capacity_percentage >= CRITICAL_LOAD_THRESHOLD * 100,
  };

  setCache(cacheKey, enhanced);
  return enhanced;
}

async function predictWaitTime(supabase: any, payload: Record<string, unknown>) {
  const storeId = payload.store_id as number;
  const itemIds = payload.item_ids as number[] | undefined;

  // Get current kitchen load
  const load = await getKitchenLoad(supabase, { store_id: storeId, window_minutes: 15 });

  // Base wait time calculation
  let baseWaitMinutes = 10; // Default prep time

  if (itemIds && itemIds.length > 0) {
    // Get average prep time for selected items
    const { data: items } = await supabase
      .from('menu_items')
      .select('prep_time_minutes')
      .in('id', itemIds);

    if (items && items.length > 0) {
      const avgPrepTime = items.reduce((sum: number, item: any) =>
        sum + (item.prep_time_minutes || 5), 0) / items.length;
      baseWaitMinutes = Math.ceil(avgPrepTime);
    }
  }

  // Adjust based on current load
  const loadMultiplier = {
    low: 1.0,
    moderate: 1.3,
    high: 1.7,
    critical: 2.5,
  }[load.load_level as string] || 1.0;

  const estimatedWait = Math.ceil(baseWaitMinutes * loadMultiplier);

  return {
    estimated_minutes: estimatedWait,
    range_min: Math.max(5, estimatedWait - 5),
    range_max: estimatedWait + 10,
    load_level: load.load_level,
    confidence: load.load_level === 'low' ? 0.9 : load.load_level === 'critical' ? 0.6 : 0.75,
    message: getWaitTimeMessage(estimatedWait, load.load_level as string),
  };
}

function getLoadColor(level: string): string {
  switch (level) {
    case 'low': return '#22c55e'; // green
    case 'moderate': return '#eab308'; // yellow
    case 'high': return '#f97316'; // orange
    case 'critical': return '#ef4444'; // red
    default: return '#6b7280'; // gray
  }
}

function getLoadIcon(level: string): string {
  switch (level) {
    case 'low': return 'check-circle';
    case 'moderate': return 'clock';
    case 'high': return 'alert-triangle';
    case 'critical': return 'alert-octagon';
    default: return 'help-circle';
  }
}

function getWaitTimeMessage(minutes: number, loadLevel: string): string {
  if (minutes <= 10) return 'Quick preparation expected';
  if (minutes <= 20) return 'Standard wait time';
  if (loadLevel === 'critical') return 'Kitchen is very busy - longer wait expected';
  return 'Moderate wait time expected';
}

// ============================================================================
// STAFFING FUNCTIONS
// ============================================================================

async function getStaffingRecommendations(supabase: any, payload: Record<string, unknown>) {
  const storeId = payload.store_id as number;
  const date = (payload.date as string) || new Date().toISOString().split('T')[0];

  const cacheKey = `staffing:${storeId}:${date}`;
  const cached = getCached(cacheKey);
  if (cached) return cached;

  // Call the staffing generation function
  const { data, error } = await supabase.rpc('generate_staffing_recommendations', {
    p_store_id: storeId,
    p_date: date,
  });

  if (error) throw error;

  // Enhance with schedule visualization data
  const recommendations = (data || []).map((rec: any) => ({
    ...rec,
    hour_label: formatHour(rec.hour_of_day),
    staff_delta: rec.recommended_staff - rec.current_staff,
    is_understaffed: rec.recommended_staff > rec.current_staff,
    is_overstaffed: rec.recommended_staff < rec.current_staff,
    cost_impact: calculateStaffCostImpact(rec.recommended_staff - rec.current_staff),
  }));

  setCache(cacheKey, recommendations);
  return recommendations;
}

function formatHour(hour: number): string {
  if (hour === 0) return '12 AM';
  if (hour === 12) return '12 PM';
  return hour < 12 ? `${hour} AM` : `${hour - 12} PM`;
}

function calculateStaffCostImpact(delta: number): { amount: number; label: string } {
  const hourlyRate = 15; // Assume $15/hour average
  const amount = delta * hourlyRate;
  return {
    amount,
    label: amount > 0 ? `+$${amount}/hr` : amount < 0 ? `-$${Math.abs(amount)}/hr` : '$0',
  };
}

// ============================================================================
// PROFITABILITY FUNCTIONS
// ============================================================================

async function getMenuProfitability(supabase: any, payload: Record<string, unknown>) {
  const storeId = payload.store_id as number;
  const days = (payload.days as number) || 30;

  const cacheKey = `profitability:${storeId}:${days}`;
  const cached = getCached(cacheKey);
  if (cached) return cached;

  // Call the profitability calculation function
  const { data, error } = await supabase.rpc('calculate_menu_profitability', {
    p_store_id: storeId,
    p_days: days,
  });

  if (error) throw error;

  // Categorize items by profitability
  const items = data || [];
  const categorized = {
    stars: items.filter((i: any) => i.margin_percentage >= 60 && i.total_quantity >= 10),
    puzzles: items.filter((i: any) => i.margin_percentage >= 60 && i.total_quantity < 10),
    plowhorses: items.filter((i: any) => i.margin_percentage < 60 && i.total_quantity >= 10),
    dogs: items.filter((i: any) => i.margin_percentage < 60 && i.total_quantity < 10),
    all: items,
  };

  // Add recommendations
  const withRecommendations = {
    ...categorized,
    recommendations: generateProfitabilityRecommendations(categorized),
    summary: {
      total_items: items.length,
      avg_margin: items.reduce((sum: number, i: any) => sum + i.margin_percentage, 0) / items.length || 0,
      total_profit: items.reduce((sum: number, i: any) => sum + i.total_profit, 0),
      top_performers: items.slice(0, 5).map((i: any) => i.item_name),
    },
  };

  setCache(cacheKey, withRecommendations);
  return withRecommendations;
}

function generateProfitabilityRecommendations(categorized: any): string[] {
  const recommendations: string[] = [];

  if (categorized.dogs.length > 0) {
    recommendations.push(`Consider removing or repricing ${categorized.dogs.length} low-performing items`);
  }

  if (categorized.puzzles.length > 0) {
    recommendations.push(`Promote ${categorized.puzzles.length} high-margin items to increase sales`);
  }

  if (categorized.plowhorses.length > 3) {
    recommendations.push(`Review pricing on ${categorized.plowhorses.length} popular but low-margin items`);
  }

  if (categorized.stars.length > 0) {
    recommendations.push(`Feature your ${categorized.stars.length} star items prominently on the menu`);
  }

  return recommendations;
}

// ============================================================================
// OPERATIONAL HEALTH FUNCTIONS
// ============================================================================

async function getOperationalHealth(supabase: any, payload: Record<string, unknown>) {
  const storeId = payload.store_id as number;

  const cacheKey = `health:${storeId}`;
  const cached = getCached(cacheKey);
  if (cached) return cached;

  // Call the health check function
  const { data, error } = await supabase.rpc('get_operational_health', {
    p_store_id: storeId,
  });

  if (error) throw error;

  const health = data?.[0] || {
    overall_score: 0,
    kitchen_score: 0,
    inventory_score: 0,
    staff_score: 0,
    pricing_score: 0,
    active_alerts: 0,
    recommendations: [],
  };

  // Add visual grade
  const enhanced = {
    ...health,
    grade: getHealthGrade(health.overall_score),
    grade_color: getGradeColor(health.overall_score),
    status: health.overall_score >= 80 ? 'healthy' : health.overall_score >= 60 ? 'attention' : 'critical',
    breakdown: [
      { name: 'Kitchen', score: health.kitchen_score, icon: 'utensils' },
      { name: 'Inventory', score: health.inventory_score, icon: 'package' },
      { name: 'Staffing', score: health.staff_score, icon: 'users' },
      { name: 'Pricing', score: health.pricing_score, icon: 'dollar-sign' },
    ],
  };

  setCache(cacheKey, enhanced);
  return enhanced;
}

function getHealthGrade(score: number): string {
  if (score >= 90) return 'A';
  if (score >= 80) return 'B';
  if (score >= 70) return 'C';
  if (score >= 60) return 'D';
  return 'F';
}

function getGradeColor(score: number): string {
  if (score >= 90) return '#22c55e';
  if (score >= 80) return '#84cc16';
  if (score >= 70) return '#eab308';
  if (score >= 60) return '#f97316';
  return '#ef4444';
}

// ============================================================================
// ALERTS FUNCTIONS
// ============================================================================

async function getOpsAlerts(supabase: any, payload: Record<string, unknown>) {
  const storeId = payload.store_id as number;
  const includeResolved = payload.include_resolved as boolean || false;

  let query = supabase
    .from('ops_alerts')
    .select('*')
    .eq('store_id', storeId)
    .order('created_at', { ascending: false })
    .limit(50);

  if (!includeResolved) {
    query = query.eq('is_resolved', false);
  }

  const { data, error } = await query;

  if (error) throw error;

  // Group by severity
  const alerts = data || [];
  return {
    critical: alerts.filter((a: any) => a.severity === 'critical'),
    warning: alerts.filter((a: any) => a.severity === 'warning'),
    info: alerts.filter((a: any) => a.severity === 'info'),
    all: alerts,
    total_unresolved: alerts.filter((a: any) => !a.is_resolved).length,
  };
}

// ============================================================================
// STORE SETTINGS FUNCTIONS
// ============================================================================

async function getStoreSettings(supabase: any, payload: Record<string, unknown>) {
  const storeId = payload.store_id as number;

  const { data, error } = await supabase
    .from('store_ops_settings')
    .select('*')
    .eq('store_id', storeId)
    .single();

  if (error && error.code !== 'PGRST116') throw error; // PGRST116 = not found

  // Return defaults if not found
  return data || {
    store_id: storeId,
    dynamic_pricing_enabled: false,
    auto_hide_slow_items: true,
    kitchen_capacity_per_hour: 30,
    max_price_increase_pct: 15,
    max_price_decrease_pct: 15,
    min_confidence_threshold: 0.6,
    alert_on_critical_load: true,
    auto_staffing_suggestions: true,
  };
}

async function updateStoreSettings(supabase: any, payload: Record<string, unknown>) {
  const storeId = payload.store_id as number;
  const settings = payload.settings as Record<string, unknown>;

  // Validate safety bounds
  if (settings.max_price_increase_pct && (settings.max_price_increase_pct as number) > 20) {
    settings.max_price_increase_pct = 20; // Hard cap at 20%
  }
  if (settings.max_price_decrease_pct && (settings.max_price_decrease_pct as number) > 25) {
    settings.max_price_decrease_pct = 25; // Hard cap at 25%
  }

  const { data, error } = await supabase
    .from('store_ops_settings')
    .upsert({
      store_id: storeId,
      ...settings,
      updated_at: new Date().toISOString(),
    })
    .select()
    .single();

  if (error) throw error;
  return data;
}

// ============================================================================
// ITEM AVAILABILITY FUNCTIONS
// ============================================================================

async function toggleItemAvailability(supabase: any, payload: Record<string, unknown>) {
  const itemId = payload.item_id as number;
  const isAvailable = payload.is_available as boolean;
  const reason = payload.reason as string;

  const { data, error } = await supabase
    .from('menu_items')
    .update({
      is_available: isAvailable,
      updated_at: new Date().toISOString(),
    })
    .eq('id', itemId)
    .select()
    .single();

  if (error) throw error;

  // Log the change
  await supabase.from('ops_alerts').insert({
    store_id: data.store_id || 1,
    alert_type: isAvailable ? 'item_restored' : 'item_hidden',
    severity: 'info',
    title: isAvailable ? 'Item Restored' : 'Item Hidden',
    message: `${data.name} ${isAvailable ? 'restored to menu' : 'hidden from menu'}. Reason: ${reason}`,
    data: { item_id: itemId, reason },
    is_resolved: true,
    resolved_at: new Date().toISOString(),
  });

  return data;
}

// ============================================================================
// AUTONOMOUS CYCLE FUNCTION
// ============================================================================

async function runAutonomousCycle(supabase: any, payload: Record<string, unknown>) {
  const storeId = payload.store_id as number;
  const dryRun = (payload.dry_run as boolean) ?? true; // Default to dry run for safety

  const results = {
    timestamp: new Date().toISOString(),
    store_id: storeId,
    dry_run: dryRun,
    actions: [] as { type: string; description: string; applied: boolean }[],
    errors: [] as string[],
  };

  try {
    // 1. Check kitchen load and auto-hide slow items if critical
    const load = await getKitchenLoad(supabase, { store_id: storeId, window_minutes: 30 });
    if (load.is_critical && load.bottleneck_items?.length > 0) {
      for (const itemId of load.bottleneck_items) {
        results.actions.push({
          type: 'hide_item',
          description: `Auto-hide slow item ${itemId} due to critical kitchen load`,
          applied: !dryRun,
        });
        if (!dryRun) {
          await toggleItemAvailability(supabase, {
            item_id: itemId,
            is_available: false,
            reason: 'Auto-hidden: Critical kitchen load',
          });
        }
      }
    }

    // 2. Check inventory and generate alerts
    const { data: lowStock } = await supabase
      .from('inventory_alerts')
      .select('*')
      .eq('store_id', storeId)
      .eq('is_resolved', false)
      .eq('severity', 'critical');

    if (lowStock && lowStock.length > 0) {
      results.actions.push({
        type: 'inventory_alert',
        description: `${lowStock.length} critical inventory alerts detected`,
        applied: true, // Alerts already exist
      });
    }

    // 3. Check profitability and flag low-margin items
    const profitability = await getMenuProfitability(supabase, { store_id: storeId, days: 7 });
    if (profitability.dogs.length > 0) {
      results.actions.push({
        type: 'profitability_review',
        description: `${profitability.dogs.length} items flagged for profitability review`,
        applied: true,
      });
    }

    // 4. Generate staffing recommendations
    const staffing = await getStaffingRecommendations(supabase, { store_id: storeId });
    const understaffedHours = staffing.filter((s: any) => s.is_understaffed);
    if (understaffedHours.length > 0) {
      results.actions.push({
        type: 'staffing_recommendation',
        description: `${understaffedHours.length} hours identified as understaffed`,
        applied: true,
      });
    }

  } catch (error) {
    results.errors.push(error.message);
  }

  return results;
}
