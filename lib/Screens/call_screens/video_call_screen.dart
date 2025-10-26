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
    localRender.dispose();
    remoteRender.dispose();
    webrtcService.endCall();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // End call if app backgrounds or is about to terminate
      webrtcService.endCall();
    }
  }

  Future<void> _initializeCall() async {
    try {
      // CRITICAL: Initialize renderers FIRST before any callbacks
      print('📞 VideoCallScreen: Initializing renderers...');
      await localRender.initialize();
      await remoteRender.initialize();
      _renderersInitialized = true;
      print('✅ VideoCallScreen: Renderers initialized successfully');

      // CRITICAL: Set up callbacks AFTER renderers are ready
      webrtcService.onRemoteStream = (stream) {
        print('📞 VideoCallScreen: Remote stream callback triggered');
        print('📞 VideoCallScreen: Renderers initialized: $_renderersInitialized');
        print('📞 VideoCallScreen: Stream has video tracks: ${stream.getVideoTracks().length}');
        print('📞 VideoCallScreen: Stream has audio tracks: ${stream.getAudioTracks().length}');
        print('📞 VideoCallScreen: Is Initiator: ${widget.payload.callAction == CallAction.create}');
        
        // CRITICAL: Ensure we're on the main thread and widget is mounted
        if (!mounted) {
          print('⚠️ VideoCallScreen: Widget not mounted, skipping stream attachment');
          return;
        }
        
        // Attach the stream to the renderer
        try {
          // CRITICAL: Ensure video tracks are enabled before attaching
          final videoTracks = stream.getVideoTracks();
          final audioTracks = stream.getAudioTracks();
          
          // CRITICAL DEBUG: Log what videos this user can see
          print('🎯 ===========================================');
          print('🎯 VIDEO DISPLAY DEBUG (${widget.payload.callAction == CallAction.create ? "CALLER" : "RECEIVER"})');
          print('🎯 ===========================================');
          print('🎯 User Role: ${widget.payload.callAction == CallAction.create ? "CALLER" : "RECEIVER"}');
          print('🎯 Call Action: ${widget.payload.callAction}');
          print('🎯 Remote Stream Audio Tracks: ${audioTracks.length}');
          print('🎯 Remote Stream Video Tracks: ${videoTracks.length}');
          
          for (var track in audioTracks) {
            print('🎯 Remote Audio: ${track.id} - enabled: ${track.enabled}, muted: ${track.muted}');
          }
          for (var track in videoTracks) {
            if (!track.enabled) {
              track.enabled = true;
              print('📞 VideoCallScreen: Enabled video track: ${track.id}');
            }
            print('🎯 Remote Video: ${track.id} - enabled: ${track.enabled}, muted: ${track.muted}');
          }
          print('🎯 ===========================================');
          
          // 🔧 CRITICAL FIX: Force stream attachment for BOTH caller and receiver
          remoteRender.srcObject = stream;
          print('✅ VideoCallScreen: Remote stream attached to renderer');
          
          // 🔧 CRITICAL FIX: Force UI rebuild to display the video
          setState(() {
            _hasRemoteStream = true;
          });
          print('✅ VideoCallScreen: UI rebuilt with remote stream');
          
          // 🔧 CRITICAL FIX: Additional safety for both caller and receiver
          // Force a small delay to ensure video is properly displayed
          Future.delayed(Duration(milliseconds: 200), () {
            if (mounted) {
              // 🔧 CRITICAL FIX: Force stream re-attachment for receiver
              if (widget.payload.callAction != CallAction.create) {
                print('📞 VideoCallScreen: RECEIVER - Force re-attaching remote stream');
                remoteRender.srcObject = stream;
              }
              
              setState(() {
                _hasRemoteStream = true;
              });
              print('📞 VideoCallScreen: Safety rebuild completed');
              
              // 🔧 CRITICAL FIX: Force video to play even if tracks are muted
              // This is especially important for web browsers
              Future.delayed(Duration(milliseconds: 500), () {
                if (mounted && _hasRemoteStream) {
                  // 🔧 CRITICAL FIX: Final stream attachment attempt for receiver
                  if (widget.payload.callAction != CallAction.create) {
                    print('📞 VideoCallScreen: RECEIVER - Final stream attachment attempt');
                    remoteRender.srcObject = stream;
                  }
                  
                  // Force another rebuild to ensure video is displayed
                  setState(() {});
                  print('📞 VideoCallScreen: Final video display attempt');
                }
              });
            }
          });
          
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
                        color: themeController.blackColor.withOpacity(0.8),
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
                            title: _getConnectionStatusText(),
                            color: themeController.whiteColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          heightBox(8.h.toInt()),
                          TextConstant(
                            title: 'Please wait while we connect your video call...',
                            color: themeController.whiteColor.withOpacity(0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
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
        icon: Icon(
          icon,
          color: themeController.whiteColor,
          size: 30.sp,
        ),
      ),
    );
  }
}
