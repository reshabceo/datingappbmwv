import 'dart:io';
import 'dart:ui';
import 'package:uuid/uuid.dart';
import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/widget_constant.dart';
import 'package:lovebug/Constant/app_assets.dart';
import 'package:lovebug/Screens/ChatPage/controller_message_screen.dart';
import 'package:lovebug/Screens/ChatPage/ui_chatbubble_screen.dart';
import 'package:lovebug/Screens/DiscoverPage/profile_detail_screen.dart';
import 'package:lovebug/Screens/DiscoverPage/controller_discover_screen.dart';
import 'package:lovebug/Screens/ChatPage/disappearing_photo_screen.dart';
import 'package:lovebug/Screens/ChatPage/astro_compatibility_widget.dart';
import 'package:lovebug/Screens/ChatPage/ice_breaker_widget.dart';
import 'package:lovebug/Screens/ChatPage/improved_ice_breaker_widget.dart';
import 'package:lovebug/Screens/ChatPage/enhanced_photo_upload_service.dart';
import 'package:lovebug/Screens/ChatPage/ui_simple_camera_screen.dart';
import 'package:lovebug/Screens/ChatPage/controller_chat_screen.dart';
import 'package:lovebug/Screens/ChatPage/audio_recording_widget.dart';
import 'package:lovebug/Screens/ChatPage/audio_message_bubble.dart';
import 'package:lovebug/services/audio_recording_service.dart';
import 'package:lovebug/models/audio_message.dart';
import 'package:lovebug/services/disappearing_photo_service.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:lovebug/services/astro_service.dart';
import 'package:lovebug/controllers/call_controller.dart';
import 'package:lovebug/models/call_models.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:lovebug/Widgets/upgrade_prompt_widget.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:typed_data';

// Astro compatibility button states
enum AstroCompatibilityButtonState { generate, show, hide, regenerate }

// Helper to merge messages chronologically

class EnhancedMessageScreen extends StatefulWidget {
  EnhancedMessageScreen({
    super.key,
    required this.userImage,
    required this.userName,
    required this.matchId,
    this.isBffMatch = false,
  });

  final String? userImage;
  final String? userName;
  final String matchId;
  final bool isBffMatch;

  @override
  State<EnhancedMessageScreen> createState() => _EnhancedMessageScreenState();
}

class _EnhancedMessageScreenState extends State<EnhancedMessageScreen> with WidgetsBindingObserver {
  final ThemeController themeController = Get.find<ThemeController>();
  String? otherUserZodiac;
  bool isLoadingZodiac = true;
  bool astroVisible = false;
  String? currentUserImage;
  String? currentUserZodiac;
  
  // Astro compatibility button state
  AstroCompatibilityButtonState _astroButtonState = AstroCompatibilityButtonState.generate;
  
  
  
