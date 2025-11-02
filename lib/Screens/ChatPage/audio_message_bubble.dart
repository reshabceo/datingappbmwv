import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  final bool isSelected;
  final bool isSelectionMode;
  final bool isSelectable;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const AudioMessageBubble({
    Key? key,
    required this.audioMessage,
    required this.isMe,
    this.userImage,
    this.otherUserImage,
    this.isBffMatch = false,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.isSelectable = false,
    this.onTap,
    this.onLongPress,
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

  // Listener handles to deregister later
  void Function(Duration, Duration)? _onPlaybackPos;
  VoidCallback? _onPlaybackStart;
  VoidCallback? _onPlaybackStop;

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
    // Remove playback listeners
    if (_onPlaybackPos != null || _onPlaybackStart != null || _onPlaybackStop != null) {
      AudioRecordingService.removePlaybackListeners(
        onPosition: _onPlaybackPos,
        onStarted: _onPlaybackStart,
        onStopped: _onPlaybackStop,
      );
    }
    super.dispose();
  }

  void _setupAudioListeners() {
    _onPlaybackPos = (position, duration) {
      if (!mounted) return;
      final isThisAudio = AudioRecordingService.currentAudioUrl == widget.audioMessage.audioUrl;
      setState(() {
        if (isThisAudio) {
          _playbackPosition = position;
          _playbackDuration = duration;
        } else {
          _isPlaying = false;
        }
      });
    };
    _onPlaybackStart = () {
      if (!mounted) return;
      setState(() {
        _isPlaying = AudioRecordingService.currentAudioUrl == widget.audioMessage.audioUrl;
      });
    };
    _onPlaybackStop = () {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _playbackPosition = Duration.zero;
      });
    };
    AudioRecordingService.addPlaybackListeners(
      onPosition: _onPlaybackPos,
      onStarted: _onPlaybackStart,
      onStopped: _onPlaybackStop,
    );
  }

  Future<void> _togglePlayback() async {
    try {
      print('🔊 DEBUG: Tapped audio bubble for URL: ${widget.audioMessage.audioUrl}');
      if (_isPlaying) {
        await AudioRecordingService.pausePlayback();
      } else {
        // If we have progress AND it's the same audio as the current one, resume; otherwise start the requested audio
        final isSameAudio = AudioRecordingService.currentAudioUrl == widget.audioMessage.audioUrl;
        if (_playbackPosition > Duration.zero && isSameAudio) {
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
    if (widget.audioMessage.deletedForEveryone) {
      return _buildDeletedPlaceholder();
    }

    final Color accentColor = widget.isBffMatch
        ? themeController.bffPrimaryColor
        : themeController.getAccentColor();

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.isSelectable ? widget.onLongPress : null,
      behavior: HitTestBehavior.translucent,
      child: Container(
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
            child: () {
              final bool showSelection = widget.isSelectionMode && widget.isSelected;
              
              final LinearGradient bubbleGradient = showSelection
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor.withOpacity(widget.isMe ? 0.85 : 0.6),
                        accentColor.withOpacity(widget.isMe ? 0.65 : 0.48),
                      ],
                    )
                  : LinearGradient(
                      colors: widget.isMe
                          ? (widget.isBffMatch
                              ? [themeController.bffPrimaryColor, themeController.bffSecondaryColor]
                              : [themeController.getAccentColor(), themeController.getSecondaryColor()])
                          : [themeController.whiteColor.withOpacity(0.12), themeController.whiteColor.withOpacity(0.06)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    );

              final Color borderColor = showSelection
                  ? accentColor
                  : themeController.whiteColor.withOpacity(widget.isMe ? 0.08 : 0.18);
              
              return Container(
                constraints: BoxConstraints(
                  maxWidth: Get.width * 0.7,
                  minWidth: 200.w,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
                decoration: BoxDecoration(
                  gradient: bubbleGradient,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18.r),
                    topRight: Radius.circular(18.r),
                    bottomLeft: Radius.circular(widget.isMe ? 18.r : 4.r),
                    bottomRight: Radius.circular(widget.isMe ? 4.r : 18.r),
                  ),
                  border: Border.all(
                    color: borderColor,
                    width: showSelection ? 2.w : 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (showSelection
                              ? accentColor
                              : widget.isMe
                                  ? themeController.getAccentColor()
                                  : Colors.black)
                          .withOpacity(showSelection ? 0.35 : 0.14),
                      blurRadius: showSelection ? 18 : 9,
                      offset: Offset(0, showSelection ? 6 : 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAudioControls(),
                    SizedBox(height: 8.h),
                    _buildDurationAndTimestamp(),
                  ],
                ),
              );
            }(),
          ),
          
          // Current user's avatar (only for sent messages)
          if (widget.isMe) ...[
            widthBox(8),
            _buildAvatar(),
          ],
        ],
      ),
    ),
    );
  }

  Widget _buildDeletedPlaceholder() {
    final Color accentColor = widget.isBffMatch
        ? themeController.bffPrimaryColor
        : themeController.getAccentColor();

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.isSelectable ? widget.onLongPress : null,
      behavior: HitTestBehavior.translucent,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 4.h,
        ),
        child: Row(
          mainAxisAlignment: widget.isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            if (!widget.isMe) ...[
              _buildAvatar(),
              widthBox(8),
            ],
            Flexible(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: themeController.greyColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: widget.isSelected ? accentColor : themeController.whiteColor.withOpacity(0.15),
                    width: widget.isSelectionMode && widget.isSelected ? 2.w : 1.w,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.block,
                      color: themeController.whiteColor.withOpacity(0.6),
                      size: 16.sp,
                    ),
                    SizedBox(width: 8.w),
                    TextConstant(
                      title: 'This audio message was deleted',
                      color: themeController.whiteColor.withOpacity(0.7),
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ],
                ),
              ),
            ),
            if (widget.isMe) ...[
              widthBox(8),
              _buildAvatar(),
            ],
          ],
        ),
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
    // Mirror text message timestamp formatting to avoid locale/timezone discrepancies
    final ts = timestamp.toLocal();
    final now = DateTime.now();
    final isToday = ts.year == now.year && ts.month == now.month && ts.day == now.day;

    final hour12 = ts.hour == 0 ? 12 : (ts.hour > 12 ? ts.hour - 12 : ts.hour);
    final amPm = ts.hour < 12 ? 'AM' : 'PM';
    final timeString = '${hour12.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')} $amPm';

    if (isToday) {
      return timeString; // e.g., 2:30 PM
    }
    // e.g., 19/10 2:30 PM
    return '${ts.day.toString().padLeft(2, '0')}/${ts.month.toString().padLeft(2, '0')} $timeString';
  }
}
