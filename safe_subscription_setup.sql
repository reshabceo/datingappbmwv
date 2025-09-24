-- Safe subscription setup - only adds what doesn't exist

-- Step 1: Add premium fields to profiles (if they don't exist)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'is_premium') THEN
        ALTER TABLE profiles ADD COLUMN is_premium BOOLEAN DEFAULT FALSE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'premium_until') THEN
        ALTER TABLE profiles ADD COLUMN premium_until TIMESTAMP WITH TIME ZONE;
    END IF;
END $$;

-- Step 2: Create payment_orders table (if it doesn't exist)
CREATE TABLE IF NOT EXISTS payment_orders (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  order_id TEXT UNIQUE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  plan_type TEXT NOT NULL CHECK (plan_type IN ('1_month', '3_month', '6_month')),
  amount INTEGER NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'success', 'failed', 'cancelled')),
  payment_id TEXT,
  user_email TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 3: Create user_subscriptions table (if it doesn't exist)
CREATE TABLE IF NOT EXISTS user_subscriptions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  plan_type TEXT NOT NULL CHECK (plan_type IN ('1_month', '3_month', '6_month')),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'expired', 'cancelled')),
  start_date TIMESTAMP WITH TIME ZONE NOT NULL,
  end_date TIMESTAMP WITH TIME ZONE NOT NULL,
  order_id TEXT REFERENCES payment_orders(order_id),
  cancelled_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 4: Create subscription_plans table (if it doesn't exist)
CREATE TABLE IF NOT EXISTS subscription_plans (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  price_monthly INTEGER NOT NULL,
  price_yearly INTEGER NOT NULL,
  features JSONB DEFAULT '[]'::jsonb,
  is_active BOOLEAN DEFAULT TRUE,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 5: Enable RLS (only if not already enabled)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'payment_orders' AND relrowsecurity = true) THEN
        ALTER TABLE payment_orders ENABLE ROW LEVEL SECURITY;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'user_subscriptions' AND relrowsecurity = true) THEN
        ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'subscription_plans' AND relrowsecurity = true) THEN
        ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;
    END IF;
END $$;

-- Step 6: Create RLS policies (only if they don't exist)
DO $$ 
BEGIN
    -- Payment orders policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'payment_orders' AND policyname = 'Users can view their own payment orders') THEN
        CREATE POLICY "Users can view their own payment orders" ON payment_orders
          FOR SELECT USING (auth.uid() = user_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'payment_orders' AND policyname = 'Users can create payment orders') THEN
        CREATE POLICY "Users can create payment orders" ON payment_orders
          FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
    
    -- User subscriptions policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'user_subscriptions' AND policyname = 'Users can view their own subscriptions') THEN
        CREATE POLICY "Users can view their own subscriptions" ON user_subscriptions
          FOR SELECT USING (auth.uid() = user_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'user_subscriptions' AND policyname = 'Users can create subscriptions') THEN
        CREATE POLICY "Users can create subscriptions" ON user_subscriptions
          FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
    
    -- Subscription plans policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'subscription_plans' AND policyname = 'Anyone can view subscription plans') THEN
        CREATE POLICY "Anyone can view subscription plans" ON subscription_plans
          FOR SELECT USING (true);
    END IF;
END $$;

-- Step 7: Insert sample plans (only if they don't exist)
INSERT INTO subscription_plans (id, name, description, price_monthly, price_yearly, features, is_active, sort_order)
SELECT 
  uuid_generate_v4(), 'Premium 1 Month', 'Premium features for 1 month', 1500, 0, 
  '["See who liked you", "Priority visibility", "Advanced filters", "Read receipts", "Unlimited matches", "Super likes", "Profile boost"]'::jsonb, 
  true, 1
WHERE NOT EXISTS (SELECT 1 FROM subscription_plans WHERE name = 'Premium 1 Month');

INSERT INTO subscription_plans (id, name, description, price_monthly, price_yearly, features, is_active, sort_order)
SELECT 
  uuid_generate_v4(), 'Premium 3 Months', 'Premium features for 3 months', 2250, 0, 
  '["See who liked you", "Priority visibility", "Advanced filters", "Read receipts", "Unlimited matches", "Super likes", "Profile boost"]'::jsonb, 
  true, 2
WHERE NOT EXISTS (SELECT 1 FROM subscription_plans WHERE name = 'Premium 3 Months');

INSERT INTO subscription_plans (id, name, description, price_monthly, price_yearly, features, is_active, sort_order)
SELECT 
  uuid_generate_v4(), 'Premium 6 Months', 'Premium features for 6 months', 3600, 0, 
  '["See who liked you", "Priority visibility", "Advanced filters", "Read receipts", "Unlimited matches", "Super likes", "Profile boost"]'::jsonb, 
  true, 3
WHERE NOT EXISTS (SELECT 1 FROM subscription_plans WHERE name = 'Premium 6 Months');
