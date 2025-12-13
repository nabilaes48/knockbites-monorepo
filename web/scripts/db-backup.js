#!/usr/bin/env node

/**
 * Database Backup Script for Cameron's Connect
 *
 * Downloads schema and data snapshots from Supabase and uploads to storage.
 *
 * Usage:
 *   node scripts/db-backup.js
 *   npm run db:backup
 *
 * Environment Variables Required:
 *   SUPABASE_URL
 *   SUPABASE_SERVICE_ROLE_KEY
 *   BACKUP_STORAGE_BUCKET (default: 'backups')
 */

import { createClient } from '@supabase/supabase-js';
import { writeFileSync, mkdirSync, existsSync, readFileSync } from 'fs';
import { join } from 'path';

const SUPABASE_URL = process.env.SUPABASE_URL || process.env.VITE_SUPABASE_URL;
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const BACKUP_BUCKET = process.env.BACKUP_STORAGE_BUCKET || 'backups';

if (!SUPABASE_URL || !SUPABASE_KEY) {
  console.error('Error: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required');
  console.error('Set these environment variables before running the backup.');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

// Tables to back up (in order for foreign key dependencies)
const TABLES_TO_BACKUP = [
  'stores',
  'menu_categories',
  'menu_items',
  'menu_item_customizations',
  'ingredient_templates',
  'customers',
  'user_profiles',
  'orders',
  'order_items',
  'alert_rules',
  'alert_history',
  'deployment_log',
];

// Tables with sensitive data (exclude or mask)
const SENSITIVE_TABLES = ['runtime_metrics'];

async function main() {
  const timestamp = new Date().toISOString().split('T')[0];
  const backupId = `backup_${timestamp}_${Date.now()}`;

  console.log(`Starting backup: ${backupId}`);
  console.log(`Timestamp: ${new Date().toISOString()}`);
  console.log('─'.repeat(50));

  const localBackupDir = join(process.cwd(), 'backups', timestamp);

  // Create local backup directory
  if (!existsSync(localBackupDir)) {
    mkdirSync(localBackupDir, { recursive: true });
  }

  const backupManifest = {
    id: backupId,
    timestamp: new Date().toISOString(),
    supabase_url: SUPABASE_URL,
    tables: {},
    errors: [],
  };

  // Backup each table
  for (const tableName of TABLES_TO_BACKUP) {
    console.log(`Backing up: ${tableName}...`);

    try {
      const { data, error, count } = await supabase
        .from(tableName)
        .select('*', { count: 'exact' });

      if (error) {
        console.error(`  Error: ${error.message}`);
        backupManifest.errors.push({ table: tableName, error: error.message });
        continue;
      }

      const rowCount = count || data?.length || 0;
      console.log(`  Rows: ${rowCount}`);

      // Save to local file
      const filename = `${tableName}.json`;
      const filepath = join(localBackupDir, filename);
      writeFileSync(filepath, JSON.stringify(data, null, 2));

      backupManifest.tables[tableName] = {
        rows: rowCount,
        filename,
        backed_up_at: new Date().toISOString(),
      };

      // Upload to Supabase Storage
      const storageFile = readFileSync(filepath);
      const storagePath = `${timestamp}/${filename}`;

      const { error: uploadError } = await supabase.storage
        .from(BACKUP_BUCKET)
        .upload(storagePath, storageFile, {
          contentType: 'application/json',
          upsert: true,
        });

      if (uploadError) {
        console.error(`  Storage upload error: ${uploadError.message}`);
        backupManifest.errors.push({
          table: tableName,
          error: `Storage upload: ${uploadError.message}`,
        });
      } else {
        console.log(`  Uploaded to: ${BACKUP_BUCKET}/${storagePath}`);
        backupManifest.tables[tableName].storage_path = storagePath;
      }
    } catch (err) {
      console.error(`  Exception: ${err.message}`);
      backupManifest.errors.push({ table: tableName, error: err.message });
    }
  }

  // Save manifest
  const manifestPath = join(localBackupDir, 'manifest.json');
  writeFileSync(manifestPath, JSON.stringify(backupManifest, null, 2));

  // Upload manifest to storage
  const manifestFile = readFileSync(manifestPath);
  await supabase.storage
    .from(BACKUP_BUCKET)
    .upload(`${timestamp}/manifest.json`, manifestFile, {
      contentType: 'application/json',
      upsert: true,
    });

  // Log backup to metrics
  try {
    await supabase.from('runtime_metrics').insert({
      session_id: 'system',
      event_type: 'auto_heal',
      event_data: {
        action: 'database_backup',
        backup_id: backupId,
        timestamp,
        tables_backed_up: Object.keys(backupManifest.tables).length,
        total_rows: Object.values(backupManifest.tables).reduce(
          (sum, t) => sum + (t.rows || 0),
          0
        ),
        errors_count: backupManifest.errors.length,
      },
    });
  } catch (metricsErr) {
    console.warn('Failed to log backup to metrics:', metricsErr.message);
  }

  // Summary
  console.log('─'.repeat(50));
  console.log('Backup Summary:');
  console.log(`  Backup ID: ${backupId}`);
  console.log(`  Tables backed up: ${Object.keys(backupManifest.tables).length}`);
  console.log(
    `  Total rows: ${Object.values(backupManifest.tables).reduce(
      (sum, t) => sum + (t.rows || 0),
      0
    )}`
  );
  console.log(`  Errors: ${backupManifest.errors.length}`);
  console.log(`  Local path: ${localBackupDir}`);
  console.log(`  Storage path: ${BACKUP_BUCKET}/${timestamp}/`);

  if (backupManifest.errors.length > 0) {
    console.log('\nErrors:');
    backupManifest.errors.forEach((err) => {
      console.log(`  - ${err.table}: ${err.error}`);
    });
    process.exit(1);
  }

  console.log('\nBackup completed successfully!');
}

main().catch((err) => {
  console.error('Backup failed:', err);
  process.exit(1);
});
