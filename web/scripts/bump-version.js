#!/usr/bin/env node

/**
 * Version Bump Script for Cameron's Connect
 *
 * Usage:
 *   npm run version:bump [patch|minor|major]
 *   node scripts/bump-version.js [patch|minor|major]
 *
 * This script:
 * 1. Reads current version from package.json
 * 2. Bumps the version according to semver
 * 3. Updates package.json and package-lock.json
 * 4. Creates a git tag
 * 5. Outputs the new version
 */

import { readFileSync, writeFileSync } from 'fs';
import { execSync } from 'child_process';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const rootDir = join(__dirname, '..');

// Parse command line arguments
const bumpType = process.argv[2] || 'patch';

if (!['patch', 'minor', 'major'].includes(bumpType)) {
  console.error('Usage: npm run version:bump [patch|minor|major]');
  console.error('  patch - Bug fixes (1.0.0 -> 1.0.1)');
  console.error('  minor - New features (1.0.0 -> 1.1.0)');
  console.error('  major - Breaking changes (1.0.0 -> 2.0.0)');
  process.exit(1);
}

// Read package.json
const packageJsonPath = join(rootDir, 'package.json');
const packageJson = JSON.parse(readFileSync(packageJsonPath, 'utf-8'));
const currentVersion = packageJson.version;

// Parse and bump version
const [major, minor, patch] = currentVersion.split('.').map(Number);
let newVersion;

switch (bumpType) {
  case 'major':
    newVersion = `${major + 1}.0.0`;
    break;
  case 'minor':
    newVersion = `${major}.${minor + 1}.0`;
    break;
  case 'patch':
  default:
    newVersion = `${major}.${minor}.${patch + 1}`;
    break;
}

console.log(`Bumping version: ${currentVersion} -> ${newVersion}`);

// Update package.json
packageJson.version = newVersion;
writeFileSync(packageJsonPath, JSON.stringify(packageJson, null, 2) + '\n');
console.log('Updated package.json');

// Update package-lock.json if it exists
const packageLockPath = join(rootDir, 'package-lock.json');
try {
  const packageLock = JSON.parse(readFileSync(packageLockPath, 'utf-8'));
  packageLock.version = newVersion;
  if (packageLock.packages && packageLock.packages['']) {
    packageLock.packages[''].version = newVersion;
  }
  writeFileSync(packageLockPath, JSON.stringify(packageLock, null, 2) + '\n');
  console.log('Updated package-lock.json');
} catch (e) {
  console.log('No package-lock.json found, skipping');
}

// Check if we're in a git repository
try {
  execSync('git rev-parse --is-inside-work-tree', { stdio: 'ignore' });

  // Check for uncommitted changes
  const status = execSync('git status --porcelain').toString();
  const hasChanges = status.includes('package.json') || status.includes('package-lock.json');

  if (hasChanges) {
    console.log('\nStaging version changes...');
    execSync('git add package.json package-lock.json', { stdio: 'inherit' });

    // Create commit
    console.log('Creating version commit...');
    execSync(`git commit -m "chore: bump version to ${newVersion}"`, { stdio: 'inherit' });

    // Create tag
    console.log('Creating git tag...');
    execSync(`git tag -a v${newVersion} -m "Release v${newVersion}"`, { stdio: 'inherit' });

    console.log(`\nVersion ${newVersion} committed and tagged.`);
    console.log('\nTo push the release:');
    console.log(`  git push origin main --tags`);
  }
} catch (e) {
  console.log('\nNot in a git repository or git error, skipping git operations');
}

console.log(`\nNew version: ${newVersion}`);

// Output for CI/CD pipelines
if (process.env.GITHUB_OUTPUT) {
  const fs = await import('fs');
  fs.appendFileSync(process.env.GITHUB_OUTPUT, `version=${newVersion}\n`);
}

process.exit(0);
