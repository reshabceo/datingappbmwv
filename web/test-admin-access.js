import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = "https://dkcitxzvojvecuvacwsp.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrY2l0eHp2b2p2ZWN1dmFjd3NwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcxNDcwMTAsImV4cCI6MjA3MjcyMzAxMH0.0YmJgKVDkdmH6o-IMeT_eeMZEKBUfTuba9XsOruCYYw";

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function testAdminAccess() {
  console.log('🔍 Testing admin access to communication data...\n');
  
  try {
    // First, try to sign in as admin
    console.log('1. Attempting admin login...');
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
      email: 'admin@datingapp.com',
      password: 'admin123'
    });
    
    if (authError) {
      console.log('❌ Admin login failed:', authError.message);
      return;
    }
    
    console.log('✅ Admin login successful');
    console.log('User ID:', authData.user?.id);
    
    // Now test accessing the data with authenticated session
    console.log('\n2. Testing conversation_metadata with admin session...');
    const { data: conversations, error: convError } = await supabase
      .from('conversation_metadata')
      .select('*')
      .order('last_activity', { ascending: false });
    
    console.log('Conversations result:', { 
      count: conversations?.length || 0, 
      error: convError?.message || null 
    });
    
    if (conversations && conversations.length > 0) {
      console.log('Sample conversation:', conversations[0]);
    }
    
    // Test matches
    console.log('\n3. Testing matches with admin session...');
    const { data: matches, error: matchesError } = await supabase
      .from('matches')
      .select('*');
    
    console.log('Matches result:', { 
      count: matches?.length || 0, 
      error: matchesError?.message || null 
    });
    
    // Test messages
    console.log('\n4. Testing messages with admin session...');
    const { data: messages, error: messagesError } = await supabase
      .from('messages')
      .select('*')
      .limit(5);
    
    console.log('Messages result:', { 
      count: messages?.length || 0, 
      error: messagesError?.message || null 
    });
    
    if (messages && messages.length > 0) {
      console.log('Sample message:', messages[0]);
    }
    
    // Test message_analytics
    console.log('\n5. Testing message_analytics with admin session...');
    const { data: analytics, error: analyticsError } = await supabase
      .from('message_analytics')
      .select('*')
      .order('date', { ascending: false })
      .limit(1);
    
    console.log('Analytics result:', { 
      count: analytics?.length || 0, 
      error: analyticsError?.message || null 
    });
    
  } catch (error) {
    console.error('❌ Error during admin access test:', error);
  }
}

testAdminAccess();
