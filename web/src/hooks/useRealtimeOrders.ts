import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/contexts/AuthContext'
import type { RealtimeChannel } from '@supabase/supabase-js'

export interface Order {
  id: string
  order_number: string
  customer_id: string | null
  store_id: number
  customer_name: string
  customer_phone: string
  customer_email: string | null
  status: 'pending' | 'confirmed' | 'preparing' | 'ready' | 'completed' | 'cancelled'
  priority: 'normal' | 'express' | 'vip'
  subtotal: number
  tax: number
  tip: number
  total: number
  order_type: 'pickup' | 'delivery'
  estimated_ready_at: string | null
  completed_at: string | null
  special_instructions: string | null
  is_repeat_customer: boolean
  created_at: string
  updated_at: string
  order_items?: OrderItem[]
}

export interface OrderItem {
  id: number
  order_id: string
  menu_item_id: number | null
  item_name: string
  item_price: number
  quantity: number
  customizations: any[]
  subtotal: number
  notes: string | null
}

interface UseRealtimeOrdersOptions {
  storeId?: number
  status?: Order['status']
  limit?: number
  includeAll?: boolean // Include completed and cancelled orders
}

export function useRealtimeOrders(options: UseRealtimeOrdersOptions = {}) {
  const { storeId, status, limit, includeAll } = options
  const [orders, setOrders] = useState<Order[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const { profile } = useAuth()

  useEffect(() => {
    let channel: RealtimeChannel | null = null

    const fetchOrders = async () => {
      try {
        let query = supabase
          .from('orders')
          .select(`
            *,
            order_items (*)
          `)
          .order('created_at', { ascending: false })

        // Filter by store for non-super_admin users (only if profile exists)
        if (profile && profile.role !== 'super_admin') {
          if (profile.store_id) {
            query = query.eq('store_id', profile.store_id)
          }
        } else if (storeId) {
          query = query.eq('store_id', storeId)
        }

        // Filter by status if provided
        if (status) {
          query = query.eq('status', status)
        } else if (!includeAll) {
          // By default, exclude completed and cancelled orders (unless includeAll is true)
          query = query.not('status', 'in', '(completed,cancelled)')
        }

        // Apply limit if provided
        if (limit) {
          query = query.limit(limit)
        }

        const { data, error: fetchError } = await query

        if (fetchError) throw fetchError

        setOrders(data || [])
        setError(null)
      } catch (err) {
        console.error('Error fetching orders:', err)
        setError(err instanceof Error ? err.message : 'Failed to fetch orders')
      } finally {
        setLoading(false)
      }
    }

    fetchOrders()

    // Subscribe to real-time changes
    const channelName = `orders-${profile?.store_id || storeId || 'all'}`
    channel = supabase.channel(channelName)

    // Build filter for realtime subscription (only if we have a profile with store restrictions)
    let realtimeFilter: string | undefined = undefined
    if (profile && profile.role !== 'super_admin' && profile.store_id) {
      realtimeFilter = `store_id=eq.${profile.store_id}`
    } else if (storeId) {
      realtimeFilter = `store_id=eq.${storeId}`
    }

    channel
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'orders',
          filter: realtimeFilter,
        },
        async (payload) => {
          // Fetch full order with items
          const { data } = await supabase
            .from('orders')
            .select(`
              *,
              order_items (*)
            `)
            .eq('id', payload.new.id)
            .single()

          if (data) {
            setOrders((current) => [data as Order, ...current])
          }
        }
      )
      .on(
        'postgres_changes',
        {
          event: 'UPDATE',
          schema: 'public',
          table: 'orders',
          filter: realtimeFilter,
        },
        async (payload) => {
          // Fetch updated order with items
          const { data } = await supabase
            .from('orders')
            .select(`
              *,
              order_items (*)
            `)
            .eq('id', payload.new.id)
            .single()

          if (data) {
            setOrders((current) =>
              current.map((order) =>
                order.id === data.id ? (data as Order) : order
              )
            )
          }
        }
      )
      .on(
        'postgres_changes',
        {
          event: 'DELETE',
          schema: 'public',
          table: 'orders',
          filter: realtimeFilter,
        },
        (payload) => {
          setOrders((current) =>
            current.filter((order) => order.id !== payload.old.id)
          )
        }
      )
      .subscribe()

    return () => {
      if (channel) {
        supabase.removeChannel(channel)
      }
    }
  }, [profile, storeId, status, limit, includeAll])

  const updateOrderStatus = async (
    orderId: string,
    newStatus: Order['status']
  ): Promise<{ success: boolean; error?: string }> => {
    try {
      const { error } = await supabase
        .from('orders')
        .update({
          status: newStatus,
          ...(newStatus === 'completed' && { completed_at: new Date().toISOString() }),
        })
        .eq('id', orderId)

      if (error) throw error

      return { success: true }
    } catch (err) {
      console.error('Error updating order status:', err)
      return {
        success: false,
        error: err instanceof Error ? err.message : 'Failed to update order status',
      }
    }
  }

  return {
    orders,
    loading,
    error,
    updateOrderStatus,
  }
}
