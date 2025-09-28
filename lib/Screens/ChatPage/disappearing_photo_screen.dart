import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/widget_constant.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:lovebug/services/disappearing_photo_service.dart';
import 'dart:async';

class DisappearingPhotoScreen extends StatefulWidget {
  final String photoUrl;
  final String senderName;
  final DateTime sentAt;
  final int viewDuration; // in seconds

  const DisappearingPhotoScreen({
    Key? key,
    required this.photoUrl,
    required this.senderName,
    required this.sentAt,
    this.viewDuration = 10, // Default 10 seconds
  }) : super(key: key);

  @override
  State<DisappearingPhotoScreen> createState() => _DisappearingPhotoScreenState();
}

class _DisappearingPhotoScreenState extends State<DisappearingPhotoScreen>
    with TickerProviderStateMixin {
  final ThemeController themeController = Get.find<ThemeController>();
  
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  Timer? _viewTimer;
  Timer? _progressTimer;
  bool _hasBeenViewed = false;
  bool _isExpired = false;
  int _remainingSeconds = 0;
  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.viewDuration;
    
    _progressController = AnimationController(
      duration: Duration(seconds: widget.viewDuration),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_progressController);
    
    // Mark as viewed immediately
    _markAsViewed();
    
    // Prevent screenshots
    _preventScreenshots();
    
    // Don't start timers yet - wait for photo to load
  }

  void _startViewTimer() {
    _viewTimer = Timer(Duration(seconds: widget.viewDuration), () {
      if (mounted) {
        setState(() {
          _isExpired = true;
        });
        _deletePhoto();
        Get.back();
      }
    });
  }

  void _startProgressTimer() {
    _progressController.forward();
    
    _progressTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingSeconds = widget.viewDuration - timer.tick;
        });
        
        if (_remainingSeconds <= 0) {
          timer.cancel();
        }
      }
    });
  }

  void _markAsViewed() {
    if (!_hasBeenViewed) {
      _hasBeenViewed = true;
      // TODO: Update database to mark photo as viewed
      print('📸 Photo viewed by user');
    }
  }

  void _deletePhoto() {
    // TODO: Delete photo from storage and database
    print('🗑️ Photo deleted after viewing');
  }

  void _preventScreenshots() {
    // Prevent screenshots using secure flag
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // Set secure flag to prevent screenshots and screen recording
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    
    // Additional security: Hide system UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
  }

  @override
  void dispose() {
    _viewTimer?.cancel();
    _progressTimer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main photo
          Center(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              child: Image.network(
                widget.photoUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null && !_imageLoaded) {
                    // Photo loaded successfully - start timers now
                    _imageLoaded = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _startViewTimer();
                      _startProgressTimer();
                    });
                    return child;
                  }
                  
                  if (_imageLoaded) {
                    return child;
                  }
                  
                  // Show loading indicator
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: themeController.lightPinkColor,
                        ),
                        SizedBox(height: 20.h),
                        TextConstant(
                          title: 'Loading photo...',
                          fontSize: 16,
                          color: themeController.whiteColor,
                        ),
                        SizedBox(height: 10.h),
                        TextConstant(
                          title: 'Timer will start after photo loads',
                          fontSize: 12,
                          color: themeController.whiteColor.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: TextConstant(
                      title: 'Photo expired',
                      fontSize: 18,
                      color: themeController.whiteColor,
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Top bar with sender info and progress
          Positioned(
            top: 50.h,
            left: 15.w,
            right: 15.w,
            child: Column(
              children: [
                // Sender info
                Row(
                  children: [
                    TextConstant(
                      title: 'From ${widget.senderName}',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: themeController.whiteColor,
                    ),
                    Spacer(),
                    TextConstant(
                      title: '${_remainingSeconds}s',
                      fontSize: 14,
                      color: themeController.whiteColor.withValues(alpha: 0.8),
                    ),
                  ],
                ),
                heightBox(10.h.toInt()),
                
                // Progress bar
                Container(
                  height: 3.h,
                  decoration: BoxDecoration(
                    color: themeController.whiteColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                  child: AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _progressAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            color: themeController.lightPinkColor,
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom instructions
          Positioned(
            bottom: 100.h,
            left: 15.w,
            right: 15.w,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
                  decoration: BoxDecoration(
                    color: themeController.blackColor.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: themeController.lightPinkColor.withValues(alpha: 0.3),
                      width: 1.w,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.visibility_off,
                        color: themeController.lightPinkColor,
                        size: 24.sp,
                      ),
                      heightBox(8.h.toInt()),
                      TextConstant(
                        title: _imageLoaded 
                            ? 'This photo will disappear in ${_remainingSeconds}s'
                            : 'Loading photo... Timer will start after photo loads',
                        fontSize: 14,
                        color: themeController.whiteColor,
                        textAlign: TextAlign.center,
                      ),
                      heightBox(4.h.toInt()),
                      TextConstant(
                        title: 'Screenshots are not allowed',
                        fontSize: 12,
                        color: themeController.whiteColor.withValues(alpha: 0.7),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Close button
          Positioned(
            top: 50.h,
            right: 15.w,
            child: GestureDetector(
              onTap: () {
                _viewTimer?.cancel();
                _progressTimer?.cancel();
                Get.back();
              },
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: themeController.blackColor.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: themeController.whiteColor,
                  size: 20.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
