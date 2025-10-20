import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/widget_constant.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:lovebug/services/analytics_service.dart';
import 'package:lovebug/Screens/StoriesPage/controller_stories_screen.dart';
import 'package:lovebug/Screens/StoriesPage/ui_instagram_story_viewer.dart';

class CreateStoryScreen extends StatefulWidget {
  final String imagePath;
  final String imageUrl;
  final bool isLocalImage;

  const CreateStoryScreen({
    Key? key,
    required this.imagePath,
    required this.imageUrl,
    this.isLocalImage = false,
  }) : super(key: key);

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final ThemeController themeController = Get.find<ThemeController>();
  final StoriesController storiesController = Get.find<StoriesController>();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  bool _isUploading = false;
  bool _isBackgroundUploading = false;
  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();
    print('🔄 DEBUG: CreateStoryScreen initState called');
    print('🔄 DEBUG: ImagePath: ${widget.imagePath}');
    print('🔄 DEBUG: ImageUrl: ${widget.imageUrl}');
    print('🔄 DEBUG: IsLocalImage: ${widget.isLocalImage}');
    
    // Auto-focus the text input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _textFocusNode.requestFocus();
    });
    
    // Start background upload if it's a local image
    if (widget.isLocalImage && widget.imageUrl.isEmpty) {
      _startBackgroundUpload();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  Future<void> _startBackgroundUpload() async {
    if (_isBackgroundUploading) return;
    
    print('🔄 DEBUG: _startBackgroundUpload called');
    if (mounted) {
      setState(() {
        _isBackgroundUploading = true;
      });
    }
    
    try {
      print('🔄 DEBUG: Starting background upload...');
      final uid = SupabaseService.currentUser?.id;
      if (uid == null) {
        print('❌ DEBUG: No user ID for background upload');
        return;
      }
      
      print('🔄 DEBUG: Reading file: ${widget.imagePath}');
      final bytes = await File(widget.imagePath).readAsBytes();
      print('🔄 DEBUG: File size: ${bytes.length} bytes');
      
      final path = uid + '/story_' + DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
      print('🔄 DEBUG: Upload path: $path');
      
      final url = await SupabaseService.uploadFile(bucket: 'story-media', path: path, fileBytes: bytes);
      print('✅ DEBUG: Background upload completed: $url');
      
      if (mounted) {
        setState(() {
          _uploadedImageUrl = url;
          _isBackgroundUploading = false;
        });
      }
      
      print('✅ DEBUG: _uploadedImageUrl set to: $_uploadedImageUrl');
    } catch (e) {
      print('❌ DEBUG: Background upload failed: $e');
      if (mounted) {
        setState(() {
          _isBackgroundUploading = false;
        });
      }
    }
  }

  Future<void> _uploadStory() async {
    if (_isUploading) return;

    print('🔄 DEBUG: Starting story upload...');
    setState(() {
      _isUploading = true;
    });

    try {
      final uid = SupabaseService.currentUser?.id;
      if (uid == null) {
        print('❌ DEBUG: No user ID found');
        Get.snackbar('Login required', 'Please sign in to add a story');
        setState(() {
          _isUploading = false;
        });
        return;
      }

      final text = _textController.text.trim();
      print('🔄 DEBUG: Story text: "$text"');
      
      // Show immediate feedback
      Get.snackbar(
        'Uploading Story...',
        'Please wait while we upload your story',
        backgroundColor: themeController.lightPinkColor,
        colorText: Colors.white,
        duration: Duration(seconds: 1),
      );
      
      // Perform the upload with timeout
      await Future.any([
        _performUpload(uid, text),
        Future.delayed(Duration(seconds: 30), () {
          throw Exception('Upload timeout - please check your connection and try again');
        }),
      ]);
      
      // Show success message
      Get.snackbar(
        'Story Posted! 📸',
        'Your story is live for 24 hours',
        backgroundColor: themeController.lightPinkColor,
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );
      
      // Navigate to story viewer to show the posted story
      try {
        // Find the current user's story group index
        final currentUserId = SupabaseService.currentUser?.id;
        if (currentUserId != null) {
          int userStoryIndex = 0;
          for (int i = 0; i < storiesController.storyGroups.length; i++) {
            if (storiesController.storyGroups[i].userId == currentUserId) {
              userStoryIndex = i;
              break;
            }
          }
          
          print('✅ DEBUG: Navigating to story viewer at index: $userStoryIndex');
          Get.offAll(() => InstagramStoryViewer(
            storyGroups: storiesController.storyGroups,
            initialIndex: userStoryIndex,
            isUploading: false,
          ));
        } else {
          // Fallback: go back to stories screen
          Get.back(); // Exit create story screen
          Get.back(); // Exit camera screen
        }
      } catch (e) {
        print('❌ DEBUG: Error navigating to story viewer: $e');
        // Fallback: go back to stories screen
        Get.back(); // Exit create story screen
        Get.back(); // Exit camera screen
      }
      
    } catch (e) {
      print('❌ DEBUG: Error uploading story: $e');
      print('❌ DEBUG: Error type: ${e.runtimeType}');
      
      String errorMessage = 'Could not upload story. Please try again.';
      if (e.toString().contains('timeout')) {
        errorMessage = 'Upload timed out. Please check your connection and try again.';
      } else if (e.toString().contains('Connection reset')) {
        errorMessage = 'Connection lost. Please check your internet and try again.';
      }
      
      Get.snackbar(
        'Upload Failed',
        errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 4),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }


  Future<void> _performUpload(String uid, String text) async {
    // If this is a local image, we need to upload it first
    String imageUrl = '';
    if (widget.isLocalImage) {
      print('🔄 DEBUG: This is a local image, need to upload first');

      // Check if background upload completed
      if (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty) {
        imageUrl = _uploadedImageUrl!;
        print('✅ DEBUG: Using already uploaded URL: $imageUrl');
      } else {
        // Upload the image now with retry logic
        print('🔄 DEBUG: Uploading image now...');
        int retryCount = 0;
        const maxRetries = 3;
        
        while (retryCount < maxRetries) {
          try {
            final bytes = await File(widget.imagePath).readAsBytes();
            final path = uid + '/story_' + DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
            
            // Add timeout for image upload
            imageUrl = await Future.any([
              SupabaseService.uploadFile(bucket: 'story-media', path: path, fileBytes: bytes),
              Future.delayed(Duration(seconds: 20), () {
                throw Exception('Image upload timeout');
              }),
            ]);
            
            print('✅ DEBUG: Image uploaded successfully: $imageUrl');
            break; // Success, exit retry loop
          } catch (e) {
            retryCount++;
            print('❌ DEBUG: Image upload attempt $retryCount failed: $e');
            
            if (retryCount >= maxRetries) {
              throw Exception('Failed to upload image after $maxRetries attempts: $e');
            }
            
            // Wait before retry
            await Future.delayed(Duration(seconds: 2));
          }
        }
      }
    } else {
      // Use the provided URL
      imageUrl = widget.imageUrl;
      print('🔄 DEBUG: Using provided URL: $imageUrl');
    }
      
    // Final check - ensure we have a valid URL
    if (imageUrl.isEmpty) {
      throw Exception('No valid image URL available');
    }
    
    final expiresAt = DateTime.now().add(const Duration(hours: 24)).toIso8601String();
    
    // Insert story with text content with retry logic
    print('🔄 DEBUG: Inserting story with content: "$text"');
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        final result = await Future.any(<Future<dynamic>>[
          SupabaseService.client.from('stories').insert({
            'user_id': uid,
            'media_url': imageUrl,
            'content': text.isNotEmpty ? text : null,
            'expires_at': expiresAt,
          }).select().single(),
          Future.delayed(Duration(seconds: 15), () {
            throw Exception('Database insert timeout');
          }),
        ]);
        
        print('✅ DEBUG: Story inserted successfully: ${result['id']}');
        
        // Track story posted analytics
        await AnalyticsService.trackStoryPosted(
          result['id'].toString(),
          'image',
        );
        
        // Reload stories to include the new story
        await storiesController.loadStories();
        
        print('✅ DEBUG: Story upload completed successfully');
        break; // Success, exit retry loop
      } catch (e) {
        retryCount++;
        print('❌ DEBUG: Database insert attempt $retryCount failed: $e');
        
        if (retryCount >= maxRetries) {
          throw Exception('Failed to save story after $maxRetries attempts: $e');
        }
        
        // Wait before retry
        await Future.delayed(Duration(seconds: 1));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: TextConstant(
          title: 'Add to Story',
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _uploadStory,
            child: TextConstant(
              title: _isUploading ? 'Posting...' : 'Share',
              color: _isUploading ? Colors.grey : themeController.lightPinkColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Story Image Background
          Positioned.fill(
            child: widget.isLocalImage && widget.imageUrl.isEmpty
                ? Image.file(
                    File(widget.imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: themeController.greyColor,
                        child: Icon(
                          Icons.image,
                          color: Colors.white,
                          size: 50.sp,
                        ),
                      );
                    },
                  )
                : Image.network(
                    _uploadedImageUrl ?? widget.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: themeController.greyColor,
                        child: Icon(
                          Icons.image,
                          color: Colors.white,
                          size: 50.sp,
                        ),
                      );
                    },
                  ),
          ),
          
          // Dark overlay for text visibility
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),
          ),
          
          // Text Input Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Background Upload Status
                  if (widget.isLocalImage && _isBackgroundUploading)
                    Container(
                      margin: EdgeInsets.only(bottom: 10.h),
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16.w,
                            height: 16.h,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          TextConstant(
                            title: 'Preparing story...',
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ],
                      ),
                    ),
                  
                  // Text Input
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9), // White with transparency
                      borderRadius: BorderRadius.circular(25.r),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _textController,
                      focusNode: _textFocusNode,
                      style: TextStyle(
                        color: Colors.black, // Black text
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: "Add a message to your story...",
                        hintStyle: TextStyle(
                          color: Colors.black.withValues(alpha: 0.6), // Black hint text
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 15.h,
                        ),
                      ),
                      maxLines: 3,
                      textInputAction: TextInputAction.newline,
                    ),
                  ),
                  
                  SizedBox(height: 20.h),
                  
                  // Upload Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _uploadStory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeController.lightPinkColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 15.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.r),
                        ),
                        elevation: 0,
                      ),
                      child: _isUploading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20.w,
                                  height: 20.h,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.0,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                TextConstant(
                                  title: 'Posting Story...',
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ],
                            )
                          : TextConstant(
                              title: 'Share Story',
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
