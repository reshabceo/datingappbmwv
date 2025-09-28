import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/widget_constant.dart';
import 'package:lovebug/Constant/app_assets.dart';
import 'package:lovebug/Screens/ChatPage/controller_message_screen.dart';
import 'package:lovebug/Screens/ChatPage/ui_chatbubble_screen.dart';
import 'package:lovebug/Screens/DiscoverPage/profile_detail_screen.dart';
import 'package:lovebug/Screens/DiscoverPage/controller_discover_screen.dart';
import 'package:lovebug/Screens/ChatPage/disappearing_photo_screen.dart';
import 'package:lovebug/Screens/ChatPage/astro_compatibility_widget.dart';
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

class EnhancedMessageScreen extends StatefulWidget {
  EnhancedMessageScreen({
    super.key,
    required this.userImage,
    required this.userName,
    required this.matchId,
  });

  final String? userImage;
  final String? userName;
  final String matchId;

  @override
  State<EnhancedMessageScreen> createState() => _EnhancedMessageScreenState();
}

class _EnhancedMessageScreenState extends State<EnhancedMessageScreen> {
  final ThemeController themeController = Get.find<ThemeController>();
  String? otherUserZodiac;
  bool isLoadingZodiac = true;

  @override
  void initState() {
    super.initState();
    _loadOtherUserZodiac();
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
        final photoUrl = await DisappearingPhotoService.sendDisappearingPhoto(
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
      final source = await Get.dialog<ImageSource>(
        AlertDialog(
          backgroundColor: themeController.blackColor,
          title: TextConstant(
            title: 'Select Photo Source',
            color: themeController.whiteColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: themeController.primaryColor.value),
                title: TextConstant(
                  title: 'Camera',
                  color: themeController.whiteColor,
                ),
                onTap: () => Get.back(result: ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: themeController.primaryColor.value),
                title: TextConstant(
                  title: 'Gallery',
                  color: themeController.whiteColor,
                ),
                onTap: () => Get.back(result: ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      // Pick image
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (image != null) {
        // Read image bytes
        final Uint8List imageBytes = await image.readAsBytes();
        
        // Send regular photo
        final photoUrl = await SupabaseService.uploadFile(
          bucket: 'profile-photos',
          path: 'chat_${DateTime.now().millisecondsSinceEpoch}.jpg',
          fileBytes: imageBytes,
        );

        if (photoUrl != null) {
          await SupabaseService.sendMessage(
            matchId: widget.matchId,
            content: photoUrl,
          );
        } else {
          Get.snackbar('Error', 'Failed to upload photo');
        }
      }
    } catch (e) {
      print('Error showing photo options: $e');
      Get.snackbar('Error', 'Failed to access photos');
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
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: themeController.blackColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.person, color: themeController.primaryColor.value),
              title: TextConstant(
                title: 'View Profile',
                color: themeController.whiteColor,
              ),
              onTap: () {
                Get.back();
                _viewProfile();
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_camera, color: themeController.primaryColor.value),
              title: TextConstant(
                title: 'Send Disappearing Photo',
                color: themeController.whiteColor,
              ),
              onTap: () {
                Get.back();
                final controller = Get.find<MessageController>(tag: 'msg_${widget.matchId}');
                _sendDisappearingPhoto(controller);
              },
            ),
            ListTile(
              leading: Icon(Icons.block, color: Colors.red),
              title: TextConstant(
                title: 'Block User',
                color: Colors.red,
              ),
              onTap: () {
                Get.back();
                // TODO: Implement block functionality
                Get.snackbar('Info', 'Block functionality coming soon');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MessageController controller =
        Get.put(MessageController(), tag: 'msg_${widget.matchId}')
          ..ensureInitialized(widget.matchId);

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
                  widthBox(12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextConstant(
                        title: widget.userName ?? '',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: themeController.whiteColor,
                      ),
                      if (!isLoadingZodiac && otherUserZodiac != null && otherUserZodiac != 'unknown')
                        Row(
                          children: [
                            Text(
                              AstroService.getZodiacEmoji(otherUserZodiac!),
                              style: TextStyle(fontSize: 16.sp),
                            ),
                            widthBox(4),
                            TextConstant(
                              title: otherUserZodiac!.toUpperCase(),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: themeController.primaryColor.value,
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Astrological Compatibility Widget
            if (!isLoadingZodiac && otherUserZodiac != null && otherUserZodiac != 'unknown')
              AstroCompatibilityWidget(
                matchId: widget.matchId,
                otherUserName: widget.userName ?? '',
                otherUserZodiac: otherUserZodiac!,
              ),
            
            // Messages area
            Expanded(
              child: Obx(() {
                if (controller.messages.isEmpty) {
                  return Center(
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

                return ListView.builder(
                  controller: controller.scrollController,
                  itemCount: controller.messages.length,
                  itemBuilder: (context, index) {
                    final message = controller.messages[index];
                    return ChatBubble(
                      message: message,
                      userImage: widget.userImage ?? '',
                      userName: widget.userName ?? '',
                      matchId: widget.matchId,
                    );
                  },
                );
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
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ButtonSquare(
              height: 35,
              width: 35,
              onTap: () => _showPhotoOptions(controller),
              iconSize: 16,
              icon: LucideIcons.paperclip,
              iconColor: themeController.whiteColor,
              borderColor: themeController.transparentColor,
              backgroundColor: themeController.lightPinkColor,
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
              backgroundColor: themeController.lightPinkColor,
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
                        color: themeController.primaryColor.value,
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
            ButtonSquare(
              height: 40,
              width: 40,
              onTap: () {
                if (controller.textController.text.trim().isNotEmpty) {
                  controller.sendMessage(
                    widget.matchId, 
                    controller.textController.text.trim()
                  );
                }
              },
              iconSize: 18,
              icon: LucideIcons.send,
              iconColor: themeController.whiteColor,
              borderColor: themeController.transparentColor,
              backgroundColor: themeController.primaryColor.value,
            ),
          ],
        ),
      ),
    );
  }
}
