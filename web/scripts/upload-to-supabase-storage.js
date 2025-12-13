#!/usr/bin/env node

/**
 * Upload Menu Images to Supabase Storage
 *
 * This script uploads local menu item images to Supabase Storage
 * and generates a SQL migration to update the database URLs
 */

const fs = require('fs');
const path = require('path');

// You'll need to install: npm install @supabase/supabase-js
// Then set your Supabase URL and service key

console.log('='.repeat(60));
console.log('MANUAL UPLOAD REQUIRED');
console.log('='.repeat(60));
console.log('\nYour menu images need to be uploaded to Supabase Storage.');
console.log('\nSTEPS:\n');
console.log('1. Go to Supabase Dashboard → Storage');
console.log('2. Create a bucket named: "menu-images" (public)');
console.log('3. Create folders: breakfast, signature-sandwiches, classic-sandwiches, burgers, munchies');
console.log('4. Upload images from local folders:');
console.log('   - public/images/menu/items/breakfast/');
console.log('   - public/images/menu/items/signature-sandwiches/');
console.log('   - public/images/menu/items/classic-sandwiches/');
console.log('   - public/images/menu/items/burgers/');
console.log('   - public/images/menu/items/munchies/');
console.log('\n5. After upload, run: node scripts/generate-storage-urls.js');
console.log('\n' + '='.repeat(60));

// List all images that need to be uploaded
const ITEMS_DIR = path.join(__dirname, '../public/images/menu/items');
const categories = ['breakfast', 'signature-sandwiches', 'classic-sandwiches', 'burgers', 'munchies'];

console.log('\nIMAGES TO UPLOAD:\n');

categories.forEach(category => {
  const categoryPath = path.join(ITEMS_DIR, category);
  if (fs.existsSync(categoryPath)) {
    const files = fs.readdirSync(categoryPath).filter(f => /\.(jpg|jpeg|png|webp)$/i.test(f));
    if (files.length > 0) {
      console.log(`📁 ${category}/ (${files.length} images)`);
      files.forEach(file => {
        console.log(`   - ${file}`);
      });
      console.log('');
    }
  }
});

console.log('\nTotal: Upload these to Supabase Storage bucket "menu-images"\n');
