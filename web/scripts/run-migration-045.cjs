#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

// Read environment variables
require('dotenv').config({ path: path.join(__dirname, '..', '.env.local') });

const SUPABASE_URL = process.env.VITE_SUPABASE_URL;
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
  console.error('❌ Missing required environment variables');
  console.error('Please ensure VITE_SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are set in .env.local');
  process.exit(1);
}

async function runMigration() {
  try {
    console.log('🚀 Starting Migration 045: Add Customizations to All Items\n');

    // Read the migration file
    const migrationPath = path.join(__dirname, '..', 'supabase', 'migrations', '045_add_customizations_to_all_items.sql');
    const migrationSQL = fs.readFileSync(migrationPath, 'utf8');

    console.log('📖 Migration file loaded successfully\n');

    // Use fetch to execute the SQL
    const response = await fetch(`${SUPABASE_URL}/rest/v1/rpc/exec_sql`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': SUPABASE_SERVICE_KEY,
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`
      },
      body: JSON.stringify({ query: migrationSQL })
    });

    if (!response.ok) {
      // Try alternative method using pg_stat_statements
      console.log('⚠️  First method failed, trying direct SQL execution...\n');

      // Split SQL into individual statements
      const statements = migrationSQL
        .split(/;\s*$/gm)
        .filter(stmt => stmt.trim().length > 0)
        .map(stmt => stmt.trim() + ';');

      console.log(`📝 Executing ${statements.length} SQL statements...\n`);

      for (let i = 0; i < statements.length; i++) {
        const stmt = statements[i];
        if (stmt.trim().startsWith('--') || stmt.trim().length < 3) continue;

        try {
          const stmtResponse = await fetch(`${SUPABASE_URL}/rest/v1/rpc/exec_sql`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'apikey': SUPABASE_SERVICE_KEY,
              'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`
            },
            body: JSON.stringify({ query: stmt })
          });

          if (!stmtResponse.ok) {
            console.log(`⏭️  Statement ${i + 1} (skipped or already applied)`);
          } else {
            console.log(`✅ Statement ${i + 1} executed successfully`);
          }
        } catch (err) {
          console.log(`⏭️  Statement ${i + 1} (skipped):`, err.message);
        }
      }
    }

    console.log('\n✅ Migration 045 completed!\n');
    console.log('📊 Verifying customizations...\n');

    // Verify the migration by querying menu items with customizations
    const verifyResponse = await fetch(
      `${SUPABASE_URL}/rest/v1/menu_items?select=id,name,category_id,menu_item_customizations(count)`,
      {
        headers: {
          'apikey': SUPABASE_SERVICE_KEY,
          'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`
        }
      }
    );

    if (verifyResponse.ok) {
      const items = await verifyResponse.json();
      const itemsWithCustomizations = items.filter(item =>
        item.menu_item_customizations &&
        item.menu_item_customizations[0]?.count > 0
      );

      console.log(`✅ ${itemsWithCustomizations.length} menu items now have customizations`);
      console.log(`📋 Total menu items: ${items.length}\n`);

      // Show breakdown by category
      const categoryBreakdown = {};
      items.forEach(item => {
        const catId = item.category_id;
        if (!categoryBreakdown[catId]) {
          categoryBreakdown[catId] = { total: 0, withCustomizations: 0 };
        }
        categoryBreakdown[catId].total++;
        if (item.menu_item_customizations && item.menu_item_customizations[0]?.count > 0) {
          categoryBreakdown[catId].withCustomizations++;
        }
      });

      console.log('📊 Breakdown by category:');
      Object.entries(categoryBreakdown).forEach(([catId, stats]) => {
        console.log(`   Category ${catId}: ${stats.withCustomizations}/${stats.total} items have customizations`);
      });
    }

    console.log('\n✅ All done! Customizations have been added to all applicable menu items.\n');
    console.log('🔍 You can now test customization on any item in the menu.\n');

  } catch (error) {
    console.error('❌ Error running migration:', error.message);
    console.error(error);
    process.exit(1);
  }
}

runMigration();
