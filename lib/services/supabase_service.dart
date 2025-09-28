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
  
  // OAuth provider sign-in
  static Future<void> signInWithProvider(Provider provider) async {
    await client.auth.signInWithOAuth(
      provider: provider,
      // On mobile, use external browser to avoid in-app webview issues
      authScreenLaunchMode: LaunchMode.externalApplication,
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
    await client.auth.signOut(scope: SignOutScope.global);
    // Wait briefly until session is cleared to avoid race conditions on web
    for (int i = 0; i < 10; i++) {
      if (client.auth.currentSession == null) break;
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
  
  static User? get currentUser => client.auth.currentUser;
  
  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
  
  // Database methods (aligned to database_schema.sql)
  static Future<List<Map<String, dynamic>>> getProfiles({
    double? userLat,
    double? userLon,
    double? maxDistanceKm,
  }) async {
    var query = client
        .from('profiles')
        .select();

    if (currentUser?.id != null) {
      query = query.neq('id', currentUser!.id);
    }

    // Note: Supabase Dart doesn't allow arbitrary SQL in lt on columns easily; we'll filter client-side for now

    final response = await query;
    return (response as List).cast<Map<String, dynamic>>();
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
  
  static Future<void> sendMessage({
    required String matchId,
    required String content,
    String? storyId,
    String? storyUserName,
  }) async {
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
  }) async {
    final result = await client.rpc('handle_swipe', params: {
      'p_swiped_id': swipedId,
      'p_action': action,
    });
    
    print('DEBUG: Raw RPC result: $result (type: ${result.runtimeType})');
    
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
        .select('id,user_id,media_url,created_at,expires_at')
        .gt('expires_at', DateTime.now().toIso8601String())
        .order('created_at', ascending: false);
    
    print('DEBUG: getActiveStories - Found ${rows.length} total stories');
    for (final row in rows) {
      print('DEBUG: Story - user_id: ${row['user_id']}, created_at: ${row['created_at']}');
    }
    
    return (rows as List).cast<Map<String, dynamic>>();
  }
}
