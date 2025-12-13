#!/usr/bin/env npx ts-node

/**
 * Supabase Contract Verification Script
 *
 * This script verifies that the Supabase schema matches the contract
 * defined in docs/CAMERONS_SUPABASE_CONTRACT.md
 *
 * Usage:
 *   npx ts-node scripts/verify_supabase_contract.ts
 *
 * Environment variables required:
 *   SUPABASE_URL - Your Supabase project URL
 *   SUPABASE_SERVICE_KEY - Your Supabase service role key (for schema access)
 *
 * Exit codes:
 *   0 - No mismatches found
 *   1 - Mismatches found or error occurred
 */

import { createClient } from '@supabase/supabase-js';
import * as fs from 'fs';
import * as path from 'path';

// Contract definition - canonical schema from CAMERONS_SUPABASE_CONTRACT.md
const CONTRACT: Record<string, ContractTable> = {
  orders: {
    columns: {
      id: { type: 'uuid', nullable: false },
      order_number: { type: 'character varying', nullable: false },
      user_id: { type: 'uuid', nullable: true },
      customer_id: { type: 'character varying', nullable: true },
      customer_name: { type: 'character varying', nullable: false },
      customer_email: { type: 'character varying', nullable: true },
      customer_phone: { type: 'character varying', nullable: true },
      store_id: { type: 'integer', nullable: false },
      order_type: { type: 'character varying', nullable: true },
      status: { type: 'character varying', nullable: false },
      subtotal: { type: 'numeric', nullable: false },
      tax: { type: 'numeric', nullable: false },
      tip: { type: 'numeric', nullable: true },
      total: { type: 'numeric', nullable: false },
      special_instructions: { type: 'text', nullable: true },
      priority: { type: 'character varying', nullable: true },
      is_repeat_customer: { type: 'boolean', nullable: true },
      created_at: { type: 'timestamp with time zone', nullable: true },
      estimated_ready_at: { type: 'timestamp with time zone', nullable: true },
      completed_at: { type: 'timestamp with time zone', nullable: true },
      updated_at: { type: 'timestamp with time zone', nullable: true },
    },
  },
  order_items: {
    columns: {
      id: { type: 'integer', nullable: false },
      order_id: { type: 'uuid', nullable: true },
      menu_item_id: { type: 'integer', nullable: true },
      item_name: { type: 'character varying', nullable: false },
      item_price: { type: 'numeric', nullable: false },
      quantity: { type: 'integer', nullable: false },
      subtotal: { type: 'numeric', nullable: false },
      notes: { type: 'text', nullable: true },
      customizations: { type: 'ARRAY', nullable: true },
      selected_options: { type: 'jsonb', nullable: true },
    },
  },
  menu_items: {
    columns: {
      id: { type: 'integer', nullable: false },
      name: { type: 'character varying', nullable: false },
      description: { type: 'text', nullable: true },
      price: { type: 'numeric', nullable: true },
      base_price: { type: 'numeric', nullable: false },
      category_id: { type: 'integer', nullable: true },
      image_url: { type: 'character varying', nullable: true },
      is_available: { type: 'boolean', nullable: true },
      is_featured: { type: 'boolean', nullable: true },
      calories: { type: 'integer', nullable: true },
      preparation_time: { type: 'integer', nullable: true },
      allergens: { type: 'ARRAY', nullable: true },
      tags: { type: 'ARRAY', nullable: true },
      created_at: { type: 'timestamp with time zone', nullable: true },
      updated_at: { type: 'timestamp with time zone', nullable: true },
    },
  },
  menu_categories: {
    columns: {
      id: { type: 'integer', nullable: false },
      name: { type: 'character varying', nullable: false },
      description: { type: 'text', nullable: true },
      display_order: { type: 'integer', nullable: true },
      is_active: { type: 'boolean', nullable: true },
      created_at: { type: 'timestamp with time zone', nullable: true },
    },
  },
  coupons: {
    columns: {
      id: { type: 'integer', nullable: false },
      store_id: { type: 'integer', nullable: true },
      code: { type: 'character varying', nullable: false },
      name: { type: 'character varying', nullable: false },
      description: { type: 'text', nullable: true },
      discount_type: { type: 'character varying', nullable: false },
      discount_value: { type: 'numeric', nullable: false },
      min_order_value: { type: 'numeric', nullable: true },
      max_discount_amount: { type: 'numeric', nullable: true },
      first_order_only: { type: 'boolean', nullable: true },
      max_uses_total: { type: 'integer', nullable: true },
      max_uses_per_customer: { type: 'integer', nullable: true },
      current_uses: { type: 'integer', nullable: true },
      start_date: { type: 'timestamp with time zone', nullable: false },
      end_date: { type: 'timestamp with time zone', nullable: true },
      is_active: { type: 'boolean', nullable: true },
      is_featured: { type: 'boolean', nullable: true },
      created_at: { type: 'timestamp with time zone', nullable: true },
      updated_at: { type: 'timestamp with time zone', nullable: true },
    },
  },
  loyalty_programs: {
    columns: {
      id: { type: 'integer', nullable: false },
      store_id: { type: 'integer', nullable: true },
      name: { type: 'character varying', nullable: false },
      points_per_dollar: { type: 'numeric', nullable: true },
      welcome_bonus_points: { type: 'integer', nullable: true },
      referral_bonus_points: { type: 'integer', nullable: true },
      is_active: { type: 'boolean', nullable: true },
      created_at: { type: 'timestamp with time zone', nullable: true },
      updated_at: { type: 'timestamp with time zone', nullable: true },
    },
  },
  loyalty_tiers: {
    columns: {
      id: { type: 'integer', nullable: false },
      program_id: { type: 'integer', nullable: true },
      name: { type: 'character varying', nullable: false },
      min_points: { type: 'integer', nullable: false },
      discount_percentage: { type: 'numeric', nullable: true },
      free_delivery: { type: 'boolean', nullable: true },
      priority_support: { type: 'boolean', nullable: true },
      early_access_promos: { type: 'boolean', nullable: true },
      birthday_reward_points: { type: 'integer', nullable: true },
      tier_color: { type: 'character varying', nullable: true },
      sort_order: { type: 'integer', nullable: false },
      created_at: { type: 'timestamp with time zone', nullable: true },
    },
  },
  customer_loyalty: {
    columns: {
      id: { type: 'integer', nullable: false },
      customer_id: { type: 'integer', nullable: true },
      program_id: { type: 'integer', nullable: true },
      current_tier_id: { type: 'integer', nullable: true },
      total_points: { type: 'integer', nullable: true },
      lifetime_points: { type: 'integer', nullable: true },
      total_orders: { type: 'integer', nullable: true },
      total_spent: { type: 'numeric', nullable: true },
      joined_at: { type: 'timestamp with time zone', nullable: true },
      last_order_at: { type: 'timestamp with time zone', nullable: true },
      updated_at: { type: 'timestamp with time zone', nullable: true },
    },
  },
  stores: {
    columns: {
      id: { type: 'integer', nullable: false },
      name: { type: 'character varying', nullable: false },
      address: { type: 'character varying', nullable: true },
      city: { type: 'character varying', nullable: true },
      state: { type: 'character varying', nullable: true },
      zip: { type: 'character varying', nullable: true },
      phone_number: { type: 'character varying', nullable: true },
      latitude: { type: 'double precision', nullable: true },
      longitude: { type: 'double precision', nullable: true },
      hours_open: { type: 'character varying', nullable: true },
      hours_close: { type: 'character varying', nullable: true },
      is_open: { type: 'boolean', nullable: true },
      store_code: { type: 'character varying', nullable: true },
      created_at: { type: 'timestamp with time zone', nullable: true },
    },
  },
  customers: {
    columns: {
      id: { type: 'uuid', nullable: false },
      email: { type: 'character varying', nullable: true },
      full_name: { type: 'character varying', nullable: true },
      phone: { type: 'character varying', nullable: true },
      avatar_url: { type: 'character varying', nullable: true },
      created_at: { type: 'timestamp with time zone', nullable: true },
      updated_at: { type: 'timestamp with time zone', nullable: true },
    },
  },
  push_notifications: {
    columns: {
      id: { type: 'integer', nullable: false },
      store_id: { type: 'integer', nullable: true },
      title: { type: 'character varying', nullable: false },
      body: { type: 'text', nullable: false },
      image_url: { type: 'character varying', nullable: true },
      action_url: { type: 'character varying', nullable: true },
      target_segment: { type: 'character varying', nullable: true },
      scheduled_for: { type: 'timestamp with time zone', nullable: true },
      send_immediately: { type: 'boolean', nullable: true },
      status: { type: 'character varying', nullable: true },
      sent_at: { type: 'timestamp with time zone', nullable: true },
      created_at: { type: 'timestamp with time zone', nullable: true },
      updated_at: { type: 'timestamp with time zone', nullable: true },
    },
  },
  automated_campaigns: {
    columns: {
      id: { type: 'integer', nullable: false },
      store_id: { type: 'integer', nullable: true },
      campaign_type: { type: 'character varying', nullable: true },
      name: { type: 'character varying', nullable: false },
      description: { type: 'text', nullable: true },
      trigger_condition: { type: 'jsonb', nullable: true },
      trigger_event: { type: 'character varying', nullable: true },
      trigger_delay_hours: { type: 'integer', nullable: true },
      notification_title: { type: 'character varying', nullable: true },
      notification_body: { type: 'text', nullable: true },
      coupon_id: { type: 'integer', nullable: true },
      is_active: { type: 'boolean', nullable: true },
      total_triggered: { type: 'integer', nullable: true },
      total_converted: { type: 'integer', nullable: true },
      created_at: { type: 'timestamp with time zone', nullable: true },
      updated_at: { type: 'timestamp with time zone', nullable: true },
    },
  },
};

