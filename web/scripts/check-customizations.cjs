#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

// Read environment variables from .env.local
const envPath = path.join(__dirname, '..', '.env.local');
let SUPABASE_URL, SUPABASE_ANON_KEY;

if (fs.existsSync(envPath)) {
  const envContent = fs.readFileSync(envPath, 'utf8');
  const urlMatch = envContent.match(/VITE_SUPABASE_URL=(.+)/);
  const keyMatch = envContent.match(/VITE_SUPABASE_(?:ANON_KEY|PUBLISHABLE_KEY)=(.+)/);

  SUPABASE_URL = urlMatch ? urlMatch[1].trim() : process.env.VITE_SUPABASE_URL;
  SUPABASE_ANON_KEY = keyMatch ? keyMatch[1].trim() : (process.env.VITE_SUPABASE_ANON_KEY || process.env.VITE_SUPABASE_PUBLISHABLE_KEY);
} else {
  SUPABASE_URL = process.env.VITE_SUPABASE_URL;
  SUPABASE_ANON_KEY = process.env.VITE_SUPABASE_ANON_KEY || process.env.VITE_SUPABASE_PUBLISHABLE_KEY;
}

if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
  console.error('❌ Missing required environment variables');
  console.error('Please ensure VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY are set in .env.local');
  process.exit(1);
}

async function checkCustomizations() {
  try {
    console.log('🔍 Checking customization status for all menu items...\n');

    // Fetch all menu items with their category and customizations
    const response = await fetch(
      `${SUPABASE_URL}/rest/v1/menu_items?select=id,name,category_id,menu_categories(name),menu_item_customizations(id,name,category,supports_portions)&order=category_id,name`,
      {
        headers: {
          'apikey': SUPABASE_ANON_KEY,
          'Authorization': `Bearer ${SUPABASE_ANON_KEY}`
        }
      }
    );

    if (!response.ok) {
      throw new Error(`Failed to fetch menu items: ${response.statusText}`);
    }

    const items = await response.json();

    // Group by category
    const categorizedItems = {};
    items.forEach(item => {
      const categoryName = item.menu_categories?.name || `Category ${item.category_id}`;
      if (!categorizedItems[categoryName]) {
        categorizedItems[categoryName] = [];
      }

      const customizationCount = item.menu_item_customizations?.length || 0;
      categorizedItems[categoryName].push({
        name: item.name,
        customizationCount,
        hasCustomizations: customizationCount > 0,
        customizations: item.menu_item_customizations || []
      });
    });

    // Display results
    console.log('📊 CUSTOMIZATION STATUS BY CATEGORY\n');
    console.log('='.repeat(80) + '\n');

    Object.entries(categorizedItems).forEach(([categoryName, items]) => {
      const itemsWithCustomizations = items.filter(i => i.hasCustomizations).length;
      const totalItems = items.length;
      const percentage = totalItems > 0 ? ((itemsWithCustomizations / totalItems) * 100).toFixed(0) : 0;

      console.log(`📁 ${categoryName}`);
      console.log(`   ${itemsWithCustomizations}/${totalItems} items have customizations (${percentage}%)\n`);

      items.forEach(item => {
        const icon = item.hasCustomizations ? '✅' : '❌';
        const count = item.customizationCount;
        const details = count > 0 ? ` (${count} customizations)` : '';

        console.log(`   ${icon} ${item.name}${details}`);

        if (item.hasCustomizations && item.customizations.length > 0) {
          // Group customizations by category
          const customsByCategory = {};
          item.customizations.forEach(custom => {
            const cat = custom.category || 'other';
            if (!customsByCategory[cat]) customsByCategory[cat] = [];
            customsByCategory[cat].push(custom.name);
          });

          Object.entries(customsByCategory).forEach(([cat, names]) => {
            console.log(`      • ${cat}: ${names.join(', ')}`);
          });
        }
      });

      console.log('\n' + '-'.repeat(80) + '\n');
    });

    // Summary
    const totalItems = items.length;
    const itemsWithCustomizations = items.filter(item =>
      item.menu_item_customizations && item.menu_item_customizations.length > 0
    ).length;
    const totalCustomizations = items.reduce((sum, item) =>
      sum + (item.menu_item_customizations?.length || 0), 0
    );

    console.log('📈 OVERALL SUMMARY\n');
    console.log(`   Total menu items: ${totalItems}`);
    console.log(`   Items with customizations: ${itemsWithCustomizations}`);
    console.log(`   Items without customizations: ${totalItems - itemsWithCustomizations}`);
    console.log(`   Total customizations: ${totalCustomizations}`);
    console.log(`   Average customizations per item: ${(totalCustomizations / totalItems).toFixed(1)}\n`);

    // List items that should have customizations but don't
    const itemsNeedingCustomizations = items.filter(item => {
      const categoryName = item.menu_categories?.name || '';
      const isApplicable = ['Breakfast', 'Signature Sandwiches', 'Classic Sandwiches', 'Burgers'].includes(categoryName);
      const skipItems = ['Hash Browns', 'French Toast Sticks (8pc)'];
      const shouldHave = isApplicable && !skipItems.includes(item.name);
      const hasCustomizations = item.menu_item_customizations && item.menu_item_customizations.length > 0;

      return shouldHave && !hasCustomizations;
    });

    if (itemsNeedingCustomizations.length > 0) {
      console.log('⚠️  ITEMS THAT SHOULD HAVE CUSTOMIZATIONS BUT DON\'T:\n');
      itemsNeedingCustomizations.forEach(item => {
        const categoryName = item.menu_categories?.name || `Category ${item.category_id}`;
        console.log(`   ❌ ${item.name} (${categoryName})`);
      });
      console.log('');
      console.log('💡 Run Migration 045 to add customizations to these items.\n');
    } else {
      console.log('✅ All applicable items have customizations!\n');
    }

  } catch (error) {
    console.error('❌ Error checking customizations:', error.message);
    process.exit(1);
  }
}

checkCustomizations();
