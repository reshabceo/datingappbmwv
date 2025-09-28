import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = "https://dkcitxzvojvecuvacwsp.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrY2l0eHp2b2p2ZWN1dmFjd3NwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcxNDcwMTAsImV4cCI6MjA3MjcyMzAxMH0.0YmJgKVDkdmH6o-IMeT_eeMZEKBUfTuba9XsOruCYYw";

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function quickDataCheck() {
  console.log('🔍 Quick data check for admin panel...\n');
  
  try {
    // Check profiles (should show your user)
    console.log('👤 PROFILES:');
    const { data: profiles, error: profilesError } = await supabase
      .from('profiles')
      .select('id, name, email, created_at')
      .limit(10);
    
    if (profilesError) {
      console.log(`❌ Error: ${profilesError.message}`);
    } else {
      console.log(`✅ Found ${profiles?.length || 0} profiles`);
      profiles?.forEach((profile, index) => {
        console.log(`  ${index + 1}. ${profile.name} (${profile.email}) - ${profile.created_at}`);
      });
    }
    
    // Check messages
    console.log('\n💬 MESSAGES:');
    const { data: messages, error: messagesError } = await supabase
      .from('messages')
      .select('id, content, created_at, sender_id')
      .limit(10);
    
    if (messagesError) {
      console.log(`❌ Error: ${messagesError.message}`);
    } else {
      console.log(`✅ Found ${messages?.length || 0} messages`);
      messages?.forEach((message, index) => {
        console.log(`  ${index + 1}. ${message.content?.substring(0, 50)}... - ${message.created_at}`);
      });
    }
    
    // Check matches
    console.log('\n💕 MATCHES:');
    const { data: matches, error: matchesError } = await supabase
      .from('matches')
      .select('id, user_id_1, user_id_2, created_at')
      .limit(10);
    
    if (matchesError) {
      console.log(`❌ Error: ${matchesError.message}`);
    } else {
      console.log(`✅ Found ${matches?.length || 0} matches`);
      matches?.forEach((match, index) => {
        console.log(`  ${index + 1}. Match between ${match.user_id_1?.slice(0,8)}... and ${match.user_id_2?.slice(0,8)}...`);
      });
    }
    
    // Check admin users
    console.log('\n👑 ADMIN USERS:');
    const { data: adminUsers, error: adminError } = await supabase
      .from('admin_users')
      .select('id, email, full_name, role')
      .limit(10);
    
    if (adminError) {
      console.log(`❌ Error: ${adminError.message}`);
    } else {
      console.log(`✅ Found ${adminUsers?.length || 0} admin users`);
      adminUsers?.forEach((admin, index) => {
        console.log(`  ${index + 1}. ${admin.full_name} (${admin.email}) - ${admin.role}`);
      });
    }
    
    console.log('\n📋 SUMMARY:');
    console.log(`- Profiles: ${profiles?.length || 0}`);
    console.log(`- Messages: ${messages?.length || 0}`);
    console.log(`- Matches: ${matches?.length || 0}`);
    console.log(`- Admin Users: ${adminUsers?.length || 0}`);
    
    if (profiles?.length === 0) {
      console.log('\n⚠️  NO USER DATA FOUND!');
      console.log('This means your Flutter app data is not being saved to the database.');
      console.log('You need to:');
      console.log('1. Create a user profile in your Flutter app');
      console.log('2. Send some messages');
      console.log('3. Check if data appears here');
    }
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

quickDataCheck();
