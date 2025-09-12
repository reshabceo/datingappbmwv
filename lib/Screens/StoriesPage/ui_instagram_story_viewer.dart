import 'package:boliler_plate/Common/text_constant.dart';
import 'package:boliler_plate/Common/widget_constant.dart';
import 'package:boliler_plate/Screens/StoriesPage/controller_stories_screen.dart';
import 'package:boliler_plate/ThemeController/theme_controller.dart';
import 'package:boliler_plate/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class InstagramStoryViewer extends StatefulWidget {
  final List<StoryGroup> storyGroups;
  final int initialIndex;

  const InstagramStoryViewer({
    super.key,
    required this.storyGroups,
    required this.initialIndex,
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
        
        // Send message to chat with story context
        print('DEBUG: Sending message to match $matchId: "$comment"');
        await SupabaseService.sendMessage(
          matchId: matchId,
          content: comment,
          storyId: currentStory.id,
          storyUserName: currentStory.userName,
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
    if (_currentGroupIndex >= 0 && _currentGroupIndex < widget.storyGroups.length) {
      final storyGroup = widget.storyGroups[_currentGroupIndex];
      if (_currentStoryIndex >= 0 && _currentStoryIndex < storyGroup.stories.length) {
        return storyGroup.stories[_currentStoryIndex];
      }
    }
    return null;
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
    final currentGroup = widget.storyGroups[_currentGroupIndex];
    print('DEBUG: Next story - currentGroupIndex: $_currentGroupIndex, currentStoryIndex: $_currentStoryIndex, total stories: ${currentGroup.stories.length}');
    
    if (_currentStoryIndex < currentGroup.stories.length - 1) {
      // Move to next story of current user
      setState(() {
        _currentStoryIndex++;
      });
      print('DEBUG: Moving to next story of current user: $_currentStoryIndex');
      _startStoryTimer();
    } else if (_currentGroupIndex < widget.storyGroups.length - 1) {
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
    }
  }

  void _previousStory() {
    print('DEBUG: Previous story - currentGroupIndex: $_currentGroupIndex, currentStoryIndex: $_currentStoryIndex');
    
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
        _currentStoryIndex = widget.storyGroups[_currentGroupIndex].stories.length - 1;
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
          
          // More responsive swipe down detection
          if (velocity > 100 || (velocity > 50 && _panDelta > 20)) {
            // Swipe down to exit
            print('DEBUG: Swipe down to exit');
            Get.back();
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
              itemCount: widget.storyGroups.length,
              itemBuilder: (context, groupIndex) {
                final storyGroup = widget.storyGroups[groupIndex];
                return _buildStoryContent(storyGroup);
              },
            ),
            
            // Top Progress Bars
            Positioned(
              top: 50.h,
              left: 15.w,
              right: 15.w,
              child: _buildProgressBars(),
            ),
            
            // Top User Info
            Positioned(
              top: 80.h,
              left: 15.w,
              right: 15.w,
              child: _buildUserInfo(),
            ),
            
            // Bottom Actions
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryContent(StoryGroup storyGroup) {
    final currentStory = storyGroup.stories[_currentStoryIndex];
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(currentStory.mediaUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildProgressBars() {
    final currentGroup = widget.storyGroups[_currentGroupIndex];
    
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

  Widget _buildUserInfo() {
    final currentGroup = widget.storyGroups[_currentGroupIndex];
    
    return Row(
      children: [
        ProfileAvatar(
          imageUrl: currentGroup.avatarUrl,
          borderWidth: 2,
          size: 40,
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
        IconButton(
          onPressed: () => Get.back(),
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
}
