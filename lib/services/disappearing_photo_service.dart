import 'dart:typed_data';
import 'package:lovebug/services/supabase_service.dart';
import 'package:lovebug/Screens/ChatPage/disappearing_photo_screen.dart';
import 'package:get/get.dart';

class DisappearingPhotoService {
  static const String _bucketName = 'disappearing-photos';
  
  /// Send a disappearing photo
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
      
      // Prepare data for database - use consistent timestamp
      final now = DateTime.now();
      final expiresAt = now.add(Duration(seconds: viewDuration + 30));
      // Don't set created_at manually - let database handle it like regular messages
      
      print('🕐 DEBUG: Timestamp details:');
      print('  - now: $now');
      print('  - expiresAt: $expiresAt');
      
      final insertData = {
        'match_id': matchId,
        'photo_url': photoUrl,
        'sender_id': SupabaseService.currentUser?.id,
        'view_duration': viewDuration,
        'expires_at': expiresAt.toIso8601String(),
        // Don't set created_at - let database handle it automatically
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
      
      // Also add to messages table so it shows in chat - use same timestamp
      final messageData = {
        'match_id': matchId,
        'sender_id': SupabaseService.currentUser?.id,
        'content': '📸 Disappearing Photo',
        'is_disappearing_photo': true,
        'disappearing_photo_id': disappearingPhotoId,
        // Don't set created_at - let database handle it automatically
      };
      
      print('🔄 DEBUG: Adding to messages table: $messageData');
      await SupabaseService.client.from('messages').insert(messageData);
      print('✅ DEBUG: Message added to chat successfully');
      
      return photoUrl;
    } catch (e) {
      print('❌ DEBUG: Error sending disappearing photo: $e');
      print('❌ DEBUG: Error type: ${e.runtimeType}');
      if (e.toString().contains('DateTime')) {
        print('❌ DEBUG: DateTime conversion issue detected');
      }
      return null;
    }
  }
  
  /// Get disappearing photos for a match
  static Future<List<Map<String, dynamic>>> getDisappearingPhotos(String matchId) async {
    try {
      final response = await SupabaseService.client
          .from('disappearing_photos')
          .select('*')
          .eq('match_id', matchId)
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);
      
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error getting disappearing photos: $e');
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
