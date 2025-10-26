import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = "https://dkcitxzvojvecuvacwsp.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrY2l0eHp2b2p2ZWN1dmFjd3NwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcxNDcwMTAsImV4cCI6MjA3MjcyMzAxMH0.0YmJgKVDkdmH6o-IMeT_eeMZEKBUfTuba9XsOruCYYw";

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function simpleDataCheck() {
  console.log('🔍 Simple data check...\n');
  
  try {
    // Authenticate as admin
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
      email: 'admin@datingapp.com',
      password: 'admin123'
    });
    
    if (authError) {
      console.log('❌ Auth failed:', authError.message);
      return;
    }
    
    console.log('✅ Authenticated as admin');
    
    // Check each table with count
    const tables = ['conversation_metadata', 'messages', 'matches', 'message_analytics', 'message_flags'];
    
    for (const table of tables) {
      console.log(`\n📊 Checking ${table}:`);
      
      const { count, error } = await supabase
        .from(table)
        .select('*', { count: 'exact', head: true });
      
      if (error) {
        console.log(`  ❌ Error: ${error.message}`);
      } else {
        console.log(`  ✅ Count: ${count || 0} records`);
        
        // If there are records, fetch a few samples
        if (count > 0) {
          const { data, error: dataError } = await supabase
            .from(table)
            .select('*')
            .limit(3);
          
          if (dataError) {
            console.log(`  ❌ Data fetch error: ${dataError.message}`);
          } else {
            console.log(`  📋 Sample records:`);
            data.forEach((record, index) => {
              console.log(`    ${index + 1}. ${JSON.stringify(record, null, 2)}`);
            });
          }
        }
      }
    }
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

simpleDataCheck();
