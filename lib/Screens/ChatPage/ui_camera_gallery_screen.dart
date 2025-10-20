import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:camera/camera.dart';
import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/widget_constant.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/Screens/ChatPage/ui_photo_preview_screen.dart';

class CameraGalleryScreen extends StatefulWidget {
  final String matchId;
  
  const CameraGalleryScreen({super.key, required this.matchId});

  @override
  State<CameraGalleryScreen> createState() => _CameraGalleryScreenState();
}

class _CameraGalleryScreenState extends State<CameraGalleryScreen> {
  final ThemeController themeController = Get.find<ThemeController>();
  final ImagePicker _picker = ImagePicker();
  List<AssetEntity> _recentImages = [];
  bool _isLoading = true;
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isGalleryExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadRecentImages();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      print('🔍 DEBUG: Starting camera initialization...');
      
      // Get available cameras first
      _cameras = await availableCameras();
      print('🔍 DEBUG: Found ${_cameras?.length} cameras');
      
      if (_cameras == null || _cameras!.isEmpty) {
        print('❌ No cameras available');
        setState(() {
          _isCameraInitialized = false;
        });
        return;
      }
      
      // Create camera controller
      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      
      print('🔍 DEBUG: Camera controller created, initializing...');
      
      // Initialize camera
      await _cameraController!.initialize();
      
