import 'dart:typed_data';
import 'package:lovebug/services/supabase_service.dart';
import 'package:lovebug/Screens/ChatPage/disappearing_photo_screen.dart';
import 'package:get/get.dart';

class EnhancedDisappearingPhotoService {
  static const String _bucketName = 'disappearing-photos';
  
  /// Send a disappearing photo with enhanced UX
  static Future<String?> sendDisappearingPhoto({
    required String matchId,
    required Uint8List photoBytes,
    required String fileName,
    int viewDuration = 10, // seconds
  }) async {
    try {
      print('🔄 DEBUG: Starting disappearing photo upload');
      print('  - matchId: $matchId');
      print('  - fileName: $fileName');
      print('  - viewDuration: $viewDuration');
      print('  - currentUser: ${SupabaseService.currentUser?.id}');
      
      // Upload photo to Supabase storage
      print('🔄 DEBUG: Uploading to storage...');
      final photoUrl = await SupabaseService.uploadFile(
        bucket: _bucketName,
        path: '${DateTime.now().millisecondsSinceEpoch}_$fileName',
        fileBytes: photoBytes,
      );
      print('✅ DEBUG: Storage upload successful: $photoUrl');
      
      // Prepare data for database
      final now = DateTime.now();
      final expiresAt = now.add(Duration(seconds: viewDuration + 30));
      
      final insertData = {
        'match_id': matchId,
        'photo_url': photoUrl,
        'sender_id': SupabaseService.currentUser?.id,
        'view_duration': viewDuration,
        'expires_at': expiresAt.toIso8601String(),
      };
      
      print('🔄 DEBUG: Inserting to database with data: $insertData');
      
      // Store photo metadata in database
      final response = await SupabaseService.client.from('disappearing_photos').insert(insertData).select('id');
      print('✅ DEBUG: Database insert successful: $response');
      
      // Get the ID from the response
      String? disappearingPhotoId;
      if (response != null && response.isNotEmpty) {
        disappearingPhotoId = response[0]['id']?.toString();
        print('✅ DEBUG: Got disappearing photo ID: $disappearingPhotoId');
      } else {
        print('❌ DEBUG: No ID returned from disappearing_photos insert');
        return null;
      }
      
      // Add to messages table so it shows in chat - but only for receiver
      final messageData = {
        'match_id': matchId,
        'sender_id': SupabaseService.currentUser?.id,
        'content': '📸 Disappearing Photo',
        'is_disappearing_photo': true,
        'disappearing_photo_id': disappearingPhotoId,
      };
      
      print('🔄 DEBUG: Adding to messages table: $messageData');
      await SupabaseService.client.from('messages').insert(messageData);
      print('✅ DEBUG: Message added to chat successfully');
      
      return photoUrl;
    } catch (e) {
      print('❌ DEBUG: Error sending disappearing photo: $e');
      return null;
    }
  }
  
  /// Send a regular photo (non-disappearing)
  static Future<String?> sendRegularPhoto({
    required String matchId,
    required Uint8List photoBytes,
    required String fileName,
  }) async {
    try {
      print('🔄 DEBUG: Starting regular photo upload');
      print('  - matchId: $matchId');
      print('  - fileName: $fileName');
      print('  - currentUser: ${SupabaseService.currentUser?.id}');
      
      // Upload photo to Supabase storage
      print('🔄 DEBUG: Uploading to storage...');
      final photoUrl = await SupabaseService.uploadFile(
        bucket: 'chat-photos', // Use regular chat photos bucket
        path: '${DateTime.now().millisecondsSinceEpoch}_$fileName',
        fileBytes: photoBytes,
      );
      print('✅ DEBUG: Storage upload successful: $photoUrl');
      
      // Add to messages table as regular photo (store URL in content like other photos)
      final messageData = {
        'match_id': matchId,
        'sender_id': SupabaseService.currentUser?.id,
        'content': '📸 Photo: $photoUrl',
        'is_disappearing_photo': false,
      };
      
      print('🔄 DEBUG: Adding to messages table: $messageData');
      await SupabaseService.client.from('messages').insert(messageData);
      print('✅ DEBUG: Message added to chat successfully');
      
      return photoUrl;
    } catch (e) {
      print('❌ DEBUG: Error sending regular photo: $e');
      return null;
    }
  }

  /// Get disappearing photos for a match (receiver only)
  static Future<List<Map<String, dynamic>>> getDisappearingPhotos(String matchId) async {
    try {
      final currentUserId = SupabaseService.currentUser?.id;
      if (currentUserId == null) return [];
      
      // Only get disappearing photos where current user is NOT the sender
      final response = await SupabaseService.client
          .from('disappearing_photos')
          .select('*')
          .eq('match_id', matchId)
          .neq('sender_id', currentUserId) // Exclude photos sent by current user
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);
      
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error getting disappearing photos: $e');
      return [];
    }
  }
  
  /// Get disappearing photos sent by current user (for sender view)
  static Future<List<Map<String, dynamic>>> getSentDisappearingPhotos(String matchId) async {
    try {
      final currentUserId = SupabaseService.currentUser?.id;
      if (currentUserId == null) return [];
      
      // Get disappearing photos sent by current user
      final response = await SupabaseService.client
          .from('disappearing_photos')
          .select('*')
          .eq('match_id', matchId)
          .eq('sender_id', currentUserId) // Only photos sent by current user
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);
      
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error getting sent disappearing photos: $e');
      return [];
    }
  }
  
  /// View a disappearing photo
  static Future<void> viewDisappearingPhoto(String photoId) async {
    try {
      await SupabaseService.client
          .from('disappearing_photos')
          .update({'viewed_by': SupabaseService.currentUser?.id, 'viewed_at': DateTime.now().toIso8601String()})
          .eq('id', photoId);
    } catch (e) {
      print('Error marking photo as viewed: $e');
    }
  }

  /// Mark a disappearing photo as viewed
  static Future<void> markPhotoAsViewed(String photoId) async {
    try {
      await SupabaseService.client
          .from('disappearing_photos')
          .update({'viewed_by': SupabaseService.currentUser?.id, 'viewed_at': DateTime.now().toIso8601String()})
          .eq('id', photoId);
      print('✅ DEBUG: Photo marked as viewed: $photoId');
    } catch (e) {
      print('❌ DEBUG: Error marking photo as viewed: $e');
    }
  }
  
  /// Get a specific disappearing photo by ID
  static Future<Map<String, dynamic>?> getDisappearingPhoto(String photoId) async {
    try {
      final response = await SupabaseService.client
          .from('disappearing_photos')
          .select('*')
          .eq('id', photoId)
          .maybeSingle();
      
      return response;
    } catch (e) {
      print('Error getting disappearing photo: $e');
      return null;
    }
  }

  /// Clean up expired photos
  static Future<void> cleanupExpiredPhotos() async {
    try {
      // Delete expired photos from database
      await SupabaseService.client
          .from('disappearing_photos')
          .delete()
          .lt('expires_at', DateTime.now().toIso8601String());
      
      // TODO: Delete actual files from storage
    } catch (e) {
      print('Error cleaning up expired photos: $e');
    }
  }
  
  /// Show disappearing photo viewer
  static void showDisappearingPhoto({
    required String photoUrl,
    required String senderName,
    required DateTime sentAt,
    int viewDuration = 10,
  }) {
    Get.to(() => DisappearingPhotoScreen(
      photoUrl: photoUrl,
      senderName: senderName,
      sentAt: sentAt,
      viewDuration: viewDuration,
    ));
  }
}
