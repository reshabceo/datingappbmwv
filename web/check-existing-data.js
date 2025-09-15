import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = "https://dkcitxzvojvecuvacwsp.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrY2l0eHp2b2p2ZWN1dmFjd3NwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcxNDcwMTAsImV4cCI6MjA3MjcyMzAxMH0.0YmJgKVDkdmH6o-IMeT_eeMZEKBUfTuba9XsOruCYYw";

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function checkExistingData() {
  console.log('🔍 Checking existing data in Supabase...\n');
  
  try {
    // Check matches
    console.log('📊 MATCHES:');
    const { data: matches, error: matchesError } = await supabase
      .from('matches')
      .select('*')
      .limit(10);
    
    if (matchesError) {
      console.log(`❌ Error: ${matchesError.message}`);
    } else {
      console.log(`✅ Found ${matches?.length || 0} matches`);
      if (matches && matches.length > 0) {
        matches.forEach((match, index) => {
          console.log(`  ${index + 1}. ID: ${match.id} - Users: ${match.user_id_1?.slice(0,8)}... & ${match.user_id_2?.slice(0,8)}... (Status: ${match.status})`);
        });
      }
    }
    
    // Check messages
    console.log('\n💬 MESSAGES:');
    const { data: messages, error: messagesError } = await supabase
      .from('messages')
      .select('*')
      .limit(10);
    
    if (messagesError) {
      console.log(`❌ Error: ${messagesError.message}`);
    } else {
      console.log(`✅ Found ${messages?.length || 0} messages`);
      if (messages && messages.length > 0) {
        messages.forEach((msg, index) => {
          console.log(`  ${index + 1}. ID: ${msg.id} - Match: ${msg.match_id?.slice(0,8)}... - Sender: ${msg.sender_id?.slice(0,8)}... - Content: "${msg.content?.substring(0, 50)}..."`);
        });
      }
    }
    
    // Check profiles
    console.log('\n👤 PROFILES:');
    const { data: profiles, error: profilesError } = await supabase
      .from('profiles')
      .select('*')
      .limit(10);
    
    if (profilesError) {
      console.log(`❌ Error: ${profilesError.message}`);
    } else {
      console.log(`✅ Found ${profiles?.length || 0} profiles`);
      if (profiles && profiles.length > 0) {
        profiles.forEach((profile, index) => {
          console.log(`  ${index + 1}. ID: ${profile.id} - Name: ${profile.name || 'No name'} - Age: ${profile.age || 'No age'}`);
        });
      }
    }
    
    // Check conversation_metadata (if exists)
    console.log('\n💬 CONVERSATION METADATA:');
    const { data: conversations, error: convError } = await supabase
      .from('conversation_metadata')
      .select('*')
      .limit(10);
    
    if (convError) {
      console.log(`❌ Table doesn't exist or error: ${convError.message}`);
    } else {
      console.log(`✅ Found ${conversations?.length || 0} conversation records`);
      if (conversations && conversations.length > 0) {
        conversations.forEach((conv, index) => {
          console.log(`  ${index + 1}. ID: ${conv.id} - Match: ${conv.match_id?.slice(0,8)}... - Messages: ${conv.message_count} - Flagged: ${conv.is_flagged}`);
        });
      }
    }
    
    // Check message_analytics (if exists)
    console.log('\n📈 MESSAGE ANALYTICS:');
    const { data: analytics, error: analyticsError } = await supabase
      .from('message_analytics')
      .select('*')
      .limit(10);
    
    if (analyticsError) {
      console.log(`❌ Table doesn't exist or error: ${analyticsError.message}`);
    } else {
      console.log(`✅ Found ${analytics?.length || 0} analytics records`);
      if (analytics && analytics.length > 0) {
        analytics.forEach((analytics, index) => {
          console.log(`  ${index + 1}. Date: ${analytics.date} - Total Messages: ${analytics.total_messages} - Flagged: ${analytics.flagged_messages}`);
        });
      }
    }
    
    // Check banned_users
    console.log('\n🚫 BANNED USERS:');
    const { data: bannedUsers, error: bannedError } = await supabase
      .from('banned_users')
      .select('*')
      .limit(10);
    
    if (bannedError) {
      console.log(`❌ Error: ${bannedError.message}`);
    } else {
      console.log(`✅ Found ${bannedUsers?.length || 0} banned users`);
      if (bannedUsers && bannedUsers.length > 0) {
        bannedUsers.forEach((banned, index) => {
          console.log(`  ${index + 1}. User ID: ${banned.user_id?.slice(0,8)}... - Active: ${banned.is_active} - Reason: ${banned.reason}`);
        });
      }
    }
    
    // Summary
    console.log('\n📋 SUMMARY:');
    console.log(`- Matches: ${matches?.length || 0}`);
    console.log(`- Messages: ${messages?.length || 0}`);
    console.log(`- Profiles: ${profiles?.length || 0}`);
    console.log(`- Conversation Metadata: ${conversations?.length || 0} (${convError ? 'Table missing' : 'Table exists'})`);
    console.log(`- Message Analytics: ${analytics?.length || 0} (${analyticsError ? 'Table missing' : 'Table exists'})`);
    console.log(`- Banned Users: ${bannedUsers?.length || 0}`);
    
  } catch (error) {
    console.error('❌ Error checking data:', error);
  }
}

checkExistingData();
