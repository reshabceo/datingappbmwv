#!/bin/bash

# Deploy AI Verification Edge Function
# This script deploys the updated ai-verification function to Supabase

echo "🚀 Deploying AI Verification Edge Function..."

# Check if supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI not found. Please install it first:"
    echo "   npm install -g supabase"
    exit 1
fi

# Deploy the function
echo "📦 Deploying ai-verification function..."
supabase functions deploy ai-verification

if [ $? -eq 0 ]; then
    echo "✅ AI Verification function deployed successfully!"
    echo ""
    echo "🔧 Next steps:"
    echo "1. Set your OpenAI API key:"
    echo "   supabase secrets set OPENAI_API_KEY=your_openai_api_key_here"
    echo ""
    echo "2. Update verification challenges in database:"
    echo "   Run: update_verification_challenges.sql"
    echo ""
    echo "3. Test the function:"
    echo "   supabase functions list"
else
    echo "❌ Deployment failed. Check the error messages above."
    exit 1
fi
