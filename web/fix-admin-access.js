import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = "https://dkcitxzvojvecuvacwsp.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrY2l0eHp2b2p2ZWN1dmFjd3NwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcxNDcwMTAsImV4cCI6MjA3MjcyMzAxMH0.0YmJgKVDkdmH6o-IMeT_eeMZEKBUfTuba9XsOruCYYw";

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function fixAdminAccess() {
  console.log('🔧 Fixing admin access to communication data...\n');
  
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
    
    console.log('✅ Admin authenticated');
    console.log('Admin user ID:', authData.user?.id);
    
    // Check if admin_users table exists and what it contains
    console.log('\n2. Checking admin_users table...');
    const { data: adminUsers, error: adminUsersError } = await supabase
      .from('admin_users')
      .select('*');
    
    if (adminUsersError) {
      console.log('❌ Error accessing admin_users table:', adminUsersError.message);
      console.log('This suggests the admin_users table might not exist or have different permissions');
      return;
    }
    
    console.log('✅ admin_users table accessible');
    console.log('Current admin users:', adminUsers?.length || 0);
    
    if (adminUsers && adminUsers.length > 0) {
      console.log('Existing admin users:', adminUsers);
    }
    
    // Check if our admin user is already in admin_users
    const existingAdmin = adminUsers?.find(admin => admin.id === authData.user?.id);
    
    if (existingAdmin) {
      console.log('✅ Admin user already exists in admin_users table');
    } else {
      console.log('\n3. Adding admin user to admin_users table...');
      
      // Add the admin user to admin_users table
      const { data: newAdmin, error: insertError } = await supabase
        .from('admin_users')
        .insert({
          id: authData.user?.id,
          email: authData.user?.email,
          full_name: 'Admin User',
          role: 'super_admin',
          is_active: true,
          created_at: new Date().toISOString()
        })
        .select();
      
      if (insertError) {
        console.log('❌ Error adding admin to admin_users:', insertError.message);
        return;
      }
      
      console.log('✅ Admin user added to admin_users table');
      console.log('New admin record:', newAdmin);
    }
    
    // Now test accessing the communication data
    console.log('\n4. Testing access to communication data...');
    
    // Test conversation_metadata
    const { data: conversations, error: convError } = await supabase
      .from('conversation_metadata')
      .select('*')
      .limit(5);
    
    console.log('Conversation metadata access:', { 
      count: conversations?.length || 0, 
      error: convError?.message || null 
    });
    
    // Test messages
    const { data: messages, error: msgError } = await supabase
      .from('messages')
      .select('*')
      .limit(5);
    
    console.log('Messages access:', { 
      count: messages?.length || 0, 
      error: msgError?.message || null 
    });
    
    // Test message_analytics
    const { data: analytics, error: analyticsError } = await supabase
      .from('message_analytics')
      .select('*')
      .limit(5);
    
    console.log('Message analytics access:', { 
      count: analytics?.length || 0, 
      error: analyticsError?.message || null 
    });
    
    // Test matches
    const { data: matches, error: matchesError } = await supabase
      .from('matches')
      .select('*')
      .limit(5);
    
    console.log('Matches access:', { 
      count: matches?.length || 0, 
      error: matchesError?.message || null 
    });
    
    if (conversations && conversations.length > 0) {
      console.log('\n🎉 SUCCESS! Admin can now access communication data');
      console.log('The Communication Logs section should now work properly!');
    } else {
      console.log('\n⚠️  Admin access fixed but no data found in communication tables');
      console.log('The data might be in a different state than expected');
    }
    
  } catch (error) {
    console.error('❌ Error fixing admin access:', error);
  }
}

fixAdminAccess();
