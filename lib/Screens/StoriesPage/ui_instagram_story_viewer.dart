import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/widget_constant.dart';
import 'package:lovebug/Screens/StoriesPage/controller_stories_screen.dart';
import 'package:lovebug/Screens/StoriesPage/ui_stories_screen.dart';
import 'package:lovebug/Screens/BottomBarPage/bottombar_screen.dart';
import 'package:lovebug/Screens/DiscoverPage/profile_detail_screen.dart';
import 'package:lovebug/Screens/DiscoverPage/controller_discover_screen.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:lovebug/widgets/upgrade_prompt_widget.dart';
import 'package:lovebug/Screens/SubscriptionPage/ui_subscription_screen.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:ui';

class InstagramStoryViewer extends StatefulWidget {
  final List<StoryGroup> storyGroups;
  final int initialIndex;
  final bool isUploading;

  const InstagramStoryViewer({
    super.key,
    required this.storyGroups,
    required this.initialIndex,
    this.isUploading = false,
  });

  @override
  State<InstagramStoryViewer> createState() => _InstagramStoryViewerState();
}

class _InstagramStoryViewerState extends State<InstagramStoryViewer>
    with TickerProviderStateMixin {
  final ThemeController themeController = Get.find<ThemeController>();
  
  late PageController _pageController;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  
  int _currentGroupIndex = 0;
  int _currentStoryIndex = 0;
  Timer? _storyTimer;
  bool _isPaused = false;
  double _panDelta = 0.0;
  Map<String, bool> _likedStories = {};
  TextEditingController _commentController = TextEditingController();
  FocusNode _commentFocusNode = FocusNode();
  
  bool get _isLiked {
    final currentStory = _getCurrentStory();
    return _likedStories[currentStory?.id] ?? false;
  }

  void _toggleLike() {
    final currentStory = _getCurrentStory();
    if (currentStory != null) {
      setState(() {
        _likedStories[currentStory.id] = !_isLiked;
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

  Future<void> _viewProfile(String userId) async {
    try {
      print('🔍 _viewProfile called for userId: $userId');
      // Get the user's profile
      final profileData = await SupabaseService.getProfile(userId);
      print('🔍 Profile data received: $profileData');
      if (profileData != null) {
        // Convert Map to Profile object
        final profile = _mapToProfile(profileData);
        print('🔍 Profile object created: ${profile.name}');
        // Navigate to profile detail screen with isMatched: true
        Get.to(() => ProfileDetailScreen(profile: profile, isMatched: true));
      } else {
        print('❌ Profile data is null');
        Get.snackbar('Error', 'Profile not found');
      }
    } catch (e) {
      print('❌ Error viewing profile: $e');
      Get.snackbar('Error', 'Failed to load profile');
    }
  }

  Future<void> _deleteCurrentStory() async {
    try {
      // Get the filtered story groups (same logic as in build method)
      const ssUserId = 'c1ffb3e0-0e25-4176-9736-0db8522fd357';
      final validStoryGroups = widget.storyGroups.where((group) => 
        group.stories.isNotEmpty || group.userId == ssUserId
      ).toList();
      
      final currentGroup = validStoryGroups[_currentGroupIndex];
      
      // Safety check - ensure we have stories and valid index
      if (currentGroup.stories.isEmpty || _currentStoryIndex >= currentGroup.stories.length) {
        Get.back();
        return;
      }
      
      final currentStory = currentGroup.stories[_currentStoryIndex];
      
      // Pause the story when delete dialog is shown
      _pauseStory();
      
      // Show confirmation dialog with same size as logout popup
      final confirmed = await Get.dialog<bool>(
        Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      themeController.lightPinkColor.withValues(alpha: 0.15),
                      themeController.lightPinkColor.withValues(alpha: 0.2),
                      themeController.blackColor.withValues(alpha: 0.85),
                    ],
                    stops: const [0.0, 0.3, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(22.r),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Delete Story',
                      style: TextStyle(
                        color: themeController.whiteColor,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    heightBox(16),
                    Text(
                      'Are you sure you want to delete this story?',
                      style: TextStyle(
                        color: themeController.whiteColor.withValues(alpha: 0.8),
                        fontSize: 15.sp,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    heightBox(24),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Get.back(result: false);
                              _resumeStory(); // Resume story if cancelled
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              decoration: BoxDecoration(
                                color: themeController.whiteColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: themeController.whiteColor.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: themeController.whiteColor,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        widthBox(12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Get.back(result: true);
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.red.shade600, Colors.red.shade800],
                                ),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: const Text(
                                'Delete',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
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
          ),
        ),
      );

      if (confirmed == true) {
        try {
          print('🔄 DEBUG: Starting story deletion for: ${currentStory.id}');
          
          // Delete the story from database first
          final deleteResult = await SupabaseService.client
              .from('stories')
              .delete()
              .eq('id', currentStory.id)
              .select();
              
          print('✅ DEBUG: Database deletion result: $deleteResult');

          // Show success message
          Get.snackbar(
            'Story Deleted',
            'Your story has been removed',
            backgroundColor: themeController.lightPinkColor,
            colorText: Colors.white,
            duration: Duration(seconds: 2),
          );

          // Update the global StoriesController
          try {
            final storiesController = Get.find<StoriesController>();
            storiesController.removeStoryById(currentStory.id);
            print('✅ DEBUG: Story removed from global controller');
          } catch (e) {
            print('❌ DEBUG: Could not update global StoriesController: $e');
          }

          // Update local UI state - reload stories to get fresh data
          try {
            final storiesController = Get.find<StoriesController>();
            await storiesController.loadStories();
            
            // Check if current user has any stories left
            final currentUserId = SupabaseService.currentUser?.id;
            if (currentUserId != null) {
              final userStoryGroup = storiesController.storyGroups.firstWhere(
                (group) => group.userId == currentUserId,
                orElse: () => StoryGroup(userId: '', userName: '', avatarUrl: '', stories: [], hasUnviewed: false),
              );
              
              if (userStoryGroup.stories.isEmpty) {
                print('✅ DEBUG: No stories left for current user, going back to main app');
                Get.offAll(() => BottombarScreen()); // Navigate back to main app with bottom bar
                return;
              }
            }
            
            // Navigate to a fresh story viewer with updated data
            if (currentUserId != null) {
              int userStoryIndex = 0;
              for (int i = 0; i < storiesController.storyGroups.length; i++) {
                if (storiesController.storyGroups[i].userId == currentUserId) {
                  userStoryIndex = i;
                  break;
                }
              }
              
              print('✅ DEBUG: Navigating to fresh story viewer at index: $userStoryIndex');
              Get.off(() => InstagramStoryViewer(
                storyGroups: storiesController.storyGroups,
                initialIndex: userStoryIndex,
                isUploading: false,
              ));
            }
            
          } catch (e) {
            print('❌ DEBUG: Error reloading stories: $e');
            // Fallback: navigate to main app
            Get.offAll(() => BottombarScreen());
          }
          
        } catch (e) {
          print('❌ DEBUG: Error deleting story: $e');
          Get.snackbar(
            'Delete Failed',
            'Failed to delete story. Please try again.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: Duration(seconds: 2),
          );
        }
      } else {
        // User cancelled, resume the story
        _resumeStory();
      }
    } catch (e) {
      print('❌ DEBUG: Error deleting story: $e');
      Get.snackbar(
        'Delete Failed',
        'Failed to delete story. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );
    }
  }

  void _sendComment() async {
    final comment = _commentController.text.trim();
    print('DEBUG: _sendComment called with: "$comment"');
    
    if (comment.isNotEmpty) {
      try {
        // Get current story user ID
        final currentStory = _getCurrentStory();
        print('DEBUG: Current story: ${currentStory?.userId}');
        
        if (currentStory == null) {
          print('DEBUG: No current story found');
          return;
        }
        
        // Find match ID between current user and story user
        print('DEBUG: Looking for match between current user and ${currentStory.userId}');
        final matchId = await _findMatchId(currentStory.userId);
        print('DEBUG: Found match ID: $matchId');
        
        if (matchId == null) {
          print('DEBUG: No match found, showing error');
          Get.snackbar(
            'No Match',
            'You need to match with this user first to send messages',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: Duration(seconds: 2),
          );
          return;
        }
        
        // Ensure flame chat state is initialized
        final flameMeta = await SupabaseService.startFlameChat(matchId);
        final meta = flameMeta.isNotEmpty
            ? flameMeta
            : await SupabaseService.getFlameStatus(matchId);

        final userSummary = await SupabaseService.getCurrentUserSummary();
        final gender = (userSummary['gender'] ?? '').toString().toLowerCase();
        final bool isPremium = gender == 'female' || userSummary['is_premium'] == true;
        final bool isFlameActive = _isFlameActive(meta);

        if (!isFlameActive && !isPremium) {
          _showUpgradePrompt(_nextMessageTime(meta));
          return;
        }

        // Send message to chat with story context
        print('DEBUG: Sending message to match $matchId: "$comment"');
        await SupabaseService.sendMessage(
          matchId: matchId,
          content: comment,
          storyId: currentStory.id,
          storyUserName: currentStory.userName,
          bypassFreemium: isFlameActive,
        );
        print('DEBUG: Message sent successfully');
        
        // Clear input and show success
        _commentController.clear();
        _commentFocusNode.unfocus();
        
        Get.snackbar(
          'Message Sent! 💬',
          'Your reply was sent to their chat',
          backgroundColor: themeController.lightPinkColor,
          colorText: Colors.white,
          duration: Duration(seconds: 2),
        );
        
        // Navigate to chat after a short delay
        Future.delayed(Duration(seconds: 1), () {
          Get.back(); // Exit story viewer
          // TODO: Navigate to specific chat screen
        });
        
      } catch (e) {
        print('DEBUG: Error sending story reply: $e');
        print('DEBUG: Error type: ${e.runtimeType}');
        if (e is PostgrestException) {
          print('DEBUG: Postgres error: ${e.message}');
        }
        Get.snackbar(
          'Send Failed',
          'Could not send message. Please try again.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: Duration(seconds: 2),
        );
      }
    }
  }

  StoryItem? _getCurrentStory() {
    final validStoryGroups = widget.storyGroups.where((group) => group.stories.isNotEmpty).toList();
    if (_currentGroupIndex >= 0 && _currentGroupIndex < validStoryGroups.length) {
      final storyGroup = validStoryGroups[_currentGroupIndex];
      if (storyGroup.stories.isNotEmpty && _currentStoryIndex >= 0 && _currentStoryIndex < storyGroup.stories.length) {
        return storyGroup.stories[_currentStoryIndex];
      }
    }
    return null;
  }

  bool _isCurrentUserStory(StoryItem story) {
    final currentUserId = SupabaseService.currentUser?.id;
    return currentUserId != null && story.userId == currentUserId;
  }

  Future<String?> _findMatchId(String storyUserId) async {
    try {
      print('DEBUG: _findMatchId called with storyUserId: $storyUserId');
      final matches = await SupabaseService.getMatches();
      final currentUserId = SupabaseService.currentUser?.id;
      
      print('DEBUG: Current user ID: $currentUserId');
      print('DEBUG: Found ${matches.length} matches');
      
      if (currentUserId == null) {
        print('DEBUG: No current user ID, returning null');
        return null;
      }
      
      // Prevent self-match
      if (currentUserId == storyUserId) {
        print('DEBUG: Cannot send message to own story, returning null');
        return null;
      }
      
      for (final match in matches) {
        final userId1 = match['user_id_1']?.toString();
        final userId2 = match['user_id_2']?.toString();
        final matchId = match['id']?.toString();
        
        print('DEBUG: Checking match $matchId: user1=$userId1, user2=$userId2');
        
        if ((userId1 == currentUserId && userId2 == storyUserId) ||
            (userId1 == storyUserId && userId2 == currentUserId)) {
          print('DEBUG: Found matching match: $matchId');
          return matchId;
        }
      }
      
      print('DEBUG: No match found for story user $storyUserId');
      return null;
    } catch (e) {
      print('DEBUG: Error finding match ID: $e');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _currentGroupIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _progressController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_progressController);
    _startStoryTimer();
    
    // Add focus listeners to pause/resume story
    _commentFocusNode.addListener(() {
      if (_commentFocusNode.hasFocus) {
        _pauseStory();
        print('DEBUG: Story paused - user started typing');
      } else {
        _resumeStory();
        print('DEBUG: Story resumed - user stopped typing');
      }
    });
  }

  @override
  void dispose() {
    _storyTimer?.cancel();
    _progressController.dispose();
    _pageController.dispose();
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  void _startStoryTimer() {
    _storyTimer?.cancel();
    _progressController.reset();
    _progressController.forward();
    
    _storyTimer = Timer(const Duration(seconds: 5), () {
      _nextStory();
    });
    
    // Force UI update
    setState(() {});
  }

  void _nextStory() {
    // Get the filtered story groups (same logic as in build method)
    const ssUserId = 'c1ffb3e0-0e25-4176-9736-0db8522fd357';
    final validStoryGroups = widget.storyGroups.where((group) => 
      group.stories.isNotEmpty || group.userId == ssUserId
    ).toList();
    
    final currentGroup = validStoryGroups[_currentGroupIndex];
    print('DEBUG: Next story - currentGroupIndex: $_currentGroupIndex, currentStoryIndex: $_currentStoryIndex, total stories: ${currentGroup.stories.length}');
    
    // Safety check - if current group has no stories, go back
    if (currentGroup.stories.isEmpty) {
      Get.back();
      return;
    }
    
    if (_currentStoryIndex < currentGroup.stories.length - 1) {
      // Move to next story of current user
      setState(() {
        _currentStoryIndex++;
      });
      print('DEBUG: Moving to next story of current user: $_currentStoryIndex');
      _startStoryTimer();
    } else if (_currentGroupIndex < validStoryGroups.length - 1) {
      // Move to next user's first story
      setState(() {
        _currentGroupIndex++;
        _currentStoryIndex = 0;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      print('DEBUG: Moving to next user: $_currentGroupIndex');
    } else {
      // End of all stories
      print('DEBUG: End of all stories, exiting');
      Get.back();
      Get.back(); // Go back twice to exit camera and story viewer
    }
  }

  void _previousStory() {
    print('DEBUG: Previous story - currentGroupIndex: $_currentGroupIndex, currentStoryIndex: $_currentStoryIndex');
    
    // Get the filtered story groups (same logic as in build method)
    const ssUserId = 'c1ffb3e0-0e25-4176-9736-0db8522fd357';
    final validStoryGroups = widget.storyGroups.where((group) => 
      group.stories.isNotEmpty || group.userId == ssUserId
    ).toList();
    
    final currentGroup = validStoryGroups[_currentGroupIndex];
    
    // Safety check - if current group has no stories, go back
    if (currentGroup.stories.isEmpty) {
      Get.back();
      return;
    }
    
    if (_currentStoryIndex > 0) {
      // Move to previous story of current user
      setState(() {
        _currentStoryIndex--;
      });
      print('DEBUG: Moving to previous story of current user: $_currentStoryIndex');
      _startStoryTimer();
    } else if (_currentGroupIndex > 0) {
      // Move to previous user's last story
      setState(() {
        _currentGroupIndex--;
        _currentStoryIndex = validStoryGroups[_currentGroupIndex].stories.length - 1;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      print('DEBUG: Moving to previous user: $_currentGroupIndex, story: $_currentStoryIndex');
    }
  }

  void _pauseStory() {
    _isPaused = true;
    _storyTimer?.cancel();
    _progressController.stop();
  }

  void _resumeStory() {
    _isPaused = false;
    _startStoryTimer();
  }

  @override
  Widget build(BuildContext context) {
    // Safety check - if no story groups or current group has no stories, go back
    if (widget.storyGroups.isEmpty || 
        _currentGroupIndex >= widget.storyGroups.length ||
        widget.storyGroups[_currentGroupIndex].stories.isEmpty) {
      // Navigate back to stories screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.back();
      });
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: themeController.lightPinkColor,
          ),
        ),
      );
    }
    
    // Filter out empty story groups, but keep SS even if empty
    const ssUserId = 'c1ffb3e0-0e25-4176-9736-0db8522fd357';
    final validStoryGroups = widget.storyGroups.where((group) => 
      group.stories.isNotEmpty || group.userId == ssUserId
    ).toList();
    
    if (validStoryGroups.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.back();
      });
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: TextConstant(
            title: 'No stories available',
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          final tapX = details.globalPosition.dx;
          
          print('DEBUG: Tap detected at x: $tapX, screen width: $screenWidth');
          
          if (tapX < screenWidth * 0.3) {
            // Tap left side - previous story
            print('DEBUG: Tapping left side - previous story');
            _previousStory();
          } else if (tapX > screenWidth * 0.7) {
            // Tap right side - next story
            print('DEBUG: Tapping right side - next story');
            _nextStory();
          } else {
            // Tap center - pause/resume
            print('DEBUG: Tapping center - pause/resume');
            if (_isPaused) {
              _resumeStory();
            } else {
              _pauseStory();
            }
          }
        },
        onPanUpdate: (details) {
          // Track pan delta for swipe detection
          _panDelta += details.delta.dy;
          
          // Handle swipe down to exit - more sensitive
          if (details.delta.dy > 2) {
            _pauseStory();
          }
        },
        onPanEnd: (details) {
          final velocity = details.velocity.pixelsPerSecond.dy;
          print('DEBUG: Pan end - velocity: $velocity, delta: $_panDelta');
          
          // More responsive swipe down detection - make it easier to exit
          if (velocity > 50 || _panDelta > 50) {
            // Swipe down to exit
            print('DEBUG: Swipe down to exit');
            Get.offAll(() => BottombarScreen()); // Navigate directly to main app
          } else {
            print('DEBUG: Resuming story');
            _resumeStory();
          }
          
          // Reset pan delta
          _panDelta = 0.0;
        },
        child: Stack(
          children: [
            // Story Content
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentGroupIndex = index;
                  _currentStoryIndex = 0;
                });
                _startStoryTimer();
              },
              itemCount: validStoryGroups.length,
              itemBuilder: (context, groupIndex) {
                final storyGroup = validStoryGroups[groupIndex];
                return _buildStoryContent(storyGroup);
              },
            ),
            
            // Top Progress Bars
            Positioned(
              top: 50.h,
              left: 15.w,
              right: 15.w,
              child: _buildProgressBars(validStoryGroups),
            ),
            
            // Top User Info
            Positioned(
              top: 80.h,
              left: 15.w,
              right: 15.w,
              child: _buildUserInfo(validStoryGroups),
            ),
            
            // Bottom Actions
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryContent(StoryGroup storyGroup) {
    // Safety check - if no stories, return empty container
    if (storyGroup.stories.isEmpty || _currentStoryIndex >= storyGroup.stories.length) {
      // Special handling for SS (BFF chat story) - show placeholder
      const ssUserId = 'c1ffb3e0-0e25-4176-9736-0db8522fd357';
      if (storyGroup.userId == ssUserId) {
        return Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                SizedBox(height: 16),
                Text(
                  'SS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'BFF Chat Story',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      
      return Container(
        color: Colors.black,
        child: Center(
          child: Text(
            'No stories available',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    
    final currentStory = storyGroup.stories[_currentStoryIndex];
    
    return Stack(
      children: [
        // Background Image
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(currentStory.mediaUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        
        // Uploading overlay (only show for current user's story when uploading)
        if (widget.isUploading && _isCurrentUserStory(currentStory))
          GestureDetector(
            onTap: () {
              print('DEBUG: Tapped uploading overlay to exit');
              Get.offAll(() => BottombarScreen()); // Navigate directly to main app
            },
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(30.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: themeController.getAccentColor(),
                        strokeWidth: 3.0,
                      ),
                      heightBox(16),
                      TextConstant(
                        title: 'Uploading Story...',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      heightBox(8),
                      TextConstant(
                        title: 'Tap to exit if stuck',
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        
        // Story Caption/Content
        if (currentStory.content != null && currentStory.content!.isNotEmpty)
          Positioned(
            bottom: 100.h,
            left: 20.w,
            right: 20.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: TextConstant(
                title: currentStory.content!,
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        
        // Upload Progress Overlay (if story is being uploaded)
        if (currentStory.mediaUrl.isEmpty)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 60.w,
                      height: 60.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(themeController.lightPinkColor),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    TextConstant(
                      title: 'Uploading your story...',
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    SizedBox(height: 8.h),
                    TextConstant(
                      title: 'Please wait while we process your content',
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProgressBars(List<StoryGroup> validStoryGroups) {
    final currentGroup = validStoryGroups[_currentGroupIndex];
    
    return Row(
      children: List.generate(currentGroup.stories.length, (index) {
        final isActive = index == _currentStoryIndex;
        final isCompleted = index < _currentStoryIndex;
        
        return Expanded(
          child: Container(
            height: 4.h,
            margin: EdgeInsets.only(right: index < currentGroup.stories.length - 1 ? 3.w : 0),
            decoration: BoxDecoration(
              color: isCompleted
                  ? themeController.lightPinkColor
                  : themeController.lightPinkColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2.r),
            ),
            child: isActive
                ? AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(2.r),
                        child: LinearProgressIndicator(
                          value: _progressAnimation.value,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            themeController.lightPinkColor,
                          ),
                        ),
                      );
                    },
                  )
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildUserInfo(List<StoryGroup> validStoryGroups) {
    final currentGroup = validStoryGroups[_currentGroupIndex];
    
    // Safety check - if no stories, return empty container
    if (currentGroup.stories.isEmpty || _currentStoryIndex >= currentGroup.stories.length) {
      return Container();
    }
    
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            print('🎯 Profile picture tapped in story viewer for user: ${currentGroup.userId}');
            _viewProfile(currentGroup.userId);
          },
          child: ProfileAvatar(
            imageUrl: currentGroup.avatarUrl,
            borderWidth: 2,
            size: 40,
          ),
        ),
        widthBox(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextConstant(
                title: currentGroup.userName,
                fontWeight: FontWeight.bold,
                color: themeController.whiteColor,
                fontSize: 16,
              ),
              TextConstant(
                title: currentGroup.stories[_currentStoryIndex].timeLabel,
                color: themeController.whiteColor.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ],
          ),
        ),
        // Show delete option only for current user's stories
        if (currentGroup.userId == SupabaseService.currentUser?.id) ...[
          IconButton(
            onPressed: () => _deleteCurrentStory(),
            icon: Icon(
              Icons.delete_outline,
              color: themeController.whiteColor,
              size: 24,
            ),
          ),
          SizedBox(width: 8.w),
        ],
        IconButton(
          onPressed: () => Get.offAll(() => BottombarScreen()), // Navigate directly to main app
          icon: Icon(
            Icons.close,
            color: themeController.whiteColor,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    final currentStory = _getCurrentStory();
    final isOwnStory = currentStory != null && _isCurrentUserStory(currentStory);
    
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 30.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.3),
              Colors.black.withValues(alpha: 0.7),
            ],
            stops: [0.0, 0.7, 1.0],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(left: 15.w, right: 15.w), // Match progress bar exactly
          child: Row(
            children: [
              // Only show message bar for others' stories, not own stories
              if (!isOwnStory) ...[
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          themeController.lightPinkColor.withValues(alpha: 0.15),
                          themeController.purpleColor.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: themeController.lightPinkColor.withValues(alpha: 0.3),
                        width: 1.w,
                      ),
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: themeController.lightPinkColor.withValues(alpha: 0.1),
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.message_outlined,
                          color: themeController.lightPinkColor,
                          size: 20,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            focusNode: _commentFocusNode,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: "Send message...",
                              filled: true,
                              fillColor: Colors.transparent,
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            maxLines: 1,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (value) {
                              if (value.trim().isNotEmpty) {
                                _sendComment();
                              }
                            },
                          ),
                        ),
                        SizedBox(width: 8.w),
                        GestureDetector(
                          onTap: _sendComment,
                          child: Container(
                            width: 24.w,
                            height: 24.w,
                            decoration: BoxDecoration(
                              color: themeController.lightPinkColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
              ],
              SizedBox(width: 12.w),
              Container(
                width: 40.w, // Reduced size
                height: 40.w, // Reduced size
                decoration: BoxDecoration(
                  gradient: _isLiked ? LinearGradient(
                    colors: [
                      themeController.lightPinkColor,
                      themeController.purpleColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ) : null,
                  color: _isLiked ? null : Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: _isLiked ? null : Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: _isLiked ? [
                    BoxShadow(
                      color: themeController.lightPinkColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: IconButton(
                  onPressed: _toggleLike,
                  icon: Icon(
                    Icons.favorite,
                    color: _isLiked ? Colors.white : Colors.white.withValues(alpha: 0.7),
                    size: 20, // Reduced icon size
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isFlameActive(Map<String, dynamic> meta) {
    final expiresRaw = meta['flame_expires_at'];
    if (expiresRaw == null) return false;
    final expires = DateTime.tryParse(expiresRaw.toString())?.toLocal();
    if (expires == null) return false;
    return DateTime.now().isBefore(expires);
  }

  DateTime? _nextMessageTime(Map<String, dynamic> meta) {
    final expiresRaw = meta['flame_expires_at'];
    final expires = expiresRaw == null
        ? DateTime.now()
        : DateTime.tryParse(expiresRaw.toString())?.toLocal() ?? DateTime.now();
    return expires.add(const Duration(days: 1));
  }

  void _showUpgradePrompt(DateTime? nextTime) {
    final formatted = nextTime != null
        ? DateFormat('MMM d • h:mm a').format(nextTime)
        : 'tomorrow';
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: UpgradePromptWidget(
          title: 'Continue Chat',
          message: 'You can send your next message $formatted. Upgrade now to keep the conversation alive.',
          action: 'Upgrade Now',
          limitType: 'message',
        ),
      ),
      barrierDismissible: true,
    );
  }
}
