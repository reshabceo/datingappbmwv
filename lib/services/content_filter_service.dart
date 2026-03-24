import 'package:lovebug/services/supabase_service.dart';

/// Service for filtering objectionable content in user-generated content
class ContentFilterService {
  // List of objectionable words/phrases (basic implementation)
  // In production, this should be more comprehensive and possibly use ML/AI
  static const List<String> _blockedWords = [
    'spam',
    'scam',
    'fake',
    'bot',
    // Add more as needed
  ];

  /// Filter text content for objectionable words
  /// Returns true if content should be blocked, false otherwise
  static bool containsObjectionableContent(String content) {
    final lowerContent = content.toLowerCase();
    for (final word in _blockedWords) {
      if (lowerContent.contains(word.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  /// Filter and sanitize user input (bio, messages, etc.)
  /// Returns filtered content or null if too objectionable
  static String? filterContent(String content) {
    if (containsObjectionableContent(content)) {
      // Replace objectionable words with asterisks
      String filtered = content;
      for (final word in _blockedWords) {
        filtered = filtered.replaceAll(
          RegExp(word, caseSensitive: false),
          '*' * word.length,
        );
      }
      return filtered;
    }
    return content;
  }

  /// Check if content should be automatically flagged for review
  static bool shouldFlagForReview(String content) {
    // Flag if contains multiple objectionable words or suspicious patterns
    final lowerContent = content.toLowerCase();
    int objectionableCount = 0;
    for (final word in _blockedWords) {
      if (lowerContent.contains(word.toLowerCase())) {
        objectionableCount++;
      }
    }
    return objectionableCount >= 2;
  }

  /// Report content as objectionable
  static Future<void> reportContent({
    required String reportedUserId,
    required String contentType, // 'message', 'profile', 'story', etc.
    required String contentId,
    required String reason,
    String? description,
  }) async {
    try {
      await SupabaseService.client.from('reports').insert({
        'reporter_id': SupabaseService.currentUser?.id,
        'reported_id': reportedUserId,
        'content_type': contentType,
        'content_id': contentId,
        'reason': reason,
        'description': description ?? 'User reported objectionable content',
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error reporting content: $e');
      rethrow;
    }
  }

  /// Check if a user is blocked
  static Future<bool> isUserBlocked(String userId) async {
    try {
      final currentUserId = SupabaseService.currentUser?.id;
      if (currentUserId == null) return false;

      final response = await SupabaseService.client
          .from('blocked_users')
          .select('id')
          .or('blocker_id.eq.$currentUserId,blocked_id.eq.$currentUserId')
          .or('blocker_id.eq.$userId,blocked_id.eq.$userId')
          .limit(1);

      return (response as List).isNotEmpty;
    } catch (e) {
      print('Error checking if user is blocked: $e');
      return false;
    }
  }
}

