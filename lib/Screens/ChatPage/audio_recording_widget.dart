import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lovebug/services/audio_recording_service.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/widget_constant.dart';

class AudioRecordingWidget extends StatefulWidget {
  final Function(String audioPath, int duration, int fileSize) onSend;
  final Function() onCancel;

  const AudioRecordingWidget({
    Key? key,
    required this.onSend,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<AudioRecordingWidget> createState() => _AudioRecordingWidgetState();
}

class _AudioRecordingWidgetState extends State<AudioRecordingWidget>
    with TickerProviderStateMixin {
  final ThemeController themeController = Get.find<ThemeController>();
  
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _durationTimer;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startRecording();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _durationTimer?.cancel();
    super.dispose();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _waveController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _startRecording() async {
    try {
      final success = await AudioRecordingService.startRecording();
      if (success) {
        setState(() {
          _isRecording = true;
        });
        
        // Start animations
        _pulseController.repeat(reverse: true);
        _waveController.repeat();
        
        // Start duration timer
        _startDurationTimer();
        
        // Listen to duration changes
        AudioRecordingService.onRecordingDurationChanged = (duration) {
          if (mounted) {
            setState(() {
              _recordingDuration = duration;
            });
          }
        };
      } else {
        widget.onCancel();
      }
    } catch (e) {
      print('❌ Error starting recording: $e');
      widget.onCancel();
    }
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted && _isRecording) {
        setState(() {
          _recordingDuration = Duration(seconds: _recordingDuration.inSeconds + 1);
        });
      }
    });
  }

  Future<void> _stopRecording() async {
    try {
      final audioPath = await AudioRecordingService.stopRecording();
      if (audioPath != null) {
        // Get file size
        final fileSize = await AudioRecordingService.getAudioFileSize(audioPath);
        
        // Stop animations
        _pulseController.stop();
        _waveController.stop();
        
        // Send the audio
        widget.onSend(audioPath, _recordingDuration.inSeconds, fileSize);
      } else {
        widget.onCancel();
      }
    } catch (e) {
      print('❌ Error stopping recording: $e');
      widget.onCancel();
    }
  }

  Future<void> _cancelRecording() async {
    try {
      await AudioRecordingService.cancelRecording();
      
      // Stop animations
      _pulseController.stop();
      _waveController.stop();
      
      widget.onCancel();
    } catch (e) {
      print('❌ Error cancelling recording: $e');
      widget.onCancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeController.getAccentColor().withOpacity(0.1),
            themeController.getSecondaryColor().withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: themeController.getAccentColor().withOpacity(0.3),
          width: 2.w,
        ),
        boxShadow: [
          BoxShadow(
            color: themeController.getAccentColor().withOpacity(0.2),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Recording indicator and controls
          Row(
            children: [
              // Recording button with animation
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isRecording ? _pulseAnimation.value : 1.0,
                    child: GestureDetector(
                      onTap: _isRecording ? _stopRecording : _startRecording,
                      child: Container(
                        width: 50.w,
                        height: 50.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: _isRecording
                                ? [Colors.red, Colors.red.shade700]
                                : [themeController.getAccentColor(), themeController.getSecondaryColor()],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_isRecording ? Colors.red : themeController.getAccentColor()).withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop : Icons.mic,
                          color: Colors.white,
                          size: 24.sp,
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              SizedBox(width: 16.w),
              
              // Waveform animation
              Expanded(
                child: _buildWaveform(),
              ),
              
              SizedBox(width: 16.w),
              
              // Cancel button
              GestureDetector(
                onTap: _cancelRecording,
                child: Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withOpacity(0.1),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                      width: 2.w,
                    ),
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.red,
                    size: 20.sp,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12.h),
          
          // Duration and instructions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Duration
              TextConstant(
                title: AudioRecordingService.formatDuration(_recordingDuration),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: themeController.getAccentColor(),
              ),
              
              // Instructions
              TextConstant(
                title: _isRecording ? 'Tap to stop' : 'Tap to record',
                fontSize: 12,
                color: themeController.whiteColor.withOpacity(0.7),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaveform() {
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(20, (index) {
            final delay = (index * 0.1) % 1.0;
            final waveHeight = _isRecording 
                ? (0.3 + 0.7 * (1.0 - (delay - _waveAnimation.value).abs()).clamp(0.0, 1.0))
                : 0.3;
            
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 1.w),
              width: 3.w,
              height: (20.h * waveHeight).clamp(4.h, 20.h),
              decoration: BoxDecoration(
                color: themeController.getAccentColor().withOpacity(0.6),
                borderRadius: BorderRadius.circular(2.r),
              ),
            );
          }),
        );
      },
    );
  }
}
