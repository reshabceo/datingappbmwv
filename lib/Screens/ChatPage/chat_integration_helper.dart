import 'package:lovebug/Screens/ChatPage/enhanced_message_screen.dart';
import 'package:lovebug/Screens/ChatPage/ui_message_screen.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:get/get.dart';

class ChatIntegrationHelper {
  /// Navigate to the appropriate chat screen based on user preferences
  static void navigateToChat({
    required String userImage,
    required String userName,
    required String matchId,
  }) {
    // Check if user has astrological data enabled
    _checkAstroFeatureAndNavigate(
      userImage: userImage,
      userName: userName,
      matchId: matchId,
    );
  }

  static Future<void> _checkAstroFeatureAndNavigate({
    required String userImage,
    required String userName,
    required String matchId,
  }) async {
    try {
      // Get current user's profile to check if they have zodiac data
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        // Fallback to regular chat
        Get.to(() => MessageScreen(
          userImage: userImage,
          userName: userName,
          matchId: matchId,
          isBffMatch: false, // Default to dating mode when user is null
        ));
        return;
      }

      // Check if this is a BFF match or dating match
      bool isBffMatch = false;
      try {
        // Check if match exists in bff_matches table
        final bffMatchResponse = await SupabaseService.client
            .from('bff_matches')
            .select('id')
            .eq('id', matchId)
            .maybeSingle();
        
        isBffMatch = bffMatchResponse != null;
      } catch (e) {
        print('Error checking BFF match: $e');
      }

      final profile = await SupabaseService.client
          .from('profiles')
          .select('zodiac_sign, birth_date')
          .eq('id', currentUser.id)
          .maybeSingle();

      // Check if user has astrological data
      final hasZodiacData = profile != null && 
          (profile['zodiac_sign'] != null || profile['birth_date'] != null);

      if (hasZodiacData) {
        // Use enhanced chat with astrological features
        Get.to(() => EnhancedMessageScreen(
          userImage: userImage,
          userName: userName,
          matchId: matchId,
          isBffMatch: isBffMatch, // Pass BFF mode info
        ));
      } else {
        // Use regular chat
        Get.to(() => MessageScreen(
          userImage: userImage,
          userName: userName,
          matchId: matchId,
          isBffMatch: isBffMatch, // Pass BFF mode info
        ));
      }
    } catch (e) {
      print('Error checking astro feature: $e');
      // Fallback to regular chat on error
      Get.to(() => MessageScreen(
        userImage: userImage,
        userName: userName,
        matchId: matchId,
        isBffMatch: false, // Default to dating mode on error
      ));
    }
  }

  /// Check if a match has astrological enhancements available
  static Future<bool> hasAstroEnhancements(String matchId) async {
    try {
      final row = await SupabaseService.client
          .from('match_enhancements')
          .select('id')
          .eq('match_id', matchId)
          .maybeSingle();

      return row != null;
    } catch (e) {
      print('Error checking astro enhancements: $e');
      return false;
    }
  }

  /// Get astrological compatibility score for a match
  static Future<int?> getCompatibilityScore(String matchId) async {
    try {
      final row = await SupabaseService.client
          .from('match_enhancements')
          .select('astro_compatibility')
          .eq('match_id', matchId)
          .maybeSingle();

      if (row != null && row['astro_compatibility'] != null) {
        return row['astro_compatibility']['compatibility_score'] as int?;
      }
      return null;
    } catch (e) {
      print('Error getting compatibility score: $e');
      return null;
    }
  }

  /// Check if user should see astrological features
  static Future<bool> shouldShowAstroFeatures() async {
    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) return false;

      final profile = await SupabaseService.client
          .from('profiles')
          .select('zodiac_sign, birth_date')
          .eq('id', currentUser.id)
          .maybeSingle();

      return profile != null &&
          (profile['zodiac_sign'] != null || profile['birth_date'] != null);
    } catch (e) {
      print('Error checking astro features: $e');
      return false;
    }
  }
}
