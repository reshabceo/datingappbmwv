import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = "https://dkcitxzvojvecuvacwsp.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrY2l0eHp2b2p2ZWN1dmFjd3NwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcxNDcwMTAsImV4cCI6MjA3MjcyMzAxMH0.0YmJgKVDkdmH6o-IMeT_eeMZEKBUfTuba9XsOruCYYw";

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function debugCommunicationLogs() {
  console.log('🔍 Debugging Communication Logs data fetching...\n');
  
  try {
    // Test 1: Check conversation_metadata
    console.log('1. Testing conversation_metadata query...');
    const { data: conversations, error: convError } = await supabase
      .from('conversation_metadata')
      .select('*')
      .order('last_activity', { ascending: false });
    
    console.log('Conversations result:', { data: conversations, error: convError });
    
    // Test 2: Check matches
    console.log('\n2. Testing matches query...');
    const { data: matches, error: matchesError } = await supabase
      .from('matches')
      .select('*');
    
    console.log('Matches result:', { data: matches, error: matchesError });
    
    // Test 3: Check profiles
    console.log('\n3. Testing profiles query...');
    const { data: profiles, error: profilesError } = await supabase
      .from('profiles')
      .select('id, name')
      .limit(5);
    
    console.log('Profiles result:', { data: profiles, error: profilesError });
    
    // Test 4: Check message_analytics
    console.log('\n4. Testing message_analytics query...');
    const { data: analytics, error: analyticsError } = await supabase
      .from('message_analytics')
      .select('*')
      .order('date', { ascending: false })
      .limit(1);
    
    console.log('Analytics result:', { data: analytics, error: analyticsError });
    
    // Test 5: Check banned_users
    console.log('\n5. Testing banned_users query...');
    const { data: bannedUsers, error: bannedError } = await supabase
      .from('banned_users')
      .select('*', { count: 'exact' })
      .eq('is_active', true);
    
    console.log('Banned users result:', { data: bannedUsers, error: bannedError });
    
    // Test 6: Check messages
    console.log('\n6. Testing messages query...');
    const { data: messages, error: messagesError } = await supabase
      .from('messages')
      .select('*')
      .limit(5);
    
    console.log('Messages result:', { data: messages, error: messagesError });
    
  } catch (error) {
    console.error('❌ Error during debugging:', error);
  }
}

debugCommunicationLogs();
