#!/usr/bin/env node

/**
 * Database Restore Script for Cameron's Connect
 *
 * Restores data from a backup to the database.
 * USE WITH CAUTION - This will overwrite existing data!
 *
 * Usage:
 *   node scripts/db-restore.js <backup-date>
 *   node scripts/db-restore.js 2025-12-01
 *   npm run db:restore -- 2025-12-01
 *
 * Options:
 *   --dry-run    Preview restore without making changes
 *   --tables     Comma-separated list of specific tables to restore
 *   --local      Restore from local backup instead of storage
 *
 * Environment Variables Required:
 *   SUPABASE_URL
 *   SUPABASE_SERVICE_ROLE_KEY
 *   BACKUP_STORAGE_BUCKET (default: 'backups')
 */

import { createClient } from '@supabase/supabase-js';
import { readFileSync, existsSync } from 'fs';
import { join } from 'path';

const SUPABASE_URL = process.env.SUPABASE_URL || process.env.VITE_SUPABASE_URL;
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const BACKUP_BUCKET = process.env.BACKUP_STORAGE_BUCKET || 'backups';

if (!SUPABASE_URL || !SUPABASE_KEY) {
  console.error('Error: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

// Parse command line arguments
const args = process.argv.slice(2);
const backupDate = args.find((arg) => !arg.startsWith('--'));
const dryRun = args.includes('--dry-run');
const useLocal = args.includes('--local');
const tablesArg = args.find((arg) => arg.startsWith('--tables='));
const specificTables = tablesArg ? tablesArg.split('=')[1].split(',') : null;

// Tables in restore order (respect foreign key dependencies)
const RESTORE_ORDER = [
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

async function main() {
  if (!backupDate) {
    console.error('Usage: node scripts/db-restore.js <backup-date>');
    console.error('Example: node scripts/db-restore.js 2025-12-01');
    console.error('\nOptions:');
    console.error('  --dry-run    Preview restore without making changes');
    console.error('  --tables=a,b Restore only specific tables');
    console.error('  --local      Restore from local backup directory');
    process.exit(1);
  }

  console.log('─'.repeat(50));
  console.log('DATABASE RESTORE');
  console.log('─'.repeat(50));
  console.log(`Backup Date: ${backupDate}`);
  console.log(`Mode: ${dryRun ? 'DRY RUN (no changes)' : 'LIVE RESTORE'}`);
  console.log(`Source: ${useLocal ? 'Local files' : 'Supabase Storage'}`);
  if (specificTables) {
    console.log(`Tables: ${specificTables.join(', ')}`);
  }
  console.log('─'.repeat(50));

  if (!dryRun) {
    console.log('\n⚠️  WARNING: This will OVERWRITE existing data!');
    console.log('Press Ctrl+C to cancel or wait 5 seconds to continue...\n');
    await new Promise((resolve) => setTimeout(resolve, 5000));
  }

  // Load manifest
  let manifest;
  try {
    if (useLocal) {
      const localPath = join(process.cwd(), 'backups', backupDate, 'manifest.json');
      manifest = JSON.parse(readFileSync(localPath, 'utf-8'));
    } else {
      const { data, error } = await supabase.storage
        .from(BACKUP_BUCKET)
        .download(`${backupDate}/manifest.json`);

      if (error) throw error;
      manifest = JSON.parse(await data.text());
    }
  } catch (err) {
    console.error(`Failed to load manifest: ${err.message}`);
    console.error(`Make sure backup exists for date: ${backupDate}`);
    process.exit(1);
  }

  console.log(`Loaded manifest: ${manifest.id}`);
  console.log(`Original backup time: ${manifest.timestamp}`);
  console.log(`Available tables: ${Object.keys(manifest.tables).join(', ')}`);
  console.log('');

  const restoreResults = {
    backup_id: manifest.id,
    restore_started: new Date().toISOString(),
    dry_run: dryRun,
    tables: {},
    errors: [],
  };

  // Determine tables to restore
  const tablesToRestore = specificTables
    ? RESTORE_ORDER.filter((t) => specificTables.includes(t))
    : RESTORE_ORDER.filter((t) => manifest.tables[t]);

  // Restore each table
  for (const tableName of tablesToRestore) {
    const tableInfo = manifest.tables[tableName];
    if (!tableInfo) {
      console.log(`Skipping ${tableName}: Not in backup`);
      continue;
    }

    console.log(`\nRestoring: ${tableName} (${tableInfo.rows} rows)`);

    try {
      // Load backup data
      let backupData;
      if (useLocal) {
        const localPath = join(
          process.cwd(),
          'backups',
          backupDate,
          tableInfo.filename
        );
        backupData = JSON.parse(readFileSync(localPath, 'utf-8'));
      } else {
        const { data, error } = await supabase.storage
          .from(BACKUP_BUCKET)
          .download(`${backupDate}/${tableInfo.filename}`);

        if (error) throw error;
        backupData = JSON.parse(await data.text());
      }

      console.log(`  Loaded ${backupData.length} records`);

      if (dryRun) {
        console.log(`  [DRY RUN] Would delete existing data and insert ${backupData.length} records`);
        restoreResults.tables[tableName] = {
          status: 'dry_run',
          rows: backupData.length,
        };
        continue;
      }

      // Delete existing data
      console.log(`  Deleting existing data...`);
      const { error: deleteError } = await supabase
        .from(tableName)
        .delete()
        .neq('id', -999999); // Delete all (workaround for Supabase)

      if (deleteError) {
        console.error(`  Delete error: ${deleteError.message}`);
        // Try alternative delete
        await supabase.from(tableName).delete().gte('id', 0);
      }

      // Insert backup data in batches
      if (backupData.length > 0) {
        console.log(`  Inserting ${backupData.length} records...`);
        const batchSize = 100;

        for (let i = 0; i < backupData.length; i += batchSize) {
          const batch = backupData.slice(i, i + batchSize);
          const { error: insertError } = await supabase
            .from(tableName)
            .insert(batch);

          if (insertError) {
            console.error(`  Insert error (batch ${i / batchSize + 1}): ${insertError.message}`);
            restoreResults.errors.push({
              table: tableName,
              batch: i / batchSize + 1,
              error: insertError.message,
            });
          }
        }
      }

      console.log(`  ✓ Restored ${backupData.length} records`);
      restoreResults.tables[tableName] = {
        status: 'success',
        rows: backupData.length,
      };
    } catch (err) {
      console.error(`  Error: ${err.message}`);
      restoreResults.errors.push({ table: tableName, error: err.message });
      restoreResults.tables[tableName] = {
        status: 'error',
        error: err.message,
      };
    }
  }

  restoreResults.restore_completed = new Date().toISOString();

  // Log restore to metrics (if not dry run)
  if (!dryRun) {
    try {
      await supabase.from('runtime_metrics').insert({
        session_id: 'system',
        event_type: 'auto_heal',
        event_data: {
          action: 'database_restore',
          backup_id: manifest.id,
          backup_date: backupDate,
          tables_restored: Object.keys(restoreResults.tables).length,
          errors_count: restoreResults.errors.length,
        },
      });
    } catch (metricsErr) {
      console.warn('Failed to log restore to metrics');
    }
  }

  // Summary
  console.log('\n' + '─'.repeat(50));
  console.log('Restore Summary:');
  console.log(`  Backup ID: ${manifest.id}`);
  console.log(`  Mode: ${dryRun ? 'DRY RUN' : 'LIVE'}`);
  console.log(`  Tables processed: ${Object.keys(restoreResults.tables).length}`);
  console.log(`  Errors: ${restoreResults.errors.length}`);

  if (restoreResults.errors.length > 0) {
    console.log('\nErrors:');
    restoreResults.errors.forEach((err) => {
      console.log(`  - ${err.table}: ${err.error}`);
    });
  }

  if (dryRun) {
    console.log('\n[DRY RUN] No changes were made.');
    console.log('Run without --dry-run to perform actual restore.');
  } else {
    console.log('\n✓ Restore completed!');
  }
}

main().catch((err) => {
  console.error('Restore failed:', err);
  process.exit(1);
});
