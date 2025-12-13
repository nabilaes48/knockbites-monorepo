#!/usr/bin/env node

/**
 * Run Migration 017: Update Image URLs to Supabase Storage
 */

const fs = require('fs');
const path = require('path');

// Read environment variables
const envPath = path.join(__dirname, '../.env');
const envContent = fs.readFileSync(envPath, 'utf8');
const SUPABASE_URL = envContent.match(/VITE_SUPABASE_URL="([^"]+)"/)[1];
const SUPABASE_KEY = envContent.match(/VITE_SUPABASE_PUBLISHABLE_KEY="([^"]+)"/)[1];

console.log('🚀 Running Migration 017: Update Image URLs to Supabase Storage\n');
console.log(`📍 Supabase URL: ${SUPABASE_URL}\n`);

// Breakfast items (5 items)
const breakfastUpdates = [
  { name: "Bacon, Egg & Cheese on a Bagel", file: "bacon-egg-cheese-bagel.jpg" },
  { name: "Bacon, Egg & Cheese w/ Hash Brown on a Fresh Croissant", file: "bacon-egg-cheese-croissant.jpg" },
  { name: "Shack Attack AKA Jimmy", file: "shack-attack-aka-jimmy.jpg" },
  { name: "French Toast Sticks (8pc)", file: "french-toast-sticks.jpg" },
  { name: "Western Omelet", file: "western-omelet.jpg" }
];

// Signature sandwiches (24 items)
const signatureUpdates = [
  { name: "Cluck'en Russian®", file: "clucken-russian.jpg.jpg" },
  { name: "Cluck'en Ranch®", file: "clucken-ranch.jpg" },
  { name: "Cluck'en Club®", file: "clucken-club.jpg" },
  { name: "No Way Jose", file: "no-way-jose.jpg" },
  { name: "Buffalo Blu", file: "buffalo-blu.jpg" },
  { name: "Sicilian Supreme", file: "sicilian-supreme.jpg" },
  { name: "Cam's Spicy Chicken", file: "cams-spicy-chicken.jpg" },
  { name: "Texas Ranger", file: "texas-ranger.jpg" },
  { name: "Chopped Cheese", file: "chopped-cheese.jpg" },
  { name: "Tuscany", file: "tuscany.jpg" },
  { name: "Mrs. I", file: "mrs-i.jpg" },
  { name: "Beef Eater", file: "beef_eater.jpg" },
  { name: "Healthy Bird", file: "healthy_bird.jpg" },
  { name: "Turkey Dijon", file: "turkey_dijon.jpg" },
  { name: "Chicken Stack", file: "chicken_stack.jpg" },
  { name: "Wild Turkey", file: "wild_turkey.jpg" },
  { name: "The Roma Wrap", file: "the_roma_wrap.jpg" },
  { name: "Slim Chicken Wrap", file: "slim_chicken_wrap.jpg" },
  { name: "Yankee Peddler", file: "yankee_peddler.jpg" },
  { name: "Mama Rosa", file: "mama_rose.jpg" },
  { name: "Portobello Grove", file: "portobello_grove.jpg" },
  { name: "Cajun Horse", file: "cajun_horse.jpg" },
  { name: "Eggplanter", file: "eggplanter.jpg" },
  { name: "Miss Virginia", file: "miss_virginia.jpg" }
];

// Classic sandwiches (12 items)
const classicUpdates = [
  { name: "Chicken Cutlet", file: "chicken-cutlet.jpg" },
  { name: "Reuben", file: "reuben.jpg" },
  { name: "Philly Cheesesteak", file: "philly-cheesesteak.jpg" },
  { name: "Meatball Parmessan", file: "meatball-parmesan.jpg" },
  { name: "Captain Tuna", file: "captain-tuna.jpg" },
  { name: "Chicken Parmesan", file: "chicken-parmesan.jpg" },
  { name: "The Cross River Club", file: "cross-river-club.jpg" },
  { name: "Italian Combo", file: "italian-combo.jpg" },
  { name: "American Combo", file: "american-combo.jpg" },
  { name: "Buffalo Chicken Wrap", file: "buffalo-chicken-wrap.jpg" },
  { name: "All American", file: "all_american.jpg" },
  { name: "Cheese Burger", file: "cheese-burger.jpg" }
];

async function updateImages() {
  const { createClient } = require('@supabase/supabase-js');
  const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

  const baseUrl = `${SUPABASE_URL}/storage/v1/object/public/menu-images`;

  let updated = 0;
  let skipped = 0;

  // Update breakfast items
  console.log('📦 Updating Breakfast items...');
  for (const item of breakfastUpdates) {
    const imageUrl = `${baseUrl}/breakfast/${item.file}`;
    const { error } = await supabase
      .from('menu_items')
      .update({ image_url: imageUrl })
      .eq('name', item.name);

    if (error) {
      console.error(`   ❌ ${item.name}: ${error.message}`);
      skipped++;
    } else {
      console.log(`   ✅ ${item.name}`);
      updated++;
    }
  }

  // Update signature sandwiches
  console.log('\n📦 Updating Signature Sandwiches...');
  for (const item of signatureUpdates) {
    const imageUrl = `${baseUrl}/signature-sandwiches/${item.file}`;
    const { error } = await supabase
      .from('menu_items')
      .update({ image_url: imageUrl })
      .eq('name', item.name);

    if (error) {
      console.error(`   ❌ ${item.name}: ${error.message}`);
      skipped++;
    } else {
      console.log(`   ✅ ${item.name}`);
      updated++;
    }
  }

  // Update classic sandwiches
  console.log('\n📦 Updating Classic Sandwiches...');
  for (const item of classicUpdates) {
    const imageUrl = `${baseUrl}/classic-sandwiches/${item.file}`;
    const { error } = await supabase
      .from('menu_items')
      .update({ image_url: imageUrl })
      .eq('name', item.name);

    if (error) {
      console.error(`   ❌ ${item.name}: ${error.message}`);
      skipped++;
    } else {
      console.log(`   ✅ ${item.name}`);
      updated++;
    }
  }

  console.log('\n' + '='.repeat(60));
  console.log(`✅ Migration Complete: ${updated} updated, ${skipped} skipped`);
  console.log('='.repeat(60) + '\n');

  // Verify
  console.log('📊 Verifying updated images...\n');
  const { data, error } = await supabase
    .from('menu_items')
    .select('name, image_url')
    .like('image_url', `${SUPABASE_URL}/storage%`)
    .order('category_id')
    .order('name')
    .limit(10);

  if (data && data.length > 0) {
    console.log(`✅ Found ${data.length} items with Supabase Storage URLs:`);
    data.forEach(item => console.log(`   - ${item.name}`));
  } else {
    console.log('⚠️  No items found with Supabase Storage URLs');
  }
}

updateImages().catch(err => {
  console.error('❌ Migration failed:', err);
  process.exit(1);
});
