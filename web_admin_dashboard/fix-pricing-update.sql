-- Fix pricing data to match user requirements
-- All plans have 25% pre-launch discount
-- 1 month: ₹2,000 - ₹500 = ₹1,500 (Save ₹500)
-- 3 months: ₹3,000 - ₹750 = ₹2,250 (Save ₹750) 
-- 6 months: ₹5,000 - ₹1,250 = ₹3,750 (Save ₹1,250) - Most Popular

-- Update 1 month pricing: Save ₹500
UPDATE pricing_options 
SET 
  original_price = 2000,  -- ₹2,000 original price
  discount_percentage = 25,  -- 25% discount
  is_popular = false
WHERE duration_months = 1;

-- Update 3 months pricing: Save ₹750
UPDATE pricing_options 
SET 
  original_price = 3000,  -- ₹3,000 original price
  discount_percentage = 25,  -- 25% discount
  is_popular = false
WHERE duration_months = 3;

-- Update 6 months pricing: Save ₹1,250 and make it popular
UPDATE pricing_options 
SET 
  original_price = 5000,  -- ₹5,000 original price
  discount_percentage = 25,  -- 25% discount
  is_popular = true  -- Make it the most popular
WHERE duration_months = 6;
