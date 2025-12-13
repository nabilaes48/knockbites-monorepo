/**
 * AI Engine Edge Function
 *
 * Handles AI-powered features for Cameron's Connect:
 * - Menu personalization
 * - Demand forecasting
 * - Inventory intelligence
 * - Smart recommendations
 *
 * Supports both OpenAI and Supabase Vector for embeddings
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// Types
interface AIRequest {
  action: string;
  payload: Record<string, unknown>;
}

interface AIResponse {
  data: unknown;
  meta: {
    action: string;
    model: string;
    executionTime: number;
    cached: boolean;
  };
}

interface ClientContext {
  appVersion: string;
  appName: string;
  customerId?: string;
  storeId?: number;
}

interface MenuItem {
  id: number;
  name: string;
  description: string;
  category: string;
  price: number;
  image_url?: string;
  is_available: boolean;
}

interface Recommendation {
  item_id: number;
  name: string;
  price: number;
  score: number;
  reason: string;
}

interface InventoryPrediction {
  item_id: number;
  item_name: string;
  current_stock: number;
  predicted_demand: number;
  days_until_stockout: number;
  recommended_reorder: number;
  priority: string;
}

// Constants
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || '';
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';
const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY') || '';

const EMBEDDING_MODEL = 'text-embedding-3-large';
const EMBEDDING_DIMENSIONS = 1536;

// Simple in-memory cache (TTL: 5 minutes)
const cache = new Map<string, { data: unknown; timestamp: number }>();
const CACHE_TTL = 5 * 60 * 1000;

// CORS headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type, x-app-version, x-app-name, x-customer-id, x-store-id',
};

// Parse client context from headers
function parseClientContext(req: Request): ClientContext {
  return {
    appVersion: req.headers.get('X-App-Version') || '1.0.0',
    appName: req.headers.get('X-App-Name') || 'web',
    customerId: req.headers.get('X-Customer-Id') || undefined,
    storeId: parseInt(req.headers.get('X-Store-Id') || '0', 10) || undefined,
  };
}

// Cache helper
function getCached<T>(key: string): T | null {
  const cached = cache.get(key);
  if (cached && Date.now() - cached.timestamp < CACHE_TTL) {
    return cached.data as T;
  }
  cache.delete(key);
  return null;
}

function setCache(key: string, data: unknown): void {
  // Limit cache size
  if (cache.size > 1000) {
    const oldest = Array.from(cache.entries())
      .sort((a, b) => a[1].timestamp - b[1].timestamp)
      .slice(0, 100);
    oldest.forEach(([k]) => cache.delete(k));
  }
  cache.set(key, { data, timestamp: Date.now() });
}

// Generate embedding using OpenAI
async function generateEmbedding(text: string): Promise<number[] | null> {
  if (!OPENAI_API_KEY) {
    console.warn('OpenAI API key not configured');
    return null;
  }

  try {
    const response = await fetch('https://api.openai.com/v1/embeddings', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${OPENAI_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: EMBEDDING_MODEL,
        input: text,
        dimensions: EMBEDDING_DIMENSIONS,
      }),
    });

    if (!response.ok) {
      throw new Error(`OpenAI API error: ${response.status}`);
    }

    const data = await response.json();
    return data.data[0].embedding;
  } catch (error) {
    console.error('Embedding generation failed:', error);
    return null;
  }
}

// Get smart menu recommendations
async function getSmartMenu(
  supabase: ReturnType<typeof createClient>,
  context: ClientContext,
  limit: number = 20
): Promise<MenuItem[]> {
  const cacheKey = `smart_menu:${context.customerId}:${context.storeId}:${limit}`;
  const cached = getCached<MenuItem[]>(cacheKey);
  if (cached) return cached;

  // Call the V4 RPC
  const { data, error } = await supabase.rpc('rpc_v4_dispatch', {
    p_name: 'get_smart_menu',
    p_payload: {
      customer_id: context.customerId,
      store_id: context.storeId,
      limit,
    },
  });

  if (error) {
    console.error('Smart menu error:', error);
    throw new Error(error.message);
  }

  const items = data?.items || [];
  setCache(cacheKey, items);
  return items;
}

// Get personalized recommendations
async function getPersonalizedRecommendations(
  supabase: ReturnType<typeof createClient>,
  customerId: string,
  storeId?: number,
  limit: number = 10
): Promise<Recommendation[]> {
  const cacheKey = `recommendations:${customerId}:${storeId}:${limit}`;
  const cached = getCached<Recommendation[]>(cacheKey);
  if (cached) return cached;

  const { data, error } = await supabase.rpc('rpc_v4_dispatch', {
    p_name: 'get_personalized_recommendations',
    p_payload: {
      customer_id: customerId,
      store_id: storeId,
      limit,
    },
  });

  if (error) {
    console.error('Recommendations error:', error);
    throw new Error(error.message);
  }

  const recommendations = data || [];
  setCache(cacheKey, recommendations);
  return recommendations;
}

// Get similar items
async function getSimilarItems(
  supabase: ReturnType<typeof createClient>,
  itemId: number,
  limit: number = 5
): Promise<MenuItem[]> {
  const cacheKey = `similar:${itemId}:${limit}`;
  const cached = getCached<MenuItem[]>(cacheKey);
  if (cached) return cached;

  const { data, error } = await supabase.rpc('rpc_v4_dispatch', {
    p_name: 'get_similar_items',
    p_payload: { item_id: itemId, limit },
  });

  if (error) {
    console.error('Similar items error:', error);
    throw new Error(error.message);
  }

  const items = data || [];
  setCache(cacheKey, items);
  return items;
}

// Get substitute items (when out of stock)
async function getSubstituteItems(
  supabase: ReturnType<typeof createClient>,
  itemId: number,
  storeId?: number,
  limit: number = 3
): Promise<MenuItem[]> {
  const { data, error } = await supabase.rpc('rpc_v4_dispatch', {
    p_name: 'get_substitute_items',
    p_payload: { item_id: itemId, store_id: storeId, limit },
  });

  if (error) {
    console.error('Substitute items error:', error);
    throw new Error(error.message);
  }

  return data || [];
}

// Predict inventory needs
async function predictInventoryNeeds(
  supabase: ReturnType<typeof createClient>,
  storeId: number,
  daysAhead: number = 7
): Promise<InventoryPrediction[]> {
  const cacheKey = `inventory:${storeId}:${daysAhead}`;
  const cached = getCached<InventoryPrediction[]>(cacheKey);
  if (cached) return cached;

  const { data, error } = await supabase.rpc('rpc_v4_dispatch', {
    p_name: 'predict_inventory_needs',
    p_payload: { store_id: storeId, days_ahead: daysAhead },
  });

  if (error) {
    console.error('Inventory prediction error:', error);
    throw new Error(error.message);
  }

  const predictions = data || [];
  setCache(cacheKey, predictions);
  return predictions;
}

// Get top sellers predicted
async function getTopSellersPredicted(
  supabase: ReturnType<typeof createClient>,
  storeId: number,
  daysAhead: number = 7,
  limit: number = 10
): Promise<unknown[]> {
  const cacheKey = `top_sellers:${storeId}:${daysAhead}:${limit}`;
  const cached = getCached<unknown[]>(cacheKey);
  if (cached) return cached;

  const { data, error } = await supabase.rpc('rpc_v4_dispatch', {
    p_name: 'get_top_sellers_predicted',
    p_payload: { store_id: storeId, days_ahead: daysAhead, limit },
  });

  if (error) {
    console.error('Top sellers error:', error);
    throw new Error(error.message);
  }

  const sellers = data || [];
  setCache(cacheKey, sellers);
  return sellers;
}

// Get inventory alerts
async function getInventoryAlerts(
  supabase: ReturnType<typeof createClient>,
  storeId: number
): Promise<unknown[]> {
  const { data, error } = await supabase.rpc('rpc_v4_dispatch', {
    p_name: 'get_inventory_alerts',
    p_payload: { store_id: storeId },
  });

  if (error) {
    console.error('Inventory alerts error:', error);
    throw new Error(error.message);
  }

  return data || [];
}

// Get demand forecast
async function getDemandForecast(
  supabase: ReturnType<typeof createClient>,
  storeId: number,
  daysAhead: number = 7
): Promise<unknown[]> {
  const cacheKey = `forecast:${storeId}:${daysAhead}`;
  const cached = getCached<unknown[]>(cacheKey);
  if (cached) return cached;

  const { data, error } = await supabase.rpc('rpc_v4_dispatch', {
    p_name: 'get_demand_forecast',
    p_payload: { store_id: storeId, days_ahead: daysAhead },
  });

  if (error) {
    console.error('Demand forecast error:', error);
    throw new Error(error.message);
  }

  const forecast = data || [];
  setCache(cacheKey, forecast);
  return forecast;
}

// Explain menu performance
async function explainMenuPerformance(
  supabase: ReturnType<typeof createClient>,
  storeId: number
): Promise<unknown> {
  const cacheKey = `performance:${storeId}`;
  const cached = getCached<unknown>(cacheKey);
  if (cached) return cached;

  const { data, error } = await supabase.rpc('rpc_v4_dispatch', {
    p_name: 'explain_menu_performance',
    p_payload: { store_id: storeId },
  });

  if (error) {
    console.error('Menu performance error:', error);
    throw new Error(error.message);
  }

  setCache(cacheKey, data);
  return data;
}

// Update customer taste profile
async function updateCustomerTaste(
  supabase: ReturnType<typeof createClient>,
  customerId: string,
  categories: string[]
): Promise<unknown> {
  const { data, error } = await supabase.rpc('rpc_v4_dispatch', {
    p_name: 'update_customer_taste',
    p_payload: { customer_id: customerId, categories },
  });

  if (error) {
    console.error('Update taste error:', error);
    throw new Error(error.message);
  }

  // Invalidate related caches
  Array.from(cache.keys())
    .filter((k) => k.includes(customerId))
    .forEach((k) => cache.delete(k));

  return data;
}

// Generate menu item embedding
async function generateMenuItemEmbedding(
  supabase: ReturnType<typeof createClient>,
  itemId: number
): Promise<boolean> {
  // Get item details
  const { data: item, error: itemError } = await supabase
    .from('menu_items')
    .select('id, name, description, category_id')
    .eq('id', itemId)
    .single();

  if (itemError || !item) {
    throw new Error('Item not found');
  }

  // Get category name
  const { data: category } = await supabase
    .from('menu_categories')
    .select('name')
    .eq('id', item.category_id)
    .single();

  // Generate embedding text
  const embeddingText = `${item.name}. ${item.description || ''}. Category: ${category?.name || 'General'}`;

  // Generate embedding
  const embedding = await generateEmbedding(embeddingText);
  if (!embedding) {
    throw new Error('Failed to generate embedding');
  }

  // Store embedding
  const { error: upsertError } = await supabase
    .from('menu_item_embedding')
    .upsert({
      item_id: itemId,
      embedding: `[${embedding.join(',')}]`,
      category: category?.name,
      semantic_description: embeddingText,
      updated_at: new Date().toISOString(),
    });

  if (upsertError) {
    throw new Error(upsertError.message);
  }

  return true;
}

// Main handler
serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  const startTime = Date.now();
  let action = '';
  let cached = false;

  try {
    const body: AIRequest = await req.json();
    action = body.action;
    const payload = body.payload || {};

    if (!action) {
      return new Response(
        JSON.stringify({ error: 'Missing required field: action' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    // Parse client context
    const context = parseClientContext(req);

    // Get Supabase client
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY, {
      auth: { persistSession: false },
    });

    let result: unknown;

    // Route to appropriate handler
    switch (action) {
      case 'get_smart_menu':
        result = await getSmartMenu(
          supabase,
          {
            ...context,
            customerId: (payload.customer_id as string) || context.customerId,
            storeId: (payload.store_id as number) || context.storeId,
          },
          (payload.limit as number) || 20
        );
        break;

      case 'get_recommendations':
        if (!payload.customer_id && !context.customerId) {
          throw new Error('customer_id is required');
        }
        result = await getPersonalizedRecommendations(
          supabase,
          (payload.customer_id as string) || context.customerId!,
          (payload.store_id as number) || context.storeId,
          (payload.limit as number) || 10
        );
        break;

      case 'get_similar_items':
        if (!payload.item_id) {
          throw new Error('item_id is required');
        }
        result = await getSimilarItems(
          supabase,
          payload.item_id as number,
          (payload.limit as number) || 5
        );
        break;

      case 'get_substitutes':
        if (!payload.item_id) {
          throw new Error('item_id is required');
        }
        result = await getSubstituteItems(
          supabase,
          payload.item_id as number,
          (payload.store_id as number) || context.storeId,
          (payload.limit as number) || 3
        );
        break;

      case 'predict_inventory':
        if (!payload.store_id && !context.storeId) {
          throw new Error('store_id is required');
        }
        result = await predictInventoryNeeds(
          supabase,
          (payload.store_id as number) || context.storeId!,
          (payload.days_ahead as number) || 7
        );
        break;

      case 'get_top_sellers':
        if (!payload.store_id && !context.storeId) {
          throw new Error('store_id is required');
        }
        result = await getTopSellersPredicted(
          supabase,
          (payload.store_id as number) || context.storeId!,
          (payload.days_ahead as number) || 7,
          (payload.limit as number) || 10
        );
        break;

      case 'get_inventory_alerts':
        if (!payload.store_id && !context.storeId) {
          throw new Error('store_id is required');
        }
        result = await getInventoryAlerts(
          supabase,
          (payload.store_id as number) || context.storeId!
        );
        break;

      case 'get_demand_forecast':
        if (!payload.store_id && !context.storeId) {
          throw new Error('store_id is required');
        }
        result = await getDemandForecast(
          supabase,
          (payload.store_id as number) || context.storeId!,
          (payload.days_ahead as number) || 7
        );
        break;

      case 'explain_performance':
        if (!payload.store_id && !context.storeId) {
          throw new Error('store_id is required');
        }
        result = await explainMenuPerformance(
          supabase,
          (payload.store_id as number) || context.storeId!
        );
        break;

      case 'update_taste':
        if (!payload.customer_id && !context.customerId) {
          throw new Error('customer_id is required');
        }
        if (!payload.categories || !Array.isArray(payload.categories)) {
          throw new Error('categories array is required');
        }
        result = await updateCustomerTaste(
          supabase,
          (payload.customer_id as string) || context.customerId!,
          payload.categories as string[]
        );
        break;

      case 'generate_embedding':
        if (!payload.item_id) {
          throw new Error('item_id is required');
        }
        result = await generateMenuItemEmbedding(
          supabase,
          payload.item_id as number
        );
        break;

      case 'generate_all_embeddings':
        // Generate embeddings for all menu items
        const { data: items } = await supabase
          .from('menu_items')
          .select('id')
          .eq('is_available', true);

        if (items) {
          const results = await Promise.allSettled(
            items.map((item) =>
              generateMenuItemEmbedding(supabase, item.id)
            )
          );
          const succeeded = results.filter((r) => r.status === 'fulfilled').length;
          result = { total: items.length, succeeded, failed: items.length - succeeded };
        } else {
          result = { total: 0, succeeded: 0, failed: 0 };
        }
        break;

      case 'refresh_views':
        // Refresh materialized views
        await supabase.rpc('refresh_ai_materialized_views');
        result = { refreshed: true };
        break;

      case 'health':
        result = {
          status: 'healthy',
          version: 'v4',
          openai_configured: !!OPENAI_API_KEY,
          cache_size: cache.size,
        };
        break;

      default:
        return new Response(
          JSON.stringify({ error: `Unknown action: ${action}` }),
          {
            status: 400,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          }
        );
    }

    const executionTime = Date.now() - startTime;

    // Build response
    const response: AIResponse = {
      data: result,
      meta: {
        action,
        model: EMBEDDING_MODEL,
        executionTime,
        cached,
      },
    };

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json',
        'X-Execution-Time': executionTime.toString(),
      },
    });
  } catch (err) {
    const executionTime = Date.now() - startTime;
    console.error('AI Engine error:', err);

    return new Response(
      JSON.stringify({
        error: err instanceof Error ? err.message : 'Internal AI engine error',
        action,
        executionTime,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
});
