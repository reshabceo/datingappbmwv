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
        ));
        return;
      }

      final response = await SupabaseService.client
          .from('profiles')
          .select('zodiac_sign, birth_date')
          .eq('id', currentUser.id)
          .single();
      
      final profile = response.data;

      // Check if user has astrological data
      final hasZodiacData = profile != null && 
          (profile['zodiac_sign'] != null || profile['birth_date'] != null);

      if (hasZodiacData) {
        // Use enhanced chat with astrological features
        Get.to(() => EnhancedMessageScreen(
          userImage: userImage,
          userName: userName,
          matchId: matchId,
        ));
      } else {
        // Use regular chat
        Get.to(() => MessageScreen(
          userImage: userImage,
          userName: userName,
          matchId: matchId,
        ));
      }
    } catch (e) {
      print('Error checking astro feature: $e');
      // Fallback to regular chat on error
      Get.to(() => MessageScreen(
        userImage: userImage,
        userName: userName,
        matchId: matchId,
      ));
    }
  }

  /// Check if a match has astrological enhancements available
  static Future<bool> hasAstroEnhancements(String matchId) async {
    try {
      final response = await SupabaseService.client
          .from('match_enhancements')
          .select('id')
          .eq('match_id', matchId)
          .maybeSingle();
      
      final data = response.data;

      return data != null;
    } catch (e) {
      print('Error checking astro enhancements: $e');
      return false;
    }
  }

  /// Get astrological compatibility score for a match
  static Future<int?> getCompatibilityScore(String matchId) async {
    try {
      final response = await SupabaseService.client
          .from('match_enhancements')
          .select('astro_compatibility')
          .eq('match_id', matchId)
          .single();
      
      final data = response.data;

      if (data != null && data['astro_compatibility'] != null) {
        return data['astro_compatibility']['compatibility_score'] as int?;
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

      final response = await SupabaseService.client
          .from('profiles')
          .select('zodiac_sign, birth_date')
          .eq('id', currentUser.id)
          .single();
      
      final profile = response.data;

      return profile != null &&
          (profile['zodiac_sign'] != null || profile['birth_date'] != null);
    } catch (e) {
      print('Error checking astro features: $e');
      return false;
    }
  }
}
