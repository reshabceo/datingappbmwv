#!/bin/bash

# AI Verification System Deployment Script
# This script deploys the complete AI verification system

echo "🚀 Deploying AI Verification System..."

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI not found. Please install it first:"
    echo "npm install -g supabase"
    exit 1
fi

# Check if user is logged in to Supabase
if ! supabase status &> /dev/null; then
    echo "❌ Not logged in to Supabase. Please run:"
    echo "supabase login"
    exit 1
fi

echo "✅ Supabase CLI is ready"

# Step 1: Deploy the AI verification edge function
echo "📦 Deploying AI verification edge function..."
if supabase functions deploy ai-verification; then
    echo "✅ Edge function deployed successfully"
else
    echo "❌ Failed to deploy edge function"
    exit 1
fi

# Step 2: Set OpenAI API key
echo "🔑 Setting OpenAI API key..."
read -p "Enter your OpenAI API key: " OPENAI_KEY
if [ -z "$OPENAI_KEY" ]; then
    echo "❌ OpenAI API key is required"
    exit 1
fi

if supabase secrets set OPENAI_API_KEY="$OPENAI_KEY"; then
    echo "✅ OpenAI API key set successfully"
else
    echo "❌ Failed to set OpenAI API key"
    exit 1
fi

# Step 3: Run database migration
echo "🗄️ Running database migration..."
echo "Please run the following SQL in your Supabase SQL Editor:"
echo ""
echo "=========================================="
echo "Copy and paste this SQL into Supabase SQL Editor:"
echo "=========================================="
cat verification_system_schema.sql
echo "=========================================="
echo ""
read -p "Press Enter after running the SQL migration..."

# Step 4: Test the system
echo "🧪 Testing the AI verification system..."

# Test edge function
echo "Testing edge function deployment..."
if supabase functions list | grep -q "ai-verification"; then
    echo "✅ Edge function is deployed"
else
    echo "❌ Edge function not found"
    exit 1
fi

# Test database functions
echo "Testing database functions..."
echo "Please run this SQL to test:"
echo "SELECT get_random_verification_challenge();"
echo ""
read -p "Press Enter after testing the database function..."

echo ""
echo "🎉 AI Verification System Deployment Complete!"
echo ""
echo "📋 Next Steps:"
echo "1. Test the verification flow in your app"
echo "2. Check the admin panel at /admin/verification"
echo "3. Monitor verification success rates"
echo ""
echo "🔗 Important URLs:"
echo "- User verification: /verification"
echo "- Admin panel: /admin/verification"
echo ""
echo "📊 Monitor your system:"
echo "- Check Supabase logs: supabase functions logs ai-verification"
echo "- Monitor OpenAI usage in your OpenAI dashboard"
echo ""
echo "✅ Deployment complete! Your AI verification system is ready to use."