interface ContractColumn {
  type: string;
  nullable: boolean;
}

interface ContractTable {
  columns: Record<string, ContractColumn>;
}

interface SchemaMismatch {
  table: string;
  column?: string;
  issue: string;
  expected?: string;
  actual?: string;
}

async function getSupabaseSchema(supabase: any): Promise<Record<string, any>> {
  // Query the information_schema to get table and column definitions
  const { data, error } = await supabase.rpc('get_schema_info');

  if (error) {
    // Fallback: query information_schema directly
    const { data: columns, error: colError } = await supabase
      .from('information_schema.columns')
      .select('table_name, column_name, data_type, is_nullable')
      .eq('table_schema', 'public');

    if (colError) {
      throw new Error(`Failed to fetch schema: ${colError.message}`);
    }

    // Group by table
    const schema: Record<string, any> = {};
    for (const col of columns || []) {
      if (!schema[col.table_name]) {
        schema[col.table_name] = { columns: {} };
      }
      schema[col.table_name].columns[col.column_name] = {
        type: col.data_type,
        nullable: col.is_nullable === 'YES',
      };
    }
    return schema;
  }

  return data;
}

function compareSchemas(
  contract: Record<string, ContractTable>,
  actual: Record<string, any>
): SchemaMismatch[] {
  const mismatches: SchemaMismatch[] = [];

  // Check each table in contract
  for (const [tableName, tableContract] of Object.entries(contract)) {
    if (!actual[tableName]) {
      mismatches.push({
        table: tableName,
        issue: 'Table missing from database',
      });
      continue;
    }

    const actualTable = actual[tableName];

    // Check each column in contract
    for (const [colName, colContract] of Object.entries(tableContract.columns)) {
      if (!actualTable.columns?.[colName]) {
        mismatches.push({
          table: tableName,
          column: colName,
          issue: 'Column missing from database',
          expected: `${colContract.type} (nullable: ${colContract.nullable})`,
        });
        continue;
      }

      const actualCol = actualTable.columns[colName];

      // Check type (allow some flexibility for type aliases)
      const expectedType = normalizeType(colContract.type);
      const actualType = normalizeType(actualCol.type);

      if (expectedType !== actualType && !areTypesCompatible(expectedType, actualType)) {
        mismatches.push({
          table: tableName,
          column: colName,
          issue: 'Type mismatch',
          expected: colContract.type,
          actual: actualCol.type,
        });
      }

      // Check nullability
      if (colContract.nullable !== actualCol.nullable) {
        mismatches.push({
          table: tableName,
          column: colName,
          issue: 'Nullability mismatch',
          expected: `nullable: ${colContract.nullable}`,
          actual: `nullable: ${actualCol.nullable}`,
        });
      }
    }

    // Check for extra columns in database (informational only)
    for (const colName of Object.keys(actualTable.columns || {})) {
      if (!tableContract.columns[colName]) {
        // This is informational - extra columns are allowed
        console.log(`  INFO: Extra column in ${tableName}: ${colName}`);
      }
    }
  }

  return mismatches;
}

