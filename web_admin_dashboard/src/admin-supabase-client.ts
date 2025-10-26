// Admin Supabase client with service role for bypassing RLS
import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = "https://dkcitxzvojvecuvacwsp.supabase.co";
const SUPABASE_SERVICE_ROLE_KEY = "YOUR_SERVICE_ROLE_KEY_HERE"; // You need to get this from Supabase dashboard

// Create admin client with service role that bypasses RLS
export const adminSupabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
});

// Use this client for admin operations that need to bypass RLS
export default adminSupabase;
