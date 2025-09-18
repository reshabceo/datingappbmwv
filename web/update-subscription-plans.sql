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

-- Note: Women's Free is handled as a special offer, not a separate plan

-- Create pricing options for Premium plan with 25% pre-release discount
-- 1 Month: ₹2,000 → ₹1,500 (₹500 off)
INSERT INTO pricing_options (plan_id, duration_months, price, original_price, discount_percentage, is_popular)
SELECT 
  sp.id,
  1,
  1500,  -- ₹2,000 - ₹500 = ₹1,500
  2000,
  25,
  false
FROM subscription_plans sp WHERE sp.name = 'Premium';

-- 3 Months: ₹3,000 → ₹2,250 (₹750 off)
INSERT INTO pricing_options (plan_id, duration_months, price, original_price, discount_percentage, is_popular)
SELECT 
  sp.id,
  3,
  2250,  -- ₹3,000 - ₹750 = ₹2,250
  3000,
  25,
  true   -- Most popular
FROM subscription_plans sp WHERE sp.name = 'Premium';

-- 6 Months: ₹5,000 → ₹3,750 (₹1,250 off)
INSERT INTO pricing_options (plan_id, duration_months, price, original_price, discount_percentage, is_popular)
SELECT 
  sp.id,
  6,
  3750,  -- ₹5,000 - ₹1,250 = ₹3,750
  5000,
  25,
  false
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

-- Note: Women's free offer is handled in frontend logic, not as a special offer

-- Enable RLS for special_offers
ALTER TABLE special_offers ENABLE ROW LEVEL SECURITY;

-- Create policies for special_offers
DROP POLICY IF EXISTS "Anyone can view active special offers" ON special_offers;
CREATE POLICY "Anyone can view active special offers" ON special_offers
  FOR SELECT USING (is_active = true);

-- Note: Admin policy will be added after confirming the correct admin column name
-- CREATE POLICY "Admin can manage special offers" ON special_offers
--   FOR ALL USING (
--     EXISTS (
--       SELECT 1 FROM profiles 
--       WHERE profiles.id = auth.uid() 
--       AND profiles.is_admin = true
--     )
--   );

-- Update the existing pricing_options policies
DROP POLICY IF EXISTS "Anyone can view pricing options" ON pricing_options;
DROP POLICY IF EXISTS "Admin can manage pricing options" ON pricing_options;

CREATE POLICY "Anyone can view pricing options" ON pricing_options
  FOR SELECT USING (true);

-- Note: Admin policy will be added after confirming the correct admin column name
-- CREATE POLICY "Admin can manage pricing options" ON pricing_options
--   FOR ALL USING (
--     EXISTS (
--       SELECT 1 FROM profiles 
--       WHERE profiles.id = auth.uid() 
--       AND profiles.is_admin = true
--     )
--   );