function normalizeType(type: string): string {
  const normalized = type.toLowerCase()
    .replace(/character varying.*/, 'varchar')
    .replace(/timestamp with time zone/, 'timestamptz')
    .replace(/timestamp without time zone/, 'timestamp')
    .replace(/double precision/, 'float8')
    .replace(/^integer$/, 'int4')
    .replace(/^bigint$/, 'int8')
    .replace(/^smallint$/, 'int2')
    .replace(/^numeric.*/, 'numeric')
    .replace(/^decimal.*/, 'numeric')
    .replace(/^real$/, 'float4');
  return normalized;
}

function areTypesCompatible(expected: string, actual: string): boolean {
  // Allow some type flexibility
  const compatiblePairs: [string, string][] = [
    ['varchar', 'text'],
    ['numeric', 'float8'],
    ['int4', 'int8'],
    ['timestamptz', 'timestamp'],
  ];

  for (const [a, b] of compatiblePairs) {
    if ((expected === a && actual === b) || (expected === b && actual === a)) {
      return true;
    }
  }

  return false;
}

async function main() {
  console.log('='.repeat(60));
  console.log('Supabase Contract Verification');
  console.log('='.repeat(60));
  console.log('');

  const supabaseUrl = process.env.SUPABASE_URL || process.env.VITE_SUPABASE_URL;
  const supabaseKey = process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_ANON_KEY || process.env.VITE_SUPABASE_PUBLISHABLE_KEY;

  if (!supabaseUrl || !supabaseKey) {
    console.error('Error: SUPABASE_URL and SUPABASE_SERVICE_KEY environment variables required');
    console.log('');
    console.log('Set them in your environment or .env file:');
    console.log('  export SUPABASE_URL="https://your-project.supabase.co"');
    console.log('  export SUPABASE_SERVICE_KEY="your-service-role-key"');
    process.exit(1);
  }

  console.log(`Connecting to: ${supabaseUrl}`);
  console.log('');

  const supabase = createClient(supabaseUrl, supabaseKey);

  try {
    console.log('Fetching database schema...');
    const actualSchema = await getSupabaseSchema(supabase);
    console.log(`Found ${Object.keys(actualSchema).length} tables`);
    console.log('');

    console.log('Comparing against contract...');
    console.log('');

    const mismatches = compareSchemas(CONTRACT, actualSchema);

    if (mismatches.length === 0) {
      console.log('SUCCESS: Schema matches contract!');
      console.log('');
      console.log(`Verified ${Object.keys(CONTRACT).length} tables`);
      process.exit(0);
    } else {
      console.log('MISMATCHES FOUND:');
      console.log('');

      for (const mismatch of mismatches) {
        console.log(`  [${mismatch.table}${mismatch.column ? '.' + mismatch.column : ''}]`);
        console.log(`    Issue: ${mismatch.issue}`);
        if (mismatch.expected) {
          console.log(`    Expected: ${mismatch.expected}`);
        }
        if (mismatch.actual) {
          console.log(`    Actual: ${mismatch.actual}`);
        }
        console.log('');
      }

      console.log(`Total mismatches: ${mismatches.length}`);
      process.exit(1);
    }
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

main();
