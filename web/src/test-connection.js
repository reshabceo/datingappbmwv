// Test script to verify Supabase connection
import { supabase } from './supabaseClient.js'

async function testConnection() {
  console.log('🔍 Testing Supabase connection...')
  
  try {
    // Test 1: Check if we can connect to Supabase
    const { data, error } = await supabase.from('profiles').select('count').limit(1)
    
    if (error) {
      console.error('❌ Connection failed:', error.message)
      return false
    }
    
    console.log('✅ Supabase connection successful!')
    
    // Test 2: Get actual user count
    const { count, error: countError } = await supabase
      .from('profiles')
      .select('*', { count: 'exact', head: true })
    
    if (countError) {
      console.error('❌ Count query failed:', countError.message)
      return false
    }
    
    console.log(`📊 Found ${count} users in database`)
    
    // Test 3: Get actual user data
    const { data: users, error: usersError } = await supabase
      .from('profiles')
      .select('id, name, email, created_at, is_active')
      .limit(5)
    
    if (usersError) {
      console.error('❌ Users query failed:', usersError.message)
      return false
    }
    
    console.log('👥 Users found:', users)
    console.log('✅ All tests passed! Admin panel should now show real data.')
    
    return true
    
  } catch (err) {
    console.error('❌ Test failed:', err)
    return false
  }
}

// Run the test
testConnection()
