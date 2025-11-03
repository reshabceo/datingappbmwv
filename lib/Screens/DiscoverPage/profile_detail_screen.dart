import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/widget_constant.dart';
import 'package:lovebug/Screens/ChatPage/chat_integration_helper.dart';
import 'package:lovebug/Screens/DiscoverPage/controller_discover_screen.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/Widgets/upgrade_prompt_widget.dart';
import 'package:lovebug/controllers/call_controller.dart';
import 'package:lovebug/models/call_models.dart';
import 'package:lovebug/services/supabase_service.dart';

class ProfileDetailScreen extends StatefulWidget {
  final Profile profile;
  final bool isMatched;

  const ProfileDetailScreen({
    super.key,
    required this.profile,
    this.isMatched = false,
  });

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  int _currentImageIndex = 0;
  String? _resolvedMatchId;
  bool _isBffMatch = false;
  bool _isLoadingMatchContext = false;

  @override
  void initState() {
    super.initState();
    _resolvedMatchId = widget.profile.matchId;
    _initializeMatchContext();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _initializeMatchContext() {
    if (!widget.isMatched) return;
    if (_resolvedMatchId != null) {
      _determineMatchTypeForResolvedId(_resolvedMatchId!);
    } else {
      _fetchAndStoreMatchContext();
    }
  }

  Future<void> _determineMatchTypeForResolvedId(String matchId) async {
    try {
      final existing = await SupabaseService.client
          .from('bff_matches')
          .select('id')
          .eq('id', matchId)
          .maybeSingle();
      if (!mounted) return;
      setState(() {
        _isBffMatch = existing != null;
      });
    } catch (e) {
      print('Error determining match type: $e');
    }
  }

  Future<_MatchContext?> _queryMatchContext() async {
    try {
      final currentUserId = SupabaseService.currentUser?.id;
      if (currentUserId == null || widget.profile.id.isEmpty) return null;

      final otherUserId = widget.profile.id;

      final matchesResponse = await SupabaseService.client
          .from('matches')
          .select('id,user_id_1,user_id_2,status')
          .or('user_id_1.eq.$currentUserId,user_id_2.eq.$currentUserId')
          .neq('status', 'unmatched');

      if (matchesResponse is List) {
        for (final row in matchesResponse) {
          final user1 = row['user_id_1']?.toString();
          final user2 = row['user_id_2']?.toString();
          if ((user1 == currentUserId && user2 == otherUserId) ||
              (user2 == currentUserId && user1 == otherUserId)) {
            return _MatchContext(matchId: row['id'].toString(), isBff: false);
          }
        }
      }

      final bffResponse = await SupabaseService.client
          .from('bff_matches')
          .select('id,user_id_1,user_id_2,status')
          .or('user_id_1.eq.$currentUserId,user_id_2.eq.$currentUserId')
          .neq('status', 'unmatched');

      if (bffResponse is List) {
        for (final row in bffResponse) {
          final user1 = row['user_id_1']?.toString();
          final user2 = row['user_id_2']?.toString();
          if ((user1 == currentUserId && user2 == otherUserId) ||
              (user2 == currentUserId && user1 == otherUserId)) {
            return _MatchContext(matchId: row['id'].toString(), isBff: true);
          }
        }
      }
    } catch (e) {
      print('Error querying match context: $e');
    }
    return null;
  }

  Future<void> _fetchAndStoreMatchContext() async {
    if (_isLoadingMatchContext) return;
    setState(() {
      _isLoadingMatchContext = true;
    });
    try {
      final context = await _queryMatchContext();
      if (!mounted) return;
      setState(() {
        _resolvedMatchId = context?.matchId;
        _isBffMatch = context?.isBff ?? false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMatchContext = false;
        });
      }
    }
  }

