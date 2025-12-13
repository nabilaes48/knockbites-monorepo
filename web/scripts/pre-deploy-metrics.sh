#!/bin/bash
# pre-deploy-metrics.sh
# Capture baseline metrics before deploying security changes
# Run this BEFORE deploying migration 070

set -e

echo "📊 KnockBites Pre-Deployment Metrics"
echo "====================================="
echo "Date: $(date)"
echo ""

# Load environment
if [ -f .env.local ]; then
    export $(grep -v '^#' .env.local | xargs)
fi

SUPABASE_URL="${VITE_SUPABASE_URL:-$SUPABASE_URL}"
SUPABASE_KEY="${SUPABASE_SERVICE_ROLE_KEY:-$VITE_SUPABASE_ANON_KEY}"

if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_KEY" ]; then
    echo "❌ Missing Supabase credentials. Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY"
    exit 1
fi

echo "Connecting to: $SUPABASE_URL"
echo ""

# Function to query Supabase
query_supabase() {
    local table=$1
    local select=$2
    local filter=$3

    curl -s "${SUPABASE_URL}/rest/v1/${table}?select=${select}&${filter}" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_KEY}"
}

# 1. Order Metrics (Last 24 hours)
echo "📦 ORDER METRICS (Last 24 hours)"
echo "--------------------------------"

# Total orders today
ORDERS_TODAY=$(curl -s "${SUPABASE_URL}/rest/v1/orders?select=id&created_at=gte.$(date -u -v-1d '+%Y-%m-%dT%H:%M:%S')" \
    -H "apikey: ${SUPABASE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_KEY}" \
    -H "Prefer: count=exact" \
    -I 2>/dev/null | grep -i 'content-range' | sed 's/.*\///')

echo "Orders in last 24h: ${ORDERS_TODAY:-0}"

# Orders by status
echo ""
echo "Orders by Status:"
for status in pending preparing ready completed cancelled; do
    COUNT=$(curl -s "${SUPABASE_URL}/rest/v1/orders?select=id&status=eq.${status}" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_KEY}" \
        -H "Prefer: count=exact" \
        -I 2>/dev/null | grep -i 'content-range' | sed 's/.*\///')
    echo "  - ${status}: ${COUNT:-0}"
done

# 2. User Metrics
echo ""
echo "👥 USER METRICS"
echo "---------------"

# Total customers
CUSTOMERS=$(curl -s "${SUPABASE_URL}/rest/v1/customers?select=id" \
    -H "apikey: ${SUPABASE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_KEY}" \
    -H "Prefer: count=exact" \
    -I 2>/dev/null | grep -i 'content-range' | sed 's/.*\///')

echo "Total Customers: ${CUSTOMERS:-0}"

# Staff users
STAFF=$(curl -s "${SUPABASE_URL}/rest/v1/user_profiles?select=id" \
    -H "apikey: ${SUPABASE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_KEY}" \
    -H "Prefer: count=exact" \
    -I 2>/dev/null | grep -i 'content-range' | sed 's/.*\///')

echo "Total Staff Users: ${STAFF:-0}"

# 3. Revenue Metrics
echo ""
echo "💰 REVENUE METRICS (Last 7 days)"
echo "---------------------------------"

REVENUE=$(curl -s "${SUPABASE_URL}/rest/v1/orders?select=total&status=eq.completed&created_at=gte.$(date -u -v-7d '+%Y-%m-%dT%H:%M:%S')" \
    -H "apikey: ${SUPABASE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_KEY}" | \
    jq -r 'map(.total) | add // 0')

echo "Revenue (7 days): \$${REVENUE:-0}"

# 4. Store Distribution
echo ""
echo "🏪 ORDERS BY STORE (Last 24h)"
echo "-----------------------------"

STORE_ORDERS=$(curl -s "${SUPABASE_URL}/rest/v1/orders?select=store_id,stores(name)&created_at=gte.$(date -u -v-1d '+%Y-%m-%dT%H:%M:%S')" \
    -H "apikey: ${SUPABASE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_KEY}")

echo "$STORE_ORDERS" | jq -r 'group_by(.store_id) | map({store: .[0].stores.name, count: length}) | .[] | "  - \(.store // "Unknown"): \(.count)"' 2>/dev/null || echo "  (No data or jq error)"

# 5. Save metrics to file
echo ""
echo "📁 Saving metrics to pre-deploy-metrics.json..."

cat > pre-deploy-metrics.json << EOF
{
  "timestamp": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')",
  "orders_24h": ${ORDERS_TODAY:-0},
  "total_customers": ${CUSTOMERS:-0},
  "total_staff": ${STAFF:-0},
  "revenue_7d": ${REVENUE:-0},
  "notes": "Baseline before security migration 070"
}
EOF

echo "✅ Metrics saved!"
echo ""
echo "NEXT STEPS:"
echo "  1. Review metrics above"
echo "  2. If traffic is high, consider deploying during low-traffic window"
echo "  3. Run: ./scripts/setup-staging.sh (if not done)"
echo "  4. Test on staging first"
echo "  5. Deploy to production"
echo ""
echo "After deployment, run this script again to compare metrics."
