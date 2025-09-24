-- Fix RLS policies for payment_orders table to allow order creation
-- Run this in your Supabase SQL Editor

-- Check current policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies 
WHERE tablename = 'payment_orders';

-- Drop existing restrictive policies for payment_orders (if any)
DROP POLICY IF EXISTS "Users can view their own orders" ON payment_orders;
DROP POLICY IF EXISTS "Users can create orders" ON payment_orders;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON payment_orders;
DROP POLICY IF EXISTS "Enable select for authenticated users" ON payment_orders;

-- Create more permissive RLS policies that allow order creation
-- Allow authenticated users to insert orders
CREATE POLICY "Allow authenticated users to create orders" ON payment_orders
  FOR INSERT 
  TO authenticated 
  WITH CHECK (true);

-- Allow authenticated users to view their own orders
CREATE POLICY "Allow users to view their orders" ON payment_orders
  FOR SELECT 
  TO authenticated 
  USING (auth.uid() = user_id OR user_id IS NULL);

-- Allow authenticated users to update their own orders (for payment status updates)
CREATE POLICY "Allow users to update their orders" ON payment_orders
  FOR UPDATE 
  TO authenticated 
  USING (auth.uid() = user_id OR user_id IS NULL)
  WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

-- Allow service_role to do everything (for edge functions)
CREATE POLICY "Allow service role full access" ON payment_orders
  FOR ALL 
  TO service_role 
  USING (true)
  WITH CHECK (true);

-- Grant necessary permissions
GRANT ALL ON payment_orders TO authenticated;
GRANT ALL ON payment_orders TO service_role;

-- Verify the policies were created
SELECT schemaname, tablename, policyname, permissive, roles, cmd
FROM pg_policies 
WHERE tablename = 'payment_orders';
