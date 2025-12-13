#!/bin/bash
# Setup Staging Environment for KnockBites
# Run this BEFORE deploying any security changes to production

set -e

echo "📦 KnockBites Staging Environment Setup"
echo "========================================"
echo ""

# Check if supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI not found. Install with: brew install supabase/tap/supabase"
    exit 1
fi

echo "Step 1: Create new Supabase project for staging"
echo "------------------------------------------------"
echo "Go to: https://app.supabase.com/new/knockbites-staging"
echo ""
echo "Project name: knockbites-staging"
echo "Database password: [generate strong password]"
echo "Region: Same as production (for latency testing)"
echo ""
read -p "Press Enter once staging project is created..."

echo ""
echo "Step 2: Get staging credentials"
echo "--------------------------------"
read -p "Enter staging Supabase URL: " STAGING_URL
read -p "Enter staging anon key: " STAGING_ANON_KEY
read -p "Enter staging service role key: " STAGING_SERVICE_KEY

# Create staging env file
cat > .env.staging << ENVFILE
# KnockBites Staging Environment
# Created: $(date)
VITE_SUPABASE_URL=${STAGING_URL}
VITE_SUPABASE_ANON_KEY=${STAGING_ANON_KEY}
SUPABASE_SERVICE_ROLE_KEY=${STAGING_SERVICE_KEY}
ENVFILE

echo "✅ Created .env.staging"

echo ""
echo "Step 3: Apply baseline schema to staging"
echo "-----------------------------------------"
echo "Run these commands:"
echo ""
echo "  export SUPABASE_DB_URL=\"postgresql://postgres:[password]@db.[project-ref].supabase.co:5432/postgres\""
echo "  psql \$SUPABASE_DB_URL -f supabase/migrations/000_BASELINE_CANONICAL_SCHEMA.sql"
echo ""

echo ""
echo "Step 4: Deploy Edge Functions to staging"
echo "-----------------------------------------"
echo "  supabase functions deploy secure-checkout --project-ref [staging-ref]"
echo ""

echo "✅ Staging setup script complete"
echo ""
echo "Next steps:"
echo "  1. Run baseline migration on staging"
echo "  2. Run security migration 070 on staging"  
echo "  3. Test all flows on staging"
echo "  4. Only then deploy to production"
