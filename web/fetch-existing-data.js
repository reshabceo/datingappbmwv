import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = "https://dkcitxzvojvecuvacwsp.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrY2l0eHp2b2p2ZWN1dmFjd3NwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcxNDcwMTAsImV4cCI6MjA3MjcyMzAxMH0.0YmJgKVDkdmH6o-IMeT_eeMZEKBUfTuba9XsOruCYYw";

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function fetchExistingData() {
  console.log('🔍 Fetching existing data from Supabase...\n');
  
  try {
    // Authenticate as admin
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
    
    // Try different approaches to fetch data
    console.log('\n2. Trying different query approaches...');
    
    // Approach 1: Direct select with no filters
    console.log('\n--- Approach 1: Direct select ---');
    const { data: conv1, error: conv1Error } = await supabase
      .from('conversation_metadata')
      .select('*');
    console.log('conversation_metadata (direct):', { count: conv1?.length || 0, error: conv1Error?.message });
    
    const { data: msg1, error: msg1Error } = await supabase
      .from('messages')
      .select('*');
    console.log('messages (direct):', { count: msg1?.length || 0, error: msg1Error?.message });
    
    const { data: match1, error: match1Error } = await supabase
      .from('matches')
      .select('*');
    console.log('matches (direct):', { count: match1?.length || 0, error: match1Error?.message });
    
    // Approach 2: Try with different column selections
    console.log('\n--- Approach 2: Specific columns ---');
    const { data: conv2, error: conv2Error } = await supabase
      .from('conversation_metadata')
      .select('id, match_id, last_activity, message_count');
    console.log('conversation_metadata (specific cols):', { count: conv2?.length || 0, error: conv2Error?.message });
    
    // Approach 3: Try with count only
    console.log('\n--- Approach 3: Count only ---');
    const { count: convCount, error: convCountError } = await supabase
      .from('conversation_metadata')
      .select('*', { count: 'exact', head: true });
    console.log('conversation_metadata count:', { count: convCount, error: convCountError?.message });
    
    const { count: msgCount, error: msgCountError } = await supabase
      .from('messages')
      .select('*', { count: 'exact', head: true });
    console.log('messages count:', { count: msgCount, error: msgCountError?.message });
    
    const { count: matchCount, error: matchCountError } = await supabase
      .from('matches')
      .select('*', { count: 'exact', head: true });
    console.log('matches count:', { count: matchCount, error: matchCountError?.message });
    
    // Approach 4: Try with different schemas
    console.log('\n--- Approach 4: Check different schemas ---');
    const { data: allTables, error: tablesError } = await supabase
      .rpc('get_table_names');
    console.log('Available tables:', { data: allTables, error: tablesError?.message });
    
    // Approach 5: Try raw SQL query
    console.log('\n--- Approach 5: Raw SQL approach ---');
    const { data: rawConv, error: rawConvError } = await supabase
      .rpc('exec_sql', { query: 'SELECT COUNT(*) FROM conversation_metadata' });
    console.log('Raw SQL conversation_metadata count:', { data: rawConv, error: rawConvError?.message });
    
    // If we found any data, show it
    if (conv1 && conv1.length > 0) {
      console.log('\n📊 Found conversation_metadata data:');
      conv1.forEach((conv, index) => {
        console.log(`  ${index + 1}. ID: ${conv.id}, Match: ${conv.match_id}, Messages: ${conv.message_count}`);
      });
    }
    
    if (msg1 && msg1.length > 0) {
      console.log('\n💬 Found messages data:');
      msg1.forEach((msg, index) => {
        console.log(`  ${index + 1}. ID: ${msg.id}, Match: ${msg.match_id}, Content: ${msg.content?.substring(0, 50)}...`);
      });
    }
    
    if (match1 && match1.length > 0) {
      console.log('\n🤝 Found matches data:');
      match1.forEach((match, index) => {
        console.log(`  ${index + 1}. ID: ${match.id}, Users: ${match.user_id_1?.slice(0,8)}... & ${match.user_id_2?.slice(0,8)}...`);
      });
    }
    
  } catch (error) {
    console.error('❌ Error fetching data:', error);
  }
}

fetchExistingData();