      print('✅ Camera initialized successfully');
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
      
    } catch (e) {
      print('❌ Camera initialization error: $e');
      setState(() {
        _isCameraInitialized = false;
      });
      
      // Show error message
      Get.snackbar(
        'Camera Error',
        'Failed to initialize camera. Tap "Retry Camera" to try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: themeController.blackColor,
        colorText: themeController.whiteColor,
        duration: Duration(seconds: 3),
      );
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _loadRecentImages() async {
    try {
      // Check if permission is already granted
      final PermissionStatus status = await Permission.photos.status;
      print('Gallery permission status: $status');
      
      if (status.isGranted) {
        await _loadGalleryPhotos();
      } else {
        // Don't request permission automatically, wait for user to tap gallery
        setState(() {
          _recentImages = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking gallery permission: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadGalleryPhotos() async {
    try {
      // Get recent images from gallery using photo_manager
      final List<AssetEntity> assets = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        hasAll: true,
      ).then((paths) async {
        if (paths.isNotEmpty) {
          return await paths.first.getAssetListPaged(
            page: 0,
            size: 20, // Get 20 most recent photos
          );
        }
        return <AssetEntity>[];
      });
      
      setState(() {
        _recentImages = assets;
        _isLoading = false;
      });
      
      print('Loaded ${assets.length} gallery photos');
    } catch (e) {
      print('Error loading gallery photos: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestGalleryPermission() async {
    try {
      // Check current permission status first
      final PermissionStatus currentStatus = await Permission.photos.status;
      print('Current gallery permission status: $currentStatus');
      
      PermissionStatus status;
      
      if (currentStatus.isPermanentlyDenied) {
        // Permission was permanently denied, show settings dialog
        Get.dialog(
          AlertDialog(
            backgroundColor: themeController.blackColor,
            title: Text(
              'Permission Required',
              style: TextStyle(color: themeController.whiteColor),
            ),
            content: Text(
              'Photo access was permanently denied. Please enable it in Settings > Privacy & Security > Photos > LoveBug',
              style: TextStyle(color: themeController.whiteColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text('Cancel', style: TextStyle(color: themeController.greyColor)),
              ),
              TextButton(
                onPressed: () {
                  Get.back();
                  openAppSettings();
                },
                child: Text('Open Settings', style: TextStyle(color: themeController.getAccentColor())),
              ),
            ],
          ),
        );
        return;
      } else if (currentStatus.isDenied) {
        // Request permission
        status = await Permission.photos.request();
      } else {
        status = currentStatus;
      }
      
      print('Gallery permission request result: $status');
      
      if (status.isGranted) {
        await _loadGalleryPhotos();
        Get.snackbar(
          'Success',
          'Gallery access granted',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: themeController.getAccentColor(),
          colorText: themeController.whiteColor,
        );
      } else {
        Get.snackbar(
          'Permission Required',
          'Please allow photo access to view your gallery',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: themeController.blackColor,
          colorText: themeController.whiteColor,
        );
      }
    } catch (e) {
      print('Error requesting gallery permission: $e');
      Get.snackbar(
        'Error',
        'Failed to request gallery permission',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: themeController.blackColor,
        colorText: themeController.whiteColor,
      );
    }
  }

  Future<void> _capturePhoto() async {
    try {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        print('🔍 DEBUG: Taking photo with camera controller...');
        final XFile photo = await _cameraController!.takePicture();
        _navigateToPreview(File(photo.path));
      } else {
        print('🔍 DEBUG: Camera controller not available, using image picker fallback...');
        // Fallback to image picker if camera not available
        final XFile? photo = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
        );
        
        if (photo != null) {
          _navigateToPreview(File(photo.path));
        }
      }
    } catch (e) {
      print('❌ Error taking photo: $e');
      Get.snackbar('Error', 'Failed to take photo');
    }
  }

  Future<void> _selectFromGallery(AssetEntity asset) async {
    try {
      final File? file = await asset.originFile;
      if (file != null) {
        _navigateToPreview(file);
      } else {
        Get.snackbar('Error', 'Failed to load image');
      }
    } catch (e) {
      print('Error loading asset: $e');
      Get.snackbar('Error', 'Failed to load image');
    }
  }

  void _navigateToPreview(File imageFile) {
    Get.to(() => PhotoPreviewScreen(
      imageFile: imageFile,
      matchId: widget.matchId,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: themeController.blackColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Full screen camera view
            Positioned.fill(
              child: _isCameraInitialized && _cameraController != null
                  ? CameraPreview(_cameraController!)
                  : Container(
                      color: themeController.blackColor,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!_isCameraInitialized)
                              CircularProgressIndicator(
                                color: themeController.getAccentColor(),
                                strokeWidth: 2.0,
                              )
                            else
                              Icon(
                                Icons.camera_alt,
                                size: 80.sp,
                                color: themeController.whiteColor.withValues(alpha: 0.3),
                              ),
                            heightBox(16),
                            TextConstant(
                              title: _isCameraInitialized ? 'Camera View' : 'Initializing Camera...',
                              fontSize: 16,
                              color: themeController.whiteColor.withValues(alpha: 0.7),
                            ),
                            if (!_isCameraInitialized) ...[
                              heightBox(16),
                              GestureDetector(
                                onTap: _initializeCamera,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                                  decoration: BoxDecoration(
                                    color: themeController.getAccentColor().withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20.r),
                                    border: Border.all(
                                      color: themeController.getAccentColor(),
                                      width: 1.w,
                                    ),
                                  ),
                                  child: TextConstant(
                                    title: 'Retry Camera',
                                    fontSize: 14,
                                    color: themeController.getAccentColor(),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
            ),
            
            // Top controls
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
                    // Flash toggle
                    GestureDetector(
                      onTap: () {
                        // Toggle flash
                      },
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: themeController.blackColor.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Icon(
                          Icons.flash_off,
                          color: themeController.whiteColor,
                          size: 20.sp,
                        ),
                      ),
                    ),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Gallery strip (collapsible)
                    AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      height: _isGalleryExpanded ? 120.h : 0,
                      child: _isGalleryExpanded
                          ? Container(
                              height: 120.h,
                              child: Column(
                                children: [
                                  // Gallery header
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.photo_library,
                                          color: themeController.whiteColor.withValues(alpha: 0.7),
                                          size: 16.sp,
                                        ),
                                        widthBox(8),
                                        TextConstant(
                                          title: 'Recent Photos',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: themeController.whiteColor.withValues(alpha: 0.7),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Gallery images
                                  Expanded(
                                    child: _isLoading
                                        ? Center(
                                            child: CircularProgressIndicator(
                                              color: themeController.getAccentColor(),
                                              strokeWidth: 2.0,
                                            ),
                                          )
                                        : _recentImages.isEmpty
                                            ? Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.photo_library_outlined,
                                                      size: 30.sp,
                                                      color: themeController.whiteColor.withValues(alpha: 0.3),
                                                    ),
                                                    heightBox(4),
                                                    TextConstant(
                                                      title: 'Tap to access gallery',
                                                      fontSize: 12,
                                                      color: themeController.whiteColor.withValues(alpha: 0.5),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : ListView.builder(
                                                scrollDirection: Axis.horizontal,
                                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                                itemCount: _recentImages.length,
                                                itemBuilder: (context, index) {
                                                  final asset = _recentImages[index];
                                                  return GestureDetector(
                                                    onTap: () => _selectFromGallery(asset),
                                                    child: Container(
                                                      margin: EdgeInsets.only(right: 8.w),
                                                      width: 60.w,
                                                      height: 60.w,
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(8.r),
                                                        border: Border.all(
                                                          color: themeController.getAccentColor().withValues(alpha: 0.3),
                                                          width: 1.w,
                                                        ),
                                                      ),
                                                      child: ClipRRect(
                                                        borderRadius: BorderRadius.circular(8.r),
                                                        child: FutureBuilder<File?>(
                                                          future: asset.originFile,
                                                          builder: (context, snapshot) {
                                                            if (snapshot.hasData && snapshot.data != null) {
                                                              return Image.file(
                                                                snapshot.data!,
                                                                fit: BoxFit.cover,
                                                                errorBuilder: (context, error, stackTrace) {
                                                                  return Container(
                                                                    color: themeController.greyColor.withValues(alpha: 0.2),
                                                                    child: Icon(
                                                                      Icons.broken_image,
                                                                      color: themeController.whiteColor.withValues(alpha: 0.3),
                                                                      size: 20.sp,
                                                                    ),
                                                                  );
                                                                },
                                                              );
                                                            } else {
                                                              return Container(
                                                                color: themeController.greyColor.withValues(alpha: 0.2),
                                                                child: Icon(
                                                                  Icons.image,
                                                                  color: themeController.whiteColor.withValues(alpha: 0.3),
                                                                  size: 20.sp,
                                                                ),
                                                              );
                                                            }
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                  ),
                                ],
                              ),
                            )
                          : null,
                    ),
                    
                    heightBox(16),
                    
                    // Camera controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Gallery toggle button
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isGalleryExpanded = !_isGalleryExpanded;
                            });
                            if (_recentImages.isEmpty && !_isGalleryExpanded) {
                              _requestGalleryPermission();
                            }
                          },
                          child: Container(
                            width: 50.w,
                            height: 50.w,
                            decoration: BoxDecoration(
                              color: themeController.blackColor.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(25.r),
                              border: Border.all(
                                color: themeController.whiteColor.withValues(alpha: 0.3),
                                width: 1.w,
                              ),
                            ),
                            child: Icon(
                              Icons.photo_library,
                              color: themeController.whiteColor,
                              size: 24.sp,
                            ),
                          ),
                        ),
                        
                        // Capture button
                        GestureDetector(
                          onTap: _capturePhoto,
                          child: Container(
                            width: 70.w,
                            height: 70.w,
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
                              size: 30.sp,
                            ),
                          ),
                        ),
                        
                        // Camera switch button
                        GestureDetector(
                          onTap: () {
                            // Switch camera
                          },
                          child: Container(
                            width: 50.w,
                            height: 50.w,
                            decoration: BoxDecoration(
                              color: themeController.blackColor.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(25.r),
                              border: Border.all(
                                color: themeController.whiteColor.withValues(alpha: 0.3),
                                width: 1.w,
                              ),
                            ),
                            child: Icon(
                              Icons.flip_camera_ios,
                              color: themeController.whiteColor,
                              size: 24.sp,
                            ),
                          ),
                        ),
                      ],
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
