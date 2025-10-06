// Script to execute the subscription plans update in Supabase
// Run this in your browser console on the Supabase dashboard

const sqlScript = `
-- Update subscription plans with new pricing structure
-- Remove Premium Plus and create new plans with 25% pre-release discount and women's free plan

-- First, delete all existing plans and pricing options to start fresh
DELETE FROM pricing_options;
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

-- Insert Premium Plan
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

-- Insert Women's Free Plan (highlighted for women)
INSERT INTO subscription_plans (id, name, description, price_monthly, price_yearly, features, is_active, sort_order)
VALUES (
  gen_random_uuid(),
  'Women\\'s Free',
  'Special free subscription for women during pre-launch',
  0,
  0,
  '["Everything in Premium", "VIP support", "Advanced analytics", "Profile verification", "Exclusive events", "Priority customer service"]'::jsonb,
  true,
  3
);

-- Create pricing options for Premium plan with 25% pre-release discount
-- 1 Month: ₹2,000 → ₹1,500 (25% off)
INSERT INTO pricing_options (plan_id, duration_months, price, original_price, discount_percentage, is_popular)
SELECT 
  sp.id,
  1,
  1500,  -- 25% off from ₹2,000
  2000,
  25,
  false
FROM subscription_plans sp WHERE sp.name = 'Premium';

-- 3 Months: ₹4,500 → ₹2,250 (50% off)
INSERT INTO pricing_options (plan_id, duration_months, price, original_price, discount_percentage, is_popular)
SELECT 
  sp.id,
  3,
  2250,  -- 50% off from ₹4,500
  4500,
  50,
  false
FROM subscription_plans sp WHERE sp.name = 'Premium';

-- 6 Months: ₹9,000 → ₹3,600 (60% off) [Most popular]
INSERT INTO pricing_options (plan_id, duration_months, price, original_price, discount_percentage, is_popular)
SELECT 
  sp.id,
  6,
  3600,  -- 60% off from ₹9,000
  9000,
  60,
  true   -- Most popular
FROM subscription_plans sp WHERE sp.name = 'Premium';

-- Create a special offers table for pre-release discounts
CREATE TABLE IF NOT EXISTS special_offers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name varchar(255) NOT NULL,
  description text,
  discount_percentage integer NOT NULL,
  is_active boolean DEFAULT true,
  start_date timestamp with time zone DEFAULT now(),
  end_date timestamp with time zone,
  target_audience varchar(50) DEFAULT 'all', -- 'all', 'women', 'men'
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- Insert pre-release offer
INSERT INTO special_offers (name, description, discount_percentage, target_audience, end_date)
VALUES (
  'Pre-Launch Special',
  '25% off all Premium plans during pre-launch period',
  25,
  'all',
  now() + interval '90 days'  -- 90 days from now
);

-- Insert women's free offer
INSERT INTO special_offers (name, description, discount_percentage, target_audience, end_date)
VALUES (
  'Women\\'s Free Subscription',
  'Free Premium subscription for women during pre-launch',
  100,
  'women',
  now() + interval '90 days'  -- 90 days from now
);

-- Enable RLS for special_offers
ALTER TABLE special_offers ENABLE ROW LEVEL SECURITY;

-- Create policies for special_offers
CREATE POLICY "Anyone can view active special offers" ON special_offers
  FOR SELECT USING (is_active = true);

CREATE POLICY "Admin can manage special offers" ON special_offers
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.is_admin = true
    )
  );

-- Update the existing pricing_options policies
DROP POLICY IF EXISTS "Anyone can view pricing options" ON pricing_options;
DROP POLICY IF EXISTS "Admin can manage pricing options" ON pricing_options;

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
`;

console.log('Copy and paste this SQL script into your Supabase SQL editor:');
console.log(sqlScript);
