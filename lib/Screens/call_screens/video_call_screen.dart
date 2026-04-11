import 'dart:ui';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/widget_constant.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/models/call_models.dart';
import 'package:lovebug/services/webrtc_service.dart';
// Removed platform detection imports since calls are app-only

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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  RTCVideoRenderer localRender = RTCVideoRenderer();
  RTCVideoRenderer remoteRender = RTCVideoRenderer();
  
  final ThemeController themeController = Get.find<ThemeController>();
  late WebRTCService webrtcService;
  
  // Track whether remote video stream has been attached
  bool _hasRemoteStream = false;
  // Track whether local preview has been attached
  bool _hasLocalStream = false;
  bool _renderersInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    webrtcService = Get.put(WebRTCService());
    _initializeCall();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    
    // CRITICAL FIX: Stop video renderers before disposing to prevent EglRenderer errors
    try {
      if (_renderersInitialized) {
        // Clear video sources first
        localRender.srcObject = null;
        remoteRender.srcObject = null;
        
        // Wait a moment for cleanup
        Future.delayed(Duration(milliseconds: 100), () {
          try {
            localRender.dispose();
            remoteRender.dispose();
            print('✅ Video renderers disposed successfully');
          } catch (e) {
            print('⚠️ Error disposing video renderers: $e');
          }
        });
      }
    } catch (e) {
      print('⚠️ Error in video renderer cleanup: $e');
    }
    
    // End the call after renderer cleanup
    webrtcService.endCall();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // iOS: DO NOT auto-end call on inactivity; CallKit/OS manages call UI
      // Android: allow auto-end to avoid dangling call UIs
      if (Platform.isAndroid) {
        webrtcService.endCall();
      }
    }
  }

  Future<void> _initializeCall() async {
    try {
      // CRITICAL FIX: Reset call state before initializing
      // Note: Call state will be reset by the WebRTC service initialization
      print('📞 VideoCallScreen: Preparing to initialize call');
      
      // CRITICAL: Initialize renderers FIRST before any callbacks
      print('📞 VideoCallScreen: Initializing renderers...');
      await localRender.initialize();
      await remoteRender.initialize();
      _renderersInitialized = true;
      print('✅ VideoCallScreen: Renderers initialized successfully');

      // CRITICAL: Set up callbacks AFTER renderers are ready
      webrtcService.onRemoteStream = (stream) {
        print('📞 VideoCallScreen: Remote stream callback triggered');
        
        // CRITICAL: Ensure we\'re on the main thread and widget is mounted
        if (!mounted) {
          print('⚠️ VideoCallScreen: Widget not mounted, skipping stream attachment');
          return;
        }
        
        // Attach the stream to the renderer
        try {
          // 🔧 CRITICAL FIX: Force stream attachment
          remoteRender.srcObject = stream;
          print('✅ VideoCallScreen: Remote stream attached to renderer');
          
          setState(() {
            _hasRemoteStream = true;
          });
          
          // 🔧 AGGRESSIVE FIX: Multiple delayed re-attachments to ensure video appears
          // Some devices take time to sync the hardware decoder with the stream
          for (int delay in [500, 1000, 2000, 3000]) {
            Future.delayed(Duration(milliseconds: delay), () {
              if (mounted) {
                if (remoteRender.srcObject == null || !_hasRemoteStream) {
                   print('📞 VideoCallScreen: RE-ATTACHING remote stream ($delay ms)');
                   remoteRender.srcObject = stream;
                   setState(() { _hasRemoteStream = true; });
                }
              }
            });
          }
        } catch (e) {
          print('❌ VideoCallScreen: Error attaching remote stream: $e');
        }
      };
      
      webrtcService.onCallEnded = () {
        if (mounted) {
          Get.back();
        }
      };

      // Initialize the call
      final fallbackRoomId = (widget.payload.webrtcRoomId != null && widget.payload.webrtcRoomId!.isNotEmpty)
          ? widget.payload.webrtcRoomId!
          : (widget.payload.notificationId ?? '');
      
      // Determine if this user is the call initiator (caller)
      // If callAction is 'create', we are the initiator
      final isInitiator = widget.payload.callAction == CallAction.create;

      print('📞 VideoCallScreen: Initializing as ${isInitiator ? "CALLER" : "RECEIVER"}');

      // Prevent double-initialization if service already started by accept flow
      final alreadyInitialized = webrtcService.callState != CallState.initial || webrtcService.localStream != null;
      if (alreadyInitialized) {
        print('📞 VideoCallScreen: Skipping initializeCall (already initialized)');
      } else {
        await webrtcService.initializeCall(
          roomId: fallbackRoomId,
          callType: CallType.video,
          matchId: widget.payload.matchId ?? '',
          isBffMatch: widget.payload.isBffMatch ?? false,
          isInitiator: isInitiator, // Pass initiator flag
        );
      }

      // Set local stream
      if (webrtcService.localStream != null && mounted) {
        localRender.srcObject = webrtcService.localStream;
        _hasLocalStream = true;
        print('📞 VideoCallScreen: Local stream attached');
      }

      // CRITICAL: If local stream becomes available slightly later (iOS), attach after mount
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!_hasLocalStream && webrtcService.localStream != null && _renderersInitialized) {
          try {
            localRender.srcObject = webrtcService.localStream;
            setState(() {
              _hasLocalStream = true;
            });
            print('✅ VideoCallScreen: Attached cached LOCAL stream after mount');
          } catch (e) {
            print('❌ VideoCallScreen: Failed to attach cached LOCAL stream: $e');
          }
        }
      });

      // One more tiny delayed retry for slow camera startup
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        if (!_hasLocalStream && webrtcService.localStream != null && _renderersInitialized) {
          try {
            localRender.srcObject = webrtcService.localStream;
            setState(() {
              _hasLocalStream = true;
            });
            print('✅ VideoCallScreen: Delayed LOCAL stream attach succeeded');
          } catch (e) {
            print('❌ VideoCallScreen: Delayed LOCAL stream attach failed: $e');
          }
        }
      });

      // CRITICAL: If a remote stream arrived before the widget mounted, attach it now
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final cached = webrtcService.remoteStream;
        if (cached != null && !_hasRemoteStream && _renderersInitialized) {
          try {
            remoteRender.srcObject = cached;
            setState(() {
              _hasRemoteStream = true;
            });
            print('✅ VideoCallScreen: Attached cached remote stream after mount');
          } catch (e) {
            print('❌ VideoCallScreen: Failed to attach cached remote stream: $e');
          }
        }
      });
    } catch (e) {
      print('❌ VideoCallScreen: Initialization error: $e');
      if (mounted) {
        Get.back();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // REMOVED: Platform detection - always use mobile UI since calls are app-only
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        bool isConnected = webrtcService.callState == CallState.connected;
        
        return LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // CRITICAL: Remote video ALWAYS in widget tree (visibility controlled separately)
                // This ensures the video element exists in the DOM for web
                Positioned.fill(
                  child: Opacity(
                    opacity: (isConnected && _hasRemoteStream) ? 1.0 : 0.0,
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      child: RTCVideoView(
                        remoteRender,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        mirror: false,
                      ),
                    ),
                  ),
                ),
                
                // BEAUTIFUL: Profile picture background with pink gradient blur when not connected
                if (!isConnected || !_hasRemoteStream)
                  Positioned.fill(
                    child: _buildProfileBackground(),
                  ),
                
                // Removed verbose debug overlay in production
                
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
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        child: RTCVideoView(
                          localRender,
                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                          mirror: true, // Mirror local video for natural preview
                        ),
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
                      color: Colors.black26.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Camera switch button - always show since calls are app-only
                          _buildCallControlButton(
                            icon: CupertinoIcons.switch_camera_solid,
                            onPressed: () {
                              webrtcService.switchCamera();
                            },
                          ),
                          Obx(() => _buildCallControlButton(
                            icon: CupertinoIcons.videocam_fill,
                            onPressed: () {
                              webrtcService.toggleVideo();
                            },
                            isActive: webrtcService.isVideoEnabled,
                          )),
                          Obx(() => _buildCallControlButton(
                            icon: CupertinoIcons.mic_fill,
                            onPressed: () {
                              webrtcService.toggleMute();
                            },
                            isActive: !webrtcService.isMuted,
                          )),
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
                
                // BEAUTIFUL: Call status and Timer overlay
                Positioned(
                  top: 60.h,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Obx(() {
                      final isConnected = webrtcService.callState == CallState.connected;
                      if (!isConnected) return SizedBox.shrink();
                      
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: TextConstant(
                          title: webrtcService.formattedDuration,
                          color: themeController.whiteColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }),
                  ),
                ),

                // BEAUTIFUL: Enhanced call status overlay (Connecting)
                if (!isConnected)
                  Positioned(
                    bottom: 200.h,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 40.w),
                        padding: EdgeInsets.all(24.w),
                        decoration: BoxDecoration(
                          color: themeController.blackColor.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: themeController.getAccentColor().withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: themeController.getAccentColor().withOpacity(0.1),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40.w,
                              height: 40.w,
                              child: CircularProgressIndicator(
                                color: themeController.getAccentColor(),
                                strokeWidth: 3,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            TextConstant(
                              title: _getConnectionStatusText(),
                              color: themeController.whiteColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            SizedBox(height: 8.h),
                            TextConstant(
                              title: 'Connecting secure video line...',
                              color: themeController.whiteColor.withOpacity(0.8),
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
          },
        );
      }),
    );
  }

  String _getConnectionStatusText() {
    switch (webrtcService.callState) {
      case CallState.connecting:
        return 'Connecting...';
      case CallState.connected:
        return 'Connected';
      case CallState.disconnected:
        return 'Disconnected';
      case CallState.failed:
        return 'Call Failed';
      default:
        return 'Connecting...';
    }
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
        icon: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              icon,
              color: themeController.whiteColor,
              size: 30.sp,
            ),
            // CRITICAL FIX: Add strike-through when inactive (but not for end call button)
            if (!isActive && !isEndCall)
              Positioned(
                child: Container(
                  width: 40.w,
                  height: 3.h,
                  decoration: BoxDecoration(
                    color: themeController.whiteColor,
                    borderRadius: BorderRadius.circular(1.5.r),
                    boxShadow: [
                      BoxShadow(
                        color: themeController.blackColor.withOpacity(0.3),
                        blurRadius: 2,
                        offset: Offset(0, 1),
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

  /// BEAUTIFUL: Build profile picture background with pink gradient blur
  Widget _buildProfileBackground() {
    final otherUserImage = widget.payload.imageUrl;
    final otherUserName = widget.payload.name ?? 'Someone';
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeController.getAccentColor().withOpacity(0.3),
            themeController.getAccentColor().withOpacity(0.1),
            Colors.black.withOpacity(0.8),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Blurred profile picture background
          if (otherUserImage != null && otherUserImage.isNotEmpty)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(otherUserImage),
                    fit: BoxFit.cover,
                  ),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          
          // Pink gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    themeController.getAccentColor().withOpacity(0.4),
                    themeController.getAccentColor().withOpacity(0.2),
                    Colors.black.withOpacity(0.6),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),
          
          // Profile picture in center
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Profile picture
                Container(
                  width: 120.w,
                  height: 120.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: themeController.whiteColor.withOpacity(0.3),
                      width: 3.w,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: themeController.getAccentColor().withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: otherUserImage != null && otherUserImage.isNotEmpty
                        ? Image.network(
                            otherUserImage,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultAvatar(otherUserName);
                            },
                          )
                        : _buildDefaultAvatar(otherUserName),
                  ),
                ),
                
                SizedBox(height: 20.h),
                
                // User name
                TextConstant(
                  title: otherUserName,
                  color: themeController.whiteColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
                
                SizedBox(height: 8.h),
                
                // Call type indicator
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: themeController.getAccentColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: themeController.getAccentColor().withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.payload.callType == CallType.video 
                            ? CupertinoIcons.videocam_fill 
                            : CupertinoIcons.phone_fill,
                        color: themeController.whiteColor,
                        size: 16.sp,
                      ),
                      SizedBox(width: 6.w),
                      TextConstant(
                        title: widget.payload.callType == CallType.video 
                            ? 'Video Call' 
                            : 'Audio Call',
                        color: themeController.whiteColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build default avatar when no image is available
  Widget _buildDefaultAvatar(String name) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeController.getAccentColor(),
            themeController.getAccentColor().withOpacity(0.7),
          ],
        ),
      ),
      child: Center(
        child: TextConstant(
          title: name.isNotEmpty ? name[0].toUpperCase() : '?',
          color: themeController.whiteColor,
          fontSize: 48,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
