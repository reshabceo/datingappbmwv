import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:lovebug/Screens/ChatPage/controller_message_screen.dart';
import 'package:lovebug/Screens/ChatPage/photo_send_options_dialog.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/services/disappearing_photo_service.dart';

class EnhancedPhotoUploadService {
  static Future<void> handlePhotoSelection({
    required MessageController controller,
    required String matchId,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      // Show instant preview message with unique ID
      final previewMessageId = 'preview_${DateTime.now().millisecondsSinceEpoch}';
      final previewMessage = Message(
        text: '📸 Photo selected - choose how to send...',
        isUser: true,
        timestamp: DateTime.now(),
        id: previewMessageId,
      );
      controller.messages.add(previewMessage);
      controller.messages.refresh();

      // Show photo send options dialog
      final result = await Get.dialog<String>(
        PhotoSendOptionsDialog(
          imagePath: 'data:image/jpeg;base64,${Uri.dataFromBytes(imageBytes).toString()}',
          onSendNormal: () => Get.back(result: 'normal'),
          onSendDisappearing: () => Get.back(result: 'disappearing'),
        ),
        barrierDismissible: false,
      );

      // Remove only the specific preview message by ID
      controller.messages.removeWhere((m) => m.id == previewMessageId);

      if (result == 'normal') {
        await _sendNormalPhoto(controller, matchId, imageBytes, fileName);
      } else if (result == 'disappearing') {
        await _sendDisappearingPhoto(controller, matchId, imageBytes, fileName);
      }
    } catch (e) {
      print('Error showing photo options: $e');
      // Remove preview on error - be more specific
      controller.messages.removeWhere((m) => m.text == '📸 Photo selected - choose how to send...');
      Get.snackbar('Error', 'Failed to process photo');
    }
  }

