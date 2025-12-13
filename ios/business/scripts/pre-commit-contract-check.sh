#!/bin/bash
# Pre-commit hook to verify Supabase contract consistency
# Install: ln -sf ../../scripts/pre-commit-contract-check.sh .git/hooks/pre-commit

set -e

echo "🔍 Checking Supabase contract consistency..."

# Check if contract-related files are being modified
CONTRACT_FILES=$(git diff --cached --name-only | grep -E "(CAMERONS_SUPABASE_CONTRACT\.md|SharedModels/|shared-models/|database/migrations/)" || true)

if [ -z "$CONTRACT_FILES" ]; then
    echo "✅ No contract-related files modified, skipping check."
    exit 0
fi

echo "📋 Contract-related files detected:"
echo "$CONTRACT_FILES"
echo ""

# Check if ts-node is available
if ! command -v ts-node &> /dev/null; then
    echo "⚠️  ts-node not found. Skipping contract verification."
    echo "   Install with: npm install -g ts-node typescript"
    exit 0
fi

# Check for required environment variables
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_SERVICE_ROLE_KEY" ]; then
    echo "⚠️  Supabase credentials not set. Skipping live schema check."
    echo "   Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY to enable."
    echo ""
    echo "✅ Proceeding with commit (local validation only)."
    exit 0
fi

# Run verification
cd "$(git rev-parse --show-toplevel)"
if ts-node scripts/verify_supabase_contract.ts; then
    echo "✅ Contract verification passed!"
    exit 0
else
    echo ""
    echo "❌ CONTRACT MISMATCH DETECTED"
    echo "   Please fix mismatches before committing."
    echo "   Use 'git commit --no-verify' to bypass (not recommended)."
    exit 1
fi
