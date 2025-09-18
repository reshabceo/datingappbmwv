-- Create offers and promotions schema for subscription plans
-- This will be executed in Supabase SQL editor

-- Create offers table
CREATE TABLE IF NOT EXISTS offers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name varchar(255) NOT NULL,
  description text,
  offer_type varchar(50) NOT NULL CHECK (offer_type IN ('percentage', 'fixed_amount', 'free')),
  discount_value numeric(5,2) NOT NULL DEFAULT 0, -- percentage or fixed amount
  reason varchar(255) NOT NULL, -- e.g., "Pre-launch", "Women's special", "Holiday offer"
  target_audience varchar(50) DEFAULT 'all' CHECK (target_audience IN ('all', 'women', 'men', 'new_users', 'existing_users')),
  applicable_plans jsonb DEFAULT '[]'::jsonb, -- array of plan IDs this offer applies to
  applicable_durations jsonb DEFAULT '[]'::jsonb, -- array of duration months this offer applies to
  start_date timestamp with time zone NOT NULL,
  end_date timestamp with time zone,
  is_active boolean DEFAULT true,
  max_uses integer, -- null means unlimited
  current_uses integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  created_by uuid REFERENCES auth.users(id)
);

-- Create offer_applications table to track which users have used which offers
CREATE TABLE IF NOT EXISTS offer_applications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  offer_id uuid REFERENCES offers(id) ON DELETE CASCADE,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  plan_id uuid REFERENCES subscription_plans(id) ON DELETE CASCADE,
  pricing_option_id uuid REFERENCES pricing_options(id) ON DELETE CASCADE,
  original_price integer NOT NULL,
  discounted_price integer NOT NULL,
  discount_amount integer NOT NULL,
  applied_at timestamp with time zone DEFAULT now(),
  UNIQUE(offer_id, user_id, plan_id, pricing_option_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_offers_active ON offers(is_active, start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_offers_target_audience ON offers(target_audience);
CREATE INDEX IF NOT EXISTS idx_offer_applications_user ON offer_applications(user_id);
CREATE INDEX IF NOT EXISTS idx_offer_applications_offer ON offer_applications(offer_id);

-- Insert pre-launch offers
INSERT INTO offers (name, description, offer_type, discount_value, reason, target_audience, applicable_plans, applicable_durations, start_date, end_date, is_active, max_uses)
VALUES 
  (
    'Pre-launch 25% Off',
    'Get 25% off on all paid plans during our pre-launch phase',
    'percentage',
    25.00,
    'Pre-launch special offer',
    'all',
    '[]'::jsonb, -- applies to all plans
    '[1, 3, 6]'::jsonb, -- applies to 1, 3, and 6 month durations
    now(),
    now() + interval '3 months',
    true,
    null -- unlimited uses
  ),
  (
    'Women Free Subscription',
    'Free subscription for women during pre-launch',
    'free',
    100.00,
    'Women empowerment initiative',
    'women',
    '[]'::jsonb, -- applies to all plans
    '[1, 3, 6]'::jsonb, -- applies to all durations
    now(),
    now() + interval '6 months',
    true,
    null -- unlimited uses
  );

-- Create RLS policies for offers
ALTER TABLE offers ENABLE ROW LEVEL SECURITY;
ALTER TABLE offer_applications ENABLE ROW LEVEL SECURITY;

-- Policy for offers - everyone can read active offers
CREATE POLICY "Anyone can view active offers" ON offers
  FOR SELECT USING (is_active = true);

-- Policy for offers - only admins can modify
CREATE POLICY "Only admins can modify offers" ON offers
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM user_roles 
      WHERE user_id = auth.uid() 
      AND role = 'admin'
    )
  );

-- Policy for offer_applications - users can view their own applications
CREATE POLICY "Users can view their own offer applications" ON offer_applications
  FOR SELECT USING (user_id = auth.uid());

-- Policy for offer_applications - users can insert their own applications
CREATE POLICY "Users can apply offers" ON offer_applications
  FOR INSERT WITH CHECK (user_id = auth.uid());

-- Policy for offer_applications - admins can view all applications
CREATE POLICY "Admins can view all offer applications" ON offer_applications
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM user_roles 
      WHERE user_id = auth.uid() 
      AND role = 'admin'
    )
  );

-- Create function to calculate discounted price
CREATE OR REPLACE FUNCTION calculate_discounted_price(
  original_price integer,
  offer_type varchar(50),
  discount_value numeric(5,2)
) RETURNS integer AS $$
BEGIN
  CASE offer_type
    WHEN 'percentage' THEN
      RETURN ROUND(original_price * (1 - discount_value / 100));
    WHEN 'fixed_amount' THEN
      RETURN GREATEST(0, original_price - discount_value);
    WHEN 'free' THEN
      RETURN 0;
    ELSE
      RETURN original_price;
  END CASE;
END;
$$ LANGUAGE plpgsql;

-- Create function to get applicable offers for a user and plan
CREATE OR REPLACE FUNCTION get_applicable_offers(
  p_user_id uuid,
  p_plan_id uuid,
  p_duration_months integer
) RETURNS TABLE (
  offer_id uuid,
  offer_name varchar(255),
  offer_type varchar(50),
  discount_value numeric(5,2),
  reason varchar(255),
  discounted_price integer
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    o.id,
    o.name,
    o.offer_type,
    o.discount_value,
    o.reason,
    calculate_discounted_price(po.price, o.offer_type, o.discount_value) as discounted_price
  FROM offers o
  CROSS JOIN pricing_options po
  WHERE o.is_active = true
    AND o.start_date <= now()
    AND (o.end_date IS NULL OR o.end_date >= now())
    AND (o.max_uses IS NULL OR o.current_uses < o.max_uses)
    AND po.plan_id = p_plan_id
    AND po.duration_months = p_duration_months
    AND (
      o.target_audience = 'all' 
      OR (o.target_audience = 'women' AND EXISTS (
        SELECT 1 FROM profiles WHERE user_id = p_user_id AND gender = 'female'
      ))
      OR (o.target_audience = 'men' AND EXISTS (
        SELECT 1 FROM profiles WHERE user_id = p_user_id AND gender = 'male'
      ))
      OR (o.target_audience = 'new_users' AND EXISTS (
        SELECT 1 FROM profiles WHERE user_id = p_user_id AND created_at > now() - interval '30 days'
      ))
    )
    AND (
      o.applicable_plans = '[]'::jsonb 
      OR o.applicable_plans @> to_jsonb(p_plan_id::text)
    )
    AND (
      o.applicable_durations = '[]'::jsonb 
      OR o.applicable_durations @> to_jsonb(p_duration_months)
    )
  ORDER BY o.discount_value DESC;
END;
$$ LANGUAGE plpgsql;

