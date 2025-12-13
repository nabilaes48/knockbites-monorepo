#!/usr/bin/env node

const { createClient } = require('@supabase/supabase-js');
require('dotenv/config');

// Initialize Supabase client
const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseKey = process.env.VITE_SUPABASE_PUBLISHABLE_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('❌ Missing Supabase credentials in .env.local');
  console.error('Make sure you have:');
  console.error('  VITE_SUPABASE_URL=...');
  console.error('  VITE_SUPABASE_PUBLISHABLE_KEY=...');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

const sampleOrders = [
  {
    customer_name: 'John Doe',
    customer_email: 'john@example.com',
    customer_phone: '555-0100',
    store_id: 1,
    status: 'completed',
    total: 29.99,
    subtotal: 26.99,
    tax: 2.40,
    tip: 0.60,
    order_type: 'pickup',
    created_at: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(), // 2 hours ago
  },
  {
    customer_name: 'Jane Smith',
    customer_email: 'jane@example.com',
    customer_phone: '555-0101',
    store_id: 1,
    status: 'completed',
    total: 45.50,
    subtotal: 41.36,
    tax: 3.31,
    tip: 0.83,
    order_type: 'delivery',
    created_at: new Date(Date.now() - 4 * 60 * 60 * 1000).toISOString(), // 4 hours ago
  },
  {
    customer_name: 'Bob Johnson',
    customer_email: 'bob@example.com',
    customer_phone: '555-0102',
    store_id: 1,
    status: 'preparing',
    total: 18.75,
    subtotal: 16.95,
    tax: 1.36,
    tip: 0.44,
    order_type: 'pickup',
    created_at: new Date(Date.now() - 30 * 60 * 1000).toISOString(), // 30 mins ago
  },
  {
    customer_name: 'Alice Brown',
    customer_email: 'alice@example.com',
    customer_phone: '555-0103',
    store_id: 1,
    status: 'ready',
    total: 32.40,
    subtotal: 29.45,
    tax: 2.36,
    tip: 0.59,
    order_type: 'pickup',
    created_at: new Date(Date.now() - 15 * 60 * 1000).toISOString(), // 15 mins ago
  },
  {
    customer_name: 'Charlie Davis',
    customer_email: 'charlie@example.com',
    customer_phone: '555-0104',
    store_id: 1,
    status: 'pending',
    total: 24.99,
    subtotal: 22.72,
    tax: 1.82,
    tip: 0.45,
    order_type: 'pickup',
    created_at: new Date().toISOString(), // Just now
  },
];

async function createSampleOrders() {
  console.log('🚀 Creating sample orders...\n');

  for (const order of sampleOrders) {
    try {
      const { data, error } = await supabase
        .from('orders')
        .insert(order)
        .select()
        .single();

      if (error) {
        console.error(`❌ Error creating order for ${order.customer_name}:`, error.message);
      } else {
        console.log(`✅ Created order #${data.id} for ${order.customer_name} - $${order.total}`);
      }
    } catch (err) {
      console.error(`❌ Failed to create order:`, err.message);
    }
  }

  console.log('\n🎉 Done! Sample orders created.');
  console.log('\n📊 Now open your analytics dashboard:');
  console.log('   http://localhost:8081/dashboard (Analytics tab)');
  console.log('\nYou should see:');
  console.log('   - Total Revenue: ~$151.63');
  console.log('   - Total Orders: 5');
  console.log('   - Charts populated with data');
}

createSampleOrders().catch(console.error);
