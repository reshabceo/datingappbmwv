import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/widget_constant.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/models/call_models.dart';
import 'package:lovebug/services/webrtc_service.dart';

class VideoCallScreen extends StatefulWidget {
  final CallPayload payload;

  const VideoCallScreen({
    super.key,
    required this.payload,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen>
    with SingleTickerProviderStateMixin {
  RTCVideoRenderer localRender = RTCVideoRenderer();
  RTCVideoRenderer remoteRender = RTCVideoRenderer();
  
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
    localRender.dispose();
    remoteRender.dispose();
    webrtcService.endCall();
    super.dispose();
  }

  Future<void> _initializeCall() async {
    await localRender.initialize();
    await remoteRender.initialize();

    // Set up callbacks
    webrtcService.onRemoteStream = (stream) {
      remoteRender.srcObject = stream;
    };
    
    webrtcService.onCallEnded = () {
      Get.back();
    };

    // Initialize the call
    await webrtcService.initializeCall(
      roomId: widget.payload.webrtcRoomId ?? '',
      callType: CallType.video,
      matchId: widget.payload.matchId ?? '',
      isBffMatch: widget.payload.isBffMatch ?? false,
    );

    // Set local stream
    if (webrtcService.localStream != null) {
      localRender.srcObject = webrtcService.localStream;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        bool isConnected = webrtcService.callState == CallState.connected;
        
        return LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // Remote video (full screen when connected)
                if (isConnected)
                  RTCVideoView(
                    remoteRender,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                
                // Local video (picture-in-picture when connected)
                Align(
                  alignment: Alignment.topRight,
                  child: AnimatedContainer(
                    key: UniqueKey(),
                    curve: Curves.easeIn,
                    duration: const Duration(milliseconds: 1600),
                    margin: isConnected
                        ? const EdgeInsets.symmetric(horizontal: 24, vertical: 56)
                        : null,
                    height: isConnected ? 220 : constraints.maxHeight,
                    width: isConnected ? 142 : constraints.maxWidth,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: RTCVideoView(
                        localRender,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    ),
                  ),
                ),
                
                // Call controls
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 74.h,
                    margin: EdgeInsets.symmetric(vertical: 40.h, horizontal: 20.w),
                    decoration: BoxDecoration(
                      color: Colors.black26.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildCallControlButton(
                            icon: CupertinoIcons.switch_camera_solid,
                            onPressed: () {
                              // Switch camera functionality
                            },
                          ),
                          _buildCallControlButton(
                            icon: CupertinoIcons.videocam_fill,
                            onPressed: () {
                              webrtcService.toggleVideo();
                            },
                            isActive: webrtcService.isVideoEnabled,
                          ),
                          _buildCallControlButton(
                            icon: CupertinoIcons.mic_fill,
                            onPressed: () {
                              webrtcService.toggleMute();
                            },
                            isActive: !webrtcService.isMuted,
                          ),
                          _buildCallControlButton(
                            icon: CupertinoIcons.phone_down_fill,
                            onPressed: () {
                              webrtcService.endCall();
                              Get.back();
                            },
                            isEndCall: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Call status overlay
                if (!isConnected)
                  Center(
                    child: Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: themeController.blackColor.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: themeController.getAccentColor(),
                          ),
                          heightBox(16.h.toInt()),
                          TextConstant(
                            title: 'Connecting...',
                            color: themeController.whiteColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      }),
    );
  }

  Widget _buildCallControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = true,
    bool isEndCall = false,
  }) {
    return Container(
      height: 54.h,
      width: 54.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isEndCall 
            ? Colors.red
            : isActive 
                ? themeController.getAccentColor()
                : Colors.grey.withValues(alpha: 0.5),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: themeController.whiteColor,
          size: 30.sp,
        ),
      ),
    );
  }
}
