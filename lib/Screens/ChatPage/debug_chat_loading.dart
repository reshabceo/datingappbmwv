import 'package:get/get.dart';
import 'package:lovebug/services/supabase_service.dart';

class DebugChatLoading {
  static Future<void> testChatLoading() async {
    try {
      final uid = SupabaseService.currentUser?.id;
      if (uid == null) {
        print('❌ DEBUG: No user ID found');
        return;
      }
      
      print('🔍 DEBUG: Testing chat loading for user: $uid');
      
      // Test 1: Check all matches
      final allMatches = await SupabaseService.client
          .from('matches')
          .select('id, user_id_1, user_id_2')
          .or('user_id_1.eq.$uid,user_id_2.eq.$uid');
      
      print('🔍 DEBUG: Found ${allMatches.length} total matches');
      
      // Test 2: Check BFF matches
      final bffMatches = await SupabaseService.client
          .from('bff_matches')
          .select('id, user_id_1, user_id_2')
          .or('user_id_1.eq.$uid,user_id_2.eq.$uid');
      
      print('🔍 DEBUG: Found ${bffMatches.length} BFF matches');
      
      // Test 3: Check messages
      final messages = await SupabaseService.client
          .from('messages')
          .select('id, match_id, content, sender_id')
          .limit(10);
      
      print('🔍 DEBUG: Found ${messages.length} messages');
      
      // Test 4: Check if BFF matches exist in regular matches
      final bffIds = bffMatches.map((e) => e['id'].toString()).toSet();
      final datingMatches = allMatches.where((match) => !bffIds.contains(match['id'].toString())).toList();
      
      print('🔍 DEBUG: Found ${datingMatches.length} dating matches (excluding BFF)');
      
      // Test 5: Check messages for each match
      for (final match in allMatches) {
        final matchId = match['id'].toString();
        final matchMessages = await SupabaseService.client
            .from('messages')
            .select('content, created_at, sender_id')
            .eq('match_id', matchId)
            .order('created_at', ascending: false)
            .limit(1);
        
        print('🔍 DEBUG: Match $matchId has ${matchMessages.length} messages');
        if (matchMessages.isNotEmpty) {
          print('🔍 DEBUG: Latest message: ${matchMessages[0]['content']}');
        }
      }
      
    } catch (e) {
      print('❌ DEBUG: Error in chat loading test: $e');
    }
  }
}
