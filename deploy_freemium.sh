#!/bin/bash

# FREEMIUM DEPLOYMENT SCRIPT
# This script deploys the freemium system to your Supabase database

set -e  # Exit on error

echo "🚀 Starting Freemium System Deployment..."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Supabase credentials are set
if [ -z "$SUPABASE_DB_URL" ]; then
  echo -e "${YELLOW}⚠️  SUPABASE_DB_URL not set${NC}"
  echo "Please set your Supabase database URL:"
  echo "export SUPABASE_DB_URL='postgresql://postgres:[password]@[host]:[port]/postgres'"
  echo ""
  echo "Or run the SQL files manually in Supabase SQL Editor"
  echo ""
  exit 1
fi

echo -e "${GREEN}✅ Supabase credentials found${NC}"
echo ""

# Step 1: Create tables (if not exists)
echo "📦 Step 1: Creating freemium tables..."
psql "$SUPABASE_DB_URL" -f freemium_database_schema.sql 2>/dev/null || {
  echo -e "${YELLOW}⚠️  Tables might already exist, continuing...${NC}"
}
echo -e "${GREEN}✅ Step 1 complete${NC}"
echo ""

# Step 2: Apply fixes
echo "🔧 Step 2: Applying fixes to schema..."
psql "$SUPABASE_DB_URL" -f fix_freemium_schema.sql
echo -e "${GREEN}✅ Step 2 complete${NC}"
echo ""

# Step 3: Verify setup
echo "🔍 Step 3: Verifying setup..."
psql "$SUPABASE_DB_URL" -f verify_freemium_setup.sql
echo -e "${GREEN}✅ Step 3 complete${NC}"
echo ""

# Summary
echo ""
echo "=========================================="
echo -e "${GREEN}🎉 FREEMIUM DEPLOYMENT COMPLETE!${NC}"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Test freemium features in your Flutter app"
echo "2. Configure in-app purchases in Google Play Console"
echo "3. Configure in-app purchases in App Store Connect"
echo "4. Run flutter pub get to install in_app_purchase package"
echo ""
echo "For detailed setup instructions, see:"
echo "- FREEMIUM_FIX_GUIDE.md"
echo "- In-app purchase setup in your stores"
echo ""
echo "Happy coding! 🚀"
