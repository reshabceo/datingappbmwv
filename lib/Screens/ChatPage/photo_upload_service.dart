import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:lovebug/services/disappearing_photo_service.dart';
import '../../Common/theme_controller.dart';

class EnhancedPhotoUpload {
  static final ImagePicker _picker = ImagePicker();

  /// Show photo source selection with enhanced UX
  static Future<void> showPhotoSourceDialog({
    required String matchId,
    required Function(String) onPhotoSent,
    required Function(String) onError,
  }) async {
    final ThemeController themeController = Get.find<ThemeController>();
    
    try {
      final result = await Get.dialog<String>(
        Container(
          decoration: BoxDecoration(
            color: themeController.blackColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: themeController.whiteColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                heightBox(20.h.toInt()),
                
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.photo_camera,
                      color: themeController.lightPinkColor,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    TextConstant(
                      title: 'Select Photo Source',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeController.whiteColor,
                    ),
                  ],
                ),
                heightBox(20.h.toInt()),
                
                // Camera Option
                _buildPhotoSourceOption(
                  icon: Icons.camera_alt,
                  title: 'Take Photo',
                  subtitle: 'Capture a new photo',
                  onTap: () => Get.back(result: ImageSource.camera),
                ),
                
                heightBox(12.h.toInt()),
                
                // Gallery Option
                _buildPhotoSourceOption(
                  icon: Icons.photo_library,
                  title: 'Choose from Gallery',
                  subtitle: 'Select from your photos',
                  onTap: () => Get.back(result: ImageSource.gallery),
                ),
                
                heightBox(20.h.toInt()),
                
                // Photo Type Selection
                TextConstant(
                  title: 'Choose Photo Type',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: themeController.whiteColor,
                ),
                heightBox(12.h.toInt()),
                
                // Regular Photo
                ListTile(
                  leading: Icon(
                    Icons.photo,
                    color: themeController.lightPinkColor,
                    size: 24.sp,
                  ),
                  title: TextConstant(
                    title: 'Regular Photo',
                    fontSize: 16,
                    color: themeController.whiteColor,
                  ),
                  subtitle: TextConstant(
                    title: 'Photo that stays in chat',
                    fontSize: 12,
                    color: themeController.whiteColor.withValues(alpha: 0.7),
                  ),
                  onTap: () => Get.back(result: 'regular'),
                  tileColor: themeController.lightPinkColor.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                
                heightBox(8.h.toInt()),
                
                // Disappearing Photo
                ListTile(
                  leading: Icon(
                    Icons.visibility_off,
                    color: themeController.purpleColor,
                    size: 24.sp,
                  ),
                  title: TextConstant(
                    title: 'Disappearing Photo',
                    fontSize: 16,
                    color: themeController.whiteColor,
                  ),
                  subtitle: TextConstant(
                    title: 'Photo that disappears after viewing',
                    fontSize: 12,
                    color: themeController.whiteColor.withValues(alpha: 0.7),
                  ),
                  onTap: () => Get.back(result: 'disappearing'),
                  tileColor: themeController.purpleColor.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (result != null) {
        await _handlePhotoSelection(result, matchId, onPhotoSent, onError);
      }
    } catch (e) {
      print('Error in photo flow: $e');
      onError('Failed to access photo: $e');
    }
  }

  static Widget _buildPhotoSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final ThemeController themeController = Get.find<ThemeController>();
    
    return ListTile(
      leading: Icon(
        icon,
        color: themeController.lightPinkColor,
        size: 24.sp,
      ),
      title: TextConstant(
        title: title,
        fontSize: 16,
        color: themeController.whiteColor,
      ),
      subtitle: TextConstant(
        title: subtitle,
        fontSize: 12,
        color: themeController.whiteColor.withValues(alpha: 0.7),
      ),
      onTap: onTap,
      tileColor: themeController.lightPinkColor.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
    );
  }

  static Future<void> _handlePhotoSelection(
    dynamic result,
    String matchId,
    Function(String) onPhotoSent,
    Function(String) onError,
  ) async {
    try {
      ImageSource? source;
      String? photoType;
      
      if (result is ImageSource) {
        source = result;
        // Show photo type selection after source selection
        photoType = await _showPhotoTypeSelection();
        if (photoType == null) return;
      } else if (result is String) {
        photoType = result;
        // Show source selection
        final sourceResult = await _showSourceSelection();
        if (sourceResult == null) return;
        source = sourceResult;
      }
      
      if (source == null || photoType == null) return;
      
      // Pick image
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      
      if (image == null) return;
      
      // Read image bytes
      final Uint8List imageBytes = await image.readAsBytes();
      
      // Show loading indicator immediately
      _showPhotoUploadIndicator();
      
      if (photoType == 'regular') {
        await _sendRegularPhotoWithBytes(matchId, imageBytes, image.name, onPhotoSent, onError);
      } else if (photoType == 'disappearing') {
        await _sendDisappearingPhotoWithBytes(matchId, imageBytes, image.name, onPhotoSent, onError);
      }
      
    } catch (e) {
      print('Error handling photo selection: $e');
      onError('Failed to process photo: $e');
    }
  }

  static Future<String?> _showPhotoTypeSelection() async {
    final ThemeController themeController = Get.find<ThemeController>();
    
    return await Get.dialog<String>(
      Container(
        decoration: BoxDecoration(
          color: themeController.blackColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextConstant(
                title: 'Choose Photo Type',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeController.whiteColor,
              ),
              heightBox(16.h.toInt()),
              
              // Regular Photo
              ListTile(
                leading: Icon(Icons.photo, color: themeController.lightPinkColor),
                title: TextConstant(title: 'Regular Photo', color: themeController.whiteColor),
                subtitle: TextConstant(title: 'Stays in chat', color: themeController.whiteColor.withValues(alpha: 0.7)),
                onTap: () => Get.back(result: 'regular'),
                tileColor: themeController.lightPinkColor.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
              
              heightBox(8.h.toInt()),
              
              // Disappearing Photo
              ListTile(
                leading: Icon(Icons.visibility_off, color: themeController.purpleColor),
                title: TextConstant(title: 'Disappearing Photo', color: themeController.whiteColor),
                subtitle: TextConstant(title: 'Disappears after viewing', color: themeController.whiteColor.withValues(alpha: 0.7)),
                onTap: () => Get.back(result: 'disappearing'),
                tileColor: themeController.purpleColor.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<ImageSource?> _showSourceSelection() async {
    final ThemeController themeController = Get.find<ThemeController>();
    
    return await Get.dialog<ImageSource>(
      Container(
        decoration: BoxDecoration(
          color: themeController.blackColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextConstant(
                title: 'Select Photo Source',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeController.whiteColor,
              ),
              heightBox(16.h.toInt()),
              
              // Camera
              ListTile(
                leading: Icon(Icons.camera_alt, color: themeController.lightPinkColor),
                title: TextConstant(title: 'Take Photo', color: themeController.whiteColor),
                onTap: () => Get.back(result: ImageSource.camera),
                tileColor: themeController.lightPinkColor.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
              
              heightBox(8.h.toInt()),
              
              // Gallery
              ListTile(
                leading: Icon(Icons.photo_library, color: themeController.lightPinkColor),
                title: TextConstant(title: 'Choose from Gallery', color: themeController.whiteColor),
                onTap: () => Get.back(result: ImageSource.gallery),
                tileColor: themeController.lightPinkColor.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showPhotoUploadIndicator() {
    final ThemeController themeController = Get.find<ThemeController>();
    
    Get.dialog(
      Container(
        decoration: BoxDecoration(
          color: themeController.blackColor.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: themeController.lightPinkColor,
              ),
              heightBox(12.h.toInt()),
              TextConstant(
                title: 'Uploading photo...',
                color: themeController.whiteColor,
                fontSize: 14,
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  static Future<void> _sendRegularPhotoWithBytes(
    String matchId,
    Uint8List imageBytes,
    String fileName,
    Function(String) onPhotoSent,
    Function(String) onError,
  ) async {
    try {
      // Upload to Supabase storage
      final photoUrl = await SupabaseService.uploadFile(
        bucket: 'chat-photos',
        path: '${DateTime.now().millisecondsSinceEpoch}_$fileName',
        fileBytes: imageBytes,
      );

      if (photoUrl.isNotEmpty) {
        // Send as regular message with photo URL
        await SupabaseService.client.from('messages').insert({
          'match_id': matchId,
          'sender_id': SupabaseService.currentUser?.id,
          'content': '📸 Photo: $photoUrl',
          'message_type': 'image',
        });
        
        Get.back(); // Close loading dialog
        onPhotoSent('Photo sent successfully!');
      } else {
        Get.back(); // Close loading dialog
        onError('Failed to upload photo');
      }
    } catch (e) {
      print('Error sending regular photo: $e');
      Get.back(); // Close loading dialog
      onError('Failed to send photo: $e');
    }
  }

  static Future<void> _sendDisappearingPhotoWithBytes(
    String matchId,
    Uint8List imageBytes,
    String fileName,
    Function(String) onPhotoSent,
    Function(String) onError,
  ) async {
    try {
      // Send disappearing photo
      final photoUrl = await DisappearingPhotoService.sendDisappearingPhoto(
        matchId: matchId,
        photoBytes: imageBytes,
        fileName: fileName,
        viewDuration: 10,
      );
      
      if (photoUrl != null) {
        Get.back(); // Close loading dialog
        onPhotoSent('Disappearing photo sent successfully!');
      } else {
        Get.back(); // Close loading dialog
        onError('Failed to send disappearing photo');
      }
    } catch (e) {
      print('Error sending disappearing photo: $e');
      Get.back(); // Close loading dialog
      onError('Failed to send disappearing photo: $e');
    }
  }
}