  // Audio recording state (press-and-hold UX)
  bool _isRecordingAudio = false; // kept for backward-compat, not used for UI now
  DateTime? _recordStartAt;
  String? _pendingAudioPath;
  int _pendingAudioDurationSec = 0;
  int _pendingAudioFileSize = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print('🔄 DEBUG: EnhancedMessageScreen initState - loading current user profile');
    print('🔄 DEBUG: EnhancedMessageScreen initState - widget.userImage: ${widget.userImage}');
    print('🔄 DEBUG: EnhancedMessageScreen initState - widget.userName: ${widget.userName}');
    print('🔄 DEBUG: EnhancedMessageScreen initState - widget.matchId: ${widget.matchId}');
    print('🔄 DEBUG: EnhancedMessageScreen initState - widget.isBffMatch: ${widget.isBffMatch}');
    _loadCurrentUserProfile();
    _loadOtherUserZodiac();
    _loadMatchEnhancementsStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Reload profile when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _loadCurrentUserProfile();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Always reload profile when dependencies change to ensure fresh data
    _loadCurrentUserProfile();
  }

  @override
  void didUpdateWidget(EnhancedMessageScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload profile when widget updates (e.g., user returned from profile edit)
    _loadCurrentUserProfile();
  }

  Future<void> _loadCurrentUserProfile() async {
    try {
      print('🔄 DEBUG: _loadCurrentUserProfile called in EnhancedMessageScreen');
      final currentUser = SupabaseService.currentUser;
      print('🔄 DEBUG: Loading current user profile for: ${currentUser?.id}');
      if (currentUser != null) {
        // Force fresh fetch by bypassing cache
        final profile = await SupabaseService.client
            .from('profiles')
            .select()
            .eq('id', currentUser.id)
            .maybeSingle();
        print('🔄 DEBUG: Profile loaded: $profile');
        if (profile != null && mounted) {
          setState(() {
            // Prioritize image_urls over photos (image_urls is the source of truth)
            final photos = <String>[];
            
            // First check image_urls (current photos)
            if (profile['image_urls'] != null) {
              final imageUrls = List<String>.from(profile['image_urls']);
              photos.addAll(imageUrls.where((url) => 
                url.isNotEmpty && 
                (url.startsWith('http://') || url.startsWith('https://'))
              ));
            }
            
            // Only use photos field if image_urls is empty/null
            if (photos.isEmpty && profile['photos'] != null) {
              final photoList = List<String>.from(profile['photos']);
              photos.addAll(photoList.where((p) => 
                p.isNotEmpty && 
                (p.startsWith('http://') || p.startsWith('https://'))
              ));
            }
            
            // Remove duplicates
            final validPhotos = photos.toSet().toList();
            print('🔄 DEBUG: Found photos from image_urls: ${profile['image_urls']}');
            print('🔄 DEBUG: Found photos from photos: ${profile['photos']}');
            print('🔄 DEBUG: Valid photos after filtering: $validPhotos');
            final newImage = validPhotos.isNotEmpty ? validPhotos.first : null;
            // Always update to force refresh
            currentUserImage = newImage;
            print('🔄 DEBUG: Updated currentUserImage to: $currentUserImage');
            currentUserZodiac = (profile['zodiac_sign'] ?? '').toString();
          });
        }
      }
    } catch (e) {
      print('❌ DEBUG: Error loading current user profile: $e');
    }
  }

  Future<void> _loadOtherUserZodiac() async {
    try {
      // Get the match details to find the other user's ID
      final match = await SupabaseService.getMatchById(widget.matchId);
      if (match != null) {
        final currentUserId = SupabaseService.currentUser?.id;
        final userId1 = match['user_id_1']?.toString();
        final userId2 = match['user_id_2']?.toString();
        
        // Find the other user's ID (not the current user)
        String? otherUserId;
        if (userId1 == currentUserId) {
          otherUserId = userId2;
        } else if (userId2 == currentUserId) {
          otherUserId = userId1;
        }
        
        if (otherUserId != null) {
          // Get the other user's profile
          final profileData = await SupabaseService.getProfile(otherUserId);
          if (profileData != null) {
            setState(() {
              otherUserZodiac = profileData['zodiac_sign']?.toString() ?? 'unknown';
              isLoadingZodiac = false;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading other user zodiac: $e');
      setState(() {
        otherUserZodiac = 'unknown';
        isLoadingZodiac = false;
      });
    }
  }

  Profile _mapToProfile(Map<String, dynamic> profileData, {String? matchId}) {
    final photos = <String>[];
    if (profileData['photos'] != null) {
      photos.addAll(List<String>.from(profileData['photos']));
    }
    if (profileData['image_urls'] != null) {
      photos.addAll(List<String>.from(profileData['image_urls']));
    }
    
    final hobbies = <String>[];
    if (profileData['hobbies'] != null) {
      hobbies.addAll(List<String>.from(profileData['hobbies']));
    }
    if (profileData['interests'] != null) {
      hobbies.addAll(List<String>.from(profileData['interests']));
    }

    return Profile(
      id: profileData['id']?.toString() ?? '',
      name: profileData['name']?.toString() ?? 'User',
      age: (profileData['age'] ?? 25) as int,
      imageUrl: photos.isNotEmpty ? photos.first : '',
      photos: photos,
      location: profileData['location']?.toString() ?? 'Unknown',
      distance: profileData['distance']?.toString() ?? 'Unknown distance',
      description: profileData['description']?.toString() ?? 
                  profileData['bio']?.toString() ?? 
                  'No description available',
      hobbies: hobbies,
      isVerified: (profileData['is_verified'] ?? false) as bool,
      isActiveNow: (profileData['is_active'] ?? false) as bool,
      matchId: matchId,
    );
  }

  Widget _buildDefaultAppBar() {
    return Container(
      decoration: BoxDecoration(color: themeController.blackColor),
      child: AppBar(
        backgroundColor: themeController.transparentColor,
        elevation: 0,
        iconTheme: IconThemeData(color: themeController.whiteColor),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: Get.back,
        ),
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextConstant(
              title: widget.userName ?? '',
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: themeController.whiteColor,
            ),
            TextConstant(
              title: 'online'.tr,
              fontWeight: FontWeight.w600,
              color: themeController.greenColor,
              fontSize: 11,
            ),
          ],
        ),
        actions: [
          _buildAstroActionButton(),
          GestureDetector(
            onTap: () => _showChatOptions(),
            child: Container(
              width: 35.h,
              height: 35.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.isBffMatch
                      ? [themeController.bffPrimaryColor, themeController.bffSecondaryColor]
                      : [themeController.getAccentColor(), themeController.getSecondaryColor()],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
            ),
          ),
          widthBox(12),
        ],
      ),
    );
  }

  Widget _buildSelectionAppBar(MessageController controller) {
    final selectedCount = controller.selectedMessageKeys.length;
    final bool canDeleteAll = controller.canDeleteForEveryone.value;

    return Container(
      decoration: BoxDecoration(color: themeController.blackColor),
      child: AppBar(
        backgroundColor: themeController.transparentColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: controller.clearSelection,
        ),
        title: TextConstant(
          title: '$selectedCount selected',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: themeController.whiteColor,
        ),
        actions: [
          IconButton(
            icon: Icon(canDeleteAll ? Icons.delete_forever : Icons.delete_outline),
            color: themeController.whiteColor,
            onPressed: controller.selectedMessageKeys.isEmpty
                ? null
                : () => _showDeleteOptions(controller),
          ),
          widthBox(8),
        ],
      ),
    );
  }

  void _showDeleteOptions(MessageController controller) {
    final bool canDeleteAll = controller.canDeleteForEveryone.value;

    Get.bottomSheet(
      ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            margin: EdgeInsets.only(bottom: MediaQuery.of(Get.context!).viewInsets.bottom),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.25),
                  themeController.getAccentColor().withValues(alpha: 0.18),
                  themeController.getSecondaryColor().withValues(alpha: 0.16),
                ],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: themeController.getAccentColor().withValues(alpha: 0.18),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: themeController.whiteColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    heightBox(20.h.toInt()),
                    _buildDeleteOption(
                      icon: Icons.delete_outline,
                      title: 'delete_for_me'.tr,
                      onTap: () async {
                        Get.back();
                        await controller.deleteSelectedMessages(forEveryone: false);
                      },
                    ),
                    if (canDeleteAll)
                      _buildDeleteOption(
                        icon: Icons.delete_forever,
                        title: 'delete_for_everyone'.tr,
                        isDestructive: true,
                        onTap: () async {
                          Get.back();
                          await controller.deleteSelectedMessages(forEveryone: true);
                        },
                      ),
                    heightBox(8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
    );
  }

  Widget _buildDeleteOption({
    required IconData icon,
    required String title,
    required Future<void> Function() onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async => await onTap(),
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isDestructive
                  ? Colors.red.withValues(alpha: 0.1)
                  : themeController.whiteColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isDestructive
                    ? Colors.red.withValues(alpha: 0.3)
                    : themeController.getAccentColor().withValues(alpha: 0.2),
                width: 1.w,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isDestructive ? Colors.red : themeController.getAccentColor(),
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: TextConstant(
                    title: title,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDestructive
                        ? Colors.red
                        : themeController.whiteColor,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: isDestructive
                      ? Colors.red.withValues(alpha: 0.5)
                      : themeController.whiteColor.withValues(alpha: 0.5),
                  size: 14.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _viewProfile() async {
    try {
      // Get the match details to find the other user's ID
      final match = await SupabaseService.getMatchById(widget.matchId);
      if (match != null) {
        final currentUserId = SupabaseService.currentUser?.id;
        final userId1 = match['user_id_1']?.toString();
        final userId2 = match['user_id_2']?.toString();
        
        // Find the other user's ID (not the current user)
        String? otherUserId;
        if (userId1 == currentUserId) {
          otherUserId = userId2;
        } else if (userId2 == currentUserId) {
          otherUserId = userId1;
        }
        
        if (otherUserId != null) {
          // Get the other user's profile
          final profileData = await SupabaseService.getProfile(otherUserId);
          if (profileData != null) {
            // Convert Map to Profile object
            final profile = _mapToProfile(profileData, matchId: widget.matchId);
            // Navigate to profile detail screen (this is a matched profile)
            Get.to(() => ProfileDetailScreen(profile: profile, isMatched: true));
          } else {
            Get.snackbar('Error', 'Profile not found');
          }
        } else {
          Get.snackbar('Error', 'Could not find user profile');
        }
      } else {
        Get.snackbar('Error', 'Match not found');
      }
    } catch (e) {
      print('Error viewing profile: $e');
      Get.snackbar('Error', 'Failed to load profile');
    }
  }

  Future<void> _sendDisappearingPhoto(MessageController controller) async {
    try {
      // Show duration selection dialog
      final duration = await _showDurationDialog();
      if (duration == null) return;

      // Pick image from camera
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        // Read image bytes
        final Uint8List imageBytes = await image.readAsBytes();
        
        // Send disappearing photo
        final photoUrl = await EnhancedDisappearingPhotoService.sendDisappearingPhoto(
          matchId: widget.matchId,
          photoBytes: imageBytes,
          fileName: 'disappearing_${DateTime.now().millisecondsSinceEpoch}.jpg',
          viewDuration: duration,
        );

        if (photoUrl != null) {
          Get.snackbar('Success', 'Disappearing photo sent!');
        } else {
          Get.snackbar('Error', 'Failed to send disappearing photo');
        }
      }
    } catch (e) {
      print('Error sending disappearing photo: $e');
      Get.snackbar('Error', 'Failed to send disappearing photo');
    }
  }

  Future<void> _showCameraGalleryPicker(MessageController controller) async {
    try {
      // Navigate directly to simple camera screen since permissions are requested at startup
      Get.to(() => SimpleCameraScreen(matchId: widget.matchId));
    } catch (e) {
      print('Error opening camera: $e');
      Get.snackbar('Error', 'Failed to open camera');
    }
  }

  Future<void> _showPhotoOptions(MessageController controller) async {
    try {
      // Show source selection first
      final source = await showModalBottomSheet<ImageSource>(
        context: Get.context!,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.6),
        isScrollControlled: true,
        builder: (_) {
          return ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                margin: EdgeInsets.only(bottom: MediaQuery.of(Get.context!).viewInsets.bottom),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.pink.withValues(alpha: 0.15),
                      Colors.purple.withValues(alpha: 0.2),
                      themeController.blackColor.withValues(alpha: 0.85),
                    ],
                    stops: [0.0, 0.3, 1.0],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
                  border: Border.all(
                    color: themeController.getAccentColor().withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: themeController.getAccentColor().withValues(alpha: 0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: SafeArea(
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
                              color: themeController.getAccentColor(),
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
                        
                        // Gallery Option
                        _buildPhotoSourceOption(
                          icon: Icons.photo_library,
                          title: 'Choose from Gallery',
                          subtitle: 'Select from your photos',
                          onTap: () => Get.back(result: ImageSource.gallery),
                        ),
                        
                        heightBox(20.h.toInt()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );

      if (source == null) return;

      // Pick the image
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (image == null) {
        // User cancelled
        return;
      }

      // Read image bytes
      final Uint8List imageBytes = await image.readAsBytes();
      
      // Now show options for how to send the photo using our enhanced service
      await EnhancedPhotoUploadService.handlePhotoSelection(
        controller: controller,
        matchId: widget.matchId,
        imageBytes: imageBytes,
        fileName: image.name,
      );
    } catch (e) {
      print('Error in photo flow: $e');
      if (e.toString().contains('camera') || e.toString().contains('Camera')) {
        Get.snackbar(
          'Camera Not Available', 
          'Camera is not available in simulator. Please test on a real device.',
          backgroundColor: themeController.blackColor,
          colorText: themeController.whiteColor,
        );
      } else if (e.toString().contains('permission')) {
        Get.snackbar(
          'Permission Required', 
          'Camera permission is required to take photos.',
          backgroundColor: themeController.blackColor,
          colorText: themeController.whiteColor,
        );
      } else if (e.toString().contains('Bucket not found')) {
        Get.snackbar(
          'Storage Setup Required', 
          'Please run the storage setup SQL in Supabase first.',
          backgroundColor: themeController.blackColor,
          colorText: themeController.whiteColor,
        );
      } else {
        Get.snackbar('Error', 'Failed to access photo: ${e.toString()}');
      }
    }
  }

  Future<int?> _showDurationDialog() async {
    return await Get.dialog<int>(
      AlertDialog(
        backgroundColor: themeController.blackColor,
        title: TextConstant(
          title: 'Select View Duration',
          color: themeController.whiteColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.timer_10, color: themeController.primaryColor.value),
              title: TextConstant(
                title: '10 seconds',
                color: themeController.whiteColor,
              ),
              onTap: () => Get.back(result: 10),
            ),
            ListTile(
              leading: Icon(Icons.timer_3, color: themeController.primaryColor.value),
              title: TextConstant(
                title: '30 seconds',
                color: themeController.whiteColor,
              ),
              onTap: () => Get.back(result: 30),
            ),
            ListTile(
              leading: Icon(Icons.timer, color: themeController.primaryColor.value),
              title: TextConstant(
                title: '1 minute',
                color: themeController.whiteColor,
              ),
              onTap: () => Get.back(result: 60),
            ),
          ],
        ),
      ),
    );
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      isScrollControlled: true,
      builder: (_) {
        return ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              margin: EdgeInsets.only(bottom: MediaQuery.of(Get.context!).viewInsets.bottom),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.pink.withValues(alpha: 0.15),
                    Colors.purple.withValues(alpha: 0.2),
                    themeController.blackColor.withValues(alpha: 0.85),
                  ],
                  stops: [0.0, 0.3, 1.0],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
                border: Border.all(
                  color: themeController.lightPinkColor.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeController.lightPinkColor.withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: SafeArea(
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
                            Icons.more_vert,
                            color: widget.isBffMatch 
                                ? themeController.bffPrimaryColor 
                                : themeController.lightPinkColor,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          TextConstant(
                            title: 'Chat Options',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: themeController.whiteColor,
                          ),
                        ],
                      ),
                      heightBox(20.h.toInt()),
                      
                      // Menu Options
                      _buildMenuOption(
                        icon: Icons.person,
                        title: 'View Profile',
                        onTap: () {
                          Get.back();
                          _viewProfile();
                        },
                      ),
                      
                      _buildMenuOption(
                        icon: Icons.photo_camera,
                        title: 'Send Disappearing Photo',
                        onTap: () {
                          Get.back();
                          final controller = Get.find<MessageController>(tag: 'msg_${widget.matchId}');
                          _sendDisappearingPhoto(controller);
                        },
                      ),
                      
                      // Call Options
                      _buildMenuOption(
                        icon: Icons.videocam,
                        title: 'Video Call',
                        onTap: () async {
                          Get.back();
                          final isPremium = await SupabaseService.isPremiumUser();
                          if (!isPremium) {
                            _showFrostedDialog(
                              UpgradePromptWidget(
                                title: 'Premium Feature',
                                message: 'Video call is a premium feature. Upgrade to unlock it.',
                                action: 'Upgrade Now',
                                limitType: 'message',
                                onDismiss: () => Get.back(),
                              ),
                            );
                            return;
                          }
                          _startVideoCall();
                        },
                      ),
                      
                      _buildMenuOption(
                        icon: Icons.call,
                        title: 'Audio Call',
                        onTap: () async {
                          Get.back();
                          final isPremium = await SupabaseService.isPremiumUser();
                          if (!isPremium) {
                            _showFrostedDialog(
                              UpgradePromptWidget(
                                title: 'Premium Feature',
                                message: 'Audio call is a premium feature. Upgrade to unlock it.',
                                action: 'Upgrade Now',
                                limitType: 'message',
                                onDismiss: () => Get.back(),
                              ),
                            );
                            return;
                          }
                          _startAudioCall();
                        },
                      ),
                      
                      _buildMenuOption(
                        icon: Icons.notifications_off,
                        title: 'Mute Notifications',
                        onTap: () {
                          Get.back();
                          Get.snackbar('Muted', 'Notifications muted for this chat');
                        },
                      ),
                      
                      _buildMenuOption(
                        icon: Icons.delete_outline,
                        title: 'Clear Chat',
                        isDestructive: true,
                        onTap: () {
                          Get.back();
                          _showClearChatDialog();
                        },
                      ),
                      
                      _buildMenuOption(
                        icon: Icons.person_remove,
                        title: 'Unmatch User',
                        isDestructive: true,
                        onTap: () {
                          Get.back();
                          _showUnmatchUserDialog();
                        },
                      ),
                      
                      _buildMenuOption(
                        icon: Icons.block,
                        title: 'Block User',
                        isDestructive: true,
                        onTap: () {
                          Get.back();
                          Get.snackbar('Info', 'Block functionality coming soon');
                        },
                      ),
                      
                      heightBox(20.h.toInt()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isDestructive 
                  ? Colors.red.withValues(alpha: 0.1)
                  : themeController.whiteColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isDestructive 
                    ? Colors.red.withValues(alpha: 0.2)
                    : themeController.lightPinkColor.withValues(alpha: 0.1),
                width: 1.w,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isDestructive 
                      ? Colors.red
                      : themeController.lightPinkColor,
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: TextConstant(
                    title: title,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDestructive 
                        ? Colors.red
                        : themeController.whiteColor,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: isDestructive 
                      ? Colors.red.withValues(alpha: 0.5)
                      : themeController.whiteColor.withValues(alpha: 0.5),
                  size: 14.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFrostedDialog(Widget child, {bool barrierDismissible = true}) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: child,
          ),
        ),
      ),
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withOpacity(0.6),
    );
  }

  void _showClearChatDialog() {
    _showFrostedDialog(
      Container(
        decoration: BoxDecoration(
          color: themeController.blackColor.withOpacity(0.85),
          borderRadius: BorderRadius.circular(22.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextConstant(
          title: 'Clear Chat',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: themeController.whiteColor,
        ),
              SizedBox(height: 12.h),
              TextConstant(
          title: 'Are you sure you want to clear all messages in this chat? This action cannot be undone.',
          fontSize: 14,
          color: themeController.whiteColor.withValues(alpha: 0.8),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(18.r),
                        ),
            child: TextConstant(
              title: 'Cancel',
                          color: themeController.whiteColor,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
              Get.back();
              Get.snackbar('Success', 'Chat cleared successfully');
            },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.redAccent, Colors.pink],
                          ),
                          borderRadius: BorderRadius.circular(18.r),
                        ),
            child: TextConstant(
              title: 'Clear',
                          color: Colors.white,
                          textAlign: TextAlign.center,
                        ),
                      ),
            ),
          ),
                ],
              )
        ],
          ),
        ),
      ),
    );
  }

  void _showUnmatchUserDialog() {
    _showFrostedDialog(
      UpgradePromptWidget(
          title: 'Unmatch User',
        message: 'Are you sure you want to unmatch with this user? You will no longer be able to message each other.',
        action: 'Unmatch',
        dismissLabel: 'Cancel',
        icon: Icons.person_remove,
        gradientColors: [
          Colors.red.withOpacity(0.2),
          Colors.deepPurple.withOpacity(0.2),
          Colors.black.withOpacity(0.85),
        ],
        onDismiss: () => Get.back(),
        onUpgrade: () async {
              Get.back();
              await _unmatchUser();
            },
      ),
    );
  }

  Future<void> _unmatchUser() async {
    try {
      print('🔄 DEBUG: Starting to unmatch user for match: ${widget.matchId}');
      
      // Show loading indicator
      Get.dialog(
        Center(
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: themeController.blackColor,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: themeController.getAccentColor(),
                ),
                heightBox(10.h.toInt()),
                TextConstant(
                  title: 'Unmatching...',
                  color: themeController.whiteColor,
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );
      
      // Update match status to unmatched
      final updateResult = await SupabaseService.client
          .from('matches')
          .update({'status': 'unmatched'})
          .eq('id', widget.matchId)
          .select();
      
      print('🔄 DEBUG: Unmatch update result: $updateResult');
      
      // Close loading dialog
      Get.back();
      
      if (updateResult != null && updateResult.isNotEmpty) {
        print('✅ DEBUG: User unmatched successfully');
        Get.snackbar(
          'Success',
          'You have unmatched with this user',
          backgroundColor: themeController.blackColor,
          colorText: themeController.whiteColor,
          duration: Duration(seconds: 2),
        );
        
        // Navigate back to chat list and refresh
        Get.back();
        
        // Force refresh the chat list
        try {
          final chatController = Get.find<EnhancedChatController>();
          chatController.loadChats();
          print('✅ DEBUG: Chat list refreshed after unmatch');
        } catch (e) {
          print('❌ DEBUG: Could not refresh chat list: $e');
        }
      } else {
        print('❌ DEBUG: No rows updated - match might not exist');
        Get.snackbar(
          'Error',
          'Failed to unmatch user - match not found',
          backgroundColor: themeController.blackColor,
          colorText: themeController.whiteColor,
          duration: Duration(seconds: 3),
        );
      }
    } catch (e) {
      print('❌ DEBUG: Error unmatching user: $e');
      Get.back(); // Close loading dialog
      Get.snackbar(
        'Error', 
        'Failed to unmatch user: $e',
        backgroundColor: themeController.blackColor,
        colorText: themeController.whiteColor,
        duration: Duration(seconds: 3),
      );
    }
  }

  Widget _buildPhotoSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: themeController.whiteColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: themeController.lightPinkColor.withValues(alpha: 0.1),
                width: 1.w,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: themeController.lightPinkColor,
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextConstant(
                        title: title,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: themeController.whiteColor,
                      ),
                      SizedBox(height: 2.h),
                      TextConstant(
                        title: subtitle,
                        fontSize: 12,
                        color: themeController.whiteColor.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: themeController.whiteColor.withValues(alpha: 0.5),
                  size: 14.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MessageController controller =
        Get.put(MessageController(), tag: 'msg_${widget.matchId}')
          ..ensureInitialized(widget.matchId, isBffMatch: widget.isBffMatch);

    return WillPopScope(
      onWillPop: () async {
        if (controller.isSelectionMode.value) {
          controller.clearSelection();
          return false;
        }
        return true;
      },
      child: Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Obx(() {
            return controller.isSelectionMode.value
                ? _buildSelectionAppBar(controller)
                : _buildDefaultAppBar();
          }),
      ),
      body: Container(
        width: Get.width,
        height: Get.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              themeController.blackColor,
              themeController.bgGradient1,
              themeController.blackColor,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
              _buildFlameBanner(controller),
            Expanded(
              child: Obx(() {
                  final showAstro =
                      astroVisible &&
                      !isLoadingZodiac &&
                      otherUserZodiac != null &&
                      otherUserZodiac != 'unknown';
                  final hasAnyMessages =
                      controller.messages.isNotEmpty || controller.audioMessages.isNotEmpty;

                if (!hasAnyMessages) {
                  return ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      if (showAstro)
                        AstroCompatibilityWidget(
                          matchId: widget.matchId,
                          otherUserName: widget.userName ?? '',
                          otherUserZodiac: otherUserZodiac!,
                          visible: true,
                          autoGenerateIfMissing: false,
                        ),
                      Center(
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 20.w),
                            padding: EdgeInsets.all(20.w),
                            decoration: BoxDecoration(
                              color: themeController.transparentColor,
                              borderRadius: BorderRadius.circular(15.r),
                              border: Border.all(
                                color: themeController.whiteColor.withOpacity(0.2),
                                width: 1.w,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextConstant(
                                  title: 'Hey 👋',
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: themeController.whiteColor,
                                  textAlign: TextAlign.center,
                                ),
                                heightBox(10),
                                TextConstant(
                                  title: 'Say something to start the conversation!',
                                  softWrap: true,
                                  fontSize: 14,
                                  color: themeController.whiteColor,
                                  textAlign: TextAlign.center,
                                ),
                                heightBox(8),
                                TextConstant(
                                  title: 'Tap on the ice breakers below',
                                  softWrap: true,
                                  fontSize: 12,
                                  color: themeController.whiteColor.withOpacity(0.7),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ImprovedIceBreakerWidget(
                        matchId: widget.matchId,
                        otherUserName: widget.userName ?? '',
                        currentUserZodiac: currentUserZodiac,
                      ),
                    ],
                  );
                  }

              return Column(
                children: [
                  if (showAstro)
                    AstroCompatibilityWidget(
                      matchId: widget.matchId,
                      otherUserName: widget.userName ?? '',
                      otherUserZodiac: otherUserZodiac!,
                      visible: true,
                      autoGenerateIfMissing: false,
                    ),
                  Expanded(
                        child: Obx(() {
                          // Access selectedMessageKeys to make Obx reactive to selection changes
                          final _ = controller.selectedMessageKeys.length;
                          
                          print(
                              '🔊 DEBUG: Obx rebuilding - allSortedMessages count: ${controller.allSortedMessages.length}');
                      print('🔍 DEBUG: UI Display Order:');
                      for (int i = 0; i < controller.allSortedMessages.length; i++) {
                            final item = controller.allSortedMessages[i];
                            if (item is Message) {
                              print('  $i: TEXT "${item.text}" at ${item.timestamp}');
                            } else if (item is AudioMessage) {
                              print('  $i: AUDIO at ${item.createdAt}');
                            }
                          }

                          final isSelectionMode = controller.isSelectionMode.value;
                      
                      return ListView.builder(
                        controller: controller.scrollController,
                        itemCount: controller.allSortedMessages.length,
                        itemBuilder: (context, index) {
                              final item = controller.allSortedMessages[index];
                          
                              final bool isSelectable = controller.isItemSelectable(item);
                              final bool isSelected = controller.isItemSelected(item);

                              if (item is Message) {
                            return EnhancedChatBubble(
                                  message: item,
                              userName: widget.userName ?? '',
                              isBffMatch: widget.isBffMatch,
                              userImage: currentUserImage,
                              otherUserImage: widget.userImage,
                                  isSelectionMode: isSelectionMode,
                                  isSelectable: isSelectable,
                                  isSelected: isSelected,
                                  onTap: controller.isSelectionMode.value && isSelectable
                                      ? () => controller.toggleSelectionForItem(item)
                                      : null,
                                  onLongPress: isSelectable
                                      ? () => controller.startSelectionForItem(item)
                                      : null,
                                );
                              } else if (item is AudioMessage) {
                                final bool isMe =
                                    item.senderId == (SupabaseService.currentUser?.id ?? '');
                            return AudioMessageBubble(
                                  audioMessage: item,
                                  isMe: isMe,
                              userImage: currentUserImage,
                              otherUserImage: widget.userImage,
                              isBffMatch: widget.isBffMatch,
                                  isSelectionMode: isSelectionMode,
                                  isSelectable: isSelectable,
                                  isSelected: isSelected,
                                  onTap: controller.isSelectionMode.value && isSelectable
                                      ? () => controller.toggleSelectionForItem(item)
                                      : null,
                                  onLongPress: isSelectable
                                      ? () => controller.startSelectionForItem(item)
                                      : null,
                            );
                          }
                          
                          return const SizedBox.shrink();
                        },
                      );
                    }),
                  ),
                ],
              );
              }),
            ),
              if (_pendingAudioPath != null) _buildPendingAudioBar(),
              _buildChatInputField(controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlameBanner(MessageController controller) {
    return Obx(() {
      if (!controller.shouldShowFlameBanner) {
        return SizedBox.shrink();
      }

      final bool isActive = controller.isFlameActive.value;
      final bool shouldUpgrade = controller.shouldBlockPostFlameMessaging;
      final bool isBff = controller.isBffMode;

      final Color primaryColor = isBff
          ? themeController.bffPrimaryColor
          : themeController.getAccentColor();
      final Color secondaryColor = isBff
          ? themeController.bffSecondaryColor
          : themeController.getSecondaryColor();

      final IconData icon = isActive
          ? Icons.local_fire_department
          : (shouldUpgrade ? Icons.lock_clock : Icons.check_circle_outline);

      final String headline = isActive
          ? 'Flame Chat is live'
          : 'Flame Chat ended';

      final String detail = isActive
          ? '${controller.formattedFlameCountdown} remaining'
          : (shouldUpgrade
              ? 'Upgrade to keep the chat going without waiting.'
              : 'You can keep chatting freely.');

      return Container(
        margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 18.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.28),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 24.sp,
                ),
                widthBox(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextConstant(
                        title: headline,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      SizedBox(height: 6.h),
                      TextConstant(
                        title: detail,
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                        softWrap: true,
                        maxLines: null,
                      ),
                      if (isActive)
                        Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: TextConstant(
                            title: 'Make the most of this window—messages are unrestricted.',
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.75),
                            softWrap: true,
                            maxLines: null,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (!isActive) ...[
              SizedBox(height: 14.h),
              if (shouldUpgrade && controller.formattedNextMessageTime.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: TextConstant(
                    title: 'Next message available ${controller.formattedNextMessageTime}.',
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                    softWrap: true,
                    maxLines: null,
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: _buildFlameActionButton(
                  label: 'Continue Chat',
                  primary: primaryColor,
                  secondary: secondaryColor,
                  onTap: controller.handleContinueChat,
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildFlameActionButton({
    required String label,
    required Color primary,
    required Color secondary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 11.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primary, secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22.r),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.3),
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextConstant(
              title: label,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            SizedBox(width: 6.w),
            Icon(Icons.arrow_forward, color: Colors.white, size: 16.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInputField(MessageController controller) {
    final ctx = Get.context!;
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom,
        left: 15.w,
        right: 15.w,
        top: 10.h,
      ),
      decoration: BoxDecoration(
        color: themeController.blackColor,
        boxShadow: [
          BoxShadow(
            color: themeController.blackColor.withOpacity(0.6),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () async {
                // Bypass premium check during active flame chat
                final isFlameActive = controller.isFlameActive.value;
                if (!isFlameActive) {
                  final isPremium = await SupabaseService.isPremiumUser();
                  if (!isPremium) {
                    _showFrostedDialog(
                      UpgradePromptWidget(
                        title: 'Premium Feature',
                        message: 'Sending images is a premium feature. Upgrade to unlock it.',
                        action: 'Upgrade Now',
                        limitType: 'message',
                        onDismiss: () => Get.back(),
                      ),
                    );
                    return;
                  }
                }
                _showCameraGalleryPicker(controller);
              },
              child: Container(
                width: 35.h,
                height: 35.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.isBffMatch 
                        ? [themeController.bffPrimaryColor, themeController.bffSecondaryColor]
                        : [themeController.getAccentColor(), themeController.getSecondaryColor()],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white,
                  size: 16.sp,
                ),
              ),
            ),
            widthBox(6),
            
            Expanded(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: 40.h,
                  maxHeight: 200.h,
                ),
                child: Obx(() {
                  final bool inputEnabled = controller.isFlameActive.value || !controller.shouldBlockPostFlameMessaging;
                  return TextField(
                  controller: controller.textController,
                    enabled: inputEnabled,
                  maxLines: null,
                  style: TextStyle(
                    color: themeController.whiteColor,
                    fontSize: 14.sp,
                  ),
                  decoration: InputDecoration(
                      hintText: inputEnabled
                          ? 'Type a message...'
                          : 'Continue chat to keep messaging',
                    hintStyle: TextStyle(
                      color: themeController.whiteColor.withOpacity(0.6),
                      fontSize: 14.sp,
                    ),
                    filled: true,
                    fillColor: themeController.transparentColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.r),
                      borderSide: BorderSide(
                        color: themeController.whiteColor.withOpacity(0.3),
                        width: 1.w,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.r),
                      borderSide: BorderSide(
                        color: themeController.whiteColor.withOpacity(0.3),
                        width: 1.w,
                      ),
                    ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.r),
                        borderSide: BorderSide(
                          color: themeController.whiteColor.withOpacity(0.15),
                          width: 1.w,
                        ),
                      ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.r),
                      borderSide: BorderSide(
                        color: widget.isBffMatch 
                            ? themeController.bffPrimaryColor 
                            : themeController.getAccentColor(),
                        width: 1.5.w,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.r),
                      borderSide: BorderSide(
                        color: themeController.whiteColor.withOpacity(0.3),
                        width: 1.w,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.r),
                      borderSide: BorderSide(
                        color: widget.isBffMatch 
                            ? themeController.bffPrimaryColor 
                            : themeController.getAccentColor(),
                        width: 1.5.w,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 15.w,
                      vertical: 10.h,
                    ),
                  ),
                  onSubmitted: (text) {
                    if (text.trim().isNotEmpty) {
                      controller.sendMessage(widget.matchId, text.trim());
                    }
                  },
                  );
                }),
              ),
            ),
            widthBox(6),
            
            // Mic button - placed immediately to the left of Send
            GestureDetector(
              onTap: () async {
                if (_isRecordingAudio) {
                  await _stopAudioRecordingAndPreparePending();
                  return;
                }
                // Bypass premium check during active flame chat
                final isFlameActive = controller.isFlameActive.value;
                if (!isFlameActive) {
                  final isPremium = await SupabaseService.isPremiumUser();
                  if (!isPremium) {
                    _showFrostedDialog(
                      UpgradePromptWidget(
                        title: 'Premium Feature',
                        message: 'Sending audio notes is a premium feature. Upgrade to unlock it.',
                        action: 'Upgrade Now',
                        limitType: 'message',
                        onDismiss: () => Get.back(),
                      ),
                    );
                    return;
                  }
                }
                await _startAudioRecording();
              },
              child: Container(
                width: 35.h,
                height: 35.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.isBffMatch 
                        ? [themeController.bffPrimaryColor, themeController.bffSecondaryColor]
                        : [themeController.getAccentColor(), themeController.getSecondaryColor()],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isRecordingAudio ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 16.sp,
                ),
              ),
            ),
            widthBox(6),
            GestureDetector(
              onTap: () {
                if (controller.textController.text.trim().isNotEmpty) {
                  controller.sendMessage(
                    widget.matchId, 
                    controller.textController.text.trim()
                  );
                }
              },
              child: Container(
                width: 35.h,
                height: 35.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.isBffMatch 
                        ? [themeController.bffPrimaryColor, themeController.bffSecondaryColor]
                        : [themeController.getAccentColor(), themeController.getSecondaryColor()],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.send,
                  color: Colors.white,
                  size: 16.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build astro compatibility action button
  Widget _buildAstroActionButton() {
    IconData icon;
    String tooltip;
    
    switch (_astroButtonState) {
      case AstroCompatibilityButtonState.generate:
        icon = Icons.auto_awesome;
        tooltip = 'Generate Astro Compatibility';
        break;
      case AstroCompatibilityButtonState.show:
        icon = Icons.auto_awesome;
        tooltip = 'Show Astro Compatibility';
        break;
      case AstroCompatibilityButtonState.hide:
        icon = Icons.auto_awesome;
        tooltip = 'Hide Astro Compatibility';
        break;
      case AstroCompatibilityButtonState.regenerate:
        icon = Icons.auto_awesome;
        tooltip = 'Regenerate Astro Compatibility';
        break;
    }

    return Container(
      margin: EdgeInsets.only(right: 8.w),
      child: GestureDetector(
        onTap: _toggleAstroVisibility,
        child: Container(
          width: 35.h,
          height: 35.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.isBffMatch
                  ? [
                      themeController.bffPrimaryColor,
                      themeController.bffSecondaryColor,
                    ]
                  : [
                      themeController.getAccentColor(),
                      themeController.getSecondaryColor(),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 18.sp,
          ),
        ),
      ),
    );
  }

  // Toggle astro compatibility visibility
  Future<void> _toggleAstroVisibility() async {
    print('DEBUG: Astro button clicked, current state: $_astroButtonState');
    
    // Check if other user has zodiac set
    if (otherUserZodiac == null || otherUserZodiac == 'unknown') {
      Get.snackbar(
        'Info',
        'This user hasn\'t set their zodiac sign yet',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }
    
    if (_astroButtonState == AstroCompatibilityButtonState.generate) {
      // Generate new insights
      print('DEBUG: Attempting to generate astro insights...');
      try {
        // Call the edge function to generate insights
        final response = await SupabaseService.client.functions.invoke(
          'generate-match-insights',
          body: {'match_id': widget.matchId},
        );
        print('DEBUG: Edge function response: $response');
        
        setState(() {
          _astroButtonState = AstroCompatibilityButtonState.show;
          astroVisible = true;
        });
      } catch (e) {
        print('DEBUG: Error generating astro insights: $e');
        Get.snackbar('Error', 'Failed to generate astro compatibility: $e');
      }
    } else if (_astroButtonState == AstroCompatibilityButtonState.show) {
      // Hide insights
      print('DEBUG: Hiding astro insights');
      setState(() {
        _astroButtonState = AstroCompatibilityButtonState.hide;
        astroVisible = false;
      });
    } else if (_astroButtonState == AstroCompatibilityButtonState.hide) {
      // Show insights again
      print('DEBUG: Showing astro insights');
      setState(() {
        _astroButtonState = AstroCompatibilityButtonState.show;
        astroVisible = true;
      });
    } else if (_astroButtonState == AstroCompatibilityButtonState.regenerate) {
      // Regenerate insights
      print('DEBUG: Regenerating astro insights');
      try {
        final response = await SupabaseService.client.functions.invoke(
          'generate-match-insights',
          body: {'match_id': widget.matchId},
        );
        print('DEBUG: Regenerate response: $response');
        
        setState(() {
          _astroButtonState = AstroCompatibilityButtonState.show;
          astroVisible = true;
        });
      } catch (e) {
        print('DEBUG: Error regenerating astro insights: $e');
        Get.snackbar('Error', 'Failed to regenerate astro compatibility: $e');
      }
    }
  }

  // Load match enhancements status
  Future<void> _loadMatchEnhancementsStatus() async {
    try {
      final existing = await SupabaseService.client
          .from('match_enhancements')
          .select('*')
          .eq('match_id', widget.matchId)
          .single();

      if (existing != null) {
        final now = DateTime.now();
        final expiresAt = DateTime.parse(existing['expires_at']);
        
        if (now.isBefore(expiresAt)) {
          // Valid insights exist - start hidden, first click will show
          setState(() {
            _astroButtonState = AstroCompatibilityButtonState.hide;
            astroVisible = false; // Start hidden
          });
        } else {
          // Insights expired
          setState(() {
            _astroButtonState = AstroCompatibilityButtonState.regenerate;
            astroVisible = false;
          });
        }
      } else {
        // No insights exist
        setState(() {
          _astroButtonState = AstroCompatibilityButtonState.generate;
          astroVisible = false;
        });
      }
    } catch (e) {
      // No insights exist
      setState(() {
        _astroButtonState = AstroCompatibilityButtonState.generate;
        astroVisible = false;
      });
    }
  }

  // Get the other user's ID from the match
  Future<String?> _getOtherUserId() async {
    try {
      // Get the match details to find the other user's ID
      final match = await SupabaseService.getMatchById(widget.matchId);
      if (match != null) {
        final currentUserId = SupabaseService.currentUser?.id;
        final userId1 = match['user_id_1']?.toString();
        final userId2 = match['user_id_2']?.toString();
        
        // Find the other user's ID (not the current user)
        if (userId1 == currentUserId) {
          return userId2;
        } else if (userId2 == currentUserId) {
          return userId1;
        }
      }
      return null;
    } catch (e) {
      print('Error getting other user ID: $e');
      return null;
    }
  }

  Future<void> _startVideoCall() async {
    try {
      final otherUserId = await _getOtherUserId();
      if (otherUserId == null) {
        Get.snackbar('Error', 'Could not find user to call');
        return;
      }

      // Get other user's profile for call details
      final otherUserProfile = await SupabaseService.getProfile(otherUserId);
      if (otherUserProfile == null) {
        Get.snackbar('Error', 'Could not load user profile');
        return;
      }

      // Get other user's FCM token (you might need to store this in profiles)
      final fcmToken = otherUserProfile['fcm_token'] ?? '';

      // Initialize call controller
      final callController = Get.put(CallController());

      // Start video call
      await callController.initiateCall(
        matchId: widget.matchId,
        receiverId: otherUserId,
        receiverName: otherUserProfile['name'] ?? 'Unknown',
        receiverImage: otherUserProfile['image_urls']?[0] ?? '',
        receiverFcmToken: fcmToken,
        callType: CallType.video,
        isBffMatch: widget.isBffMatch,
      );

    } catch (e) {
      print('Error starting video call: $e');
      Get.snackbar('Error', 'Failed to start video call');
    }
  }

  Future<void> _startAudioCall() async {
    try {
      final otherUserId = await _getOtherUserId();
      if (otherUserId == null) {
        Get.snackbar('Error', 'Could not find user to call');
        return;
      }

      // Get other user's profile for call details
      final otherUserProfile = await SupabaseService.getProfile(otherUserId);
      if (otherUserProfile == null) {
        Get.snackbar('Error', 'Could not load user profile');
        return;
      }

      // Get other user's FCM token
      final fcmToken = otherUserProfile['fcm_token'] ?? '';

      // Initialize call controller
      final callController = Get.put(CallController());

      // Start audio call
      await callController.initiateCall(
        matchId: widget.matchId,
        receiverId: otherUserId,
        receiverName: otherUserProfile['name'] ?? 'Unknown',
        receiverImage: otherUserProfile['image_urls']?[0] ?? '',
        receiverFcmToken: fcmToken,
        callType: CallType.audio,
        isBffMatch: widget.isBffMatch,
      );

    } catch (e) {
      print('Error starting audio call: $e');
      Get.snackbar('Error', 'Failed to start audio call');
    }
  }

  // Audio recording methods
  Future<void> _startAudioRecording() async {
    try {
      _recordStartAt = DateTime.now();
      final ok = await AudioRecordingService.startRecording();
      if (!ok) {
        print('🎤 DEBUG: Audio recording failed - checking permission status...');
        final status = await Permission.microphone.status;
        print('🎤 DEBUG: Current microphone permission status: $status');
        Get.snackbar('Microphone', 'Microphone permission required. Status: $status');
        return;
      }
      setState(() {
        _isRecordingAudio = true;
      });
    } catch (e) {
      print('❌ Error starting audio recording: $e');
      Get.snackbar('Error', 'Failed to start audio recording');
    }
  }

  // New: press-and-hold handlers
  void _handleMicLongPressStart(LongPressStartDetails details) async {
    try {
      _recordStartAt = DateTime.now();
      final ok = await AudioRecordingService.startRecording();
      if (!ok) {
        print('🎤 DEBUG: Long press audio recording failed - checking permission status...');
        final status = await Permission.microphone.status;
        print('🎤 DEBUG: Current microphone permission status: $status');
        Get.snackbar('Microphone', 'Microphone permission required. Status: $status');
        return;
      }
    } catch (e) {
      print('❌ Error starting long-press recording: $e');
    }
  }

  void _handleMicLongPressEnd(LongPressEndDetails details) async {
    await _stopAudioRecordingAndPreparePending();
  }

  Future<void> _stopAudioRecordingAndPreparePending() async {
    try {
      final path = await AudioRecordingService.stopRecording();
      if (path == null) return;
      final started = _recordStartAt ?? DateTime.now();
      final durationSec = DateTime.now().difference(started).inSeconds.clamp(0, 24 * 60 * 60);
      final fileSize = await AudioRecordingService.getAudioFileSize(path);
      setState(() {
        _pendingAudioPath = path;
        _pendingAudioDurationSec = durationSec;
        _pendingAudioFileSize = fileSize;
        _recordStartAt = null;
        _isRecordingAudio = false;
      });
    } catch (e) {
      print('❌ Error finishing recording: $e');
      setState(() {
        _isRecordingAudio = false;
        _recordStartAt = null;
      });
    }
  }

  // Pending audio confirmation bar
  Widget _buildPendingAudioBar() {
    final durationLabel = AudioRecordingService.formatDuration(Duration(seconds: _pendingAudioDurationSec));
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: themeController.whiteColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: themeController.whiteColor.withOpacity(0.12), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.mic, color: themeController.getAccentColor(), size: 18.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: TextConstant(
              title: 'Voice message • $durationLabel',
              color: themeController.whiteColor,
              fontSize: 14,
            ),
          ),
          // Cancel (X)
          GestureDetector(
            onTap: _clearPendingAudio,
            child: Container(
              width: 34.w,
              height: 34.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.1),
                border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
              ),
              child: Icon(Icons.close, color: Colors.red, size: 18.sp),
            ),
          ),
          SizedBox(width: 8.w),
          // Send
          GestureDetector(
            onTap: _confirmSendPendingAudio,
            child: Container(
              width: 34.w,
              height: 34.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: widget.isBffMatch
                      ? [themeController.bffPrimaryColor, themeController.bffSecondaryColor]
                      : [themeController.getAccentColor(), themeController.getSecondaryColor()],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(LucideIcons.send, color: Colors.white, size: 18.sp),
            ),
          ),
        ],
      ),
    );
  }

  void _clearPendingAudio() {
    setState(() {
      _pendingAudioPath = null;
      _pendingAudioDurationSec = 0;
      _pendingAudioFileSize = 0;
      _recordStartAt = null;
    });
  }

  void _confirmSendPendingAudio() {
    final path = _pendingAudioPath;
    if (path == null) return;
    final duration = _pendingAudioDurationSec;
    final size = _pendingAudioFileSize;
    _sendAudioMessage(path, duration, size);
    _clearPendingAudio();
  }

  Future<void> _sendAudioMessage(String audioPath, int duration, int fileSize) async {
    try {
      final controller = Get.find<MessageController>(tag: 'msg_${widget.matchId}');
      if (!await controller.ensureMessagingAllowed()) {
        return;
      }
      // Upload audio file to Supabase Storage
      final audioUrl = await _uploadAudioFile(audioPath);
      if (audioUrl == null) {
        Get.snackbar('Error', 'Failed to upload audio message');
        return;
      }

      // Create audio message with UTC time (like text messages)
      final audioMessage = AudioMessage(
        id: const Uuid().v4(), // Generate proper UUID
        matchId: widget.matchId,
        senderId: SupabaseService.currentUser?.id ?? '',
        audioUrl: audioUrl,
        duration: duration,
        fileSize: fileSize,
        // Use UTC like text messages - fromMap will convert to local for display
        createdAt: DateTime.now().toUtc(),
      );

      // Save to database
      await _saveAudioMessage(audioMessage);

      // Add to message list
      controller.addAudioMessage(audioMessage);

      setState(() {
        _isRecordingAudio = false;
      });

      Get.snackbar('Success', 'Audio message sent!');
    } catch (e) {
      print('❌ Error sending audio message: $e');
      Get.snackbar('Error', 'Failed to send audio message');
      setState(() {
        _isRecordingAudio = false;
      });
    }
  }

  Future<void> _cancelAudioRecording() async {
    setState(() {
      _isRecordingAudio = false;
    });
  }

  Future<String?> _uploadAudioFile(String filePath) async {
    try {
      final file = File(filePath);
      final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final userId = SupabaseService.currentUser?.id ?? '';
      
      // Upload to Supabase Storage
      final response = await SupabaseService.client.storage
          .from('chat-audio')
          .upload('$userId/$fileName', file);
      
      if (response.isNotEmpty) {
        // Get public URL
        final publicUrl = SupabaseService.client.storage
            .from('chat-audio')
            .getPublicUrl('$userId/$fileName');
        
        return publicUrl;
      }
      return null;
    } catch (e) {
      print('❌ Error uploading audio file: $e');
      return null;
    }
  }

  Future<void> _saveAudioMessage(AudioMessage audioMessage) async {
    try {
      await SupabaseService.client
          .from('audio_messages')
          .insert(audioMessage.toMap());
    } catch (e) {
      print('❌ Error saving audio message: $e');
      throw e;
    }
  }
}
