import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lovebug/models/audio_message.dart';
import 'package:lovebug/services/audio_recording_service.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/widget_constant.dart';

class AudioMessageBubble extends StatefulWidget {
  final AudioMessage audioMessage;
  final bool isMe;
  final String? userImage;
  final String? otherUserImage;
  final bool isBffMatch;

  const AudioMessageBubble({
    Key? key,
    required this.audioMessage,
    required this.isMe,
    this.userImage,
    this.otherUserImage,
    this.isBffMatch = false,
  }) : super(key: key);

  @override
  State<AudioMessageBubble> createState() => _AudioMessageBubbleState();
}

class _AudioMessageBubbleState extends State<AudioMessageBubble>
    with TickerProviderStateMixin {
  final ThemeController themeController = Get.find<ThemeController>();
  
  bool _isPlaying = false;
  Duration _playbackPosition = Duration.zero;
  Duration _playbackDuration = Duration.zero;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _completeSubscription;

  @override
  void initState() {
    super.initState();
    _setupAudioListeners();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _completeSubscription?.cancel();
    super.dispose();
  }

  void _setupAudioListeners() {
    // Listen to playback position changes
    AudioRecordingService.onPlaybackPositionChanged = (position, duration) {
      if (mounted) {
        setState(() {
          _playbackPosition = position;
          _playbackDuration = duration;
        });
      }
    };

    // Listen to playback state changes
    AudioRecordingService.onPlaybackStarted = () {
      if (mounted) {
        setState(() {
          _isPlaying = true;
        });
      }
    };

    AudioRecordingService.onPlaybackStopped = () {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _playbackPosition = Duration.zero;
        });
      }
    };
  }

  Future<void> _togglePlayback() async {
    try {
      if (_isPlaying) {
        await AudioRecordingService.pausePlayback();
      } else {
        if (_playbackPosition > Duration.zero) {
          await AudioRecordingService.resumePlayback();
        } else {
          await AudioRecordingService.playAudio(widget.audioMessage.audioUrl);
        }
      }
    } catch (e) {
      print('❌ Error toggling audio playback: $e');
      Get.snackbar('Error', 'Failed to play audio message');
    }
  }

  double get _playbackProgress {
    if (_playbackDuration.inMilliseconds == 0) return 0.0;
    return _playbackPosition.inMilliseconds / _playbackDuration.inMilliseconds;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 4.h,
      ),
      child: Row(
        mainAxisAlignment: widget.isMe 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Other user's avatar (only for received messages)
          if (!widget.isMe) ...[
            _buildAvatar(),
            widthBox(8),
          ],
          
          // Audio message bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: Get.width * 0.7,
                minWidth: 200.w,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 12.h,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.isMe
                      ? (widget.isBffMatch
                          ? [themeController.bffPrimaryColor, themeController.bffSecondaryColor]
                          : [themeController.getAccentColor(), themeController.getSecondaryColor()])
                      : [themeController.whiteColor.withOpacity(0.1), themeController.whiteColor.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18.r),
                  topRight: Radius.circular(18.r),
                  bottomLeft: Radius.circular(widget.isMe ? 18.r : 4.r),
                  bottomRight: Radius.circular(widget.isMe ? 4.r : 18.r),
                ),
                border: Border.all(
                  color: widget.isMe
                      ? Colors.transparent
                      : themeController.whiteColor.withOpacity(0.2),
                  width: 1.w,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.isMe
                        ? themeController.getAccentColor().withOpacity(0.3)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Audio controls
                  _buildAudioControls(),
                  
                  // Duration and timestamp
                  SizedBox(height: 8.h),
                  _buildDurationAndTimestamp(),
                ],
              ),
            ),
          ),
          
          // Current user's avatar (only for sent messages)
          if (widget.isMe) ...[
            widthBox(8),
            _buildAvatar(),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final imageUrl = widget.isMe ? widget.userImage : widget.otherUserImage;
    
    return Container(
      width: 32.w,
      height: 32.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: widget.isMe
              ? (widget.isBffMatch
                  ? themeController.bffPrimaryColor
                  : themeController.getAccentColor())
              : themeController.whiteColor.withOpacity(0.3),
          width: 2.w,
        ),
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultAvatar();
                },
              )
            : _buildDefaultAvatar(),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: widget.isMe
              ? (widget.isBffMatch
                  ? [themeController.bffPrimaryColor, themeController.bffSecondaryColor]
                  : [themeController.getAccentColor(), themeController.getSecondaryColor()])
              : [themeController.whiteColor.withOpacity(0.3), themeController.whiteColor.withOpacity(0.1)],
        ),
      ),
      child: Icon(
        Icons.person,
        color: widget.isMe ? Colors.white : themeController.whiteColor,
        size: 16.sp,
      ),
    );
  }

  Widget _buildAudioControls() {
    return Row(
      children: [
        // Play/Pause button
        GestureDetector(
          onTap: _togglePlayback,
          child: Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isMe
                  ? Colors.white.withOpacity(0.2)
                  : themeController.getAccentColor().withOpacity(0.2),
            ),
            child: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: widget.isMe
                  ? Colors.white
                  : themeController.getAccentColor(),
              size: 20.sp,
            ),
          ),
        ),
        
        SizedBox(width: 12.w),
        
        // Progress bar and duration
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress bar
              Container(
                height: 4.h,
                decoration: BoxDecoration(
                  color: widget.isMe
                      ? Colors.white.withOpacity(0.3)
                      : themeController.getAccentColor().withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2.r),
                ),
                child: Stack(
                  children: [
                    // Progress indicator
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _playbackProgress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: widget.isMe
                              ? Colors.white
                              : themeController.getAccentColor(),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 4.h),
              
              // Duration text
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextConstant(
                    title: AudioRecordingService.formatDuration(_playbackPosition),
                    fontSize: 12,
                    color: widget.isMe
                        ? Colors.white.withOpacity(0.8)
                        : themeController.whiteColor.withOpacity(0.7),
                  ),
                  TextConstant(
                    title: widget.audioMessage.formattedDuration,
                    fontSize: 12,
                    color: widget.isMe
                        ? Colors.white.withOpacity(0.8)
                        : themeController.whiteColor.withOpacity(0.7),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        SizedBox(width: 8.w),
        
        // Microphone icon
        Icon(
          Icons.mic,
          color: widget.isMe
              ? Colors.white.withOpacity(0.7)
              : themeController.getAccentColor().withOpacity(0.7),
          size: 16.sp,
        ),
      ],
    );
  }

  Widget _buildDurationAndTimestamp() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // File size
        TextConstant(
          title: widget.audioMessage.formattedFileSize,
          fontSize: 10,
          color: widget.isMe
              ? Colors.white.withOpacity(0.6)
              : themeController.whiteColor.withOpacity(0.5),
        ),
        
        // Timestamp
        TextConstant(
          title: _formatTimestamp(widget.audioMessage.createdAt),
          fontSize: 10,
          color: widget.isMe
              ? Colors.white.withOpacity(0.6)
              : themeController.whiteColor.withOpacity(0.5),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
