#!/usr/bin/env node

/**
 * Menu Image Sync Script
 *
 * This script scans the public/images/menu/items/ folders and generates
 * a SQL update script to sync image URLs with the database.
 *
 * Usage:
 *   node scripts/sync-menu-images.js
 *
 * Output:
 *   Creates supabase/migrations/008_update_menu_images.sql
 */

const fs = require('fs');
const path = require('path');

const ITEMS_DIR = path.join(__dirname, '../public/images/menu/items');
const OUTPUT_FILE = path.join(__dirname, '../supabase/migrations/008_update_menu_images.sql');

// Category folder mapping
const categories = {
  'breakfast': 1,
  'signature-sandwiches': 2,
  'classic-sandwiches': 3,
  'burgers': 4,
  'munchies': 5
};

// Item name to filename mapping (slug format)
const itemNameToSlug = (name) => {
  return name
    .toLowerCase()
    .replace(/[®™©]/g, '') // Remove special symbols
    .replace(/[']/g, '') // Remove apostrophes
    .replace(/\s+/g, '-') // Replace spaces with hyphens
    .replace(/[()]/g, '') // Remove parentheses
    .replace(/--+/g, '-') // Replace multiple hyphens with single
    .replace(/^-|-$/g, ''); // Trim leading/trailing hyphens
};

console.log('🔍 Scanning menu item folders...\n');

const updates = [];
let totalImages = 0;

// Scan each category folder
Object.keys(categories).forEach(categoryFolder => {
  const categoryPath = path.join(ITEMS_DIR, categoryFolder);

  if (!fs.existsSync(categoryPath)) {
    console.log(`⚠️  Folder not found: ${categoryFolder}`);
    return;
  }

  const files = fs.readdirSync(categoryPath);
  const imageFiles = files.filter(f => /\.(jpg|jpeg|png|webp)$/i.test(f));

  if (imageFiles.length > 0) {
    console.log(`📁 ${categoryFolder}: Found ${imageFiles.length} images`);

    imageFiles.forEach(file => {
      const imagePath = `/images/menu/items/${categoryFolder}/${file}`;
      const itemSlug = path.basename(file, path.extname(file));

      updates.push({
        category: categoryFolder,
        slug: itemSlug,
        imagePath: imagePath
      });

      totalImages++;
    });
  }
});

console.log(`\n✅ Total images found: ${totalImages}\n`);

if (totalImages === 0) {
  console.log('❌ No images found. Please add photos to:');
  console.log('   public/images/menu/items/[category]/\n');
  process.exit(1);
}

// Generate SQL migration
let sql = `-- ============================================
-- UPDATE MENU ITEM IMAGES
-- Generated: ${new Date().toISOString()}
-- Total images: ${totalImages}
-- ============================================

`;

updates.forEach(({ category, slug, imagePath }) => {
  sql += `-- Update ${slug}\n`;
  sql += `UPDATE menu_items SET image_url = '${imagePath}'\n`;
  sql += `WHERE category_id = ${categories[category]}\n`;
  sql += `  AND LOWER(REPLACE(REPLACE(REPLACE(name, '''', ''), ' ', '-'), '®', '')) LIKE '%${slug.replace(/-/g, '%')}%';\n\n`;
});

// Write to file
fs.writeFileSync(OUTPUT_FILE, sql);

console.log('📝 Generated migration file:');
console.log(`   ${OUTPUT_FILE}\n`);
console.log('🚀 Next steps:');
console.log('   1. Review the generated SQL file');
console.log('   2. Run it in Supabase SQL Editor');
console.log('   3. Refresh your menu page to see updated images\n');