  static Future<void> _sendNormalPhoto(
    MessageController controller,
    String matchId,
    Uint8List imageBytes,
    String fileName,
  ) async {
    try {
      // Create instant photo preview message (like WhatsApp)
      final previewMessageId = 'photo_preview_${DateTime.now().millisecondsSinceEpoch}';
      final previewMessage = Message(
        text: '📸 Photo: ${Uri.dataFromBytes(imageBytes).toString()}',
        isUser: true,
        timestamp: DateTime.now(),
        id: previewMessageId,
        isPhoto: true,
        photoBytes: imageBytes,
        isUploading: true,
      );
      controller.messages.add(previewMessage);
      controller.messages.refresh();
      
      // Show loading snackbar with better styling
      final themeController = Get.find<ThemeController>();
      Get.snackbar(
        '📸 Uploading Photo',
        'Please wait while your photo is being uploaded...',
        duration: Duration(seconds: 5),
        snackPosition: SnackPosition.TOP,
        backgroundColor: themeController.getAccentColor().withValues(alpha: 0.9),
        colorText: Colors.white,
        icon: Container(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.0,
          ),
        ),
        margin: EdgeInsets.all(16),
        borderRadius: 12,
      );
      
      // Upload to Supabase storage with retry logic
      String photoUrl = '';
      int retryCount = 0;
      const maxRetries = 3;
      
      while (photoUrl.isEmpty && retryCount < maxRetries) {
        try {
          photoUrl = await SupabaseService.uploadFile(
            bucket: 'chat-photos',
            path: '${DateTime.now().millisecondsSinceEpoch}_${retryCount}_$fileName',
            fileBytes: imageBytes,
          );
        } catch (e) {
          retryCount++;
          print('Upload attempt $retryCount failed: $e');
          if (retryCount < maxRetries) {
            await Future.delayed(Duration(seconds: 1)); // Wait before retry
          }
        }
      }

      if (photoUrl.isNotEmpty) {
        // Update the preview message with the actual photo URL
        final messageIndex = controller.messages.indexWhere((m) => m.id == previewMessageId);
        if (messageIndex != -1) {
          controller.messages[messageIndex] = Message(
            text: '📸 Photo: $photoUrl',
            isUser: true,
            timestamp: DateTime.now(),
            isPhoto: true,
            photoUrl: photoUrl,
            isUploading: false,
          );
          controller.messages.refresh();
        }
        
        // Send actual photo message to database
        await controller.sendMessage(matchId, '📸 Photo: $photoUrl');
        
        Get.snackbar(
          'Success',
          'Photo sent successfully!',
          duration: Duration(seconds: 2),
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.withValues(alpha: 0.9),
          colorText: Colors.white,
          icon: Icon(Icons.check_circle, color: Colors.white),
        );
      } else {
        // Remove preview on failure
        controller.messages.removeWhere((m) => m.id == previewMessageId);
        Get.snackbar(
          'Error',
          'Failed to upload photo. Please try again.',
          duration: Duration(seconds: 3),
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.withValues(alpha: 0.9),
          colorText: Colors.white,
          icon: Icon(Icons.error, color: Colors.white),
        );
      }
    } catch (e) {
      print('Error sending normal photo: $e');
      // Remove only the specific preview message on error
      controller.messages.removeWhere((m) => m.isUploading == true && m.text.contains('📸 Photo:'));
      Get.snackbar(
        'Error',
        'Failed to send photo: ${e.toString()}',
        duration: Duration(seconds: 3),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
        icon: Icon(Icons.error, color: Colors.white),
      );
    }
  }

  static Future<void> _sendDisappearingPhoto(
    MessageController controller,
    String matchId,
    Uint8List imageBytes,
    String fileName,
  ) async {
    try {
      // Create loading message with circular progress
      final loadingMessage = Message(
        text: '📸 Disappearing photo uploading...',
        isUser: true,
        timestamp: DateTime.now(),
      );
      
      controller.messages.add(loadingMessage);
      
      // Show loading snackbar with better styling
      final themeController = Get.find<ThemeController>();
      Get.snackbar(
        '📸 Uploading Disappearing Photo',
        'Please wait while your disappearing photo is being uploaded...',
        duration: Duration(seconds: 5),
        snackPosition: SnackPosition.TOP,
        backgroundColor: themeController.purpleColor.withValues(alpha: 0.9),
        colorText: Colors.white,
        icon: Container(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.0,
          ),
        ),
        margin: EdgeInsets.all(16),
        borderRadius: 12,
      );
      
      // Upload to Supabase storage with retry logic
      String photoUrl = '';
      int retryCount = 0;
      const maxRetries = 3;
      
      while (photoUrl.isEmpty && retryCount < maxRetries) {
        try {
          photoUrl = await SupabaseService.uploadFile(
            bucket: 'disappearing-photos',
            path: '${DateTime.now().millisecondsSinceEpoch}_${retryCount}_$fileName',
            fileBytes: imageBytes,
          );
        } catch (e) {
          retryCount++;
          print('Disappearing photo upload attempt $retryCount failed: $e');
          if (retryCount < maxRetries) {
            await Future.delayed(Duration(seconds: 1)); // Wait before retry
          }
        }
      }

      if (photoUrl.isNotEmpty) {
        // Remove loading message
        controller.messages.removeWhere((m) => m.text == '📸 Disappearing photo uploading...');
        
        // Send disappearing photo using the service
        await EnhancedDisappearingPhotoService.sendDisappearingPhoto(
          matchId: matchId,
          photoBytes: imageBytes,
          fileName: fileName,
        );
        
        Get.snackbar(
          'Success',
          'Disappearing photo sent successfully!',
          duration: Duration(seconds: 2),
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.purple.withValues(alpha: 0.9),
          colorText: Colors.white,
          icon: Icon(Icons.visibility_off, color: Colors.white),
        );
      } else {
        // Remove loading on failure
        controller.messages.removeWhere((m) => m.text == '📸 Disappearing photo uploading...');
        Get.snackbar(
          'Error',
          'Failed to upload disappearing photo. Please try again.',
          duration: Duration(seconds: 3),
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.withValues(alpha: 0.9),
          colorText: Colors.white,
          icon: Icon(Icons.error, color: Colors.white),
        );
      }
    } catch (e) {
      print('Error sending disappearing photo: $e');
      // Remove only the specific loading message on error
      controller.messages.removeWhere((m) => m.text == '📸 Disappearing photo uploading...');
      Get.snackbar(
        'Error',
        'Failed to send disappearing photo: ${e.toString()}',
        duration: Duration(seconds: 3),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
        icon: Icon(Icons.error, color: Colors.white),
      );
    }
  }
}