  Future<bool> _ensureMatchContext() async {
    if (!widget.isMatched) {
      _showNotMatchedSnack();
      return false;
    }
    if (_resolvedMatchId != null) return true;
    await _fetchAndStoreMatchContext();
    if (_resolvedMatchId == null) {
      final themeController = Get.find<ThemeController>();
      Get.snackbar(
        'Match Not Found',
        'Could not locate an active chat for this profile',
        backgroundColor: themeController.blackColor,
        colorText: themeController.whiteColor,
      );
      return false;
    }
    return true;
  }

  Future<void> _onMessageTap() async {
    if (!await _ensureMatchContext()) return;
    ChatIntegrationHelper.navigateToChat(
      userImage: widget.profile.imageUrl,
      userName: widget.profile.name,
      matchId: _resolvedMatchId!,
    );
  }

  Future<void> _onVideoCallTap() async {
    if (!await _ensureMatchContext()) return;
    final isPremium = await SupabaseService.isPremiumUser();
    if (!isPremium) {
      _showUpgradePrompt('Video call is a premium feature. Upgrade to unlock it.');
      return;
    }
    await _startVideoCallInternal();
  }

  Future<void> _onAudioCallTap() async {
    if (!await _ensureMatchContext()) return;
    final isPremium = await SupabaseService.isPremiumUser();
    if (!isPremium) {
      _showUpgradePrompt('Audio call is a premium feature. Upgrade to unlock it.');
      return;
    }
    await _startAudioCallInternal();
  }

