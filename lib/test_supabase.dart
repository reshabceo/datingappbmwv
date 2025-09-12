import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';

// Test file to verify Supabase connection
// Run this to test if Supabase is working

Future<void> testSupabaseConnection() async {
  try {
    // Initialize Supabase
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    
    print('✅ Supabase initialized successfully!');
    
    // Test connection by getting current user (should be null initially)
    final user = Supabase.instance.client.auth.currentUser;
    print('Current user: ${user?.id ?? "Not logged in"}');
    
    // Test database connection by trying to read from profiles table
    final response = await Supabase.instance.client
        .from('profiles')
        .select('count')
        .limit(1);
    
    print('✅ Database connection successful!');
    print('Response: $response');
    
  } catch (e) {
    print('❌ Error connecting to Supabase: $e');
  }
}
