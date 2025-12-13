#!/usr/bin/env node

/**
 * Verify Supabase Storage URLs
 */

const fs = require('fs');
const path = require('path');

// Read environment variables
const envPath = path.join(__dirname, '../.env');
const envContent = fs.readFileSync(envPath, 'utf8');
const SUPABASE_URL = envContent.match(/VITE_SUPABASE_URL="([^"]+)"/)[1];
const SUPABASE_KEY = envContent.match(/VITE_SUPABASE_PUBLISHABLE_KEY="([^"]+)"/)[1];

const { createClient } = require('@supabase/supabase-js');
const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

async function verify() {
  console.log('📊 Verifying Supabase Storage URLs\n');
  console.log('='.repeat(60) + '\n');

  // Get all menu items with their image URLs
  const { data: items, error } = await supabase
    .from('menu_items')
    .select('id, name, image_url, menu_categories(name)')
    .order('category_id')
    .order('name');

  if (error) {
    console.error('❌ Error fetching menu items:', error.message);
    process.exit(1);
  }

  let storageCount = 0;
  let localCount = 0;
  let unsplashCount = 0;

  console.log('MENU ITEMS BY CATEGORY:\n');

  let currentCategory = '';
  items.forEach(item => {
    const category = item.menu_categories?.name || 'Unknown';

    if (category !== currentCategory) {
      console.log(`\n📁 ${category.toUpperCase()}`);
      currentCategory = category;
    }

    let status = '';
    if (item.image_url.includes('/storage/v1/object/public/')) {
      status = '✅ Storage';
      storageCount++;
    } else if (item.image_url.startsWith('/images/')) {
      status = '⚠️  Local';
      localCount++;
    } else if (item.image_url.includes('unsplash')) {
      status = '📷 Unsplash';
      unsplashCount++;
    } else {
      status = '❓ Unknown';
    }

    console.log(`   ${status} - ${item.name}`);
  });

  console.log('\n' + '='.repeat(60));
  console.log(`\n📊 SUMMARY:`);
  console.log(`   ✅ Supabase Storage: ${storageCount}`);
  console.log(`   ⚠️  Local paths: ${localCount}`);
  console.log(`   📷 Unsplash: ${unsplashCount}`);
  console.log(`   📝 Total items: ${items.length}`);
  console.log('\n' + '='.repeat(60) + '\n');

  if (storageCount > 0) {
    console.log('🎉 SUCCESS! Images are using Supabase Storage URLs\n');
    console.log('Sample Storage URLs:');
    items
      .filter(i => i.image_url.includes('/storage/'))
      .slice(0, 3)
      .forEach(i => console.log(`   - ${i.image_url}`));
  }

  if (localCount > 0) {
    console.log('\n⚠️  WARNING: Some items still using local paths:');
    items
      .filter(i => i.image_url.startsWith('/images/'))
      .slice(0, 5)
      .forEach(i => console.log(`   - ${i.name}: ${i.image_url}`));
  }

  console.log('\n');
}

verify().catch(err => {
  console.error('❌ Verification failed:', err);
  process.exit(1);
});
