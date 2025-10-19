import 'dart:ui';
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
import 'package:lovebug/Screens/ChatPage/enhanced_photo_upload_service.dart';
import 'package:lovebug/services/disappearing_photo_service.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:lovebug/services/astro_service.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:typed_data';

// Astro compatibility button states
enum AstroCompatibilityButtonState { generate, show, hide, regenerate }

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

class _EnhancedMessageScreenState extends State<EnhancedMessageScreen> {
  final ThemeController themeController = Get.find<ThemeController>();
  String? otherUserZodiac;
  bool isLoadingZodiac = true;
  bool astroVisible = false;
  String? currentUserImage;
  
  // Astro compatibility button state
  AstroCompatibilityButtonState _astroButtonState = AstroCompatibilityButtonState.generate;

  @override
  void initState() {
    super.initState();
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload profile when dependencies change
    if (currentUserImage == null) {
      _loadCurrentUserProfile();
    }
  }

  Future<void> _loadCurrentUserProfile() async {
    try {
      print('🔄 DEBUG: _loadCurrentUserProfile called in EnhancedMessageScreen');
      final currentUser = SupabaseService.currentUser;
      print('🔄 DEBUG: Loading current user profile for: ${currentUser?.id}');
      if (currentUser != null) {
        final profile = await SupabaseService.getProfile(currentUser.id);
        print('🔄 DEBUG: Profile loaded: $profile');
        if (profile != null && mounted) {
          setState(() {
            // Get the first photo from the user's profile
            final photos = <String>[];
            if (profile['photos'] != null) {
              photos.addAll(List<String>.from(profile['photos']));
            }
            if (profile['image_urls'] != null) {
              photos.addAll(List<String>.from(profile['image_urls']));
            }
            print('🔄 DEBUG: Found photos: $photos');
            currentUserImage = photos.isNotEmpty ? photos.first : null;
            print('🔄 DEBUG: Set currentUserImage to: $currentUserImage');
            print('🔄 DEBUG: currentUserImage length: ${currentUserImage?.length ?? 0}');
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

  Profile _mapToProfile(Map<String, dynamic> profileData) {
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
            final profile = _mapToProfile(profileData);
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

  void _showClearChatDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: themeController.blackColor,
        title: TextConstant(
          title: 'Clear Chat',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: themeController.whiteColor,
        ),
        content: TextConstant(
          title: 'Are you sure you want to clear all messages in this chat? This action cannot be undone.',
          fontSize: 14,
          color: themeController.whiteColor.withValues(alpha: 0.8),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: TextConstant(
              title: 'Cancel',
              color: themeController.whiteColor.withValues(alpha: 0.7),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.snackbar('Success', 'Chat cleared successfully');
            },
            child: TextConstant(
              title: 'Clear',
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  void _showUnmatchUserDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: themeController.blackColor,
        title: TextConstant(
          title: 'Unmatch User',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: themeController.whiteColor,
        ),
        content: TextConstant(
          title: 'Are you sure you want to unmatch with this user? You will no longer be able to message each other.',
          fontSize: 14,
          color: themeController.whiteColor.withValues(alpha: 0.8),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: TextConstant(
              title: 'Cancel',
              color: themeController.whiteColor.withValues(alpha: 0.7),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.snackbar('Success', 'User unmatched successfully');
            },
            child: TextConstant(
              title: 'Unmatch',
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
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

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
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
              // Astro Compatibility Button
              if (!isLoadingZodiac && otherUserZodiac != null && otherUserZodiac != 'unknown')
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
        ),
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
            
            // Astrological Compatibility Widget
            if (!isLoadingZodiac && otherUserZodiac != null && otherUserZodiac != 'unknown')
              AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                child: astroVisible
                    ? AstroCompatibilityWidget(
                        key: ValueKey('astro_visible'),
                        matchId: widget.matchId,
                        otherUserName: widget.userName ?? '',
                        otherUserZodiac: otherUserZodiac!,
                        visible: true,
                        autoGenerateIfMissing: false,
                      )
                    : SizedBox.shrink(key: ValueKey('astro_hidden')),
              ),
            
            // Messages area
            Expanded(
              child: Obx(() {
                if (controller.messages.isEmpty) {
                  return Column(
                    children: [
                      Expanded(
                        child: Center(
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
                      ),
                      // Ice Breaker Widget (below the Hey box)
                      IceBreakerWidget(
                        matchId: widget.matchId,
                        otherUserName: widget.userName ?? '',
                      ),
                    ],
                  );
            } else {
              return Column(
                children: [
                  // Ice Breaker Widget (below the Hey box)
                  IceBreakerWidget(
                    matchId: widget.matchId,
                    otherUserName: widget.userName ?? '',
                  ),
                  // Messages list
                  Expanded(
                    child: ListView.builder(
                      controller: controller.scrollController,
                      itemCount: controller.messages.length,
                      itemBuilder: (context, index) {
                        final message = controller.messages[index];
                            return EnhancedChatBubble(
                          message: message,
                          userName: widget.userName ?? '',
                          isBffMatch: widget.isBffMatch,
                          userImage: currentUserImage,
                          otherUserImage: widget.userImage,
                        );
                      },
                    ),
                  ),
                ],
              );
            }
              }),
            ),
            
            // Input field
            _buildChatInputField(controller),
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
              onTap: () => _showPhotoOptions(controller),
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
                  LucideIcons.paperclip,
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
                child: TextField(
                  controller: controller.textController,
                  maxLines: null,
                  style: TextStyle(
                    color: themeController.whiteColor,
                    fontSize: 14.sp,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
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
              colors: [Colors.purple[800]!, Colors.pink[800]!],
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
          // Valid insights exist
          setState(() {
            _astroButtonState = AstroCompatibilityButtonState.show;
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
}
