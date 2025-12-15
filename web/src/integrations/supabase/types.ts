export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "13.0.5"
  }
  public: {
    Tables: {
      automated_campaigns: {
        Row: {
          campaign_type: string | null
          coupon_id: number | null
          created_at: string | null
          description: string | null
          id: number
          is_active: boolean | null
          name: string
          notification_body: string | null
          notification_title: string | null
          store_id: number | null
          total_converted: number | null
          total_triggered: number | null
          trigger_condition: Json | null
          trigger_delay_hours: number | null
          trigger_event: string | null
          updated_at: string | null
        }
        Insert: {
          campaign_type?: string | null
          coupon_id?: number | null
          created_at?: string | null
          description?: string | null
          id?: number
          is_active?: boolean | null
          name: string
          notification_body?: string | null
          notification_title?: string | null
          store_id?: number | null
          total_converted?: number | null
          total_triggered?: number | null
          trigger_condition?: Json | null
          trigger_delay_hours?: number | null
          trigger_event?: string | null
          updated_at?: string | null
        }
        Update: {
          campaign_type?: string | null
          coupon_id?: number | null
          created_at?: string | null
          description?: string | null
          id?: number
          is_active?: boolean | null
          name?: string
          notification_body?: string | null
          notification_title?: string | null
          store_id?: number | null
          total_converted?: number | null
          total_triggered?: number | null
          trigger_condition?: Json | null
          trigger_delay_hours?: number | null
          trigger_event?: string | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "automated_campaigns_coupon_id_fkey"
            columns: ["coupon_id"]
            isOneToOne: false
            referencedRelation: "coupons"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "automated_campaigns_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "analytics_store_summary"
            referencedColumns: ["store_id"]
          },
          {
            foreignKeyName: "automated_campaigns_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "stores"
            referencedColumns: ["id"]
          },
        ]
      }
      campaign_executions: {
        Row: {
          campaign_id: number | null
          conversion_order_id: string | null
          converted: boolean | null
          converted_at: string | null
          customer_id: number | null
          id: number
          notification_id: number | null
          triggered_at: string | null
        }
        Insert: {
          campaign_id?: number | null
          conversion_order_id?: string | null
          converted?: boolean | null
          converted_at?: string | null
          customer_id?: number | null
          id?: number
          notification_id?: number | null
          triggered_at?: string | null
        }
        Update: {
          campaign_id?: number | null
          conversion_order_id?: string | null
          converted?: boolean | null
          converted_at?: string | null
          customer_id?: number | null
          id?: number
          notification_id?: number | null
          triggered_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "campaign_executions_campaign_id_fkey"
            columns: ["campaign_id"]
            isOneToOne: false
            referencedRelation: "automated_campaigns"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "campaign_executions_conversion_order_id_fkey"
            columns: ["conversion_order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "campaign_executions_notification_id_fkey"
            columns: ["notification_id"]
            isOneToOne: false
            referencedRelation: "push_notifications"
            referencedColumns: ["id"]
          },
        ]
      }
      coupon_usage: {
        Row: {
          coupon_id: number | null
          customer_id: number | null
          discount_amount: number
          id: number
          order_id: string | null
          used_at: string | null
        }
        Insert: {
          coupon_id?: number | null
          customer_id?: number | null
          discount_amount: number
          id?: number
          order_id?: string | null
          used_at?: string | null
        }
        Update: {
          coupon_id?: number | null
          customer_id?: number | null
          discount_amount?: number
          id?: number
          order_id?: string | null
          used_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "coupon_usage_coupon_id_fkey"
            columns: ["coupon_id"]
            isOneToOne: false
            referencedRelation: "coupons"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "coupon_usage_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
        ]
      }
      coupons: {
        Row: {
          active_days_of_week: number[] | null
          active_hours_end: string | null
          active_hours_start: string | null
          applicable_menu_categories: number[] | null
          applicable_order_types: string[] | null
          code: string
          created_at: string | null
          created_by: string | null
          current_uses: number | null
          description: string | null
          discount_type: string
          discount_value: number
          end_date: string | null
          first_order_only: boolean | null
          id: number
          is_active: boolean | null
          is_featured: boolean | null
          max_discount_amount: number | null
          max_uses_per_customer: number | null
          max_uses_total: number | null
          min_order_value: number | null
          minimum_tier_id: number | null
          name: string
          start_date: string
          store_id: number | null
          target_segment: string | null
          updated_at: string | null
        }
        Insert: {
          active_days_of_week?: number[] | null
          active_hours_end?: string | null
          active_hours_start?: string | null
          applicable_menu_categories?: number[] | null
          applicable_order_types?: string[] | null
          code: string
          created_at?: string | null
          created_by?: string | null
          current_uses?: number | null
          description?: string | null
          discount_type: string
          discount_value: number
          end_date?: string | null
          first_order_only?: boolean | null
          id?: number
          is_active?: boolean | null
          is_featured?: boolean | null
          max_discount_amount?: number | null
          max_uses_per_customer?: number | null
          max_uses_total?: number | null
          min_order_value?: number | null
          minimum_tier_id?: number | null
          name: string
          start_date: string
          store_id?: number | null
          target_segment?: string | null
          updated_at?: string | null
        }
        Update: {
          active_days_of_week?: number[] | null
          active_hours_end?: string | null
          active_hours_start?: string | null
          applicable_menu_categories?: number[] | null
          applicable_order_types?: string[] | null
          code?: string
          created_at?: string | null
          created_by?: string | null
          current_uses?: number | null
          description?: string | null
          discount_type?: string
          discount_value?: number
          end_date?: string | null
          first_order_only?: boolean | null
          id?: number
          is_active?: boolean | null
          is_featured?: boolean | null
          max_discount_amount?: number | null
          max_uses_per_customer?: number | null
          max_uses_total?: number | null
          min_order_value?: number | null
          minimum_tier_id?: number | null
          name?: string
          start_date?: string
          store_id?: number | null
          target_segment?: string | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "coupons_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "coupons_minimum_tier_id_fkey"
            columns: ["minimum_tier_id"]
            isOneToOne: false
            referencedRelation: "loyalty_tiers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "coupons_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "analytics_store_summary"
            referencedColumns: ["store_id"]
          },
          {
            foreignKeyName: "coupons_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "stores"
            referencedColumns: ["id"]
          },
        ]
      }
      customer_addresses: {
        Row: {
          apartment: string | null
          city: string
          created_at: string | null
          customer_id: string
          delivery_instructions: string | null
          id: number
          is_default: boolean | null
          label: string | null
          phone_number: string | null
          state: string
          street_address: string
          updated_at: string | null
          zip_code: string
        }
        Insert: {
          apartment?: string | null
          city: string
          created_at?: string | null
          customer_id: string
          delivery_instructions?: string | null
          id?: number
          is_default?: boolean | null
          label?: string | null
          phone_number?: string | null
          state: string
          street_address: string
          updated_at?: string | null
          zip_code: string
        }
        Update: {
          apartment?: string | null
          city?: string
          created_at?: string | null
          customer_id?: string
          delivery_instructions?: string | null
          id?: number
          is_default?: boolean | null
          label?: string | null
          phone_number?: string | null
          state?: string
          street_address?: string
          updated_at?: string | null
          zip_code?: string
        }
        Relationships: []
      }
      customer_favorites: {
        Row: {
          created_at: string | null
          customer_id: string
          id: number
          menu_item_id: number
        }
        Insert: {
          created_at?: string | null
          customer_id: string
          id?: number
          menu_item_id: number
        }
        Update: {
          created_at?: string | null
          customer_id?: string
          id?: number
          menu_item_id?: number
        }
        Relationships: []
      }
      customer_loyalty: {
        Row: {
          current_tier_id: number | null
          customer_id: number | null
          id: number
          joined_at: string | null
          last_order_at: string | null
          lifetime_points: number | null
          program_id: number | null
          total_orders: number | null
          total_points: number | null
          total_spent: number | null
          updated_at: string | null
        }
        Insert: {
          current_tier_id?: number | null
          customer_id?: number | null
          id?: number
          joined_at?: string | null
          last_order_at?: string | null
          lifetime_points?: number | null
          program_id?: number | null
          total_orders?: number | null
          total_points?: number | null
          total_spent?: number | null
          updated_at?: string | null
        }
        Update: {
          current_tier_id?: number | null
          customer_id?: number | null
          id?: number
          joined_at?: string | null
          last_order_at?: string | null
          lifetime_points?: number | null
          program_id?: number | null
          total_orders?: number | null
          total_points?: number | null
          total_spent?: number | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "customer_loyalty_current_tier_id_fkey"
            columns: ["current_tier_id"]
            isOneToOne: false
            referencedRelation: "loyalty_tiers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "customer_loyalty_program_id_fkey"
            columns: ["program_id"]
            isOneToOne: false
            referencedRelation: "loyalty_programs"
            referencedColumns: ["id"]
          },
        ]
      }
      customer_rewards: {
        Row: {
          created_at: string | null
          customer_id: string | null
          id: number
          points: number | null
          tier: string | null
          total_orders: number | null
          total_spent: number | null
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          customer_id?: string | null
          id?: number
          points?: number | null
          tier?: string | null
          total_orders?: number | null
          total_spent?: number | null
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          customer_id?: string | null
          id?: number
          points?: number | null
          tier?: string | null
          total_orders?: number | null
          total_spent?: number | null
          updated_at?: string | null
        }
        Relationships: []
      }
      customers: {
        Row: {
          avatar_url: string | null
          created_at: string | null
          email: string | null
          full_name: string | null
          id: string
          phone: string | null
          updated_at: string | null
        }
        Insert: {
          avatar_url?: string | null
          created_at?: string | null
          email?: string | null
          full_name?: string | null
          id: string
          phone?: string | null
          updated_at?: string | null
        }
        Update: {
          avatar_url?: string | null
          created_at?: string | null
          email?: string | null
          full_name?: string | null
          id?: string
          phone?: string | null
          updated_at?: string | null
        }
        Relationships: []
      }
      daily_analytics: {
        Row: {
          average_order_value: number | null
          created_at: string | null
          date: string
          id: number
          new_customers: number | null
          store_id: number | null
          top_items: Json | null
          total_orders: number | null
          total_revenue: number | null
        }
        Insert: {
          average_order_value?: number | null
          created_at?: string | null
          date: string
          id?: number
          new_customers?: number | null
          store_id?: number | null
          top_items?: Json | null
          total_orders?: number | null
          total_revenue?: number | null
        }
        Update: {
          average_order_value?: number | null
          created_at?: string | null
          date?: string
          id?: number
          new_customers?: number | null
          store_id?: number | null
          top_items?: Json | null
          total_orders?: number | null
          total_revenue?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "daily_analytics_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "analytics_store_summary"
            referencedColumns: ["store_id"]
          },
          {
            foreignKeyName: "daily_analytics_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "stores"
            referencedColumns: ["id"]
          },
        ]
      }
      ingredient_templates: {
        Row: {
          category: string
          created_at: string | null
          default_portion: string | null
          display_order: number | null
          id: number
          is_active: boolean | null
          name: string
          portion_pricing: Json | null
          supports_portions: boolean | null
          updated_at: string | null
        }
        Insert: {
          category: string
          created_at?: string | null
          default_portion?: string | null
          display_order?: number | null
          id?: number
          is_active?: boolean | null
          name: string
          portion_pricing?: Json | null
          supports_portions?: boolean | null
          updated_at?: string | null
        }
        Update: {
          category?: string
          created_at?: string | null
          default_portion?: string | null
          display_order?: number | null
          id?: number
          is_active?: boolean | null
          name?: string
          portion_pricing?: Json | null
          supports_portions?: boolean | null
          updated_at?: string | null
        }
        Relationships: []
      }
      loyalty_programs: {
        Row: {
          created_at: string | null
          id: number
          is_active: boolean | null
          name: string
          points_per_dollar: number | null
          referral_bonus_points: number | null
          store_id: number | null
          updated_at: string | null
          welcome_bonus_points: number | null
        }
        Insert: {
          created_at?: string | null
          id?: number
          is_active?: boolean | null
          name?: string
          points_per_dollar?: number | null
          referral_bonus_points?: number | null
          store_id?: number | null
          updated_at?: string | null
          welcome_bonus_points?: number | null
        }
        Update: {
          created_at?: string | null
          id?: number
          is_active?: boolean | null
          name?: string
          points_per_dollar?: number | null
          referral_bonus_points?: number | null
          store_id?: number | null
          updated_at?: string | null
          welcome_bonus_points?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "loyalty_programs_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "analytics_store_summary"
            referencedColumns: ["store_id"]
          },
          {
            foreignKeyName: "loyalty_programs_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "stores"
            referencedColumns: ["id"]
          },
        ]
      }
      loyalty_tiers: {
        Row: {
          birthday_reward_points: number | null
          created_at: string | null
          discount_percentage: number | null
          early_access_promos: boolean | null
          free_delivery: boolean | null
          id: number
          min_points: number
          name: string
          priority_support: boolean | null
          program_id: number | null
          sort_order: number
          tier_color: string | null
        }
        Insert: {
          birthday_reward_points?: number | null
          created_at?: string | null
          discount_percentage?: number | null
          early_access_promos?: boolean | null
          free_delivery?: boolean | null
          id?: number
          min_points: number
          name: string
          priority_support?: boolean | null
          program_id?: number | null
          sort_order: number
          tier_color?: string | null
        }
        Update: {
          birthday_reward_points?: number | null
          created_at?: string | null
          discount_percentage?: number | null
          early_access_promos?: boolean | null
          free_delivery?: boolean | null
          id?: number
          min_points?: number
          name?: string
          priority_support?: boolean | null
          program_id?: number | null
          sort_order?: number
          tier_color?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "loyalty_tiers_program_id_fkey"
            columns: ["program_id"]
            isOneToOne: false
            referencedRelation: "loyalty_programs"
            referencedColumns: ["id"]
          },
        ]
      }
      loyalty_transactions: {
        Row: {
          balance_after: number
          created_at: string | null
          customer_loyalty_id: number | null
          id: number
          order_id: string | null
          points: number
          reason: string | null
          transaction_type: string
        }
        Insert: {
          balance_after: number
          created_at?: string | null
          customer_loyalty_id?: number | null
          id?: number
          order_id?: string | null
          points: number
          reason?: string | null
          transaction_type: string
        }
        Update: {
          balance_after?: number
          created_at?: string | null
          customer_loyalty_id?: number | null
          id?: number
          order_id?: string | null
          points?: number
          reason?: string | null
          transaction_type?: string
        }
        Relationships: [
          {
            foreignKeyName: "loyalty_transactions_customer_loyalty_id_fkey"
            columns: ["customer_loyalty_id"]
            isOneToOne: false
            referencedRelation: "customer_loyalty"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "loyalty_transactions_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
        ]
      }
      menu_categories: {
        Row: {
          created_at: string | null
          description: string | null
          display_order: number | null
          id: number
          is_active: boolean | null
          name: string
        }
        Insert: {
          created_at?: string | null
          description?: string | null
          display_order?: number | null
          id?: number
          is_active?: boolean | null
          name: string
        }
        Update: {
          created_at?: string | null
          description?: string | null
          display_order?: number | null
          id?: number
          is_active?: boolean | null
          name?: string
        }
        Relationships: []
      }
      menu_item_customizations: {
        Row: {
          category: string | null
          default_portion: string | null
          display_order: number | null
          id: number
          is_required: boolean | null
          menu_item_id: number | null
          name: string
          options: Json
          portion_pricing: Json | null
          supports_portions: boolean | null
          type: string | null
        }
        Insert: {
          category?: string | null
          default_portion?: string | null
          display_order?: number | null
          id?: number
          is_required?: boolean | null
          menu_item_id?: number | null
          name: string
          options: Json
          portion_pricing?: Json | null
          supports_portions?: boolean | null
          type?: string | null
        }
        Update: {
          category?: string | null
          default_portion?: string | null
          display_order?: number | null
          id?: number
          is_required?: boolean | null
          menu_item_id?: number | null
          name?: string
          options?: Json
          portion_pricing?: Json | null
          supports_portions?: boolean | null
          type?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "menu_item_customizations_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "menu_items"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "menu_item_customizations_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "menu_items_view"
            referencedColumns: ["id"]
          },
        ]
      }
      menu_items: {
        Row: {
          allergens: string[] | null
          base_price: number
          calories: number | null
          category_id: number | null
          created_at: string | null
          description: string | null
          id: number
          image_url: string | null
          is_available: boolean | null
          is_featured: boolean | null
          name: string
          preparation_time: number | null
          price: number | null
          tags: string[] | null
          updated_at: string | null
        }
        Insert: {
          allergens?: string[] | null
          base_price: number
          calories?: number | null
          category_id?: number | null
          created_at?: string | null
          description?: string | null
          id?: number
          image_url?: string | null
          is_available?: boolean | null
          is_featured?: boolean | null
          name: string
          preparation_time?: number | null
          price?: number | null
          tags?: string[] | null
          updated_at?: string | null
        }
        Update: {
          allergens?: string[] | null
          base_price?: number
          calories?: number | null
          category_id?: number | null
          created_at?: string | null
          description?: string | null
          id?: number
          image_url?: string | null
          is_available?: boolean | null
          is_featured?: boolean | null
          name?: string
          preparation_time?: number | null
          price?: number | null
          tags?: string[] | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "menu_items_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "analytics_category_distribution"
            referencedColumns: ["category_id"]
          },
          {
            foreignKeyName: "menu_items_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "menu_items_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "menu_categories"
            referencedColumns: ["id"]
          },
        ]
      }
      notification_deliveries: {
        Row: {
          clicked_at: string | null
          created_at: string | null
          customer_id: number | null
          delivered_at: string | null
          delivery_status: string | null
          device_token: string | null
          error_message: string | null
          id: number
          notification_id: number | null
          opened_at: string | null
          sent_at: string | null
        }
        Insert: {
          clicked_at?: string | null
          created_at?: string | null
          customer_id?: number | null
          delivered_at?: string | null
          delivery_status?: string | null
          device_token?: string | null
          error_message?: string | null
          id?: number
          notification_id?: number | null
          opened_at?: string | null
          sent_at?: string | null
        }
        Update: {
          clicked_at?: string | null
          created_at?: string | null
          customer_id?: number | null
          delivered_at?: string | null
          delivery_status?: string | null
          device_token?: string | null
          error_message?: string | null
          id?: number
          notification_id?: number | null
          opened_at?: string | null
          sent_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "notification_deliveries_notification_id_fkey"
            columns: ["notification_id"]
            isOneToOne: false
            referencedRelation: "push_notifications"
            referencedColumns: ["id"]
          },
        ]
      }
      order_items: {
        Row: {
          customizations: string[] | null
          id: number
          item_name: string
          item_price: number
          menu_item_id: number | null
          notes: string | null
          order_id: string | null
          quantity: number
          selected_options: Json | null
          subtotal: number
        }
        Insert: {
          customizations?: string[] | null
          id?: number
          item_name: string
          item_price: number
          menu_item_id?: number | null
          notes?: string | null
          order_id?: string | null
          quantity?: number
          selected_options?: Json | null
          subtotal: number
        }
        Update: {
          customizations?: string[] | null
          id?: number
          item_name?: string
          item_price?: number
          menu_item_id?: number | null
          notes?: string | null
          order_id?: string | null
          quantity?: number
          selected_options?: Json | null
          subtotal?: number
        }
        Relationships: [
          {
            foreignKeyName: "order_items_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "menu_items"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "order_items_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "menu_items_view"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "order_items_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
        ]
      }
      order_sequences: {
        Row: {
          date_key: string
          sequence_number: number
          store_id: number
        }
        Insert: {
          date_key: string
          sequence_number?: number
          store_id: number
        }
        Update: {
          date_key?: string
          sequence_number?: number
          store_id?: number
        }
        Relationships: [
          {
            foreignKeyName: "order_sequences_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "analytics_store_summary"
            referencedColumns: ["store_id"]
          },
          {
            foreignKeyName: "order_sequences_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "stores"
            referencedColumns: ["id"]
          },
        ]
      }
      order_status_history: {
        Row: {
          changed_by: string | null
          created_at: string | null
          id: number
          new_status: string
          notes: string | null
          order_id: string | null
          previous_status: string | null
        }
        Insert: {
          changed_by?: string | null
          created_at?: string | null
          id?: number
          new_status: string
          notes?: string | null
          order_id?: string | null
          previous_status?: string | null
        }
        Update: {
          changed_by?: string | null
          created_at?: string | null
          id?: number
          new_status?: string
          notes?: string | null
          order_id?: string | null
          previous_status?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "order_status_history_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
        ]
      }
      orders: {
        Row: {
          completed_at: string | null
          created_at: string | null
          customer_email: string | null
          customer_id: string | null
          customer_name: string
          customer_phone: string
          estimated_ready_at: string | null
          id: string
          is_repeat_customer: boolean | null
          order_number: string
          order_type: string | null
          priority: string | null
          special_instructions: string | null
          status: string
          store_id: number
          subtotal: number
          tax: number
          tip: number | null
          total: number
          updated_at: string | null
          user_id: string | null
        }
        Insert: {
          completed_at?: string | null
          created_at?: string | null
          customer_email?: string | null
          customer_id?: string | null
          customer_name: string
          customer_phone: string
          estimated_ready_at?: string | null
          id?: string
          is_repeat_customer?: boolean | null
          order_number: string
          order_type?: string | null
          priority?: string | null
          special_instructions?: string | null
          status?: string
          store_id: number
          subtotal: number
          tax: number
          tip?: number | null
          total: number
          updated_at?: string | null
          user_id?: string | null
        }
        Update: {
          completed_at?: string | null
          created_at?: string | null
          customer_email?: string | null
          customer_id?: string | null
          customer_name?: string
          customer_phone?: string
          estimated_ready_at?: string | null
          id?: string
          is_repeat_customer?: boolean | null
          order_number?: string
          order_type?: string | null
          priority?: string | null
          special_instructions?: string | null
          status?: string
          store_id?: number
          subtotal?: number
          tax?: number
          tip?: number | null
          total?: number
          updated_at?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "orders_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "analytics_store_summary"
            referencedColumns: ["store_id"]
          },
          {
            foreignKeyName: "orders_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "stores"
            referencedColumns: ["id"]
          },
        ]
      }
      permission_changes: {
        Row: {
          change_type: string
          changed_at: string | null
          changed_by: string
          id: number
          ip_address: unknown
          metadata: Json | null
          new_permissions: Json | null
          new_role: string | null
          new_stores: number[] | null
          old_permissions: Json | null
          old_role: string | null
          old_stores: number[] | null
          reason: string | null
          user_agent: string | null
          user_id: string
        }
        Insert: {
          change_type: string
          changed_at?: string | null
          changed_by: string
          id?: number
          ip_address?: unknown
          metadata?: Json | null
          new_permissions?: Json | null
          new_role?: string | null
          new_stores?: number[] | null
          old_permissions?: Json | null
          old_role?: string | null
          old_stores?: number[] | null
          reason?: string | null
          user_agent?: string | null
          user_id: string
        }
        Update: {
          change_type?: string
          changed_at?: string | null
          changed_by?: string
          id?: number
          ip_address?: unknown
          metadata?: Json | null
          new_permissions?: Json | null
          new_role?: string | null
          new_stores?: number[] | null
          old_permissions?: Json | null
          old_role?: string | null
          old_stores?: number[] | null
          reason?: string | null
          user_agent?: string | null
          user_id?: string
        }
        Relationships: []
      }
      push_notifications: {
        Row: {
          action_url: string | null
          body: string
          clicked_count: number | null
          created_at: string | null
          created_by: string | null
          delivered_count: number | null
          id: number
          image_url: string | null
          opened_count: number | null
          recipients_count: number | null
          scheduled_for: string | null
          send_immediately: boolean | null
          sent_at: string | null
          status: string | null
          store_id: number | null
          target_customer_ids: number[] | null
          target_segment: string | null
          target_tier_ids: number[] | null
          title: string
          updated_at: string | null
        }
        Insert: {
          action_url?: string | null
          body: string
          clicked_count?: number | null
          created_at?: string | null
          created_by?: string | null
          delivered_count?: number | null
          id?: number
          image_url?: string | null
          opened_count?: number | null
          recipients_count?: number | null
          scheduled_for?: string | null
          send_immediately?: boolean | null
          sent_at?: string | null
          status?: string | null
          store_id?: number | null
          target_customer_ids?: number[] | null
          target_segment?: string | null
          target_tier_ids?: number[] | null
          title: string
          updated_at?: string | null
        }
        Update: {
          action_url?: string | null
          body?: string
          clicked_count?: number | null
          created_at?: string | null
          created_by?: string | null
          delivered_count?: number | null
          id?: number
          image_url?: string | null
          opened_count?: number | null
          recipients_count?: number | null
          scheduled_for?: string | null
          send_immediately?: boolean | null
          sent_at?: string | null
          status?: string | null
          store_id?: number | null
          target_customer_ids?: number[] | null
          target_segment?: string | null
          target_tier_ids?: number[] | null
          title?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "push_notifications_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "push_notifications_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "analytics_store_summary"
            referencedColumns: ["store_id"]
          },
          {
            foreignKeyName: "push_notifications_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "stores"
            referencedColumns: ["id"]
          },
        ]
      }
      referral_program: {
        Row: {
          created_at: string | null
          id: number
          is_active: boolean | null
          max_referrals_per_customer: number | null
          min_order_value: number | null
          referee_reward_type: string | null
          referee_reward_value: number | null
          referrer_reward_type: string | null
          referrer_reward_value: number | null
          store_id: number | null
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          id?: number
          is_active?: boolean | null
          max_referrals_per_customer?: number | null
          min_order_value?: number | null
          referee_reward_type?: string | null
          referee_reward_value?: number | null
          referrer_reward_type?: string | null
          referrer_reward_value?: number | null
          store_id?: number | null
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          id?: number
          is_active?: boolean | null
          max_referrals_per_customer?: number | null
          min_order_value?: number | null
          referee_reward_type?: string | null
          referee_reward_value?: number | null
          referrer_reward_type?: string | null
          referrer_reward_value?: number | null
          store_id?: number | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "referral_program_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "analytics_store_summary"
            referencedColumns: ["store_id"]
          },
          {
            foreignKeyName: "referral_program_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "stores"
            referencedColumns: ["id"]
          },
        ]
      }
      referrals: {
        Row: {
          completed_at: string | null
          created_at: string | null
          id: number
          program_id: number | null
          referee_customer_id: number | null
          referee_first_order_id: string | null
          referee_rewarded: boolean | null
          referral_code: string
          referrer_customer_id: number | null
          referrer_reward_order_id: string | null
          referrer_rewarded: boolean | null
          rewarded_at: string | null
          status: string | null
        }
        Insert: {
          completed_at?: string | null
          created_at?: string | null
          id?: number
          program_id?: number | null
          referee_customer_id?: number | null
          referee_first_order_id?: string | null
          referee_rewarded?: boolean | null
          referral_code: string
          referrer_customer_id?: number | null
          referrer_reward_order_id?: string | null
          referrer_rewarded?: boolean | null
          rewarded_at?: string | null
          status?: string | null
        }
        Update: {
          completed_at?: string | null
          created_at?: string | null
          id?: number
          program_id?: number | null
          referee_customer_id?: number | null
          referee_first_order_id?: string | null
          referee_rewarded?: boolean | null
          referral_code?: string
          referrer_customer_id?: number | null
          referrer_reward_order_id?: string | null
          referrer_rewarded?: boolean | null
          rewarded_at?: string | null
          status?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "referrals_program_id_fkey"
            columns: ["program_id"]
            isOneToOne: false
            referencedRelation: "referral_program"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "referrals_referee_first_order_id_fkey"
            columns: ["referee_first_order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "referrals_referrer_reward_order_id_fkey"
            columns: ["referrer_reward_order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
        ]
      }
      rewards_transactions: {
        Row: {
          created_at: string | null
          customer_id: string | null
          description: string | null
          id: number
          order_id: string | null
          points_change: number
          transaction_type: string | null
        }
        Insert: {
          created_at?: string | null
          customer_id?: string | null
          description?: string | null
          id?: number
          order_id?: string | null
          points_change: number
          transaction_type?: string | null
        }
        Update: {
          created_at?: string | null
          customer_id?: string | null
          description?: string | null
          id?: number
          order_id?: string | null
          points_change?: number
          transaction_type?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "rewards_transactions_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
        ]
      }
      spatial_ref_sys: {
        Row: {
          auth_name: string | null
          auth_srid: number | null
          proj4text: string | null
          srid: number
          srtext: string | null
        }
        Insert: {
          auth_name?: string | null
          auth_srid?: number | null
          proj4text?: string | null
          srid: number
          srtext?: string | null
        }
        Update: {
          auth_name?: string | null
          auth_srid?: number | null
          proj4text?: string | null
          srid?: number
          srtext?: string | null
        }
        Relationships: []
      }
      store_assignments: {
        Row: {
          access_level: string | null
          assigned_at: string | null
          assigned_by: string | null
          id: number
          is_primary_store: boolean | null
          notes: string | null
          role_at_store: string
          store_id: number
          user_id: string
        }
        Insert: {
          access_level?: string | null
          assigned_at?: string | null
          assigned_by?: string | null
          id?: number
          is_primary_store?: boolean | null
          notes?: string | null
          role_at_store: string
          store_id: number
          user_id: string
        }
        Update: {
          access_level?: string | null
          assigned_at?: string | null
          assigned_by?: string | null
          id?: number
          is_primary_store?: boolean | null
          notes?: string | null
          role_at_store?: string
          store_id?: number
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "store_assignments_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "analytics_store_summary"
            referencedColumns: ["store_id"]
          },
          {
            foreignKeyName: "store_assignments_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "stores"
            referencedColumns: ["id"]
          },
        ]
      }
      store_menu_items: {
        Row: {
          custom_price: number | null
          id: number
          is_available: boolean | null
          menu_item_id: number | null
          store_id: number | null
        }
        Insert: {
          custom_price?: number | null
          id?: number
          is_available?: boolean | null
          menu_item_id?: number | null
          store_id?: number | null
        }
        Update: {
          custom_price?: number | null
          id?: number
          is_available?: boolean | null
          menu_item_id?: number | null
          store_id?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "store_menu_items_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "menu_items"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "store_menu_items_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "menu_items_view"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "store_menu_items_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "analytics_store_summary"
            referencedColumns: ["store_id"]
          },
          {
            foreignKeyName: "store_menu_items_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "stores"
            referencedColumns: ["id"]
          },
        ]
      }
      stores: {
        Row: {
          address: string
          city: string
          created_at: string | null
          hours: string | null
          id: number
          is_open: boolean | null
          latitude: number
          longitude: number
          name: string
          phone: string | null
          state: string
          store_code: string | null
          store_type: string | null
          updated_at: string | null
          zip: string
        }
        Insert: {
          address: string
          city: string
          created_at?: string | null
          hours?: string | null
          id?: number
          is_open?: boolean | null
          latitude: number
          longitude: number
          name: string
          phone?: string | null
          state?: string
          store_code?: string | null
          store_type?: string | null
          updated_at?: string | null
          zip: string
        }
        Update: {
          address?: string
          city?: string
          created_at?: string | null
          hours?: string | null
          id?: number
          is_open?: boolean | null
          latitude?: number
          longitude?: number
          name?: string
          phone?: string | null
          state?: string
          store_code?: string | null
          store_type?: string | null
          updated_at?: string | null
          zip?: string
        }
        Relationships: []
      }
      user_hierarchy: {
        Row: {
          can_promote_to_level: number
          created_at: string | null
          created_by: string | null
          id: number
          level: number
          manager_id: string | null
          notes: string | null
          reporting_chain: string[] | null
          updated_at: string | null
          user_id: string
        }
        Insert: {
          can_promote_to_level: number
          created_at?: string | null
          created_by?: string | null
          id?: number
          level: number
          manager_id?: string | null
          notes?: string | null
          reporting_chain?: string[] | null
          updated_at?: string | null
          user_id: string
        }
        Update: {
          can_promote_to_level?: number
          created_at?: string | null
          created_by?: string | null
          id?: number
          level?: number
          manager_id?: string | null
          notes?: string | null
          reporting_chain?: string[] | null
          updated_at?: string | null
          user_id?: string
        }
        Relationships: []
      }
      user_profiles: {
        Row: {
          assigned_stores: number[] | null
          avatar_url: string | null
          can_hire_roles: string[] | null
          created_at: string | null
          created_by: string | null
          detailed_permissions: Json | null
          full_name: string
          id: string
          is_active: boolean | null
          is_system_admin: boolean | null
          last_store_access: number | null
          permissions: Json | null
          phone: string | null
          role: string
          store_id: number | null
          updated_at: string | null
        }
        Insert: {
          assigned_stores?: number[] | null
          avatar_url?: string | null
          can_hire_roles?: string[] | null
          created_at?: string | null
          created_by?: string | null
          detailed_permissions?: Json | null
          full_name: string
          id: string
          is_active?: boolean | null
          is_system_admin?: boolean | null
          last_store_access?: number | null
          permissions?: Json | null
          phone?: string | null
          role?: string
          store_id?: number | null
          updated_at?: string | null
        }
        Update: {
          assigned_stores?: number[] | null
          avatar_url?: string | null
          can_hire_roles?: string[] | null
          created_at?: string | null
          created_by?: string | null
          detailed_permissions?: Json | null
          full_name?: string
          id?: string
          is_active?: boolean | null
          is_system_admin?: boolean | null
          last_store_access?: number | null
          permissions?: Json | null
          phone?: string | null
          role?: string
          store_id?: number | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "user_profiles_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "analytics_store_summary"
            referencedColumns: ["store_id"]
          },
          {
            foreignKeyName: "user_profiles_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "stores"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      analytics_category_distribution: {
        Row: {
          category: string | null
          category_id: number | null
          items_sold: number | null
          order_count: number | null
          total_revenue: number | null
        }
        Relationships: []
      }
      analytics_customer_insights: {
        Row: {
          avg_spent_per_customer: number | null
          highest_order: number | null
          lowest_order: number | null
          repeat_customers: number | null
          repeat_rate: number | null
          store_id: number | null
          total_customers: number | null
        }
        Relationships: [
          {
            foreignKeyName: "orders_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "analytics_store_summary"
            referencedColumns: ["store_id"]
          },
          {
            foreignKeyName: "orders_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "stores"
            referencedColumns: ["id"]
          },
        ]
      }
      analytics_daily_stats: {
        Row: {
          avg_order_value: number | null
          date: string | null
          store_id: number | null
          total_orders: number | null
          total_revenue: number | null
          total_tax: number | null
          total_with_tax: number | null
          unique_customers: number | null
        }
        Relationships: [
          {
            foreignKeyName: "orders_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "analytics_store_summary"
            referencedColumns: ["store_id"]
          },
          {
            foreignKeyName: "orders_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "stores"
            referencedColumns: ["id"]
          },
        ]
      }
      analytics_day_of_week: {
        Row: {
          avg_order_value: number | null
          day_name: string | null
          day_number: number | null
          order_count: number | null
          store_id: number | null
          total_revenue: number | null
        }
        Relationships: [
          {
            foreignKeyName: "orders_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "analytics_store_summary"
            referencedColumns: ["store_id"]
          },
          {
            foreignKeyName: "orders_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "stores"
            referencedColumns: ["id"]
          },
        ]
      }
      analytics_hourly_today: {
        Row: {
          hour: number | null
          orders: number | null
          revenue: number | null
          store_id: number | null
        }
        Relationships: [
          {
            foreignKeyName: "orders_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "analytics_store_summary"
            referencedColumns: ["store_id"]
          },
          {
            foreignKeyName: "orders_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "stores"
            referencedColumns: ["id"]
          },
        ]
      }
      analytics_order_funnel: {
        Row: {
          avg_processing_minutes: number | null
          order_count: number | null
          revenue: number | null
          status: string | null
          store_id: number | null
        }
        Relationships: [
          {
            foreignKeyName: "orders_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "analytics_store_summary"
            referencedColumns: ["store_id"]
          },
          {
            foreignKeyName: "orders_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "stores"
            referencedColumns: ["id"]
          },
        ]
      }
      analytics_peak_hours: {
        Row: {
          avg_order_value: number | null
          hour: number | null
          order_count: number | null
          revenue: number | null
          store_id: number | null
        }
        Relationships: [
          {
            foreignKeyName: "orders_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "analytics_store_summary"
            referencedColumns: ["store_id"]
          },
          {
            foreignKeyName: "orders_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "stores"
            referencedColumns: ["id"]
          },
        ]
      }
      analytics_popular_items: {
        Row: {
          avg_price: number | null
          item_name: string | null
          menu_item_id: number | null
          store_id: number | null
          times_ordered: number | null
          total_quantity: number | null
          total_revenue: number | null
        }
        Relationships: [
          {
            foreignKeyName: "order_items_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "menu_items"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "order_items_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "menu_items_view"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "orders_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "analytics_store_summary"
            referencedColumns: ["store_id"]
          },
          {
            foreignKeyName: "orders_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "stores"
            referencedColumns: ["id"]
          },
        ]
      }
      analytics_revenue_goals: {
        Row: {
          avg_daily_orders: number | null
          avg_daily_revenue: number | null
          best_day_revenue: number | null
          orders_goal: number | null
          revenue_goal: number | null
          store_id: number | null
          worst_day_revenue: number | null
        }
        Relationships: [
          {
            foreignKeyName: "orders_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "analytics_store_summary"
            referencedColumns: ["store_id"]
          },
          {
            foreignKeyName: "orders_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "stores"
            referencedColumns: ["id"]
          },
        ]
      }
      analytics_store_summary: {
        Row: {
          avg_order_value: number | null
          repeat_customers: number | null
          store_code: string | null
          store_id: number | null
          store_name: string | null
          total_orders: number | null
          total_revenue: number | null
          unique_customers: number | null
        }
        Relationships: []
      }
      analytics_time_distribution: {
        Row: {
          order_count: number | null
          revenue: number | null
          store_id: number | null
          time_period: string | null
        }
        Relationships: [
          {
            foreignKeyName: "orders_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "analytics_store_summary"
            referencedColumns: ["store_id"]
          },
          {
            foreignKeyName: "orders_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "stores"
            referencedColumns: ["id"]
          },
        ]
      }
      analytics_top_customers: {
        Row: {
          avg_order_value: number | null
          customer_id: string | null
          last_order_date: string | null
          store_id: number | null
          total_orders: number | null
          total_spent: number | null
        }
        Relationships: [
          {
            foreignKeyName: "orders_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "analytics_store_summary"
            referencedColumns: ["store_id"]
          },
          {
            foreignKeyName: "orders_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "stores"
            referencedColumns: ["id"]
          },
        ]
      }
      categories: {
        Row: {
          created_at: string | null
          description: string | null
          display_order: number | null
          id: number | null
          is_active: boolean | null
          name: string | null
          sort_order: number | null
        }
        Insert: {
          created_at?: string | null
          description?: string | null
          display_order?: number | null
          id?: number | null
          is_active?: boolean | null
          name?: string | null
          sort_order?: number | null
        }
        Update: {
          created_at?: string | null
          description?: string | null
          display_order?: number | null
          id?: number | null
          is_active?: boolean | null
          name?: string | null
          sort_order?: number | null
        }
        Relationships: []
      }
      geography_columns: {
        Row: {
          coord_dimension: number | null
          f_geography_column: unknown
          f_table_catalog: unknown
          f_table_name: unknown
          f_table_schema: unknown
          srid: number | null
          type: string | null
        }
        Relationships: []
      }
      geometry_columns: {
        Row: {
          coord_dimension: number | null
          f_geometry_column: unknown
          f_table_catalog: string | null
          f_table_name: unknown
          f_table_schema: unknown
          srid: number | null
          type: string | null
        }
        Insert: {
          coord_dimension?: number | null
          f_geometry_column?: unknown
          f_table_catalog?: string | null
          f_table_name?: unknown
          f_table_schema?: unknown
          srid?: number | null
          type?: string | null
        }
        Update: {
          coord_dimension?: number | null
          f_geometry_column?: unknown
          f_table_catalog?: string | null
          f_table_name?: unknown
          f_table_schema?: unknown
          srid?: number | null
          type?: string | null
        }
        Relationships: []
      }
      menu_items_view: {
        Row: {
          base_price: number | null
          category_id: number | null
          created_at: string | null
          description: string | null
          id: number | null
          image_url: string | null
          is_available: boolean | null
          is_featured: boolean | null
          name: string | null
          preparation_time: number | null
          price: number | null
          tags: string[] | null
        }
        Insert: {
          base_price?: number | null
          category_id?: number | null
          created_at?: string | null
          description?: string | null
          id?: number | null
          image_url?: string | null
          is_available?: boolean | null
          is_featured?: boolean | null
          name?: string | null
          preparation_time?: number | null
          price?: number | null
          tags?: string[] | null
        }
        Update: {
          base_price?: number | null
          category_id?: number | null
          created_at?: string | null
          description?: string | null
          id?: number | null
          image_url?: string | null
          is_available?: boolean | null
          is_featured?: boolean | null
          name?: string | null
          preparation_time?: number | null
          price?: number | null
          tags?: string[] | null
        }
        Relationships: [
          {
            foreignKeyName: "menu_items_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "analytics_category_distribution"
            referencedColumns: ["category_id"]
          },
          {
            foreignKeyName: "menu_items_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "menu_items_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "menu_categories"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Functions: {
      _postgis_deprecate: {
        Args: { newname: string; oldname: string; version: string }
        Returns: undefined
      }
      _postgis_index_extent: {
        Args: { col: string; tbl: unknown }
        Returns: unknown
      }
      _postgis_pgsql_version: { Args: never; Returns: string }
      _postgis_scripts_pgsql_version: { Args: never; Returns: string }
      _postgis_selectivity: {
        Args: { att_name: string; geom: unknown; mode?: string; tbl: unknown }
        Returns: number
      }
      _postgis_stats: {
        Args: { ""?: string; att_name: string; tbl: unknown }
        Returns: string
      }
      _st_3dintersects: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_contains: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_containsproperly: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_coveredby:
        | { Args: { geog1: unknown; geog2: unknown }; Returns: boolean }
        | { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      _st_covers:
        | { Args: { geog1: unknown; geog2: unknown }; Returns: boolean }
        | { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      _st_crosses: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_dwithin: {
        Args: {
          geog1: unknown
          geog2: unknown
          tolerance: number
          use_spheroid?: boolean
        }
        Returns: boolean
      }
      _st_equals: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      _st_intersects: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_linecrossingdirection: {
        Args: { line1: unknown; line2: unknown }
        Returns: number
      }
      _st_longestline: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      _st_maxdistance: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      _st_orderingequals: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_overlaps: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_sortablehash: { Args: { geom: unknown }; Returns: number }
      _st_touches: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_voronoi: {
        Args: {
          clip?: unknown
          g1: unknown
          return_polygons?: boolean
          tolerance?: number
        }
        Returns: unknown
      }
      _st_within: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      add_standard_sandwich_customizations: {
        Args: {
          p_include_chipotle?: boolean
          p_include_russian?: boolean
          p_menu_item_id: number
        }
        Returns: number
      }
      addauth: { Args: { "": string }; Returns: boolean }
      addgeometrycolumn:
        | {
            Args: {
              column_name: string
              new_dim: number
              new_srid: number
              new_type: string
              schema_name: string
              table_name: string
              use_typmod?: boolean
            }
            Returns: string
          }
        | {
            Args: {
              column_name: string
              new_dim: number
              new_srid: number
              new_type: string
              table_name: string
              use_typmod?: boolean
            }
            Returns: string
          }
        | {
            Args: {
              catalog_name: string
              column_name: string
              new_dim: number
              new_srid_in: number
              new_type: string
              schema_name: string
              table_name: string
              use_typmod?: boolean
            }
            Returns: string
          }
      assign_user_to_store: {
        Args: {
          p_assigned_by: string
          p_is_primary?: boolean
          p_role_at_store: string
          p_store_id: number
          p_user_id: string
        }
        Returns: {
          access_level: string | null
          assigned_at: string | null
          assigned_by: string | null
          id: number
          is_primary_store: boolean | null
          notes: string | null
          role_at_store: string
          store_id: number
          user_id: string
        }
        SetofOptions: {
          from: "*"
          to: "store_assignments"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      can_promote_to_role: {
        Args: { p_new_role: string; p_promoter_id: string; p_target_id: string }
        Returns: boolean
      }
      can_user_manage_by_hierarchy: {
        Args: { p_manager_id: string; p_target_id: string }
        Returns: boolean
      }
      can_user_manage_user: {
        Args: { p_manager_id: string; p_target_user_id: string }
        Returns: boolean
      }
      disablelongtransactions: { Args: never; Returns: string }
      dropgeometrycolumn:
        | {
            Args: {
              column_name: string
              schema_name: string
              table_name: string
            }
            Returns: string
          }
        | { Args: { column_name: string; table_name: string }; Returns: string }
        | {
            Args: {
              catalog_name: string
              column_name: string
              schema_name: string
              table_name: string
            }
            Returns: string
          }
      dropgeometrytable:
        | { Args: { schema_name: string; table_name: string }; Returns: string }
        | { Args: { table_name: string }; Returns: string }
        | {
            Args: {
              catalog_name: string
              schema_name: string
              table_name: string
            }
            Returns: string
          }
      enablelongtransactions: { Args: never; Returns: string }
      equals: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      generate_order_number: { Args: { p_store_id: number }; Returns: string }
      geometry: { Args: { "": string }; Returns: unknown }
      geometry_above: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_below: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_cmp: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      geometry_contained_3d: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_contains: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_contains_3d: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_distance_box: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      geometry_distance_centroid: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      geometry_eq: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_ge: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_gt: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_le: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_left: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_lt: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_overabove: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_overbelow: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_overlaps: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_overlaps_3d: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_overleft: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_overright: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_right: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_same: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_same_3d: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_within: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geomfromewkt: { Args: { "": string }; Returns: unknown }
      get_all_reports: {
        Args: { p_user_id: string }
        Returns: {
          depth: number
          level: number
          user_id: string
          user_name: string
          user_role: string
        }[]
      }
      get_business_insights: { Args: { p_store_id: number }; Returns: Json }
      get_current_user_assigned_stores: { Args: never; Returns: number[] }
      get_current_user_email: { Args: never; Returns: string }
      get_current_user_role: { Args: never; Returns: string }
      get_current_user_store_id: { Args: never; Returns: number }
      get_customer_favorites: {
        Args: { p_customer_id: string }
        Returns: {
          favorited_at: string
          menu_item_id: number
        }[]
      }
      get_direct_reports: {
        Args: { p_user_id: string }
        Returns: {
          created_at: string
          level: number
          user_id: string
          user_name: string
          user_role: string
        }[]
      }
      get_permission_change_stats: {
        Args: { p_days?: number }
        Returns: {
          change_type: string
          count: number
        }[]
      }
      get_recent_permission_changes: {
        Args: { p_days?: number; p_limit?: number }
        Returns: {
          change_id: number
          change_type: string
          changed_at: string
          changed_by_name: string
          new_role: string
          old_role: string
          reason: string
          user_name: string
        }[]
      }
      get_revenue_chart_data: {
        Args: { p_date_range?: string; p_store_id: number }
        Returns: {
          orders: number
          revenue: number
          time_label: string
        }[]
      }
      get_role_level: { Args: { p_role: string }; Returns: number }
      get_store_metrics: {
        Args: { p_date_range?: string; p_store_id: number }
        Returns: {
          avg_order_value: number
          orders_change: number
          revenue_change: number
          total_orders: number
          total_revenue: number
          unique_customers: number
        }[]
      }
      get_top_customers_with_details: {
        Args: { p_limit?: number; p_store_id?: number }
        Returns: {
          avg_order_value: number
          customer_name: string
          customer_phone: string
          last_order_date: string
          store_id: number
          total_orders: number
          total_spent: number
        }[]
      }
      get_user_accessible_stores: {
        Args: { p_user_id: string }
        Returns: {
          store_id: number
        }[]
      }
      get_user_permission_history: {
        Args: { p_limit?: number; p_user_id: string }
        Returns: {
          change_id: number
          change_type: string
          changed_at: string
          changed_by_name: string
          new_role: string
          old_role: string
          reason: string
        }[]
      }
      get_user_stores: {
        Args: { p_user_id: string }
        Returns: {
          assigned_at: string
          is_primary: boolean
          role_at_store: string
          store_id: number
          store_name: string
        }[]
      }
      gettransactionid: { Args: never; Returns: unknown }
      is_current_user_system_admin: { Args: never; Returns: boolean }
      log_permission_change: {
        Args: {
          p_change_type: string
          p_metadata?: Json
          p_new_permissions?: Json
          p_new_role?: string
          p_new_stores?: number[]
          p_old_permissions?: Json
          p_old_role?: string
          p_old_stores?: number[]
          p_reason?: string
          p_user_id: string
        }
        Returns: {
          change_type: string
          changed_at: string | null
          changed_by: string
          id: number
          ip_address: unknown
          metadata: Json | null
          new_permissions: Json | null
          new_role: string | null
          new_stores: number[] | null
          old_permissions: Json | null
          old_role: string | null
          old_stores: number[] | null
          reason: string | null
          user_agent: string | null
          user_id: string
        }
        SetofOptions: {
          from: "*"
          to: "permission_changes"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      longtransactionsenabled: { Args: never; Returns: boolean }
      populate_geometry_columns:
        | { Args: { use_typmod?: boolean }; Returns: string }
        | { Args: { tbl_oid: unknown; use_typmod?: boolean }; Returns: number }
      postgis_constraint_dims: {
        Args: { geomcolumn: string; geomschema: string; geomtable: string }
        Returns: number
      }
      postgis_constraint_srid: {
        Args: { geomcolumn: string; geomschema: string; geomtable: string }
        Returns: number
      }
      postgis_constraint_type: {
        Args: { geomcolumn: string; geomschema: string; geomtable: string }
        Returns: string
      }
      postgis_extensions_upgrade: { Args: never; Returns: string }
      postgis_full_version: { Args: never; Returns: string }
      postgis_geos_version: { Args: never; Returns: string }
      postgis_lib_build_date: { Args: never; Returns: string }
      postgis_lib_revision: { Args: never; Returns: string }
      postgis_lib_version: { Args: never; Returns: string }
      postgis_libjson_version: { Args: never; Returns: string }
      postgis_liblwgeom_version: { Args: never; Returns: string }
      postgis_libprotobuf_version: { Args: never; Returns: string }
      postgis_libxml_version: { Args: never; Returns: string }
      postgis_proj_version: { Args: never; Returns: string }
      postgis_scripts_build_date: { Args: never; Returns: string }
      postgis_scripts_installed: { Args: never; Returns: string }
      postgis_scripts_released: { Args: never; Returns: string }
      postgis_svn_version: { Args: never; Returns: string }
      postgis_type_name: {
        Args: {
          coord_dimension: number
          geomname: string
          use_new_name?: boolean
        }
        Returns: string
      }
      postgis_version: { Args: never; Returns: string }
      postgis_wagyu_version: { Args: never; Returns: string }
      remove_user_from_store: {
        Args: { p_store_id: number; p_user_id: string }
        Returns: boolean
      }
      set_primary_store: {
        Args: { p_store_id: number; p_user_id: string }
        Returns: boolean
      }
      st_3dclosestpoint: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_3ddistance: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      st_3dintersects: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      st_3dlongestline: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_3dmakebox: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_3dmaxdistance: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      st_3dshortestline: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_addpoint: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_angle:
        | { Args: { line1: unknown; line2: unknown }; Returns: number }
        | {
            Args: { pt1: unknown; pt2: unknown; pt3: unknown; pt4?: unknown }
            Returns: number
          }
      st_area:
        | { Args: { geog: unknown; use_spheroid?: boolean }; Returns: number }
        | { Args: { "": string }; Returns: number }
      st_asencodedpolyline: {
        Args: { geom: unknown; nprecision?: number }
        Returns: string
      }
      st_asewkt: { Args: { "": string }; Returns: string }
      st_asgeojson:
        | {
            Args: {
              geom_column?: string
              maxdecimaldigits?: number
              pretty_bool?: boolean
              r: Record<string, unknown>
            }
            Returns: string
          }
        | {
            Args: { geom: unknown; maxdecimaldigits?: number; options?: number }
            Returns: string
          }
        | {
            Args: { geog: unknown; maxdecimaldigits?: number; options?: number }
            Returns: string
          }
        | { Args: { "": string }; Returns: string }
      st_asgml:
        | {
            Args: {
              geom: unknown
              id?: string
              maxdecimaldigits?: number
              nprefix?: string
              options?: number
              version: number
            }
            Returns: string
          }
        | {
            Args: { geom: unknown; maxdecimaldigits?: number; options?: number }
            Returns: string
          }
        | {
            Args: {
              geog: unknown
              id?: string
              maxdecimaldigits?: number
              nprefix?: string
              options?: number
              version: number
            }
            Returns: string
          }
        | {
            Args: {
              geog: unknown
              id?: string
              maxdecimaldigits?: number
              nprefix?: string
              options?: number
            }
            Returns: string
          }
        | { Args: { "": string }; Returns: string }
      st_askml:
        | {
            Args: { geom: unknown; maxdecimaldigits?: number; nprefix?: string }
            Returns: string
          }
        | {
            Args: { geog: unknown; maxdecimaldigits?: number; nprefix?: string }
            Returns: string
          }
        | { Args: { "": string }; Returns: string }
      st_aslatlontext: {
        Args: { geom: unknown; tmpl?: string }
        Returns: string
      }
      st_asmarc21: { Args: { format?: string; geom: unknown }; Returns: string }
      st_asmvtgeom: {
        Args: {
          bounds: unknown
          buffer?: number
          clip_geom?: boolean
          extent?: number
          geom: unknown
        }
        Returns: unknown
      }
      st_assvg:
        | {
            Args: { geom: unknown; maxdecimaldigits?: number; rel?: number }
            Returns: string
          }
        | {
            Args: { geog: unknown; maxdecimaldigits?: number; rel?: number }
            Returns: string
          }
        | { Args: { "": string }; Returns: string }
      st_astext: { Args: { "": string }; Returns: string }
      st_astwkb:
        | {
            Args: {
              geom: unknown[]
              ids: number[]
              prec?: number
              prec_m?: number
              prec_z?: number
              with_boxes?: boolean
              with_sizes?: boolean
            }
            Returns: string
          }
        | {
            Args: {
              geom: unknown
              prec?: number
              prec_m?: number
              prec_z?: number
              with_boxes?: boolean
              with_sizes?: boolean
            }
            Returns: string
          }
      st_asx3d: {
        Args: { geom: unknown; maxdecimaldigits?: number; options?: number }
        Returns: string
      }
      st_azimuth:
        | { Args: { geom1: unknown; geom2: unknown }; Returns: number }
        | { Args: { geog1: unknown; geog2: unknown }; Returns: number }
      st_boundingdiagonal: {
        Args: { fits?: boolean; geom: unknown }
        Returns: unknown
      }
      st_buffer:
        | {
            Args: { geom: unknown; options?: string; radius: number }
            Returns: unknown
          }
        | {
            Args: { geom: unknown; quadsegs: number; radius: number }
            Returns: unknown
          }
      st_centroid: { Args: { "": string }; Returns: unknown }
      st_clipbybox2d: {
        Args: { box: unknown; geom: unknown }
        Returns: unknown
      }
      st_closestpoint: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_collect: { Args: { geom1: unknown; geom2: unknown }; Returns: unknown }
      st_concavehull: {
        Args: {
          param_allow_holes?: boolean
          param_geom: unknown
          param_pctconvex: number
        }
        Returns: unknown
      }
      st_contains: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      st_containsproperly: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      st_coorddim: { Args: { geometry: unknown }; Returns: number }
      st_coveredby:
        | { Args: { geog1: unknown; geog2: unknown }; Returns: boolean }
        | { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      st_covers:
        | { Args: { geog1: unknown; geog2: unknown }; Returns: boolean }
        | { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      st_crosses: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      st_curvetoline: {
        Args: { flags?: number; geom: unknown; tol?: number; toltype?: number }
        Returns: unknown
      }
      st_delaunaytriangles: {
        Args: { flags?: number; g1: unknown; tolerance?: number }
        Returns: unknown
      }
      st_difference: {
        Args: { geom1: unknown; geom2: unknown; gridsize?: number }
        Returns: unknown
      }
      st_disjoint: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      st_distance:
        | { Args: { geom1: unknown; geom2: unknown }; Returns: number }
        | {
            Args: { geog1: unknown; geog2: unknown; use_spheroid?: boolean }
            Returns: number
          }
      st_distancesphere:
        | { Args: { geom1: unknown; geom2: unknown }; Returns: number }
        | {
            Args: { geom1: unknown; geom2: unknown; radius: number }
            Returns: number
          }
      st_distancespheroid: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      st_dwithin: {
        Args: {
          geog1: unknown
          geog2: unknown
          tolerance: number
          use_spheroid?: boolean
        }
        Returns: boolean
      }
      st_equals: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      st_expand:
        | {
            Args: {
              dm?: number
              dx: number
              dy: number
              dz?: number
              geom: unknown
            }
            Returns: unknown
          }
        | {
            Args: { box: unknown; dx: number; dy: number; dz?: number }
            Returns: unknown
          }
        | { Args: { box: unknown; dx: number; dy: number }; Returns: unknown }
      st_force3d: { Args: { geom: unknown; zvalue?: number }; Returns: unknown }
      st_force3dm: {
        Args: { geom: unknown; mvalue?: number }
        Returns: unknown
      }
      st_force3dz: {
        Args: { geom: unknown; zvalue?: number }
        Returns: unknown
      }
      st_force4d: {
        Args: { geom: unknown; mvalue?: number; zvalue?: number }
        Returns: unknown
      }
      st_generatepoints:
        | { Args: { area: unknown; npoints: number }; Returns: unknown }
        | {
            Args: { area: unknown; npoints: number; seed: number }
            Returns: unknown
          }
      st_geogfromtext: { Args: { "": string }; Returns: unknown }
      st_geographyfromtext: { Args: { "": string }; Returns: unknown }
      st_geohash:
        | { Args: { geom: unknown; maxchars?: number }; Returns: string }
        | { Args: { geog: unknown; maxchars?: number }; Returns: string }
      st_geomcollfromtext: { Args: { "": string }; Returns: unknown }
      st_geometricmedian: {
        Args: {
          fail_if_not_converged?: boolean
          g: unknown
          max_iter?: number
          tolerance?: number
        }
        Returns: unknown
      }
      st_geometryfromtext: { Args: { "": string }; Returns: unknown }
      st_geomfromewkt: { Args: { "": string }; Returns: unknown }
      st_geomfromgeojson:
        | { Args: { "": Json }; Returns: unknown }
        | { Args: { "": Json }; Returns: unknown }
        | { Args: { "": string }; Returns: unknown }
      st_geomfromgml: { Args: { "": string }; Returns: unknown }
      st_geomfromkml: { Args: { "": string }; Returns: unknown }
      st_geomfrommarc21: { Args: { marc21xml: string }; Returns: unknown }
      st_geomfromtext: { Args: { "": string }; Returns: unknown }
      st_gmltosql: { Args: { "": string }; Returns: unknown }
      st_hasarc: { Args: { geometry: unknown }; Returns: boolean }
      st_hausdorffdistance: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      st_hexagon: {
        Args: { cell_i: number; cell_j: number; origin?: unknown; size: number }
        Returns: unknown
      }
      st_hexagongrid: {
        Args: { bounds: unknown; size: number }
        Returns: Record<string, unknown>[]
      }
      st_interpolatepoint: {
        Args: { line: unknown; point: unknown }
        Returns: number
      }
      st_intersection: {
        Args: { geom1: unknown; geom2: unknown; gridsize?: number }
        Returns: unknown
      }
      st_intersects:
        | { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
        | { Args: { geog1: unknown; geog2: unknown }; Returns: boolean }
      st_isvaliddetail: {
        Args: { flags?: number; geom: unknown }
        Returns: Database["public"]["CompositeTypes"]["valid_detail"]
        SetofOptions: {
          from: "*"
          to: "valid_detail"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      st_length:
        | { Args: { geog: unknown; use_spheroid?: boolean }; Returns: number }
        | { Args: { "": string }; Returns: number }
      st_letters: { Args: { font?: Json; letters: string }; Returns: unknown }
      st_linecrossingdirection: {
        Args: { line1: unknown; line2: unknown }
        Returns: number
      }
      st_linefromencodedpolyline: {
        Args: { nprecision?: number; txtin: string }
        Returns: unknown
      }
      st_linefromtext: { Args: { "": string }; Returns: unknown }
      st_linelocatepoint: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      st_linetocurve: { Args: { geometry: unknown }; Returns: unknown }
      st_locatealong: {
        Args: { geometry: unknown; leftrightoffset?: number; measure: number }
        Returns: unknown
      }
      st_locatebetween: {
        Args: {
          frommeasure: number
          geometry: unknown
          leftrightoffset?: number
          tomeasure: number
        }
        Returns: unknown
      }
      st_locatebetweenelevations: {
        Args: { fromelevation: number; geometry: unknown; toelevation: number }
        Returns: unknown
      }
      st_longestline: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_makebox2d: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_makeline: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_makevalid: {
        Args: { geom: unknown; params: string }
        Returns: unknown
      }
      st_maxdistance: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      st_minimumboundingcircle: {
        Args: { inputgeom: unknown; segs_per_quarter?: number }
        Returns: unknown
      }
      st_mlinefromtext: { Args: { "": string }; Returns: unknown }
      st_mpointfromtext: { Args: { "": string }; Returns: unknown }
      st_mpolyfromtext: { Args: { "": string }; Returns: unknown }
      st_multilinestringfromtext: { Args: { "": string }; Returns: unknown }
      st_multipointfromtext: { Args: { "": string }; Returns: unknown }
      st_multipolygonfromtext: { Args: { "": string }; Returns: unknown }
      st_node: { Args: { g: unknown }; Returns: unknown }
      st_normalize: { Args: { geom: unknown }; Returns: unknown }
      st_offsetcurve: {
        Args: { distance: number; line: unknown; params?: string }
        Returns: unknown
      }
      st_orderingequals: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      st_overlaps: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      st_perimeter: {
        Args: { geog: unknown; use_spheroid?: boolean }
        Returns: number
      }
      st_pointfromtext: { Args: { "": string }; Returns: unknown }
      st_pointm: {
        Args: {
          mcoordinate: number
          srid?: number
          xcoordinate: number
          ycoordinate: number
        }
        Returns: unknown
      }
      st_pointz: {
        Args: {
          srid?: number
          xcoordinate: number
          ycoordinate: number
          zcoordinate: number
        }
        Returns: unknown
      }
      st_pointzm: {
        Args: {
          mcoordinate: number
          srid?: number
          xcoordinate: number
          ycoordinate: number
          zcoordinate: number
        }
        Returns: unknown
      }
      st_polyfromtext: { Args: { "": string }; Returns: unknown }
      st_polygonfromtext: { Args: { "": string }; Returns: unknown }
      st_project: {
        Args: { azimuth: number; distance: number; geog: unknown }
        Returns: unknown
      }
      st_quantizecoordinates: {
        Args: {
          g: unknown
          prec_m?: number
          prec_x: number
          prec_y?: number
          prec_z?: number
        }
        Returns: unknown
      }
      st_reduceprecision: {
        Args: { geom: unknown; gridsize: number }
        Returns: unknown
      }
      st_relate: { Args: { geom1: unknown; geom2: unknown }; Returns: string }
      st_removerepeatedpoints: {
        Args: { geom: unknown; tolerance?: number }
        Returns: unknown
      }
      st_segmentize: {
        Args: { geog: unknown; max_segment_length: number }
        Returns: unknown
      }
      st_setsrid:
        | { Args: { geom: unknown; srid: number }; Returns: unknown }
        | { Args: { geog: unknown; srid: number }; Returns: unknown }
      st_sharedpaths: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_shortestline: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_simplifypolygonhull: {
        Args: { geom: unknown; is_outer?: boolean; vertex_fraction: number }
        Returns: unknown
      }
      st_split: { Args: { geom1: unknown; geom2: unknown }; Returns: unknown }
      st_square: {
        Args: { cell_i: number; cell_j: number; origin?: unknown; size: number }
        Returns: unknown
      }
      st_squaregrid: {
        Args: { bounds: unknown; size: number }
        Returns: Record<string, unknown>[]
      }
      st_srid:
        | { Args: { geom: unknown }; Returns: number }
        | { Args: { geog: unknown }; Returns: number }
      st_subdivide: {
        Args: { geom: unknown; gridsize?: number; maxvertices?: number }
        Returns: unknown[]
      }
      st_swapordinates: {
        Args: { geom: unknown; ords: unknown }
        Returns: unknown
      }
      st_symdifference: {
        Args: { geom1: unknown; geom2: unknown; gridsize?: number }
        Returns: unknown
      }
      st_symmetricdifference: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_tileenvelope: {
        Args: {
          bounds?: unknown
          margin?: number
          x: number
          y: number
          zoom: number
        }
        Returns: unknown
      }
      st_touches: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      st_transform:
        | { Args: { geom: unknown; to_proj: string }; Returns: unknown }
        | {
            Args: { from_proj: string; geom: unknown; to_srid: number }
            Returns: unknown
          }
        | {
            Args: { from_proj: string; geom: unknown; to_proj: string }
            Returns: unknown
          }
      st_triangulatepolygon: { Args: { g1: unknown }; Returns: unknown }
      st_union:
        | {
            Args: { geom1: unknown; geom2: unknown; gridsize: number }
            Returns: unknown
          }
        | { Args: { geom1: unknown; geom2: unknown }; Returns: unknown }
      st_voronoilines: {
        Args: { extend_to?: unknown; g1: unknown; tolerance?: number }
        Returns: unknown
      }
      st_voronoipolygons: {
        Args: { extend_to?: unknown; g1: unknown; tolerance?: number }
        Returns: unknown
      }
      st_within: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      st_wkbtosql: { Args: { wkb: string }; Returns: unknown }
      st_wkttosql: { Args: { "": string }; Returns: unknown }
      st_wrapx: {
        Args: { geom: unknown; move: number; wrap: number }
        Returns: unknown
      }
      toggle_customer_favorite: {
        Args: { p_customer_id: string; p_menu_item_id: number }
        Returns: boolean
      }
      unlockrows: { Args: { "": string }; Returns: number }
      updategeometrysrid: {
        Args: {
          catalogn_name: string
          column_name: string
          new_srid_in: number
          schema_name: string
          table_name: string
        }
        Returns: string
      }
      user_has_store_access: {
        Args: { p_store_id: number; p_user_id: string }
        Returns: boolean
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      geometry_dump: {
        path: number[] | null
        geom: unknown
      }
      valid_detail: {
        valid: boolean | null
        reason: string | null
        location: unknown
      }
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {},
  },
} as const