  void _showUpgradePrompt(String message) {
    final themeController = Get.find<ThemeController>();
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: UpgradePromptWidget(
          title: 'premium_feature'.tr,
          message: message,
          action: 'Upgrade Now',
          limitType: 'message',
        ),
      ),
      barrierDismissible: true,
    );
  }

  void _showNotMatchedSnack() {
    final themeController = Get.find<ThemeController>();
    Get.snackbar(
      'Match Required',
      'You need to match with this user to open chat or call options.',
      backgroundColor: themeController.blackColor,
      colorText: themeController.whiteColor,
    );
  }

  Future<Map<String, dynamic>?> _getOtherUserProfile() async {
    try {
      return await SupabaseService.getProfile(widget.profile.id);
    } catch (e) {
      print('Error loading other user profile: $e');
      return null;
    }
  }

  String _extractPrimaryImage(Map<String, dynamic> profileData) {
    final images = <String>[];
    if (profileData['image_urls'] is List) {
      images.addAll(List<String>.from(profileData['image_urls']));
    }
    if (profileData['photos'] is List) {
      images.addAll(List<String>.from(profileData['photos']));
    }
    if (images.isNotEmpty) {
      return images.first;
    }
    return widget.profile.imageUrl;
  }

  Future<void> _startVideoCallInternal() async {
    try {
      final otherUserProfile = await _getOtherUserProfile();
      if (otherUserProfile == null) {
        Get.snackbar('Error', 'Could not load user profile');
        return;
      }

      final callController = Get.isRegistered<CallController>()
          ? Get.find<CallController>()
          : Get.put(CallController());

      await callController.initiateCall(
        matchId: _resolvedMatchId!,
        receiverId: widget.profile.id,
        receiverName: otherUserProfile['name']?.toString() ?? widget.profile.name,
        receiverImage: _extractPrimaryImage(otherUserProfile),
        receiverFcmToken: otherUserProfile['fcm_token']?.toString() ?? '',
        callType: CallType.video,
        isBffMatch: _isBffMatch,
      );
    } catch (e) {
      print('Error starting video call from profile: $e');
      Get.snackbar('Error', 'Failed to start video call');
    }
  }

  Future<void> _startAudioCallInternal() async {
    try {
      final otherUserProfile = await _getOtherUserProfile();
      if (otherUserProfile == null) {
        Get.snackbar('Error', 'Could not load user profile');
        return;
      }

      final callController = Get.isRegistered<CallController>()
          ? Get.find<CallController>()
          : Get.put(CallController());

      await callController.initiateCall(
        matchId: _resolvedMatchId!,
        receiverId: widget.profile.id,
        receiverName: otherUserProfile['name']?.toString() ?? widget.profile.name,
        receiverImage: _extractPrimaryImage(otherUserProfile),
        receiverFcmToken: otherUserProfile['fcm_token']?.toString() ?? '',
        callType: CallType.audio,
        isBffMatch: _isBffMatch,
      );
    } catch (e) {
      print('Error starting audio call from profile: $e');
      Get.snackbar('Error', 'Failed to start audio call');
    }
  }

  void _onAppBarMenuTap() {
    if (!widget.isMatched) {
      _showNotMatchedSnack();
      return;
    }
    _showProfileOptions();
  }

  void _showProfileOptions() {
    final themeController = Get.find<ThemeController>();
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
                      Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: themeController.whiteColor.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                      heightBox(20.h.toInt()),
                      Row(
                        children: [
                          Icon(
                            Icons.more_vert,
                            color: themeController.getAccentColor(),
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          TextConstant(
                            title: 'chat_options',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: themeController.whiteColor,
                          ),
                        ],
                      ),
                      heightBox(20.h.toInt()),
                      _buildSheetMenuOption(
                        themeController,
                        icon: Icons.message,
                        title: 'open_chat',
                        onTap: () async {
                          Get.back();
                          await _onMessageTap();
                        },
                      ),
                      _buildSheetMenuOption(
                        themeController,
                        icon: Icons.videocam,
                        title: 'video_call',
                        onTap: () async {
                          Get.back();
                          await _onVideoCallTap();
                        },
                      ),
                      _buildSheetMenuOption(
                        themeController,
                        icon: Icons.call,
                        title: 'audio_call',
                        onTap: () async {
                          Get.back();
                          await _onAudioCallTap();
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

  Widget _buildSheetMenuOption(
    ThemeController themeController, {
    required IconData icon,
    required String title,
    required Future<void> Function() onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            onTap();
          },
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
                  child: TextConstant(
                    title: title,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: themeController.whiteColor,
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
    final ThemeController themeController = Get.find<ThemeController>();
    final images = _getImages();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Container(
        width: double.infinity,
        height: double.infinity,
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
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                _buildCustomAppBar(themeController),
              
              // Main Content with Single Scroll
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Image Gallery
                      _buildImageGallery(themeController, images),
                      
                      // Profile Content
                      _buildProfileContent(themeController),
                      
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildCustomAppBar(ThemeController themeController) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 40.h,
              height: 40.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple[800]!, Colors.pink[800]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
          ),
          Spacer(),
          GestureDetector(
            onTap: _onAppBarMenuTap,
            child: Container(
              width: 40.h,
              height: 40.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple[800]!, Colors.pink[800]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.more_vert,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(ThemeController themeController) {
    print('🔍 Building profile content for: ${widget.profile.name}');
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: 200.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Profile Info Section
          _buildProfileInfo(themeController),
          
          // Bio Section
          _buildBioSection(themeController),
          
          // Interests Section
          _buildInterestsSection(themeController),
          
          // Action Buttons (only show for non-matched profiles)
          _buildActionButtons(themeController),
          
          // Bottom padding for safe area
          SizedBox(height: 40.h),
        ],
      ),
    );
  }



  Widget _buildImageGallery(ThemeController themeController, List<String> images) {
    return Container(
      height: Get.height * 0.6, // 60% of screen height
      width: double.infinity,
      child: Stack(
        children: [
          // Main Image with swipe functionality
          if (images.isNotEmpty)
            GestureDetector(
              onPanUpdate: (details) {
                // Handle swipe gestures
                if (details.delta.dx > 10) {
                  // Swipe right - previous image
                  if (_currentImageIndex > 0) {
                    setState(() {
                      _currentImageIndex--;
                    });
                  }
                } else if (details.delta.dx < -10) {
                  // Swipe left - next image
                  if (_currentImageIndex < images.length - 1) {
                    setState(() {
                      _currentImageIndex++;
                    });
                  }
                }
              },
              child: Image.network(
                images[_currentImageIndex],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stack) {
                  return Container(
                    color: themeController.blackColor,
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: themeController.whiteColor.withValues(alpha: 0.6),
                        size: 48.sp,
                      ),
                    ),
                  );
                },
              ),
            )
          else
            Container(
              color: themeController.blackColor,
              child: Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: themeController.whiteColor.withValues(alpha: 0.6),
                  size: 48.sp,
                ),
              ),
            ),
        
          // Image indicators (only show if multiple images)
          if (images.length > 1)
            Positioned(
              bottom: 20.h,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (index) {
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    width: _currentImageIndex == index ? 24.w : 8.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: _currentImageIndex == index
                          ? themeController.lightPinkColor
                          : themeController.whiteColor.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  );
                }),
              ),
            ),
        
          // Photo counter (top right)
          if (images.length > 1)
            Positioned(
              top: 20.h,
              right: 20.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: themeController.blackColor.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: themeController.lightPinkColor.withValues(alpha: 0.5),
                    width: 1.w,
                  ),
                ),
                child: TextConstant(
                  title: '${_currentImageIndex + 1}/${images.length}',
                  fontSize: 12.sp,
                  color: themeController.whiteColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(ThemeController themeController) {
    return Container(
      margin: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name and Age
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                widget.profile.name,
                style: GoogleFonts.dancingScript(
                  fontSize: 34.sp,
                  fontWeight: FontWeight.w700,
                  color: themeController.whiteColor,
                  shadows: [
                    Shadow(color: themeController.lightPinkColor.withValues(alpha: 0.6), blurRadius: 20.r),
                    Shadow(color: themeController.lightPinkColor.withValues(alpha: 0.3), blurRadius: 40.r),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                '${widget.profile.age}',
                style: GoogleFonts.dancingScript(
                  fontSize: 34.sp,
                  fontWeight: FontWeight.w700,
                  color: themeController.lightPinkColor,
                  shadows: [
                    Shadow(color: themeController.lightPinkColor.withValues(alpha: 0.6), blurRadius: 20.r),
                    Shadow(color: themeController.lightPinkColor.withValues(alpha: 0.3), blurRadius: 40.r),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 10.h),
          
          // Location and Distance
          Wrap(
            children: [
              Icon(
                Icons.location_on,
                color: themeController.lightPinkColor,
                size: 18.sp,
              ),
              SizedBox(width: 5.w),
              TextConstant(
                title: widget.profile.location,
                fontSize: 16.sp,
                color: themeController.whiteColor,
              ),
              TextConstant(
                title: ' • ',
                fontSize: 16.sp,
                color: themeController.whiteColor,
              ),
              TextConstant(
                title: widget.profile.distance,
                fontSize: 16.sp,
                color: themeController.lightPinkColor,
              ),
            ],
          ),
          
          SizedBox(height: 15.h),
          
          // Status Badges
          Row(
            children: [
              if (widget.profile.isVerified)
                _buildStatusBadge(
                  themeController,
                  icon: Icons.check_circle_rounded,
                  text: 'Verified',
                  color: themeController.lightPinkColor,
                ),
              if (widget.profile.isVerified) SizedBox(width: 10.w),
              if (widget.profile.isActiveNow)
                _buildStatusBadge(
                  themeController,
                  icon: LucideIcons.flame,
                  text: 'Active Now',
                  color: themeController.lightPinkColor,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(
    ThemeController themeController, {
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color, width: 1.w),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16.sp),
          SizedBox(width: 4.w),
          TextConstant(
            title: text,
            fontSize: 12.sp,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection(ThemeController themeController) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: themeController.lightPinkColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: themeController.lightPinkColor.withValues(alpha: 0.3),
          width: 1.w,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextConstant(
            title: 'about_me',
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: themeController.whiteColor,
          ),
          SizedBox(height: 10.h),
          Text(
            widget.profile.description,
            style: TextStyle(
              fontSize: 16.sp,
              color: themeController.whiteColor.withValues(alpha: 0.9),
              height: 1.5,
            ),
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsSection(ThemeController themeController) {
    return Container(
      margin: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextConstant(
            title: 'interests',
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: themeController.whiteColor,
          ),
          SizedBox(height: 15.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: widget.profile.hobbies.map((hobby) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      themeController.lightPinkColor.withValues(alpha: 0.3),
                      themeController.lightPinkColor.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25.r),
                  border: Border.all(
                    color: themeController.lightPinkColor.withValues(alpha: 0.5),
                    width: 1.w,
                  ),
                ),
                child: TextConstant(
                  title: hobby,
                  fontSize: 14.sp,
                  color: themeController.whiteColor,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeController themeController) {
    if (widget.isMatched) {
      // Show different buttons for matched profiles
      return Container(
        margin: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Message Button
            _buildActionButton(
              themeController,
              icon: Icons.message,
              color: themeController.lightPinkColor,
              onTap: () {
                _onMessageTap();
              },
            ),
            
            // Video Call Button
            _buildActionButton(
              themeController,
              icon: Icons.videocam,
              color: Colors.blue,
              onTap: () {
                _onVideoCallTap();
              },
            ),
            
            // Audio Call Button
            _buildActionButton(
              themeController,
              icon: Icons.call,
              color: themeController.greenColor,
              onTap: () {
                _onAudioCallTap();
              },
            ),
          ],
        ),
      );
    } else {
      // Show regular swipe buttons for non-matched profiles
      return Container(
        margin: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Pass Button
            _buildActionButton(
              themeController,
              icon: Icons.close,
              color: Colors.red,
              onTap: () {
                Get.back();
                // TODO: Implement pass functionality
              },
            ),
            
            // Super Like Button
            _buildActionButton(
              themeController,
              icon: Icons.star,
              color: Colors.blue,
              onTap: () {
                // TODO: Implement super like functionality
              },
            ),
            
            // Like Button
            _buildActionButton(
              themeController,
              icon: Icons.favorite,
              color: themeController.lightPinkColor,
              onTap: () {
                Get.back();
                // TODO: Implement like functionality
              },
            ),
          ],
        ),
      );
    }
  }

  Widget _buildActionButton(
    ThemeController themeController, {
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80.w,
        height: 80.w,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 3.w),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.6),
              blurRadius: 25,
              offset: Offset(0, 10),
            ),
            BoxShadow(
              color: themeController.blackColor.withValues(alpha: 0.8),
              blurRadius: 20,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: themeController.whiteColor,
          size: 36.sp,
        ),
      ),
    );
  }

  List<String> _getImages() {
    print('🔍 ProfileDetailScreen DEBUG:');
    print('  - profile.photos: ${widget.profile.photos}');
    print('  - profile.photos.length: ${widget.profile.photos.length}');
    print('  - profile.imageUrl: ${widget.profile.imageUrl}');
    
    Set<String> imageSet = <String>{};
    
    // Add photos from the photos array
    if (widget.profile.photos.isNotEmpty) {
      for (String photo in widget.profile.photos) {
        if (photo.isNotEmpty) {
          imageSet.add(photo);
        }
      }
    }
    
    // Add imageUrl if it's not empty
    if (widget.profile.imageUrl.isNotEmpty) {
      imageSet.add(widget.profile.imageUrl);
    }
    
    List<String> images = imageSet.toList();
    
    print('  - Final images array: $images');
    print('  - Final images count: ${images.length}');
    
    return images;
  }

  int _getImageCount() {
    return _getImages().length;
  }
}

class _MatchContext {
  final String matchId;
  final bool isBff;

  const _MatchContext({required this.matchId, required this.isBff});
}
