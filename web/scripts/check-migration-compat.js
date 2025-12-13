#!/usr/bin/env node

/**
 * Migration Compatibility Checker
 *
 * Validates that new migrations are compatible with deployed app versions.
 * Blocks any migration whose @breaking: true exceeds deployed mobile versions.
 *
 * Usage:
 *   node scripts/check-migration-compat.js
 *   node scripts/check-migration-compat.js --file=supabase/migrations/066_new_feature.sql
 *   npm run migration:check
 *
 * Exit codes:
 *   0 - All migrations compatible
 *   1 - Incompatible migration found or error
 */

import { readFileSync, readdirSync, existsSync } from 'fs';
import { join, basename } from 'path';

// Deployed app versions (update these when releasing new versions)
// In production, these would come from App Store Connect / Play Store
const DEPLOYED_VERSIONS = {
  web: process.env.DEPLOYED_WEB_VERSION || '1.3.0',
  customer: process.env.DEPLOYED_CUSTOMER_VERSION || '1.2.0',
  business: process.env.DEPLOYED_BUSINESS_VERSION || '1.2.0',
};

// Parse migration header comments
function parseMigrationHeaders(content) {
  const headers = {
    requires_version: '1.0.0',
    affects: ['customer', 'business', 'web'],
    breaking: false,
    description: '',
  };

  const lines = content.split('\n').slice(0, 30); // Only check first 30 lines

  for (const line of lines) {
    // Match @key: value pattern
    const match = line.match(/--\s*@(\w+):\s*(.+)/);
    if (match) {
      const [, key, value] = match;

      switch (key) {
        case 'requires_version':
          headers.requires_version = value.trim();
          break;
        case 'affects':
          headers.affects = value.split(',').map((s) => s.trim().toLowerCase());
          break;
        case 'breaking':
          headers.breaking = value.trim().toLowerCase() === 'true';
          break;
        case 'description':
          headers.description = value.trim();
          break;
      }
    }
  }

  return headers;
}

// Parse semantic version
function parseVersion(version) {
  const [major = 0, minor = 0, patch = 0] = version
    .replace(/^v/, '')
    .split('.')
    .map(Number);
  return { major, minor, patch };
}

// Compare versions: returns true if a >= b
function meetsMinVersion(current, minimum) {
  const a = parseVersion(current);
  const b = parseVersion(minimum);

  if (a.major !== b.major) return a.major > b.major;
  if (a.minor !== b.minor) return a.minor > b.minor;
  return a.patch >= b.patch;
}

// Check a single migration file
function checkMigration(filePath) {
  const content = readFileSync(filePath, 'utf-8');
  const headers = parseMigrationHeaders(content);
  const fileName = basename(filePath);

  const result = {
    file: fileName,
    headers,
    compatible: true,
    issues: [],
  };

  // If not a breaking change, it's compatible
  if (!headers.breaking) {
    return result;
  }

  // Check each affected app
  for (const app of headers.affects) {
    const deployedVersion = DEPLOYED_VERSIONS[app];

    if (!deployedVersion) {
      result.issues.push(`Unknown app: ${app}`);
      continue;
    }

    if (!meetsMinVersion(deployedVersion, headers.requires_version)) {
      result.compatible = false;
      result.issues.push(
        `BREAKING: ${app} app (v${deployedVersion}) doesn't meet required version ${headers.requires_version}`
      );
    }
  }

  return result;
}

// Main function
function main() {
  console.log('Migration Compatibility Checker');
  console.log('================================');
  console.log('');
  console.log('Deployed versions:');
  for (const [app, version] of Object.entries(DEPLOYED_VERSIONS)) {
    console.log(`  ${app}: v${version}`);
  }
  console.log('');

  // Parse arguments
  const args = process.argv.slice(2);
  const fileArg = args.find((a) => a.startsWith('--file='));
  const specificFile = fileArg ? fileArg.split('=')[1] : null;

  let files = [];

  if (specificFile) {
    // Check specific file
    if (!existsSync(specificFile)) {
      console.error(`File not found: ${specificFile}`);
      process.exit(1);
    }
    files = [specificFile];
  } else {
    // Check all migrations
    const migrationsDir = join(process.cwd(), 'supabase/migrations');
    const safeMigrationsDir = join(process.cwd(), 'supabase/safe_migrations');

    if (existsSync(migrationsDir)) {
      files.push(
        ...readdirSync(migrationsDir)
          .filter((f) => f.endsWith('.sql'))
          .map((f) => join(migrationsDir, f))
      );
    }

    if (existsSync(safeMigrationsDir)) {
      files.push(
        ...readdirSync(safeMigrationsDir)
          .filter((f) => f.endsWith('.sql') && f !== 'MIGRATION_TEMPLATE.sql')
          .map((f) => join(safeMigrationsDir, f))
      );
    }
  }

  if (files.length === 0) {
    console.log('No migration files found.');
    process.exit(0);
  }

  console.log(`Checking ${files.length} migration(s)...`);
  console.log('');

  let hasIssues = false;
  const results = [];

  for (const file of files) {
    const result = checkMigration(file);
    results.push(result);

    if (!result.compatible) {
      hasIssues = true;
    }
  }

  // Print results
  const breaking = results.filter((r) => r.headers.breaking);
  const incompatible = results.filter((r) => !r.compatible);

  if (breaking.length > 0) {
    console.log('Breaking migrations found:');
    for (const r of breaking) {
      const status = r.compatible ? '✓' : '✗';
      console.log(`  ${status} ${r.file}`);
      console.log(`    Requires: v${r.headers.requires_version}`);
      console.log(`    Affects: ${r.headers.affects.join(', ')}`);
      if (r.headers.description) {
        console.log(`    Description: ${r.headers.description}`);
      }
      if (r.issues.length > 0) {
        for (const issue of r.issues) {
          console.log(`    ⚠ ${issue}`);
        }
      }
      console.log('');
    }
  }

  // Summary
  console.log('--------------------------------');
  console.log('Summary:');
  console.log(`  Total migrations: ${results.length}`);
  console.log(`  Breaking changes: ${breaking.length}`);
  console.log(`  Incompatible: ${incompatible.length}`);
  console.log('');

  if (hasIssues) {
    console.log('❌ FAILED: Some migrations are incompatible with deployed versions.');
    console.log('');
    console.log('Options:');
    console.log('  1. Update the deployed app versions first');
    console.log('  2. Lower the @requires_version in the migration');
    console.log('  3. Make the migration non-breaking');
    process.exit(1);
  } else {
    console.log('✓ PASSED: All migrations are compatible.');
    process.exit(0);
  }
}

main();
