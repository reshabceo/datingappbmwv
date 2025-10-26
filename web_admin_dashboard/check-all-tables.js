import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = "https://dkcitxzvojvecuvacwsp.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrY2l0eHp2b2p2ZWN1dmFjd3NwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcxNDcwMTAsImV4cCI6MjA3MjcyMzAxMH0.0YmJgKVDkdmH6o-IMeT_eeMZEKBUfTuba9XsOruCYYw";

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function checkAllTables() {
  console.log('🔍 Checking all available tables and their data...\n');
  
  try {
    // First, authenticate as admin
    console.log('1. Authenticating as admin...');
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
      email: 'admin@datingapp.com',
      password: 'admin123'
    });
    
    if (authError) {
      console.log('❌ Admin login failed:', authError.message);
      return;
    }
    
    console.log('✅ Admin authenticated successfully');
    
    // List of tables to check
    const tablesToCheck = [
      'conversation_metadata',
      'messages', 
      'matches',
      'message_analytics',
      'message_flags',
      'profiles',
      'banned_users',
      'reports',
      'user_subscriptions'
    ];
    
    for (const tableName of tablesToCheck) {
      console.log(`\n📊 Checking table: ${tableName}`);
      
      try {
        const { data, error, count } = await supabase
          .from(tableName)
          .select('*', { count: 'exact' })
          .limit(5);
        
        if (error) {
          console.log(`❌ Error accessing ${tableName}:`, error.message);
        } else {
          console.log(`✅ ${tableName}: ${count || 0} total records, showing ${data?.length || 0} samples`);
          if (data && data.length > 0) {
            console.log('Sample record:', JSON.stringify(data[0], null, 2));
          }
        }
      } catch (err) {
        console.log(`❌ Exception accessing ${tableName}:`, err.message);
      }
    }
    
    // Also check if there are any RLS policies blocking access
    console.log('\n🔒 Checking RLS policies...');
    const { data: policies, error: policiesError } = await supabase
      .rpc('get_rls_policies');
    
    if (policiesError) {
      console.log('❌ Could not check RLS policies:', policiesError.message);
    } else {
      console.log('✅ RLS policies:', policies);
    }
    
  } catch (error) {
    console.error('❌ Error during table check:', error);
  }
}

checkAllTables();
