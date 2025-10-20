import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/widget_constant.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/Screens/StoriesPage/ui_create_story_screen.dart';

class StoryCameraScreen extends StatefulWidget {
  const StoryCameraScreen({super.key});

  @override
  State<StoryCameraScreen> createState() => _StoryCameraScreenState();
}

class _StoryCameraScreenState extends State<StoryCameraScreen> {
  final ThemeController themeController = Get.find<ThemeController>();
  final ImagePicker _picker = ImagePicker();
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      print('🔍 DEBUG: Initializing camera for story...');
      _cameras = await availableCameras();
      
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.medium,
          enableAudio: false,
        );
        
        await _cameraController!.initialize();
        
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
        print('✅ Camera initialized successfully for story');
      }
    } catch (e) {
      print('❌ Camera initialization error for story: $e');
      setState(() {
        _isCameraInitialized = false;
      });
    }
  }

  Future<void> _takePhoto() async {
    try {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        print('🔍 DEBUG: Taking photo for story with camera controller...');
        final XFile photo = await _cameraController!.takePicture();
        _navigateToCreateStory(File(photo.path));
      } else {
        print('🔍 DEBUG: Camera not ready for story, using image picker fallback...');
        final XFile? photo = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
        );
        
        if (photo != null) {
          _navigateToCreateStory(File(photo.path));
        }
      }
    } catch (e) {
      print('❌ Error taking photo for story: $e');
      Get.snackbar(
        'Error',
        'Failed to take photo: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: themeController.blackColor,
        colorText: themeController.whiteColor,
      );
    }
  }

  Future<void> _selectFromGallery() async {
    try {
      print('🔍 DEBUG: Selecting from gallery for story...');
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        print('✅ Image selected from gallery for story');
        _navigateToCreateStory(File(image.path));
      } else {
        print('❌ User cancelled gallery selection for story');
      }
    } catch (e) {
      print('❌ Error selecting from gallery for story: $e');
      Get.snackbar(
        'Error',
        'Failed to select image: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: themeController.blackColor,
        colorText: themeController.whiteColor,
      );
    }
  }

  void _navigateToCreateStory(File imageFile) {
    Get.to(() => CreateStoryScreen(
      imagePath: imageFile.path,
      imageUrl: '', // Empty since it's a local image
      isLocalImage: true,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: themeController.blackColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera preview
            Positioned.fill(
              child: _isCameraInitialized && _cameraController != null
                  ? CameraPreview(_cameraController!)
                  : Container(
                      color: themeController.blackColor,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: themeController.getAccentColor(),
                              strokeWidth: 2.0,
                            ),
                            heightBox(16),
                            TextConstant(
                              title: 'Initializing Camera...',
                              fontSize: 16,
                              color: themeController.whiteColor.withValues(alpha: 0.7),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            
            // Header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      themeController.blackColor.withValues(alpha: 0.7),
                      themeController.blackColor.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: themeController.blackColor.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Icon(
                          Icons.close,
                          color: themeController.whiteColor,
                          size: 20.sp,
                        ),
                      ),
                    ),
                    TextConstant(
                      title: 'Create Story',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: themeController.whiteColor,
                    ),
                    SizedBox(width: 40.w), // Spacer for centering
                  ],
                ),
              ),
            ),
            
            // Bottom controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      themeController.blackColor.withValues(alpha: 0.3),
                      themeController.blackColor.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Gallery button
                    GestureDetector(
                      onTap: _selectFromGallery,
                      child: Container(
                        width: 60.w,
                        height: 60.w,
                        decoration: BoxDecoration(
                          color: themeController.blackColor.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(30.r),
                          border: Border.all(
                            color: themeController.whiteColor.withValues(alpha: 0.3),
                            width: 1.w,
                          ),
                        ),
                        child: Icon(
                          Icons.photo_library,
                          color: themeController.whiteColor,
                          size: 28.sp,
                        ),
                      ),
                    ),
                    
                    // Capture button
                    GestureDetector(
                      onTap: _takePhoto,
                      child: Container(
                        width: 80.w,
                        height: 80.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: themeController.whiteColor,
                          border: Border.all(
                            color: themeController.getAccentColor(),
                            width: 4.w,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: themeController.blackColor.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          color: themeController.getAccentColor(),
                          size: 36.sp,
                        ),
                      ),
                    ),
                    
                    // Placeholder for symmetry
                    Container(
                      width: 60.w,
                      height: 60.w,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
