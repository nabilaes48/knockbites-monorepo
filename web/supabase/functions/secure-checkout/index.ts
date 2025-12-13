// Secure Checkout Edge Function
// This function handles order creation with SERVER-SIDE price validation
// NEVER trust client-provided prices

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

interface CheckoutItem {
  menu_item_id: number
  quantity: number
  selected_options?: Record<string, string[]>
  portion_selections?: Record<string, string>
}

interface CheckoutRequest {
  items: CheckoutItem[]
  store_id: number
  customer_name?: string
  customer_email?: string
  customer_phone?: string
  special_instructions?: string
  order_type?: 'pickup' | 'delivery'
}

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  // Only allow POST
  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ error: 'Method not allowed' }),
      { status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }

  try {
    // Initialize Supabase client with SERVICE ROLE (bypasses RLS for validation)
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

    if (!supabaseUrl || !supabaseServiceKey) {
      console.error('Missing Supabase environment variables')
      return new Response(
        JSON.stringify({ error: 'Server configuration error' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Parse request body
    const body: CheckoutRequest = await req.json()
    const {
      items,
      store_id,
      customer_name,
      customer_email,
      customer_phone,
      special_instructions,
      order_type = 'pickup'
    } = body

    // =========================================
    // VALIDATION PHASE
    // =========================================

    // 1. Validate items array
    if (!Array.isArray(items) || items.length === 0) {
      return new Response(
        JSON.stringify({ error: 'Cart is empty' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (items.length > 50) {
      return new Response(
        JSON.stringify({ error: 'Too many items (max 50)' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 2. Validate store exists and is active
    const { data: store, error: storeError } = await supabase
      .from('stores')
      .select('id, name, is_active, tax_rate')
      .eq('id', store_id)
      .single()

    if (storeError || !store) {
      return new Response(
        JSON.stringify({ error: 'Invalid store' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (!store.is_active) {
      return new Response(
        JSON.stringify({ error: 'Store is currently closed' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 3. Fetch REAL prices from database - NEVER TRUST CLIENT
    const menuItemIds = items.map(i => i.menu_item_id)
    const { data: menuItems, error: menuError } = await supabase
      .from('menu_items')
      .select(`
        id,
        name,
        base_price,
        is_available,
        preparation_time,
        menu_item_customizations (
          id,
          name,
          portion_pricing
        )
      `)
      .in('id', menuItemIds)
      .eq('is_available', true)

    if (menuError) {
      console.error('Menu fetch error:', menuError)
      return new Response(
        JSON.stringify({ error: 'Failed to validate menu items' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Create lookup map
    const menuItemMap = new Map(
      menuItems?.map(m => [m.id, m]) || []
    )

    // 4. Validate each item and calculate SERVER-SIDE prices
    let subtotal = 0
    const validatedItems: Array<{
      menu_item_id: number
      item_name: string
      item_price: number
      quantity: number
      selected_options: Record<string, string[]>
      portion_selections: Record<string, string>
      line_total: number
    }> = []

    for (const item of items) {
      // Check item exists
      const menuItem = menuItemMap.get(item.menu_item_id)
      if (!menuItem) {
        return new Response(
          JSON.stringify({ error: `Menu item ${item.menu_item_id} not found or unavailable` }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      // Validate quantity
      const qty = Math.floor(Number(item.quantity))
      if (isNaN(qty) || qty < 1 || qty > 99) {
        return new Response(
          JSON.stringify({ error: `Invalid quantity for ${menuItem.name} (must be 1-99)` }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      // Calculate base price
      let itemPrice = menuItem.base_price

      // Add customization costs (portion-based pricing)
      if (item.portion_selections && menuItem.menu_item_customizations) {
        for (const [customizationId, portion] of Object.entries(item.portion_selections)) {
          const customization = menuItem.menu_item_customizations.find(
            (c: any) => c.id === parseInt(customizationId)
          )
          if (customization?.portion_pricing?.[portion]) {
            itemPrice += customization.portion_pricing[portion]
          }
        }
      }

      const lineTotal = itemPrice * qty
      subtotal += lineTotal

      validatedItems.push({
        menu_item_id: item.menu_item_id,
        item_name: menuItem.name,
        item_price: itemPrice,
        quantity: qty,
        selected_options: item.selected_options || {},
        portion_selections: item.portion_selections || {},
        line_total: lineTotal,
      })
    }

    // 5. Calculate tax SERVER-SIDE
    const taxRate = store.tax_rate || 0.08 // Default 8% if not set
    const tax = Math.round(subtotal * taxRate * 100) / 100
    const total = Math.round((subtotal + tax) * 100) / 100

    // 6. Validate total is reasonable
    if (total <= 0) {
      return new Response(
        JSON.stringify({ error: 'Invalid order total' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (total > 10000) {
      return new Response(
        JSON.stringify({ error: 'Order total exceeds maximum ($10,000). Please contact us for large orders.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 7. Sanitize customer data
    const sanitizedName = customer_name?.trim().slice(0, 100) || 'Guest'
    const sanitizedEmail = customer_email?.trim().toLowerCase().slice(0, 255) || null
    const sanitizedPhone = customer_phone?.replace(/[^\d+\-() ]/g, '').slice(0, 20) || null
    const sanitizedInstructions = special_instructions?.trim().slice(0, 500) || null

    // Basic email validation if provided
    if (sanitizedEmail && !sanitizedEmail.match(/^[^\s@]+@[^\s@]+\.[^\s@]+$/)) {
      return new Response(
        JSON.stringify({ error: 'Invalid email format' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // =========================================
    // ORDER CREATION PHASE
    // =========================================

    // Generate tracking token
    const trackingToken = crypto.randomUUID()

    // Create order with SERVER-calculated prices
    const { data: order, error: orderError } = await supabase
      .from('orders')
      .insert({
        store_id,
        customer_name: sanitizedName,
        customer_email: sanitizedEmail,
        customer_phone: sanitizedPhone,
        special_instructions: sanitizedInstructions,
        order_type,
        subtotal,
        tax,
        total,
        status: 'pending',
        tracking_token: trackingToken,
      })
      .select('id, order_number, tracking_token, created_at')
      .single()

    if (orderError) {
      console.error('Order creation failed:', orderError)
      return new Response(
        JSON.stringify({ error: 'Failed to create order. Please try again.' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Insert validated order items
    const orderItems = validatedItems.map(item => ({
      order_id: order.id,
      menu_item_id: item.menu_item_id,
      item_name: item.item_name,
      item_price: item.item_price,
      quantity: item.quantity,
      selected_options: item.selected_options,
      portion_selections: item.portion_selections,
    }))

    const { error: itemsError } = await supabase
      .from('order_items')
      .insert(orderItems)

    if (itemsError) {
      console.error('Order items creation failed:', itemsError)
      // Rollback order
      await supabase.from('orders').delete().eq('id', order.id)
      return new Response(
        JSON.stringify({ error: 'Failed to create order items. Please try again.' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // =========================================
    // SUCCESS RESPONSE
    // =========================================

    const baseUrl = Deno.env.get('SITE_URL') || 'https://knockbites.com'

    return new Response(
      JSON.stringify({
        success: true,
        order: {
          id: order.id,
          order_number: order.order_number,
          tracking_token: order.tracking_token,
          subtotal,
          tax,
          total,
          items: validatedItems.map(i => ({
            name: i.item_name,
            quantity: i.quantity,
            price: i.item_price,
            line_total: i.line_total,
          })),
        },
        tracking_url: `${baseUrl}/order/tracking/${order.id}?token=${order.tracking_token}`,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('Checkout error:', error)
    return new Response(
      JSON.stringify({ error: 'An unexpected error occurred. Please try again.' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
