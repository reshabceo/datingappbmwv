-- Create subscription plans with new pricing structure
-- This will be executed in Supabase SQL editor

-- First, let's clear existing plans to start fresh
DELETE FROM subscription_plans;

-- Insert Free Plan
INSERT INTO subscription_plans (id, name, description, price_monthly, price_yearly, features, is_active, sort_order)
VALUES (
  gen_random_uuid(),
  'Free',
  'Perfect for getting started with Love Bug',
  0,
  0,
  '["Browse public profiles", "View limited stories", "Basic search filters", "Create your profile", "Limited matches"]'::jsonb,
  true,
  1
);

-- Insert Premium Plan with multiple pricing options
INSERT INTO subscription_plans (id, name, description, price_monthly, price_yearly, features, is_active, sort_order)
VALUES (
  gen_random_uuid(),
  'Premium',
  'Unlock all features and find your perfect match faster',
  2000,
  5000,
  '["Everything in Free", "See who liked you", "Priority visibility", "Advanced filters", "Read receipts", "Unlimited matches", "Super likes", "Profile boost"]'::jsonb,
  true,
  2
);

-- Insert Premium Plus Plan (6 months option)
INSERT INTO subscription_plans (id, name, description, price_monthly, price_yearly, features, is_active, sort_order)
VALUES (
  gen_random_uuid(),
  'Premium Plus',
  'Maximum value with our best features',
  5000,
  10000,
  '["Everything in Premium", "VIP support", "Advanced analytics", "Profile verification", "Exclusive events", "Priority customer service"]'::jsonb,
  true,
  3
);

-- Create a pricing_options table for flexible pricing
CREATE TABLE IF NOT EXISTS pricing_options (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id uuid REFERENCES subscription_plans(id) ON DELETE CASCADE,
  duration_months integer NOT NULL,
  price integer NOT NULL,
  original_price integer,
  discount_percentage integer,
  is_popular boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- Insert pricing options for Premium plan
INSERT INTO pricing_options (plan_id, duration_months, price, original_price, discount_percentage, is_popular)
SELECT 
  sp.id,
  1,
  2000,
  2000,
  0,
  false
FROM subscription_plans sp WHERE sp.name = 'Premium';

INSERT INTO pricing_options (plan_id, duration_months, price, original_price, discount_percentage, is_popular)
SELECT 
  sp.id,
  3,
  3000,
  6000,
  50,
  true
FROM subscription_plans sp WHERE sp.name = 'Premium';

INSERT INTO pricing_options (plan_id, duration_months, price, original_price, discount_percentage, is_popular)
SELECT 
  sp.id,
  6,
  5000,
  12000,
  58,
  false
FROM subscription_plans sp WHERE sp.name = 'Premium';

-- Insert pricing options for Premium Plus plan
INSERT INTO pricing_options (plan_id, duration_months, price, original_price, discount_percentage, is_popular)
SELECT 
  sp.id,
  1,
  5000,
  5000,
  0,
  false
FROM subscription_plans sp WHERE sp.name = 'Premium Plus';

INSERT INTO pricing_options (plan_id, duration_months, price, original_price, discount_percentage, is_popular)
SELECT 
  sp.id,
  3,
  8000,
  15000,
  47,
  false
FROM subscription_plans sp WHERE sp.name = 'Premium Plus';

INSERT INTO pricing_options (plan_id, duration_months, price, original_price, discount_percentage, is_popular)
SELECT 
  sp.id,
  6,
  10000,
  30000,
  67,
  true
FROM subscription_plans sp WHERE sp.name = 'Premium Plus';

-- Enable RLS
ALTER TABLE pricing_options ENABLE ROW LEVEL SECURITY;

-- Create policies for pricing_options
CREATE POLICY "Anyone can view pricing options" ON pricing_options
  FOR SELECT USING (true);

CREATE POLICY "Admin can manage pricing options" ON pricing_options
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.is_admin = true
    )
  );
