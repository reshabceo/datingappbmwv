import 'dart:math';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/widget_constant.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/models/call_models.dart';
import 'package:lovebug/services/webrtc_service.dart';

class AudioCallScreen extends StatefulWidget {
  final CallPayload payload;

  const AudioCallScreen({
    super.key,
    required this.payload,
  });

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  final ThemeController themeController = Get.find<ThemeController>();
  late WebRTCService webrtcService;

  @override
  void initState() {
    super.initState();
    webrtcService = Get.put(WebRTCService());
    _initializeCall();
  }

  @override
  void dispose() {
    webrtcService.endCall();
    super.dispose();
  }

  Future<void> _initializeCall() async {
    // Set up callbacks
    webrtcService.onCallEnded = () {
      Get.back();
    };

    // Initialize the call
    await webrtcService.initializeCall(
      roomId: widget.payload.webrtcRoomId ?? '',
      callType: CallType.audio,
      matchId: widget.payload.matchId ?? '',
      isBffMatch: widget.payload.isBffMatch ?? false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: themeController.transparentColor,
      body: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.black87.withValues(alpha: 0.8),
          ),
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              SizedBox(height: kToolbarHeight),
              Expanded(
                flex: 5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // User avatar
                    Container(
                      width: 128.w,
                      height: 128.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: themeController.getAccentColor(),
                          width: 3.w,
                        ),
                      ),
                      child: ClipOval(
                        child: widget.payload.imageUrl != null
                            ? Image.network(
                                widget.payload.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: themeController.getAccentColor(),
                                    child: Icon(
                                      Icons.person,
                                      color: themeController.whiteColor,
                                      size: 64.sp,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: themeController.getAccentColor(),
                                child: Icon(
                                  Icons.person,
                                  color: themeController.whiteColor,
                                  size: 64.sp,
                                ),
                              ),
                      ),
                    ),
                    heightBox(36.h.toInt()),
                    TextConstant(
                      title: "Audio call",
                      fontSize: 16,
                      color: themeController.whiteColor,
                      fontWeight: FontWeight.w400,
                    ),
                    heightBox(8.h.toInt()),
                    TextConstant(
                      title: widget.payload.username ?? widget.payload.name ?? 'Unknown',
                      fontSize: 24,
                      color: themeController.whiteColor,
                      fontWeight: FontWeight.w500,
                    ),
                    heightBox(16.h.toInt()),
                    Obx(() {
                      String statusText = 'Connecting...';
                      if (webrtcService.callState == CallState.connected) {
                        statusText = 'Connected';
                      } else if (webrtcService.callState == CallState.disconnected) {
                        statusText = 'Call ended';
                      } else if (webrtcService.callState == CallState.failed) {
                        statusText = 'Call failed';
                      }
                      
                      return TextConstant(
                        title: statusText,
                        fontSize: 14,
                        color: themeController.whiteColor.withValues(alpha: 0.8),
                      );
                    }),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Mute button
                      _buildAudioControlButton(
                        icon: CupertinoIcons.mic,
                        onPressed: () {
                          webrtcService.toggleMute();
                        },
                        isActive: !webrtcService.isMuted,
                      ),
                      
                      // End call button
                      _buildAudioControlButton(
                        icon: CupertinoIcons.phone_down_fill,
                        onPressed: () {
                          webrtcService.endCall();
                          Get.back();
                        },
                        isEndCall: true,
                      ),
                      
                      // Speaker button
                      _buildAudioControlButton(
                        icon: CupertinoIcons.speaker_2,
                        onPressed: () {
                          webrtcService.toggleSpeaker();
                        },
                        isActive: webrtcService.isSpeakerEnabled,
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = true,
    bool isEndCall = false,
  }) {
    return Container(
      height: isEndCall ? 64.h : 56.h,
      width: isEndCall ? 64.w : 56.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isEndCall 
            ? Colors.red
            : isActive 
                ? themeController.getAccentColor()
                : Colors.grey.withValues(alpha: 0.2),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: themeController.whiteColor,
          size: isEndCall ? 36.sp : 24.sp,
        ),
      ),
    );
  }
}

