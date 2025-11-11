import 'dart:io';
import 'dart:ui';
import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/widget_constant.dart';
import 'package:lovebug/Constant/app_assets.dart';
import 'package:lovebug/Screens/ChatPage/controller_message_screen.dart';
import 'package:lovebug/Screens/ChatPage/ui_chatbubble_screen.dart';
import 'package:lovebug/Screens/DiscoverPage/profile_detail_screen.dart';
import 'package:lovebug/Screens/DiscoverPage/controller_discover_screen.dart';
import 'package:lovebug/Screens/ChatPage/disappearing_photo_screen.dart';
import 'package:lovebug/services/disappearing_photo_service.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/Screens/ChatPage/enhanced_photo_upload_service.dart';
import 'package:lovebug/Screens/ChatPage/ui_simple_camera_screen.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:lovebug/controllers/call_controller.dart';
import 'package:lovebug/models/call_models.dart';
import 'package:lovebug/widgets/premium_indicator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:lovebug/Widgets/upgrade_prompt_widget.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:typed_data';

class MessageScreen extends StatefulWidget {
  MessageScreen({
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
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> with WidgetsBindingObserver {
  final ThemeController themeController = Get.find<ThemeController>();
  String? currentUserImage;

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print('🔄 DEBUG: MessageScreen initState - loading current user profile');
    print('🔄 DEBUG: MessageScreen initState - widget.userImage: ${widget.userImage}');
    print('🔄 DEBUG: MessageScreen initState - widget.userName: ${widget.userName}');
    print('🔄 DEBUG: MessageScreen initState - widget.matchId: ${widget.matchId}');
    print('🔄 DEBUG: MessageScreen initState - widget.isBffMatch: ${widget.isBffMatch}');
    _loadCurrentUserProfile();
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
  void didUpdateWidget(MessageScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload profile when widget updates (e.g., user returned from profile edit)
    _loadCurrentUserProfile();
  }

  Future<void> _loadCurrentUserProfile() async {
    try {
      print('🔄 DEBUG: _loadCurrentUserProfile called in MessageScreen');
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
          });
        }
      }
    } catch (e) {
      print('❌ DEBUG: Error loading current user profile: $e');
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
                              title: 'select_photo_source',
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
                          title: 'take_photo',
                          subtitle: 'capture_new_photo',
                          onTap: () => Get.back(result: ImageSource.camera),
                        ),
                        
