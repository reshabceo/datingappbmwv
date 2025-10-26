import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = "https://dkcitxzvojvecuvacwsp.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrY2l0eHp2b2p2ZWN1dmFjd3NwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcxNDcwMTAsImV4cCI6MjA3MjcyMzAxMH0.0YmJgKVDkdmH6o-IMeT_eeMZEKBUfTuba9XsOruCYYw";

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function testAdminConnection() {
  console.log('🔍 Testing admin panel connection...\n');
  
  try {
    // Login as admin
    console.log('1. Logging in as admin...');
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
      email: 'admin@datingapp.com',
      password: 'admin123'
    });
    
    if (authError) {
      console.log('❌ Admin login failed:', authError.message);
      return;
    }
    
    console.log('✅ Admin login successful');
    
    // Test accessing profiles (should show real users)
    console.log('\n2. Testing profiles access...');
    const { data: profiles, error: profilesError } = await supabase
      .from('profiles')
      .select('id, name, age, location, created_at')
      .limit(10);
    
    if (profilesError) {
      console.log('❌ Profiles error:', profilesError.message);
    } else {
      console.log(`✅ Found ${profiles?.length || 0} profiles`);
      profiles?.forEach((profile, index) => {
        console.log(`  ${index + 1}. ${profile.name} (${profile.age}) - ${profile.location}`);
      });
    }
    
    // Test accessing messages
    console.log('\n3. Testing messages access...');
    const { data: messages, error: messagesError } = await supabase
      .from('messages')
      .select('id, content, created_at, sender_id')
      .limit(10);
    
    if (messagesError) {
      console.log('❌ Messages error:', messagesError.message);
    } else {
      console.log(`✅ Found ${messages?.length || 0} messages`);
      messages?.forEach((message, index) => {
        console.log(`  ${index + 1}. ${message.content?.substring(0, 50)}... - ${message.created_at}`);
      });
    }
    
    // Test accessing matches
    console.log('\n4. Testing matches access...');
    const { data: matches, error: matchesError } = await supabase
      .from('matches')
      .select('id, user_id_1, user_id_2, created_at')
      .limit(10);
    
    if (matchesError) {
      console.log('❌ Matches error:', matchesError.message);
    } else {
      console.log(`✅ Found ${matches?.length || 0} matches`);
      matches?.forEach((match, index) => {
        console.log(`  ${index + 1}. Match between ${match.user_id_1?.slice(0,8)}... and ${match.user_id_2?.slice(0,8)}...`);
      });
    }
    
    console.log('\n📋 SUMMARY:');
    console.log(`- Profiles: ${profiles?.length || 0} (should show your real users)`);
    console.log(`- Messages: ${messages?.length || 0} (should show chat messages)`);
    console.log(`- Matches: ${matches?.length || 0} (should show user matches)`);
    
    if (profiles?.length > 0) {
      console.log('\n✅ SUCCESS: Admin panel can access real data!');
      console.log('The admin panel should now show your real users instead of dummy data.');
    } else {
      console.log('\n⚠️  ISSUE: No real data found');
      console.log('This means the admin panel queries need to be fixed.');
    }
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

testAdminConnection();
