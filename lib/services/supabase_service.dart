import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: true),
    );
  }
  
  // OAuth provider sign-in - using same configuration as web module
  static Future<void> signInWithProvider(OAuthProvider provider) async {
    await client.auth.signInWithOAuth(
      provider,
      // Use same redirect URL as web module
      redirectTo: 'https://dkcitxzvojvecuvacwsp.supabase.co/auth/v1/callback',
    );
  }
  
  // Authentication methods
  static Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }
  
  static Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  static Future<void> signOut() async {
    try {
      print('🔄 DEBUG: Starting sign out process...');
      await client.auth.signOut(scope: SignOutScope.global);
      print('🔄 DEBUG: Sign out called, waiting for session to clear...');
      
      // Wait briefly until session is cleared to avoid race conditions on web
      for (int i = 0; i < 10; i++) {
        if (client.auth.currentSession == null) {
          print('✅ DEBUG: Session cleared successfully');
          break;
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      // Final check
      if (client.auth.currentSession != null) {
        print('⚠️ DEBUG: Session still exists after sign out');
      } else {
        print('✅ DEBUG: Sign out completed successfully');
      }
    } catch (e) {
      print('❌ DEBUG: Error during sign out: $e');
      // Even if sign out fails, we should still try to clear local state
      rethrow;
    }
  }
  
  static User? get currentUser => client.auth.currentUser;
  
  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
  
  // Database methods (aligned to database_schema.sql)
  static Future<List<Map<String, dynamic>>> getProfiles({
    double? userLat,
    double? userLon,
    double? maxDistanceKm,
    int? limit,
    int? offset,
  }) async {
    var query = client
        .from('profiles')
        .select();

    if (currentUser?.id != null) {
      query = query.neq('id', currentUser!.id);
    }

    // Note: Supabase Dart doesn't allow arbitrary SQL in lt on columns easily; we'll filter client-side for now
    // For now, we'll load all profiles and handle pagination client-side
    final response = await query;
    final allProfiles = (response as List).cast<Map<String, dynamic>>();
    
    // Apply client-side pagination
    if (offset != null && limit != null) {
      final start = offset;
      final end = offset + limit;
      return allProfiles.skip(start).take(limit).toList();
    } else if (limit != null) {
      return allProfiles.take(limit).toList();
    }
    
    return allProfiles;
  }
  
  static Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      print('🔄 DEBUG: SupabaseService.getProfile called for user: $userId');
      final response = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      print('🔄 DEBUG: SupabaseService.getProfile response: $response');
      return response;
    } catch (e) {
      print('❌ DEBUG: SupabaseService.getProfile error: $e');
      return null;
    }
  }
  
  static Future<void> updateProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    await client
        .from('profiles')
        .update(data)
        .eq('id', userId);
  }
  
  static Future<void> createProfile(Map<String, dynamic> profileData) async {
    await client
        .from('profiles')
        .insert(profileData);
  }

  // Auth helpers for OTP/password flows

  static Future<void> sendEmailOtp(String email) async {
    await client.auth.signInWithOtp(email: email, shouldCreateUser: true);
  }

  static Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    return await client.auth.verifyOTP(type: OtpType.email, token: token, email: email);
  }

  static Future<void> sendPhoneOtp(String phone) async {
    await client.auth.signInWithOtp(phone: phone, shouldCreateUser: true);
  }

  static Future<AuthResponse> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {
    return await client.auth.verifyOTP(type: OtpType.sms, token: token, phone: phone);
  }
  
  // Swipes and Matches
  static Future<void> insertSwipe({
    required String swiperId,
    required String swipedId,
    required String action, // 'like' | 'pass' | 'super_like'
  }) async {
    await client.from('swipes').upsert({
      'swiper_id': swiperId,
      'swiped_id': swipedId,
      'action': action,
    }, onConflict: 'swiper_id,swiped_id');
  }

  static Future<bool> hasReciprocalLike({
    required String userId,
    required String otherUserId,
  }) async {
    final rows = await client
        .from('swipes')
        .select('id')
        .eq('swiper_id', otherUserId)
        .eq('swiped_id', userId)
        .filter('action', 'in', '(like,super_like)')
        .limit(1);
    return (rows as List).isNotEmpty;
  }

  static Future<String?> createMatch({
    required String userId1,
    required String userId2,
  }) async {
    final inserted = await client
        .from('matches')
        .insert({
          'user_id_1': userId1,
          'user_id_2': userId2,
          'status': 'matched',
        })
        .select('id')
        .single();
    return (inserted['id'] ?? '').toString();
  }
  
  static Future<List<Map<String, dynamic>>> getMatches() async {
    final uid = currentUser?.id;
    if (uid == null) return [];
    // Some environments have issues with .or() on web; query both sides and merge client-side
    final List<Map<String, dynamic>> combined = [];
    try {
      final rows1 = await client
          .from('matches')
          .select('id,user_id_1,user_id_2,created_at,status')
          .eq('status', 'matched')
          .eq('user_id_1', uid) as List<dynamic>;
      combined.addAll(rows1.cast<Map<String, dynamic>>());
    } catch (_) {}
    try {
      final rows2 = await client
          .from('matches')
          .select('id,user_id_1,user_id_2,created_at,status')
          .eq('status', 'matched')
          .eq('user_id_2', uid) as List<dynamic>;
      // Merge without duplicates
      final existing = combined.map((e) => (e['id'] ?? '').toString()).toSet();
      for (final r in rows2) {
        final id = (r['id'] ?? '').toString();
        if (!existing.contains(id)) combined.add((r as Map).cast<String, dynamic>());
      }
    } catch (_) {}
    return combined;
  }

  static Future<List<Map<String, dynamic>>> getBFFMatches() async {
    final uid = currentUser?.id;
    if (uid == null) return [];
    // Query BFF matches table
    final List<Map<String, dynamic>> combined = [];
    try {
      final rows1 = await client
          .from('bff_matches')
          .select('id,user_id_1,user_id_2,created_at,status')
          .eq('status', 'matched')
          .eq('user_id_1', uid) as List<dynamic>;
      combined.addAll(rows1.cast<Map<String, dynamic>>());
    } catch (_) {}
    try {
      final rows2 = await client
          .from('bff_matches')
          .select('id,user_id_1,user_id_2,created_at,status')
          .eq('status', 'matched')
          .eq('user_id_2', uid) as List<dynamic>;
      // Merge without duplicates
      final existing = combined.map((e) => (e['id'] ?? '').toString()).toSet();
      for (final r in rows2) {
        final id = (r['id'] ?? '').toString();
        if (!existing.contains(id)) combined.add((r as Map).cast<String, dynamic>());
      }
    } catch (_) {}
    return combined;
  }

  // Get profiles with super like status (for dating mode)
  static Future<List<Map<String, dynamic>>> getProfilesWithSuperLikes() async {
    final uid = currentUser?.id;
    if (uid == null) return [];
    
    try {
      print('🔍 DEBUG: Calling get_profiles_with_super_likes for user: $uid');
      final response = await client.rpc('get_profiles_with_super_likes', params: {
        'p_user_id': uid,
        'p_limit': 20,
      });
      print('🔍 DEBUG: RPC response: $response');
      final result = (response as List).cast<Map<String, dynamic>>();
      print('🔍 DEBUG: Parsed result count: ${result.length}');
      for (int i = 0; i < result.length && i < 3; i++) {
        print('🔍 DEBUG: Profile $i: ${result[i]}');
      }
      return result;
    } catch (e) {
      print('Error fetching profiles with super likes: $e');
      // Try fallback to get_dating_profiles function
      try {
        print('🔍 DEBUG: Trying fallback to get_dating_profiles');
        final response = await client.rpc('get_dating_profiles', params: {
          'p_user_id': uid,
          'p_limit': 20,
        });
        final result = (response as List).cast<Map<String, dynamic>>();
        print('🔍 DEBUG: Fallback result count: ${result.length}');
        return result;
      } catch (fallbackError) {
        print('Fallback also failed: $fallbackError');
        // Final fallback to regular getProfiles
        return await getProfiles();
      }
    }
  }

  // Get BFF profiles (mode-specific)
  static Future<List<Map<String, dynamic>>> getBffProfiles() async {
    final uid = currentUser?.id;
    if (uid == null) return [];
    
    try {
      print('🔍 DEBUG: Calling get_bff_profiles for user: $uid');
      final response = await client.rpc('get_bff_profiles', params: {
        'p_user_id': uid,
      });
      print('🔍 DEBUG: BFF RPC response: $response');
      final result = (response as List).cast<Map<String, dynamic>>();
      print('🔍 DEBUG: BFF Parsed result count: ${result.length}');
      for (int i = 0; i < result.length && i < 3; i++) {
        print('🔍 DEBUG: BFF Profile $i: ${result[i]}');
      }
      return result;
    } catch (e) {
      print('Error fetching BFF profiles: $e');
      // Return empty list instead of fallback to avoid showing dating profiles in BFF mode
      print('🔍 DEBUG: Returning empty list for BFF profiles due to error');
      return [];
    }
  }

  // Record BFF interaction
  static Future<void> recordBffInteraction(String targetUserId, String interactionType) async {
    final uid = currentUser?.id;
    if (uid == null) return;
    
    try {
      print('🔍 DEBUG: Recording BFF interaction: $uid -> $targetUserId ($interactionType)');
      await client.rpc('record_bff_interaction', params: {
        'p_user_id': uid,
        'p_target_user_id': targetUserId,
        'p_interaction_type': interactionType,
      });
      print('✅ BFF interaction recorded successfully');
    } catch (e) {
      print('Error recording BFF interaction: $e');
    }
  }

  // Update user's mode preferences
  static Future<void> updateModePreferences(Map<String, bool> modePreferences) async {
    final uid = currentUser?.id;
    if (uid == null) return;
    
    try {
      print('🔍 DEBUG: Updating mode preferences for user: $uid');
      await client.from('profiles').update({
        'mode_preferences': modePreferences,
        'bff_enabled_at': modePreferences['bff'] == true ? DateTime.now().toIso8601String() : null,
      }).eq('id', uid);
      print('✅ Mode preferences updated successfully');
    } catch (e) {
      print('Error updating mode preferences: $e');
    }
  }

  // Activity Feed methods
  static Future<List<Map<String, dynamic>>> getUserActivities({int limit = 50}) async {
    final uid = currentUser?.id;
    if (uid == null) return [];
    
    try {
      final response = await client.rpc('get_user_activities', params: {
        'p_user_id': uid,
        'p_limit': limit,
      });
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching activities: $e');
      return [];
    }
  }

  static Future<void> markMessageAsRead(String messageId) async {
    try {
      await client
          .from('messages')
          .update({'is_read': true})
          .eq('id', messageId);
    } catch (e) {
      print('Error marking message as read: $e');
    }
  }

  static Future<Map<String, dynamic>?> getMatchById(String matchId) async {
    if (matchId.isEmpty) return null;
    final row = await client
        .from('matches')
        .select('id,user_id_1,user_id_2,created_at,status')
        .eq('id', matchId)
        .maybeSingle();
    return row;
  }
  
  // Messages
  static Future<List<Map<String, dynamic>>> getMessages(String matchId) async {
    final response = await client
        .from('messages')
        .select('id,match_id,sender_id,content,created_at,story_id,is_story_reply,story_user_name,is_disappearing_photo,disappearing_photo_id')
        .eq('match_id', matchId)
        .order('created_at', ascending: true);
    return (response as List).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getBffMessages(String matchId) async {
    // Get the chat_id from bff_matches table
    final bffMatch = await client
        .from('bff_matches')
        .select('id')
        .eq('id', matchId)
        .maybeSingle();
    
    if (bffMatch == null) return [];
    
    // Get the chat_id from bff_chats table
    final chat = await client
        .from('bff_chats')
        .select('id')
        .or('user_a_id.eq.${currentUser?.id},user_b_id.eq.${currentUser?.id}')
        .maybeSingle();
    
    if (chat == null) return [];
    
    // Get BFF messages
    final response = await client
        .from('bff_messages')
        .select('id,chat_id,sender_id,text,created_at')
        .eq('chat_id', chat['id'])
        .order('created_at', ascending: true);
    return (response as List).cast<Map<String, dynamic>>();
  }
  
  // =============================================================================
  // FREEMIUM SYSTEM METHODS
  // =============================================================================
  
  // Check if user can perform action (swipe, super_like, message)
  static Future<bool> canPerformAction(String action) async {
    try {
      final response = await client.rpc('can_perform_action', params: {
        'p_user_id': currentUser?.id,
        'p_action': action,
      });
      return response == true;
    } catch (e) {
      print('Error checking action permission: $e');
      return false;
    }
  }
  
  // Get daily usage for current user
  static Future<Map<String, int>> getDailyUsage() async {
    try {
      final response = await client.rpc('get_daily_usage', params: {
        'p_user_id': currentUser?.id,
        'p_date': DateTime.now().toIso8601String().split('T')[0], // Today's date
      });
      
      if (response is List && response.isNotEmpty) {
        final usage = response.first as Map<String, dynamic>;
        return {
          'swipes_used': usage['swipes_used'] ?? 0,
          'super_likes_used': usage['super_likes_used'] ?? 0,
          'messages_sent': usage['messages_sent'] ?? 0,
        };
      }
      
      return {'swipes_used': 0, 'super_likes_used': 0, 'messages_sent': 0};
    } catch (e) {
      print('Error getting daily usage: $e');
      return {'swipes_used': 0, 'super_likes_used': 0, 'messages_sent': 0};
    }
  }
  
  // Increment daily usage after action
  static Future<bool> incrementDailyUsage(String action) async {
    try {
      final response = await client.rpc('increment_daily_usage', params: {
        'p_user_id': currentUser?.id,
        'p_action': action,
      });
      return response == true;
    } catch (e) {
      print('Error incrementing daily usage: $e');
      return false;
    }
  }
  
  // Send premium message before matching
  static Future<Map<String, dynamic>> sendPremiumMessage({
    required String recipientId,
    required String message,
  }) async {
    try {
      final response = await client.rpc('send_premium_message', params: {
        'p_recipient_id': recipientId,
        'p_message_content': message,
      });
      return response as Map<String, dynamic>;
    } catch (e) {
      print('Error sending premium message: $e');
      return {'error': e.toString()};
    }
  }
  
  // Get premium messages for current user
  static Future<List<Map<String, dynamic>>> getPremiumMessages() async {
    try {
      final response = await client
          .from('premium_messages')
          .select('id, sender_id, message_content, is_blurred, created_at')
          .eq('recipient_id', currentUser?.id ?? '')
          .order('created_at', ascending: false);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error getting premium messages: $e');
      return [];
    }
  }
  
  // Reveal premium message (when user gets premium)
  static Future<bool> revealPremiumMessage(String messageId) async {
    try {
      final response = await client.rpc('reveal_premium_message', params: {
        'p_message_id': messageId,
      });
      return response['success'] == true;
    } catch (e) {
      print('Error revealing premium message: $e');
      return false;
    }
  }
  
  // Check if user is premium
  static Future<bool> isPremiumUser() async {
    try {
      final response = await client
          .from('profiles')
          .select('is_premium')
          .eq('id', currentUser?.id ?? '')
          .single();
      return response['is_premium'] == true;
    } catch (e) {
      print('Error checking premium status: $e');
      return false;
    }
  }

  // Mark swipe as rewindable for premium users
  static Future<void> _markSwipeAsRewindable(String swipedId, String action) async {
    try {
      await client
          .from('swipes')
          .update({
            'can_rewind': true,
          })
          .eq('swiper_id', currentUser?.id ?? '')
          .eq('swiped_id', swipedId);
    } catch (e) {
      print('Error marking swipe as rewindable: $e');
    }
  }
  
  // =============================================================================
  // EXISTING METHODS (UPDATED WITH FREEMIUM CHECKS)
  // =============================================================================

  static Future<void> sendMessage({
    required String matchId,
    required String content,
    String? storyId,
    String? storyUserName,
  }) async {
    // Check if user can send message (freemium check)
    final canSend = await canPerformAction('message');
    if (!canSend) {
      throw Exception('Daily message limit reached. Upgrade for unlimited messaging.');
    }
    
    await client.from('messages').insert({
      'match_id': matchId,
      'sender_id': currentUser?.id,
      'content': content,
      'story_id': storyId,
      'is_story_reply': storyId != null,
      'story_user_name': storyUserName,
    });
  }

  static Future<void> sendSystemMessage({
    required String matchId,
    required String content,
  }) async {
    await client.from('messages').insert({
      'match_id': matchId,
      'sender_id': currentUser?.id,
      'content': content,
    });
  }

  // Swipe + match via RPC (server-side, transactional)
  static Future<Map<String, dynamic>> handleSwipe({
    required String swipedId,
    required String action,
    String mode = 'dating', // 'dating' or 'bff'
  }) async {
    // Check freemium limits before swiping
    final canSwipe = await canPerformAction('swipe');
    if (!canSwipe) {
      return {
        'error': 'Daily swipe limit reached. Upgrade for unlimited swipes.',
        'limit_reached': true,
        'action': 'swipe'
      };
    }
    
    // Check super like limit if action is super_like
    if (action == 'super_like') {
      final canSuperLike = await canPerformAction('super_like');
      if (!canSuperLike) {
        return {
          'error': 'Daily super like limit reached. Buy more super likes or upgrade.',
          'limit_reached': true,
          'action': 'super_like'
        };
      }
    }
    
    // Use different RPC functions based on mode
    final String rpcFunction = mode == 'bff' ? 'handle_bff_swipe' : 'handle_swipe';
    
    print('🔍 DEBUG: Using RPC function: $rpcFunction for mode: $mode');
    
    final result = await client.rpc(rpcFunction, params: {
      'p_swiped_id': swipedId,
      'p_action': action,
    });
    
    print('DEBUG: Raw RPC result: $result (type: ${result.runtimeType})');
    
    // If swipe was successful, increment daily usage and mark as rewindable for premium users
    if (result is Map<String, dynamic> && result['error'] == null) {
      await incrementDailyUsage('swipe');
      if (action == 'super_like') {
        await incrementDailyUsage('super_like');
      }
      
      // Mark swipe as rewindable for premium users
      final isPremium = await isPremiumUser();
      if (isPremium) {
        await _markSwipeAsRewindable(swipedId, action);
      }
    }
    
    if (result is Map<String, dynamic>) {
      print('DEBUG: Returning Map result: $result');
      return result;
    }
    if (result is List && result.isNotEmpty && result.first is Map) {
      final firstResult = (result.first as Map).cast<String, dynamic>();
      print('DEBUG: Returning List[0] result: $firstResult');
      return firstResult;
    }
    print('DEBUG: Returning empty result for: $result');
    return <String, dynamic>{};
  }

  // Chat extension RPC
  static Future<void> extendChat(String matchId) async {
    await client.rpc('extend_chat', params: {
      'p_match_id': matchId,
    });
  }

  // Check if a chat has been extended on server
  static Future<bool> isChatExtended(String matchId) async {
    final row = await client
        .from('chat_extensions')
        .select('match_id')
        .eq('match_id', matchId)
        .maybeSingle();
    return row != null;
  }

  // Stream chat_extensions for a specific match
  static Stream<List<Map<String, dynamic>>> streamChatExtensions(String matchId) {
    return client
        .from('chat_extensions')
        .stream(primaryKey: ['match_id'])
        .eq('match_id', matchId);
  }

  // Update last_seen for current user
  static Future<void> updateLastSeen() async {
    final uid = currentUser?.id;
    if (uid == null) return;
    await client.from('profiles').update({'last_seen': DateTime.now().toIso8601String()}).eq('id', uid);
  }

  static Future<Map<String, dynamic>?> getProfileById(String userId) async {
    final row = await client
        .from('profiles')
        .select('name,image_urls,photos,last_seen')
        .eq('id', userId)
        .maybeSingle();
    return row;
  }
  
  // Real-time subscriptions
  static RealtimeChannel subscribeToMessages(String matchId, void Function(Map<String, dynamic>) onInsert) {
    return client
        .channel('messages_$matchId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'match_id', value: matchId),
          callback: (payload) {
            onInsert(payload.newRecord);
          },
        )
        .subscribe();
  }

  // Ensure current auth user has a profile row
  static Future<void> ensureCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return;
    try {
      final existing = await client.from('profiles').select('id').eq('id', user.id).maybeSingle();
      if (existing == null) {
        await client.from('profiles').insert({
          'id': user.id,
          'name': user.email ?? 'You',
          'age': 0,
          'is_active': false,
        });
      }
    } catch (_) {
      // ignore for now
    }
  }
  
  // File upload
  static Future<String> uploadFile({
    required String bucket,
    required String path,
    required List<int> fileBytes,
  }) async {
    try {
      await client.storage.from(bucket).uploadBinary(
        path,
        Uint8List.fromList(fileBytes),
      );
      
      final urlResponse = client.storage.from(bucket).getPublicUrl(path);
      return urlResponse;
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  // Stories
  static Future<List<Map<String, dynamic>>> getActiveStories() async {
    // Joinless select to work even if FK is not registered in schema cache
    final rows = await client
        .from('stories')
        .select('id,user_id,media_url,content,created_at,expires_at')
        .gt('expires_at', DateTime.now().toIso8601String())
        .order('created_at', ascending: false);
    
    print('DEBUG: getActiveStories - Found ${rows.length} total stories');
    for (final row in rows) {
      print('DEBUG: Story - user_id: ${row['user_id']}, created_at: ${row['created_at']}');
    }
    
    return (rows as List).cast<Map<String, dynamic>>();
  }
}