                        // Gallery Option
                        _buildPhotoSourceOption(
                          icon: Icons.photo_library,
                          title: 'choose_from_gallery',
                          subtitle: 'select_from_photos',
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
      
      // Now show options for how to send the photo using our custom dialog
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

  Future<void> _sendRegularPhotoWithBytes(MessageController controller, Uint8List imageBytes, String fileName) async {
    try {
      // Show instant preview message
      final previewMessageId = 'preview_${DateTime.now().millisecondsSinceEpoch}';
      final previewMessage = Message(
        text: '📸 Photo uploading...',
        isUser: true,
        timestamp: DateTime.now(),
      );
      
      // Add preview to messages list
      controller.messages.add(previewMessage);
      
      // Show loading indicator
      Get.snackbar('Uploading', 'Photo is being uploaded...', 
        duration: Duration(seconds: 2));
      
      // Upload to Supabase storage
      final photoUrl = await SupabaseService.uploadFile(
        bucket: 'chat-photos',
        path: '${DateTime.now().millisecondsSinceEpoch}_$fileName',
        fileBytes: imageBytes,
      );

      if (photoUrl.isNotEmpty) {
        // Remove preview message
        controller.messages.removeWhere((m) => m.text == '📸 Photo uploading...');
        
        // Send actual photo message
        await controller.sendMessage(widget.matchId, '📸 Photo: $photoUrl');
        Get.snackbar('Success', 'Photo sent!');
      } else {
        // Remove preview on failure
        controller.messages.removeWhere((m) => m.text == '📸 Photo uploading...');
        Get.snackbar('Error', 'Failed to upload photo');
      }
    } catch (e) {
      print('Error sending regular photo: $e');
      // Remove preview on error
      controller.messages.removeWhere((m) => m.text.contains('uploading...'));
      Get.snackbar('Error', 'Failed to send photo');
    }
  }

  Future<void> _sendDisappearingPhotoWithBytes(MessageController controller, Uint8List imageBytes, String fileName) async {
    try {
      // Show instant preview message
      final previewMessageId = 'preview_${DateTime.now().millisecondsSinceEpoch}';
      final previewMessage = Message(
        text: '📸 Disappearing photo uploading...',
        isUser: true,
        timestamp: DateTime.now(),
      );
      
      // Add preview to messages list
      controller.messages.add(previewMessage);
      
      // Show loading indicator
      Get.snackbar('Uploading', 'Disappearing photo is being uploaded...', 
        duration: Duration(seconds: 2));
      
      print('🔄 DEBUG: Starting disappearing photo flow');
      print('  - widget.matchId: $widget.matchId');
      print('  - fileName: $fileName');
      print('  - imageBytes length: ${imageBytes.length}');
      
      // Show duration selection dialog
      print('🔄 DEBUG: Showing duration dialog...');
      final duration = await _showDurationDialog();
      if (duration == null) {
        print('❌ DEBUG: User cancelled duration selection');
        return;
      }
      print('✅ DEBUG: Duration selected: $duration seconds');

      // Send disappearing photo
      print('🔄 DEBUG: Calling EnhancedDisappearingPhotoService...');
      final photoUrl = await EnhancedDisappearingPhotoService.sendDisappearingPhoto(
        matchId: widget.matchId,
        photoBytes: imageBytes,
        fileName: 'disappearing_${DateTime.now().millisecondsSinceEpoch}.jpg',
        viewDuration: duration,
      );

      if (photoUrl != null) {
        // Remove preview message
        controller.messages.removeWhere((m) => m.text == '📸 Disappearing photo uploading...');
        print('✅ DEBUG: Disappearing photo sent successfully: $photoUrl');
        Get.snackbar('Success', 'Disappearing photo sent!');
      } else {
        // Remove preview on failure
        controller.messages.removeWhere((m) => m.text == '📸 Disappearing photo uploading...');
        print('❌ DEBUG: Disappearing photo service returned null');
        Get.snackbar('Error', 'Failed to send disappearing photo');
      }
    } catch (e) {
      // Remove preview on error
      controller.messages.removeWhere((m) => m.text.contains('uploading...'));
      print('❌ DEBUG: Error in _sendDisappearingPhotoWithBytes: $e');
      print('❌ DEBUG: Error type: ${e.runtimeType}');
      Get.snackbar('Error', 'Failed to send disappearing photo: $e');
    }
  }

  Future<int?> _showDurationDialog() async {
    return await Get.dialog<int>(
      AlertDialog(
        backgroundColor: themeController.blackColor,
        title: TextConstant(
          title: 'Disappearing Photo',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: themeController.whiteColor,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextConstant(
              title: 'How long should this photo be visible?',
              fontSize: 14,
              color: themeController.whiteColor.withValues(alpha: 0.8),
            ),
            heightBox(20.h.toInt()),
            ...([5, 10, 30, 60].map((seconds) => 
              ListTile(
                title: TextConstant(
                  title: '${seconds} seconds',
                  fontSize: 16,
                  color: themeController.whiteColor,
                ),
                onTap: () => Get.back(result: seconds),
                tileColor: themeController.getAccentColor().withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: TextConstant(
              title: 'Cancel',
              fontSize: 14,
              color: themeController.whiteColor.withValues(alpha: 0.7),
            ),
          ),
        ],
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
            // Profile header row
            Container(
              width: Get.width,
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 15.w),
              color: themeController.transparentColor,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _viewProfile,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        ProfileAvatar(
                          imageUrl: widget.userImage ?? '',
                          size: 50,
                          borderWidth: 1.5.w,
                        ),
                        Container(
                          height: 12.h,
                          width: 12.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: themeController.greenColor,
                            border: Border.all(
                              color: themeController.primaryColor.value,
                              width: 1.w,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  widthBox(11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextConstant(
                          title: widget.userName ?? '',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: themeController.whiteColor,
                        ),
                        heightBox(3),
                        TextConstant(
                          title: 'Online',
                          fontSize: 13,
                          // If you do not have withValues, replace with withOpacity
                          color: themeController.greenColor,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              color: themeController.greyColor.withOpacity(0.2),
              thickness: 1.5.h,
            ),
            _buildFlameBanner(controller),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.w),
                child: Obx(() {
                  // Access selectedMessageKeys to make Obx reactive to selection changes
                  final _ = controller.selectedMessageKeys.length;
                  
                  if (controller.messages.isEmpty) {
                    return Center(
                      child: Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              themeController.getAccentColor().withOpacity(0.1),
                              themeController.purpleColor.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color:
                                themeController.getAccentColor().withOpacity(0.3),
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
                            ),
                            heightBox(10),
                            TextConstant(
                              title: 'Say something to start the conversation!',
                              softWrap: true,
                              fontSize: 14,
                              color: themeController.whiteColor
                                  .withOpacity(0.8),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final isSelectionMode = controller.isSelectionMode.value;

                  return ListView.builder(
                    controller: controller.scrollController,
                    itemCount: controller.messages.length,
                    itemBuilder: (context, index) {
                      final message = controller.messages[index];
                      print('🔄 DEBUG: Creating chat bubble - isUser: ${message.isUser}, currentUserImage: $currentUserImage, otherUserImage: ${widget.userImage}');
                      print('🔄 DEBUG: Will show ${message.isUser ? "current user" : "other user"} profile picture');
                      print('🔄 DEBUG: Passing userImage: $currentUserImage, otherUserImage: ${widget.userImage}');
                      print('🔄 DEBUG: currentUserImage length: ${currentUserImage?.length ?? 0}');
                      
                      // If currentUserImage is still null, try to reload it
                      if (currentUserImage == null && message.isUser) {
                        _loadCurrentUserProfile();
                      }
                      
                      final isSelectable = controller.isItemSelectable(message);
                      final isSelected = controller.isItemSelected(message);

                      return EnhancedChatBubble(
                        message: message,
                        userName: widget.userName ?? '',
                        isBffMatch: widget.isBffMatch,
                        userImage: currentUserImage,
                        otherUserImage: widget.userImage,
                        isSelectionMode: isSelectionMode,
                        isSelectable: isSelectable,
                        isSelected: isSelected,
                        onTap: controller.isSelectionMode.value && isSelectable
                            ? () => controller.toggleSelectionForItem(message)
                            : null,
                        onLongPress: isSelectable
                            ? () => controller.startSelectionForItem(message)
                            : null,
                      );
                    },
                  );
                }),
              ),
            ),
            // Input field
            _buildChatInputField(controller),
          ],
        ),
      ),
      ),
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextConstant(
                  title: widget.userName ?? '',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: themeController.whiteColor,
                ),
                SizedBox(width: 8.w),
                PremiumBadge(
                  size: 10.sp,
                  showText: false,
                ),
              ],
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
          InkWell(
            onTap: () => _showChatOptions(),
            child: SvgPicture.asset(
              AppAssets.menu,
              height: 35.h,
              width: 35.h,
              fit: BoxFit.cover,
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
            icon: Icon(
              canDeleteAll ? Icons.delete_forever : Icons.delete_outline,
            ),
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

  Widget _buildFlameBanner(MessageController controller) {
    return Obx(() {
      if (!controller.shouldShowFlameBanner) {
        return SizedBox.shrink();
      }

      final bool isActive = controller.isFlameActive.value;
      final bool isBff = controller.isBffMode;
      final bool shouldUpgrade = controller.shouldBlockPostFlameMessaging;

      final Color primaryColor = isBff
          ? themeController.bffPrimaryColor
          : themeController.getAccentColor();
      final Color secondaryColor = isBff
          ? themeController.bffSecondaryColor
          : themeController.getSecondaryColor();

      final LinearGradient gradient = LinearGradient(
        colors: [primaryColor, secondaryColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

      final IconData icon = isActive
          ? Icons.local_fire_department
          : (shouldUpgrade ? Icons.lock_clock : Icons.check_circle_outline);

      final String headline = isActive
          ? 'Fire Love Chat is live'
          : 'Fire Love Chat ended';

      final String detail = isActive
          ? '${controller.formattedFlameCountdown} remaining'
          : (shouldUpgrade
              ? 'Continue now to keep the conversation going.'
              : 'You can keep chatting without restrictions.');

      return Container(
        margin: EdgeInsets.fromLTRB(15.w, 12.h, 15.w, 8.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 22.sp,
                ),
                widthBox(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextConstant(
                        title: headline,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      SizedBox(height: 4.h),
                      TextConstant(
                        title: detail,
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                        softWrap: true,
                        maxLines: null,
                      ),
                      if (isActive)
                        Padding(
                          padding: EdgeInsets.only(top: 2.h),
                          child: TextConstant(
                            title: 'Unlimited messages while the timer runs.',
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
              SizedBox(height: 12.h),
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
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primary, secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_forward, color: Colors.white, size: 16.sp),
            SizedBox(width: 6.w),
            TextConstant(
              title: label,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
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
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ButtonSquare(
              height: 35,
              width: 35,
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
              iconSize: 16,
              icon: Icons.camera_alt_outlined,
              iconColor: themeController.whiteColor,
              borderColor: themeController.transparentColor,
              backgroundColor: themeController.getAccentColor(),
            ),
            widthBox(6),
            ButtonSquare(
              width: 35,
              height: 35,
              iconSize: 16,
              onTap: () {},
              icon: Icons.emoji_emotions_rounded,
              iconColor: themeController.whiteColor,
              borderColor: themeController.transparentColor,
              backgroundColor: themeController.getAccentColor(),
            ),
            widthBox(6),
            Expanded(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: 40.h,
                  maxHeight: 200.h,
                ),
                child: SingleChildScrollView(
                  reverse: true,
                  child: Obx(() {
                    final bool inputEnabled = controller.isFlameActive.value || !controller.shouldBlockPostFlameMessaging;
                    return TextField(
                      controller: controller.textController,
                      enabled: inputEnabled,
                      onChanged: (v) {},
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: themeController.whiteColor,
                      ),
                      maxLines: null,
                      minLines: 1,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (v) {
                        if (v.trim().isNotEmpty && !v.contains('\n')) {
                          controller.sendMessage(widget.matchId, v.trim());
                        }
                      },
                      decoration: InputDecoration(
                        filled: true,
                        hintText: inputEnabled
                            ? 'type_message'.tr
                            : 'Continue chat to keep messaging',
                        hintStyle: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: themeController.whiteColor.withOpacity(0.6),
                        ),
                        fillColor: themeController.blackColor.withOpacity(0.25),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 15.w,
                          vertical: 12.h,
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: themeController.getAccentColor()
                                .withOpacity(0.3),
                            width: 1.w,
                          ),
                          borderRadius: BorderRadius.circular(50.r),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: themeController.getAccentColor()
                                .withOpacity(0.3),
                            width: 1.w,
                          ),
                          borderRadius: BorderRadius.circular(50.r),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: themeController.getAccentColor(),
                            width: 1.5.w,
                          ),
                          borderRadius: BorderRadius.circular(50.r),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: themeController.getAccentColor()
                                .withOpacity(0.15),
                            width: 1.w,
                          ),
                          borderRadius: BorderRadius.circular(50.r),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            widthBox(6),
            ButtonSquare(
              onTap: () =>
                  controller.sendMessage(widget.matchId, controller.textController.text.trim()),
              height: 35,
              width: 35,
              icon: LucideIcons.send,
              backgroundColor: themeController.getAccentColor(),
              iconColor: themeController.whiteColor,
              borderColor: themeController.transparentColor,
              iconSize: 16,
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
                            Icons.more_vert,
                            color: themeController.getAccentColor(),
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
                    : themeController.getAccentColor().withValues(alpha: 0.1),
                width: 1.w,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isDestructive 
                      ? Colors.red
                      : themeController.getAccentColor(),
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
                color: themeController.getAccentColor().withValues(alpha: 0.1),
                width: 1.w,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: themeController.getAccentColor(),
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
                      onTap: () async {
                        Get.back();
                        await _clearChat();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.redAccent, Colors.pink]),
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
              ),
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
          await _justUnmatch();
        },
      ),
    );
  }

  Future<void> _clearChat() async {
    try {
      print('🔄 DEBUG: Starting to clear chat for match: $widget.matchId');
      
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
                  title: 'Clearing chat...',
                  color: themeController.whiteColor,
                  fontSize: 14,
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );
      
      // Clear chat approach: delete ALL messages for this match (true clear chat)
      print('🔄 DEBUG: Clearing all messages for this match...');
      final currentUserId = SupabaseService.currentUser?.id;
      if (currentUserId != null) {
        print('🔄 DEBUG: Current user ID: $currentUserId');
        print('🔄 DEBUG: Match ID: $widget.matchId');
        
        // Delete ALL messages for this match (both users' messages)
        print('🔄 DEBUG: Deleting all messages for this match...');
        try {
          final messagesResult = await SupabaseService.client
              .from('messages')
              .delete()
              .eq('match_id', widget.matchId);
          print('✅ DEBUG: All messages deleted: $messagesResult');
        } catch (e) {
          print('❌ DEBUG: Error deleting messages: $e');
        }
        
        // Delete ALL disappearing photos for this match
        print('🔄 DEBUG: Deleting all disappearing photos for this match...');
        try {
          final photosResult = await SupabaseService.client
              .from('disappearing_photos')
              .delete()
              .eq('match_id', widget.matchId);
          print('✅ DEBUG: All disappearing photos deleted: $photosResult');
        } catch (e) {
          print('❌ DEBUG: Error deleting disappearing photos: $e');
        }
      } else {
        print('❌ DEBUG: No current user ID found');
      }
      
      // Close loading dialog
      Get.back();
      
      // Wait a moment for database to process deletion
      await Future.delayed(Duration(milliseconds: 500));
      
      // Clear the messages from the controller to refresh UI
      try {
        final MessageController controller = Get.find<MessageController>(tag: 'msg_$widget.matchId');
        
        // Stop the real-time subscription temporarily to prevent refetching
        controller.dispose();
        
        // Clear messages
        controller.messages.clear();
        print('✅ DEBUG: Controller messages cleared');
        
        // Force refresh by reinitializing the controller
        await controller.ensureInitialized(widget.matchId, isBffMatch: widget.isBffMatch);
        print('✅ DEBUG: Controller reinitialized');
      } catch (e) {
        print('❌ DEBUG: Could not find controller: $e');
        // Try to create a new controller instance
        try {
          final newController = Get.put(MessageController(), tag: 'msg_${widget.matchId}');
          await newController.ensureInitialized(widget.matchId, isBffMatch: widget.isBffMatch);
          print('✅ DEBUG: New controller created and initialized');
        } catch (e2) {
          print('❌ DEBUG: Could not create new controller: $e2');
        }
      }
      
      print('✅ DEBUG: Chat cleared successfully');
      Get.snackbar(
        'Chat Cleared', 
        'Your chat history has been cleared',
        backgroundColor: themeController.blackColor,
        colorText: themeController.whiteColor,
        duration: Duration(seconds: 2),
      );
    } catch (e) {
      print('❌ DEBUG: Error clearing chat: $e');
      Get.back(); // Close loading dialog
      Get.snackbar(
        'Error', 
        'Failed to clear chat: $e',
        backgroundColor: themeController.blackColor,
        colorText: themeController.whiteColor,
        duration: Duration(seconds: 3),
      );
    }
  }

  Future<void> _justUnmatch() async {
    try {
      print('🔄 DEBUG: Starting to unmatch user for match: $widget.matchId');
      
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
                  fontSize: 14,
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );
      
      // Update match status to unmatched
      await SupabaseService.client
          .from('matches')
          .update({'status': 'unmatched'})
          .eq('id', widget.matchId);
      
      // Close loading dialog
      Get.back();
      
      print('✅ DEBUG: User unmatched successfully');
      Get.snackbar(
        'Unmatched', 
        'You have unmatched with this user',
        backgroundColor: themeController.blackColor,
        colorText: themeController.whiteColor,
        duration: Duration(seconds: 2),
      );
      
      // Navigate back to chat list
      Get.back();
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

  Future<void> _reportUser() async {
    try {
      print('🔄 DEBUG: Starting to report user for match: $widget.matchId');
      
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
                  title: 'Reporting user...',
                  color: themeController.whiteColor,
                  fontSize: 14,
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );
      
      // Get the other user's ID
      final otherUserId = await _getOtherUserId();
      if (otherUserId == null) {
        Get.back(); // Close loading dialog
        Get.snackbar('Error', 'Could not find user to report');
        return;
      }
      
      // Create a report record
      await SupabaseService.client
          .from('reports')
          .insert({
            'reporter_id': SupabaseService.currentUser?.id,
            'reported_id': otherUserId,
            'reason': 'Inappropriate behavior',
            'description': 'User reported from chat',
            'status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
          });
      
      // Also unmatch the user
      await SupabaseService.client
          .from('matches')
          .update({'status': 'unmatched'})
          .eq('id', widget.matchId);
      
      // Close loading dialog
      Get.back();
      
      print('✅ DEBUG: User reported successfully');
      Get.snackbar(
        'User Reported', 
        'User has been reported and unmatched',
        backgroundColor: themeController.blackColor,
        colorText: themeController.whiteColor,
        duration: Duration(seconds: 2),
      );
      
      // Navigate back to chat list
      Get.back();
    } catch (e) {
      print('❌ DEBUG: Error reporting user: $e');
      Get.back(); // Close loading dialog
      Get.snackbar(
        'Error', 
        'Failed to report user: $e',
        backgroundColor: themeController.blackColor,
        colorText: themeController.whiteColor,
        duration: Duration(seconds: 3),
      );
    }
  }

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

}