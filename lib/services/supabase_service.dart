import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'push_notification_service.dart';
import 'content_filter_service.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: true,
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }
  
  // OAuth provider sign-in - using in-app browser (SFSafariViewController on iOS)
  // This ensures authentication happens within the app, not in external browser
  static Future<void> signInWithProvider(OAuthProvider provider) async {
    await client.auth.signInWithOAuth(
      provider,
      // Use app-specific redirect URL for mobile
      redirectTo: 'com.lovebug.lovebug://login-callback',
      // Use inAppWebView to ensure it opens in-app browser (SFSafariViewController on iOS)
      // This is required by Apple App Store guidelines
      authScreenLaunchMode: LaunchMode.inAppWebView, // Forces in-app browser on all platforms
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
      
      // CRITICAL FIX: Clean up call listener service before signing out
      try {
        // Call the cleanup method directly to avoid circular dependency
        // This will be handled by the main.dart auth state listener
        print('📞 CallListenerService cleanup will be handled by auth state listener');
      } catch (e) {
        print('⚠️ Error preparing CallListenerService cleanup: $e');
      }
      
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

  // Check if user exists and get their authentication providers
  static Future<Map<String, dynamic>?> checkUserAuthProviders(String email) async {
    try {
      // Try to get user info by email (this will work if user exists)
      final response = await client.auth.admin.listUsers();
      
      // Find user by email
      for (var user in response) {
        if (user.email == email) {
          return {
            'exists': true,
            'providers': user.appMetadata?['providers'] ?? [],
            'identities': user.identities?.map((i) => i.provider).toList() ?? [],
          };
        }
      }
      return {'exists': false};
    } catch (e) {
      print('Error checking user providers: $e');
      return null;
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
    dynamic query = client
        .from('profiles')
        .select();

    if (currentUser?.id != null) {
      query = query.neq('id', currentUser!.id);
    }

    if (offset != null) {
      final start = offset;
      final end = offset + (limit ?? 50) - 1;
      query = query.range(start, end);
    } else if (limit != null) {
      query = query.limit(limit);
    }

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
      
      // 🔍 DEBUG: Log specific fields we care about
      if (response != null) {
        print('🔍 DEBUG: Profile is_active: ${response['is_active']}');
        print('🔍 DEBUG: Profile email: ${response['email']}');
        print('🔍 DEBUG: Profile created_at: ${response['created_at']}');
      } else {
        print('🔍 DEBUG: No profile found for user: $userId');
      }
      
      return response;
    } catch (e) {
      print('❌ DEBUG: SupabaseService.getProfile error: $e');
      return null;
    }
  }

  /// Store/update the device FCM token for the current user
  static Future<void> updateFCMToken(String token) async {
    try {
      final userId = currentUser?.id;
      print('🔔 DEBUG: updateFCMToken called - userId: $userId, token length: ${token.length}');
      
      if (userId == null) {
        print('❌ DEBUG: No current user found, cannot update FCM token');
        return;
      }
      
      if (token.isEmpty) {
        print('❌ DEBUG: FCM token is empty, cannot update');
        return;
      }
      
      final response = await client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', userId);
      
      print('🔔 DEBUG: FCM token update response: $response');
      print('✅ FCM token updated for user: $userId');
    } catch (e) {
      print('❌ Failed to update FCM token: $e');
    }
  }

  /// Update notification preference
  static Future<void> updateNotificationPreference(String key, bool value) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return;
      
      await client
          .from('profiles')
          .update({key: value})
          .eq('id', userId);
      
      print('✅ Notification preference updated: $key = $value');
    } catch (e) {
      print('❌ Failed to update notification preference: $e');
    }
  }

  /// Get notification preferences
  static Future<Map<String, bool>> getNotificationPreferences() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return {};
      
      final response = await client
          .from('profiles')
          .select('notification_matches, notification_messages, notification_stories, notification_likes, notification_admin')
          .eq('id', userId)
          .single();
      
      return {
        'notification_matches': response['notification_matches'] ?? true,
        'notification_messages': response['notification_messages'] ?? true,
        'notification_stories': response['notification_stories'] ?? true,
        'notification_likes': response['notification_likes'] ?? true,
        'notification_admin': response['notification_admin'] ?? true,
      };
    } catch (e) {
      print('❌ Failed to get notification preferences: $e');
      return {};
    }
  }
  
  static Future<void> updateProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    // If gender is being updated, also update is_premium accordingly
    if (data.containsKey('gender')) {
      final gender = (data['gender'] ?? '').toString();
      final bool isPremium = gender.toLowerCase() == 'female';
      data['is_premium'] = isPremium;
    }
    
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

  static Future<void> upsertProfile(Map<String, dynamic> profileData) async {
    try {
      print('🔄 DEBUG: Upserting profile for user: ${profileData['id']}');
      await client
          .from('profiles')
          .upsert(profileData);
      print('✅ DEBUG: Profile upserted successfully');
    } catch (e) {
      print('❌ DEBUG: Profile upsert failed: $e');
      rethrow;
    }
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

  // Update user email
  static Future<UserResponse> updateUserEmail(String newEmail) async {
    try {
      final response = await client.auth.updateUser(
        UserAttributes(email: newEmail),
      );
      
      // Also update email in profiles table
      final userId = currentUser?.id;
      if (userId != null) {
        await client
            .from('profiles')
            .update({'email': newEmail})
            .eq('id', userId);
      }
      
      return response;
    } catch (e) {
      print('Error updating email: $e');
      rethrow;
    }
  }

  // Update user password
  static Future<UserResponse> updateUserPassword(String newPassword) async {
    try {
      final response = await client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return response;
    } catch (e) {
      print('Error updating password: $e');
      rethrow;
    }
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
  static Future<List<Map<String, dynamic>>> getProfilesWithSuperLikes({
    double? userLatitude,
    double? userLongitude,
    double? maxDistanceKm,
  }) async {
    final uid = currentUser?.id;
    if (uid == null) return [];
    
    try {
      print('🔍 DEBUG: Calling get_profiles_with_super_likes_v2 for user: $uid');
      final params = {
        'p_user_id': uid,
        'p_limit': 20,
        'p_exclude_hours': 24,
      };
      
      // Add location parameters if provided
      if (userLatitude != null && userLongitude != null && maxDistanceKm != null && maxDistanceKm > 0) {
        params['p_user_latitude'] = userLatitude;
        params['p_user_longitude'] = userLongitude;
        params['p_max_distance_km'] = maxDistanceKm;
        print('📍 DEBUG: Location filtering enabled - Lat: $userLatitude, Lon: $userLongitude, Max: $maxDistanceKm km');
      } else {
        print('📍 DEBUG: Location filtering disabled - showing all profiles');
      }
      
      final response = await client.rpc('get_profiles_with_super_likes_v2', params: params);
      print('🔍 DEBUG: RPC response: $response');
      final result = (response as List).cast<Map<String, dynamic>>();
      print('🔍 DEBUG: Parsed result count: ${result.length}');
      for (int i = 0; i < result.length && i < 3; i++) {
        print('🔍 DEBUG: Profile $i: ${result[i]}');
      }
      return result;
    } catch (e) {
      print('Error fetching profiles with super likes: $e');
      // Try fallback without location params (backward compatible)
      try {
        print('🔍 DEBUG: Trying fallback without location params');
        final response = await client.rpc('get_profiles_with_super_likes', params: {
          'p_user_id': uid,
          'p_limit': 20,
          'p_exclude_hours': 24,
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
    if (uid == null) {
      print('⚠️ DEBUG: No user ID, returning empty BFF profiles');
      return [];
    }
    
    try {
      print('🔍 DEBUG: Calling get_bff_profiles for user: $uid');
      final response = await client.rpc('get_bff_profiles', params: {
        'p_user_id': uid,
      });
      print('🔍 DEBUG: BFF RPC response type: ${response.runtimeType}');
      print('🔍 DEBUG: BFF RPC response: $response');
      
      if (response == null) {
        print('⚠️ DEBUG: BFF RPC returned null');
        return [];
      }
      
      final result = (response as List).cast<Map<String, dynamic>>();
      print('🔍 DEBUG: BFF Parsed result count: ${result.length}');
      
      // If we got results, return them immediately
      if (result.isNotEmpty) {
        print('✅ DEBUG: Successfully fetched ${result.length} BFF profiles from RPC');
        for (int i = 0; i < result.length && i < 3; i++) {
          print('🔍 DEBUG: BFF Profile $i: ${result[i]}');
        }
        return result;
      }
      
      // Only try fallback if RPC returned empty
      if (result.isEmpty) {
        print('⚠️ DEBUG: No BFF profiles found from RPC. Trying fallback query...');
        
        // Fallback: Query profiles directly checking both bff_enabled and mode_preferences
        try {
          // Get excluded user IDs (already interacted/matched)
          final excludedIds = <String>{};
          try {
            final interactions = await client
                .from('bff_interactions')
                .select('target_user_id')
                .eq('user_id', uid);
            for (var interaction in interactions) {
              excludedIds.add((interaction['target_user_id'] ?? '').toString());
            }
            
            final matches = await client
                .from('bff_matches')
                .select('user_id_1, user_id_2')
                .or('user_id_1.eq.$uid,user_id_2.eq.$uid')
                .filter('status', 'in', '(${['matched', 'active'].map((s) => '"$s"').join(',')})');
            for (var match in matches) {
              final id1 = (match['user_id_1'] ?? '').toString();
              final id2 = (match['user_id_2'] ?? '').toString();
              excludedIds.add(id1 == uid ? id2 : id1);
            }
          } catch (_) {}
          
          // Query profiles with BFF enabled (use bff_enabled column only)
          // Select only columns that exist (removed: interests, bio, intent)
          var fallbackResponse = await client
              .from('profiles')
              .select('id, name, age, photos, image_urls, location, description, hobbies, gender, latitude, longitude, created_at, bff_enabled')
              .neq('id', uid)
              .eq('bff_enabled', true)
              .limit(20);
          
          print('🔍 DEBUG: Fallback query found ${fallbackResponse.length} profiles with BFF enabled');
          
          // Filter out excluded IDs
          final filtered = fallbackResponse
              .where((p) => !excludedIds.contains((p['id'] ?? '').toString()))
              .toList();
          
          print('🔍 DEBUG: After filtering excluded IDs: ${filtered.length} profiles');
          
          if (filtered.isNotEmpty) {
            print('✅ DEBUG: Using fallback query results');
            return filtered.cast<Map<String, dynamic>>();
          }
        } catch (fallbackError) {
          print('⚠️ DEBUG: Fallback query also failed: $fallbackError');
        }
        
        print('⚠️ DEBUG: No BFF profiles found. Possible reasons:');
        print('  1. No profiles have bff_enabled = true');
        print('  2. No profiles have mode_preferences->>\'bff\' = \'true\'');
        print('  3. All profiles already interacted with');
        print('  4. Database function might have different requirements');
        
        // Try to check how many profiles have BFF enabled
        try {
          final checkResponse = await client
              .from('profiles')
              .select('id, name, bff_enabled, mode_preferences')
              .neq('id', uid)
              .limit(5);
          print('🔍 DEBUG: Sample profiles BFF status:');
          for (var profile in checkResponse) {
            print('  - ${profile['name']}: bff_enabled=${profile['bff_enabled']}, mode_prefs=${profile['mode_preferences']}');
          }
        } catch (checkError) {
          print('⚠️ DEBUG: Could not check profile BFF status: $checkError');
        }
      }
      
      // Return empty result if RPC returned empty and fallback also failed
      return [];
    } catch (e, stackTrace) {
      print('❌ Error fetching BFF profiles from RPC: $e');
      print('❌ Stack trace: $stackTrace');
      print('🔄 DEBUG: Trying fallback query after RPC error...');
      
      // Try fallback query if RPC fails
      try {
        // Get excluded user IDs
        final excludedIds = <String>{};
        try {
          final interactions = await client
              .from('bff_interactions')
              .select('target_user_id')
              .eq('user_id', uid);
          for (var interaction in interactions) {
            excludedIds.add((interaction['target_user_id'] ?? '').toString());
          }
          
          final matches = await client
              .from('bff_matches')
              .select('user_id_1, user_id_2')
              .or('user_id_1.eq.$uid,user_id_2.eq.$uid')
              .filter('status', 'in', '(${['matched', 'active'].map((s) => '"$s"').join(',')})');
          for (var match in matches) {
            final id1 = (match['user_id_1'] ?? '').toString();
            final id2 = (match['user_id_2'] ?? '').toString();
            excludedIds.add(id1 == uid ? id2 : id1);
          }
        } catch (_) {}
        
        // Query profiles with BFF enabled
        var fallbackResponse = await client
            .from('profiles')
            .select('id, name, age, photos, image_urls, location, description, hobbies, gender, latitude, longitude, created_at, bff_enabled')
            .neq('id', uid)
            .eq('bff_enabled', true)
            .limit(20);
        
        print('🔍 DEBUG: Fallback query found ${fallbackResponse.length} profiles with BFF enabled');
        
        // Filter out excluded IDs
        final filtered = fallbackResponse
            .where((p) => !excludedIds.contains((p['id'] ?? '').toString()))
            .toList();
        
        print('🔍 DEBUG: After filtering excluded IDs: ${filtered.length} profiles');
        
        if (filtered.isNotEmpty) {
          print('✅ DEBUG: Using fallback query results after RPC error');
          return filtered.cast<Map<String, dynamic>>();
        }
      } catch (fallbackError) {
        print('❌ Fallback query also failed: $fallbackError');
      }
      
      print('🔍 DEBUG: Returning empty list for BFF profiles - both RPC and fallback failed');
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
      final updateData = <String, dynamic>{
        'mode_preferences': modePreferences,
      };
      
      // Set bff_enabled flag based on mode preferences
      if (modePreferences['bff'] == true) {
        updateData['bff_enabled'] = true;
        updateData['bff_enabled_at'] = DateTime.now().toIso8601String();
      } else {
        updateData['bff_enabled'] = false;
        updateData['bff_enabled_at'] = null;
      }
      
      await client.from('profiles').update(updateData).eq('id', uid);
      print('✅ Mode preferences updated successfully - bff_enabled: ${updateData['bff_enabled']}');
    } catch (e) {
      print('Error updating mode preferences: $e');
      rethrow;
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
        .select('id,user_id_1,user_id_2,created_at,status,flame_started_at,flame_expires_at')
        .eq('id', matchId)
        .maybeSingle();
    return row;
  }

  static Map<String, dynamic> _normalizeRpcResponse(dynamic response) {
    if (response == null) return {};
    if (response is Map<String, dynamic>) {
      return response;
    }
    if (response is List && response.isNotEmpty) {
      final first = response.first;
      if (first is Map<String, dynamic>) {
        return first;
      }
    }
    return {};
  }

  static Future<Map<String, dynamic>> startFlameChat(String matchId) async {
    final userId = currentUser?.id;
    if (userId == null || matchId.isEmpty) return {};
    try {
      final response = await client.rpc('start_flame_chat', params: {
        'p_match_id': matchId,
        'p_user_id': userId,
      });
      return Map<String, dynamic>.from(_normalizeRpcResponse(response));
    } catch (e) {
      print('Error starting flame chat: $e');
      return {};
    }
  }

  static Future<Map<String, dynamic>> getFlameStatus(String matchId) async {
    final userId = currentUser?.id;
    if (userId == null || matchId.isEmpty) return {};
    try {
      final response = await client.rpc('get_flame_status', params: {
        'p_match_id': matchId,
        'p_user_id': userId,
      });
      return Map<String, dynamic>.from(_normalizeRpcResponse(response));
    } catch (e) {
      print('Error fetching flame status: $e');
      return {};
    }
  }

  static Future<Map<String, dynamic>> getCurrentUserSummary() async {
    final userId = currentUser?.id;
    if (userId == null) {
      return {'gender': '', 'is_premium': false};
    }
    try {
      final response = await client
          .from('profiles')
          .select('gender,is_premium')
          .eq('id', userId)
          .maybeSingle();
      if (response == null) {
        return {'gender': '', 'is_premium': false};
      }
      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('Error fetching user summary: $e');
      return {'gender': '', 'is_premium': false};
    }
  }
  
  // Messages
  static Future<List<Map<String, dynamic>>> getMessages(String matchId) async {
    final response = await client
        .from('messages')
        .select('id,match_id,sender_id,content,created_at,story_id,is_story_reply,story_user_name,is_disappearing_photo,disappearing_photo_id,deleted_by,deleted_for_everyone,deleted_at')
        .eq('match_id', matchId)
        .order('created_at', ascending: true);
    return (response as List).cast<Map<String, dynamic>>();
  }

  static Future<void> deleteMessagesForMe({
    required List<String> messageIds,
    List<String> audioMessageIds = const [],
  }) async {
    if ((messageIds.isEmpty) && audioMessageIds.isEmpty) return;
    final userId = currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await client.rpc('delete_messages_for_me', params: {
        'p_user_id': userId,
        'p_message_ids': messageIds,
        'p_audio_message_ids': audioMessageIds,
      });
    } catch (e) {
      print('Error deleting messages for user: $e');
      rethrow;
    }
  }

  static Future<void> deleteMessagesForEveryone({
    required List<String> messageIds,
    List<String> audioMessageIds = const [],
  }) async {
    if ((messageIds.isEmpty) && audioMessageIds.isEmpty) return;
    final userId = currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await client.rpc('delete_messages_for_everyone', params: {
        'p_user_id': userId,
        'p_message_ids': messageIds,
        'p_audio_message_ids': audioMessageIds,
      });
    } catch (e) {
      print('Error deleting messages for everyone: $e');
      rethrow;
    }
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
      print('📤 DEBUG: Sending premium message to $recipientId');
      print('📤 DEBUG: Message content: ${message.substring(0, message.length > 50 ? 50 : message.length)}...');
      
      // Call RPC function - ensure parameters match function signature
      final response = await client.rpc('send_premium_message', params: {
        'p_recipient_id': recipientId,
        'p_message_content': message,
      });
      
      print('✅ DEBUG: Premium message sent successfully: $response');
      return response as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error sending premium message: $e');
      // Return a more user-friendly error message
      String errorMessage = e.toString();
      if (errorMessage.contains('function') && errorMessage.contains('not found')) {
        errorMessage = 'Premium messaging function not available. Please contact support.';
      } else if (errorMessage.contains('Premium subscription required')) {
        errorMessage = 'Premium subscription required to send messages before matching';
      }
      return {'error': errorMessage};
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
          .select('is_premium, gender')
          .eq('id', currentUser?.id ?? '')
          .single();
      final gender = (response['gender'] ?? '').toString();
      if (gender.toLowerCase() == 'female') return true;
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
    bool bypassFreemium = false,
  }) async {
    // Filter content for objectionable material
    final filteredContent = ContentFilterService.filterContent(content);
    if (filteredContent == null) {
      throw Exception('Message contains inappropriate content and cannot be sent.');
    }
    
    // Auto-flag for review if content is suspicious
    if (ContentFilterService.shouldFlagForReview(content)) {
      // Get the other user's ID to report
      try {
        final match = await getMatchById(matchId);
        if (match != null) {
          final currentUserId = currentUser?.id;
          final otherUserId = match['user_id_1'] == currentUserId 
              ? match['user_id_2'] 
              : match['user_id_1'];
          if (otherUserId != null) {
            await ContentFilterService.reportContent(
              reportedUserId: otherUserId.toString(),
              contentType: 'message',
              contentId: matchId,
              reason: 'Suspicious content detected',
              description: 'Automatically flagged for review',
            );
          }
        }
      } catch (e) {
        print('Error auto-flagging content: $e');
      }
    }
    
    if (!bypassFreemium) {
      final premium = await isPremiumUser();
      if (!premium) {
        final canSend = await canPerformAction('message');
        if (!canSend) {
          throw Exception('Daily message limit reached. Upgrade for unlimited messaging.');
        }
      }
    }
    
    await client.from('messages').insert({
      'match_id': matchId,
      'sender_id': currentUser?.id,
      'content': filteredContent, // Use filtered content
      'story_id': storyId,
      'is_story_reply': storyId != null,
      'story_user_name': storyUserName,
    });

    // Send push notification to the recipient
    await _sendMessageNotification(matchId, filteredContent);
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
    // Premium users (including auto-premium females) bypass daily limit checks
    final premiumNow = await isPremiumUser();
    if (!premiumNow) {
      final canSwipe = await canPerformAction('swipe');
      if (!canSwipe) {
        return {
          'error': 'Daily swipe limit reached. Upgrade for unlimited swipes.',
          'limit_reached': true,
          'action': 'swipe'
        };
      }
    }
    
    // Check super like limit if action is super_like (ALL users have 1 per day)
    if (action == 'super_like') {
      final canSuperLike = await canPerformAction('super_like');
      if (!canSuperLike) {
        return {
          'error': 'Daily super love limit reached. Buy more super loves or upgrade.',
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

      // Send push notification for likes
      if (action == 'like' || action == 'super_like') {
        await _sendLikeNotification(swipedId, action);
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

  // =============================================================================
  // NOTIFICATION HELPER METHODS
  // =============================================================================

  /// Send like notification to the swiped user
  static Future<void> _sendLikeNotification(String swipedId, String action) async {
    try {
      // Get current user's name
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) return;

      final profile = await getProfile(currentUser.id);
      if (profile == null) return;

      final userName = profile['name'] ?? 'Someone';

      // Send push notification
      await PushNotificationService.sendNewLikeNotification(
        userId: swipedId,
        likerName: userName,
      );
      print('✅ Like notification sent to $swipedId');
    } catch (e) {
      print('❌ Failed to send like notification: $e');
    }
  }

  /// Send match notification to both users
  static Future<void> sendMatchNotification(String matchId, String otherUserId) async {
    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) return;

      // Get current user's name
      final currentProfile = await getProfile(currentUser.id);
      final currentUserName = currentProfile?['name'] ?? 'Someone';

      // Get other user's name
      final otherProfile = await getProfile(otherUserId);

      // Send notification to the other user
      await PushNotificationService.sendNewMatchNotification(
        userId: otherUserId,
        matchName: currentUserName,
        matchId: matchId,
      );
      print('✅ Match notification sent to $otherUserId');
    } catch (e) {
      print('❌ Failed to send match notification: $e');
    }
  }

  /// Send message notification to the recipient
  static Future<void> sendMessageNotification({
    required String recipientId,
    required String senderName,
    required String message,
    required String chatId,
  }) async {
    try {
      // Send push notification
      await PushNotificationService.sendNewMessageNotification(
        userId: recipientId,
        senderName: senderName,
        message: message,
        chatId: chatId,
      );
      print('✅ Message notification sent to $recipientId');
    } catch (e) {
      print('❌ Failed to send message notification: $e');
    }
  }

  /// Helper method to send message notification for a match
  static Future<void> _sendMessageNotification(String matchId, String content) async {
    try {
      // Get match information to find the other user
      final matchResponse = await client
          .from('matches')
          .select('user_id_1, user_id_2')
          .eq('id', matchId)
          .maybeSingle();

      if (matchResponse == null) return;

      final currentUserId = currentUser?.id;
      if (currentUserId == null) return;

      // Find the other user
      final otherUserId = matchResponse['user_id_1'] == currentUserId 
          ? matchResponse['user_id_2'] 
          : matchResponse['user_id_1'];

      if (otherUserId == null) return;

      // Get current user's name
      final currentProfile = await getProfile(currentUserId);
      final senderName = currentProfile?['name'] ?? 'Someone';

      // Send notification
      await sendMessageNotification(
        recipientId: otherUserId,
        senderName: senderName,
        message: content,
        chatId: matchId,
      );
    } catch (e) {
      print('❌ Failed to send message notification: $e');
    }
  }

  /// Activate Ghost Mode for current user (24 hours)
  static Future<Map<String, dynamic>> activateGhostMode() async {
    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final response = await client.rpc('activate_ghost_mode', params: {
        'p_user_id': currentUser.id,
      }).single();

      print('✅ Ghost mode activated for user: ${currentUser.id}');
      return response as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error activating ghost mode: $e');
      rethrow;
    }
  }

  /// Deactivate Ghost Mode for current user
  static Future<Map<String, dynamic>> deactivateGhostMode() async {
    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final response = await client.rpc('deactivate_ghost_mode', params: {
        'p_user_id': currentUser.id,
      }).single();

      print('✅ Ghost mode deactivated for user: ${currentUser.id}');
      return response as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error deactivating ghost mode: $e');
      rethrow;
    }
  }

  /// Get potential matches count and last liker details
  static Future<Map<String, dynamic>> getPotentialMatches() async {
    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        return {
          'total_count': 0,
          'last_liker_id': null,
          'last_liker_name': null,
          'last_liker_photo': null,
          'last_liked_at': null,
        };
      }

      final response = await client.rpc('get_potential_matches', params: {
        'p_user_id': currentUser.id,
      }).single();

      print('✅ Potential matches fetched: ${response['total_count']}');
      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('❌ Error fetching potential matches: $e');
      return {
        'total_count': 0,
        'last_liker_id': null,
        'last_liker_name': null,
        'last_liker_photo': null,
        'last_liked_at': null,
      };
    }
  }

  /// Get Ghost Mode status for current user
  static Future<Map<String, dynamic>> getGhostModeStatus() async {
    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        return {
          'is_ghost_mode': false,
          'activated_at': null,
          'expires_at': null,
          'is_expired': false,
          'remaining_hours': 0.0,
        };
      }

      // First, check and deactivate expired ghost modes
      await client.rpc('check_and_deactivate_ghost_mode');

      final response = await client.rpc('get_ghost_mode_status', params: {
        'p_user_id': currentUser.id,
      }).single();

      print('✅ Ghost mode status retrieved for user: ${currentUser.id}');
      return response as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error getting ghost mode status: $e');
      return {
        'is_ghost_mode': false,
        'activated_at': null,
        'expires_at': null,
        'is_expired': false,
        'remaining_hours': 0.0,
      };
    }
  }

  // =============================================================================
  // CHAT-FIRST DATING FEATURE - Profile Unlocking
  // =============================================================================

  /// Check if a profile is unlocked for the current user (chat-first feature)
  static Future<bool> isProfileUnlocked(String profileId) async {
    try {
      final currentUserId = currentUser?.id;
      if (currentUserId == null || profileId.isEmpty) return false;

      final response = await client.rpc('is_profile_unlocked', params: {
        'p_viewer_id': currentUserId,
        'p_profile_id': profileId,
      });

      return response == true;
    } catch (e) {
      print('Error checking profile unlock status: $e');
      // If function doesn't exist yet, return false (locked by default)
      return false;
    }
  }

  /// Get conversation count and unlock status for a profile
  static Future<Map<String, dynamic>> getProfileUnlockStatus(String profileId, String? matchId) async {
    try {
      final currentUserId = currentUser?.id;
      if (currentUserId == null || profileId.isEmpty) {
        return {
          'is_unlocked': false,
          'message_count': 0,
          'messages_needed': 10,
        };
      }

      final response = await client
          .from('profile_unlocks')
          .select('is_unlocked, message_count')
          .eq('viewer_id', currentUserId)
          .eq('profile_id', profileId)
          .maybeSingle();

      if (response == null) {
        return {
          'is_unlocked': false,
          'message_count': 0,
          'messages_needed': 10,
        };
      }

      return {
        'is_unlocked': response['is_unlocked'] ?? false,
        'message_count': response['message_count'] ?? 0,
        'messages_needed': 10,
      };
    } catch (e) {
      print('Error getting profile unlock status: $e');
      return {
        'is_unlocked': false,
        'message_count': 0,
        'messages_needed': 10,
      };
    }
  }

  /// Increment conversation count (called automatically when messages are sent)
  /// This is handled by database trigger, but we expose it for manual calls if needed
  static Future<Map<String, dynamic>> incrementConversationCount(String profileId, String matchId) async {
    try {
      final currentUserId = currentUser?.id;
      if (currentUserId == null || profileId.isEmpty || matchId.isEmpty) {
        return {
          'message_count': 0,
          'is_unlocked': false,
          'unlocked_now': false,
        };
      }

      final response = await client.rpc('increment_conversation_count', params: {
        'p_viewer_id': currentUserId,
        'p_profile_id': profileId,
        'p_match_id': matchId,
      });

      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('Error incrementing conversation count: $e');
      return {
        'message_count': 0,
        'is_unlocked': false,
        'unlocked_now': false,
      };
    }
  }

  /// Get unlock status for multiple profiles at once (for batch checking)
  static Future<Map<String, Map<String, dynamic>>> getBatchUnlockStatus(List<String> profileIds) async {
    try {
      final currentUserId = currentUser?.id;
      if (currentUserId == null || profileIds.isEmpty) return {};

      final response = await client
          .from('profile_unlocks')
          .select('profile_id, is_unlocked, message_count')
          .eq('viewer_id', currentUserId)
          .inFilter('profile_id', profileIds);

      final Map<String, Map<String, dynamic>> result = {};
      for (final row in response) {
        final profileId = row['profile_id'].toString();
        result[profileId] = {
          'is_unlocked': row['is_unlocked'] ?? false,
          'message_count': row['message_count'] ?? 0,
          'messages_needed': 10,
        };
      }

      // Add entries for profiles that don't have unlock records yet
      for (final profileId in profileIds) {
        if (!result.containsKey(profileId)) {
          result[profileId] = {
            'is_unlocked': false,
            'message_count': 0,
            'messages_needed': 10,
          };
        }
      }

      return result;
    } catch (e) {
      print('Error getting batch unlock status: $e');
      return {};
    }
  }

}
