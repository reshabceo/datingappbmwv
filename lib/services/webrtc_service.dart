import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:lovebug/models/call_models.dart';
import 'package:lovebug/services/call_debug_service.dart';
import 'package:lovebug/services/push_notification_service.dart';
import 'package:lovebug/services/audio_recording_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:lovebug/services/notification_clearing_service.dart';

class WebRTCService extends GetxController {
  static WebRTCService get instance => Get.find<WebRTCService>();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  String? _currentCallId;
  String? _currentMatchId;
  bool _isInitiator = false; // Track if this peer is the initiator
  bool _isEnding = false; // Guard to prevent repeated cleanup
  bool _isInitialized = false; // Track if service is initialized
  String? _lastDbState; // Deduplicate DB state updates
  
  final Rx<CallState> _callState = CallState.initial.obs;
  final RxBool _isMuted = false.obs;
  final RxBool _isVideoEnabled = true.obs;
  final RxBool _isSpeakerEnabled = false.obs;

  // Stream subscriptions for real-time updates
  StreamSubscription? _answerSubscription;
  StreamSubscription? _iceCandidatesSubscription;
  StreamSubscription? _callStateSubscription;
  StreamSubscription? _callSessionStateSubscription; // call_sessions table listener
  
  // Queued ICE candidates for when remote description isn't set yet
  List<Map<String, dynamic>>? _queuedIceCandidates;
  bool _readyToAddRemoteCandidates = false; // flips true after setRemoteDescription
  Timer? _queuedIceFlushTimer; // small delay before batch flush
  
  // ICE connection timeout
  Timer? _iceConnectionTimeout;
  Timer? _iceQuickFallbackTimer; // quick restart timer when stuck in checking
  Timer? _noAnswerTimeout; // auto-cancel if no answer within window
  Timer? _androidRetryTimer; // Android-specific retry timer
  int _androidRetryCount = 0; // Track Android retry attempts

  // Flags to guard duplicate operations
  bool _answerApplied = false;

  // TURN diagnostics
  bool _hasRelayCandidate = false; // set true if we see a typ relay local candidate
  Timer? _relayWarnTimer;

  // Callbacks
  Function(MediaStream stream)? onRemoteStream;
  VoidCallback? onCallEnded;
  Function(CallState state)? onCallStateChanged;

  // Getters
  CallState get callState => _callState.value;
  bool get isMuted => _isMuted.value;
  bool get isVideoEnabled => _isVideoEnabled.value;
  bool get isSpeakerEnabled => _isSpeakerEnabled.value;
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;

  // Platform detection for WebRTC compatibility
  bool get _isIOS => !kIsWeb && Platform.isIOS;
  bool get _isAndroid => !kIsWeb && Platform.isAndroid;
  bool get _isWeb => kIsWeb;

  // WebRTC Configuration with STUN and TURN servers
  // Optimized for iOS to Android compatibility
  final Map<String, dynamic> _webrtcConfiguration = {
    'iceServers': [
      // STUN servers for NAT discovery (reduced to 3 for better performance)
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun.cloudflare.com:3478'},
      // Free TURN server for relay when direct connection fails
      // NOTE: For production, replace with your own TURN server (Coturn/Twilio/Xirsys)
      // Using multiple ports/protocols for redundancy
      {
        'urls': 'turn:openrelay.metered.ca:80',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
      {
        'urls': 'turn:openrelay.metered.ca:443',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
      {
        'urls': 'turn:openrelay.metered.ca:443?transport=tcp',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
    ],
    'sdpSemantics': 'unified-plan',
    'iceTransportPolicy': 'all', // Use all ICE candidates (host, srflx, relay)
    'iceCandidatePoolSize': 10, // Pre-gather ICE candidates for faster connection
    'bundlePolicy': 'balanced', // More compatible bundle policy
    'rtcpMuxPolicy': 'require', // Require RTCP multiplexing
  };

  @override
  void onInit() {
    super.onInit();
    _callState.listen((state) {
      onCallStateChanged?.call(state);
    });
  }

  /// Initialize call as either CALLER or RECEIVER
  Future<void> initializeCall({
    required String roomId,
    required CallType callType,
    required String matchId,
    required bool isBffMatch,
    bool isInitiator = false, // NEW: explicit initiator flag
  }) async {
    try {
      print('📞 WebRTCService.initializeCall() called');
      print('📞 Parameters: roomId=$roomId, callType=${callType.name}, matchId=$matchId, isBffMatch=$isBffMatch, isInitiator=$isInitiator');
      
      // CRITICAL FIX: Prevent multiple initializations and race conditions
      if (_isEnding) {
        print('⚠️ initializeCall skipped: call is currently ending');
        return;
      }
      
      // CRITICAL FIX: Always reset state before starting new call
      if (_isInitialized && _currentCallId != roomId) {
        print('📞 Resetting service state for new call...');
        await _resetServiceState();
      }
      
      // Strong double-init guard
      if (_peerConnection != null && _currentCallId == roomId) {
        print('⚠️ initializeCall skipped: existing peer connection for same room');
        return;
      }
      
      // If another call is in progress with a different id, end it first
      if (_peerConnection != null && _currentCallId != null && _currentCallId != roomId) {
        print('⚠️ Existing call detected (${_currentCallId}), ending before starting new call $roomId');
        await endCall();
        // Wait for cleanup to complete
        await Future.delayed(Duration(milliseconds: 500));
      }
      // Cancel any lingering subscriptions before fresh start
      await _answerSubscription?.cancel();
      await _iceCandidatesSubscription?.cancel();
      await _callStateSubscription?.cancel();
      await _callSessionStateSubscription?.cancel();
      
      // CRITICAL DEBUG: Log call initiation details
      print('🎯 ===========================================');
      print('🎯 CALL INITIATION DEBUG');
      print('🎯 ===========================================');
      print('🎯 User Role: ${isInitiator ? "CALLER (Initiator)" : "RECEIVER (Accepter)"}');
      print('🎯 Call Type: ${callType == CallType.video ? "VIDEO" : "AUDIO"}');
      print('🎯 Room ID: $roomId');
      print('🎯 Match ID: $matchId');
      print('🎯 BFF Match: $isBffMatch');
      print('🎯 ===========================================');
      
      _currentCallId = roomId;
      _currentMatchId = matchId;
      _isInitiator = isInitiator;
      _answerApplied = false;
      _readyToAddRemoteCandidates = false;
      _queuedIceCandidates = [];
      _hasRelayCandidate = false;
      _relayWarnTimer?.cancel();
      _relayWarnTimer = Timer(const Duration(seconds: 5), () {
        if (!_hasRelayCandidate) {
          print('⚠️ No TURN relay candidates observed within 5s; connectivity may fail under NAT');
        }
      });
      
      print('📞 Initializing WebRTC call as ${isInitiator ? "CALLER" : "RECEIVER"}');
      print('📞 Room ID: $roomId');
      print('📞 Call Type: ${callType.name}');

      // Start listening to call_sessions state (declined/canceled/ended)
      _listenForCallSessionState(roomId);
      
      await CallDebugService.logCallEvent(
        event: 'call_initialization_started',
        callId: roomId,
        data: {
          'call_type': callType.name,
          'match_id': matchId,
          'is_bff_match': isBffMatch,
          'is_initiator': isInitiator,
        },
      );
      
      _updateCallState(CallState.connecting);
      
      // CRITICAL FIX: Pre-request permissions before initializing stream
      await _preRequestPermissions(callType);
      
      // Initialize local stream
      await _initializeLocalStream(callType);
      
      // Create peer connection
      _peerConnection = await createPeerConnection(_webrtcConfiguration);
      _registerPeerConnectionListeners();
      
      await CallDebugService.logWebRTCEvent(
        event: 'peer_connection_created',
        callId: roomId,
        webrtcData: {
          'configuration': _webrtcConfiguration,
          'is_initiator': isInitiator,
        },
      );
      
      // Add local stream tracks
      _localStream?.getTracks().forEach((track) {
        _peerConnection?.addTrack(track, _localStream!);
      });

      // Set up ICE candidate handling (no artificial delays)
      _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) async {
        if (candidate.candidate != null) {
          print('🧊 Local ICE candidate generated:');
          print('   - Candidate (first 80 chars): ${candidate.candidate?.substring(0, candidate.candidate!.length > 80 ? 80 : candidate.candidate!.length)}...');
          print('   - SDP MID: ${candidate.sdpMid}');
          print('   - SDP MLine Index: ${candidate.sdpMLineIndex}');
          final cStr = candidate.candidate ?? '';
          if (cStr.contains(' typ relay')) {
            _hasRelayCandidate = true;
            print('✅ TURN relay candidate generated');
          }
          _handleIceCandidate(candidate, roomId);
        } else {
          print('🧊 ICE candidate gathering complete (null candidate received)');
        }
      };

      // Listen for remote stream
      _peerConnection?.onTrack = (RTCTrackEvent event) {
        print('📞 Remote track received: ${event.track.kind}');
        _handleRemoteTrack(event);
      };

      // Monitor ICE connection state changes
      _peerConnection?.onIceConnectionState = (RTCIceConnectionState state) {
        print('🧊 ICE Connection State: ${state.toString()}');
        if (state == RTCIceConnectionState.RTCIceConnectionStateConnected) {
          print('✅ ICE connection established successfully!');
          _updateCallState(CallState.connected);
        } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
          print('❌ ICE connection failed!');
          _updateCallState(CallState.failed);
        } else if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
          print('⚠️ ICE connection disconnected');
        } else if (state == RTCIceConnectionState.RTCIceConnectionStateClosed) {
          print('🔒 ICE connection closed');
        }
      };

      // Monitor peer connection state changes
      _peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
        print('🔗 Peer Connection State: ${state.toString()}');
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          print('✅ Peer connection fully established!');
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          print('❌ Peer connection failed!');
        }
      };

      // Different flow for caller vs receiver
      if (_isInitiator) {
        // CALLER: Create offer immediately
        print('📞 WebRTCService: About to call _createRoom() as CALLER');
        await _createRoom(roomId);
        print('📞 WebRTCService: _createRoom() completed');
      } else {
        // RECEIVER: Join existing room
        print('📞 WebRTCService: About to call _joinRoom() as RECEIVER');
        await _joinRoom(roomId);
        print('📞 WebRTCService: _joinRoom() completed');
      }
      
    } catch (e) {
      print('❌ Error initializing call: $e');
      
      // CRITICAL FIX: Don't fail the call for permission errors
      // Only fail for critical WebRTC errors
      if (e.toString().contains('Permission denied') || 
          e.toString().contains('NotAllowedError') ||
          e.toString().contains('getUserMedia')) {
        print('📞 Permission-related error - call will continue without media');
        // Don't update call state to failed for permission issues
        return;
      }
      
      // For other critical errors, fail the call
      _updateCallState(CallState.failed);
    }
  }

  /// Pre-request permissions before initializing the call
  /// This prevents permission dialogs from interrupting the call flow
  Future<void> _preRequestPermissions(CallType callType) async {
    try {
      print('🔐 DEBUG: Pre-requesting permissions for ${callType.name} call...');
      
      // Request microphone permission (required for both audio and video calls)
      final micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted) {
        print('🔐 DEBUG: Requesting microphone permission...');
        final micResult = await Permission.microphone.request();
        print('🔐 DEBUG: Microphone permission result: $micResult');
      } else {
        print('🔐 DEBUG: Microphone permission already granted');
      }
      
      // Request camera permission (only for video calls)
      if (callType == CallType.video) {
        final cameraStatus = await Permission.camera.status;
        if (!cameraStatus.isGranted) {
          print('🔐 DEBUG: Requesting camera permission...');
          final cameraResult = await Permission.camera.request();
          print('🔐 DEBUG: Camera permission result: $cameraResult');
        } else {
          print('🔐 DEBUG: Camera permission already granted');
        }
      }
      
      print('🔐 DEBUG: Permission pre-request completed');
    } catch (e) {
      print('❌ DEBUG: Error pre-requesting permissions: $e');
      // Don't fail the call for permission errors - let it continue
    }
  }

  Future<void> _initializeLocalStream(CallType callType) async {
    try {
      // Platform-optimized constraints for cross-platform compatibility
      final constraints = _getPlatformOptimizedConstraints(callType);
      
      print('📞 Getting user media with constraints: $constraints');
      
      // CRITICAL FIX: Maintain call state during permission request
      // Don't let permission dialog reset the call state
      try {
        _localStream = await webrtc.navigator.mediaDevices.getUserMedia(constraints);
        print('✅ Local stream obtained successfully');
      } catch (permissionError) {
        print('❌ Permission error during getUserMedia: $permissionError');
        
        // Handle permission errors without resetting call state
        if (permissionError.toString().contains('Permission denied') || 
            permissionError.toString().contains('NotAllowedError') ||
            permissionError.toString().contains('getUserMedia')) {
          print('📞 Permission denied - call will continue but without media');
          print('📞 Call state remains: ${_callState.value}');
          // Don't reset call state - let the call continue
          // The UI can handle showing permission denied message
          return;
        } else {
          // For other errors, still don't reset call state immediately
          print('📞 Media access error - continuing call without local stream');
          print('📞 Call state remains: ${_callState.value}');
          return;
        }
      }
      
      if (_localStream != null) {
        final audioTracks = _localStream!.getAudioTracks();
        final videoTracks = _localStream!.getVideoTracks();
        print('✅ Local stream initialized successfully');
        print('   - Audio tracks: ${audioTracks.length}');
        print('   - Video tracks: ${videoTracks.length}');
        
        // CRITICAL DEBUG: Log local stream details
        print('🎯 ===========================================');
        print('🎯 LOCAL STREAM DEBUG (${_isInitiator ? "CALLER" : "RECEIVER"})');
        print('🎯 ===========================================');
        
        for (var track in audioTracks) {
          track.enabled = true;
          print('🎯 Local Audio: ${track.id} - enabled: ${track.enabled}, muted: ${track.muted}');
        }
        for (var track in videoTracks) {
          track.enabled = true;
          print('🎯 Local Video: ${track.id} - enabled: ${track.enabled}, muted: ${track.muted}');
        }
        print('🎯 ===========================================');

        // 🔧 CRITICAL FIX: Set appropriate audio route based on call type
        if (callType == CallType.video) {
          // VIDEO CALLS: Speaker by default (all platforms)
          try {
            Helper.setSpeakerphoneOn(true);
            _isSpeakerEnabled.value = true;
            print('🔊 VIDEO CALL: Defaulting audio to SPEAKER (all platforms)');
            
            // 🔧 AGGRESSIVE FIX: Force speaker multiple times to ensure it sticks on iOS
            // iOS audio routing is very fragile and gets reset frequently
            _enforceSpeakerForVideoCall();
          } catch (e) {
            print('⚠️ Could not enable speakerphone for video call: $e');
          }
        } else if (callType == CallType.audio) {
          // AUDIO CALLS: Earpiece by default (all platforms)
          try {
            Helper.setSpeakerphoneOn(false);
            _isSpeakerEnabled.value = false;
            print('📞 AUDIO CALL: Defaulting audio to EARPIECE (all platforms)');
            
            // For audio calls, we don't need aggressive enforcement
            // Users can manually toggle to speaker if they want
          } catch (e) {
            print('⚠️ Could not set earpiece for audio call: $e');
          }
        }
      }
    } catch (e) {
      print('❌ Error initializing local stream: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// CALLER: Create room with offer
  Future<void> _createRoom(String roomId) async {
    try {
      print('📞 _createRoom() called with roomId: $roomId');
      print('📞 Creating room as CALLER...');
      
      // Create offer
      final offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
      });
      await _peerConnection!.setLocalDescription(offer);
      
      print('📞 Offer created: ${offer.type}');
      print('📞 Offer SDP (first 200 chars): ${offer.sdp?.substring(0, offer.sdp!.length > 200 ? 200 : offer.sdp!.length)}...');

      // Store offer in Supabase
      final roomData = {
        'room_id': roomId,
        'offer': {
          'sdp': offer.sdp,
          'type': offer.type,
        },
        'created_at': DateTime.now().toIso8601String(),
      };
      
      print('📞 Storing offer in Supabase...');
      
      // CRITICAL FIX: Use upsert instead of insert to handle duplicate room IDs
      // This prevents "duplicate key" errors when retrying calls
      await SupabaseService.client
          .from('webrtc_rooms')
          .upsert(roomData, onConflict: 'room_id');
      
      print('✅ Offer stored successfully (upsert)');

      // IMPORTANT: Listen for answer from receiver
      _listenForAnswer(roomId);
      // Start listening for remote ICE immediately and queue until remoteDescription
      _listenForIceCandidates(roomId);
      
      // CRITICAL FIX: Listen for call state changes (disconnection detection)
      _listenForCallStateChanges(roomId);

      // Start no-answer timeout for caller
      _startNoAnswerTimeout();
      
    } catch (e) {
      print('❌ Error creating room: $e');
      _updateCallState(CallState.failed);
    }
  }

  /// RECEIVER: Join room with answer
  Future<void> _joinRoom(String roomId) async {
    try {
      print('📞 Joining room as RECEIVER...');
      
      // Get offer from Supabase - CRITICAL FIX: Use maybeSingle() instead of single()
      // single() throws 406 error when no rows found, maybeSingle() returns null
      final roomData = await SupabaseService.client
          .from('webrtc_rooms')
          .select('offer')
          .eq('room_id', roomId)
          .maybeSingle();

      // CRITICAL FIX: Check if roomData is null OR if offer is null
      if (roomData == null || roomData['offer'] == null) {
        print('⚠️ No offer found yet. Polling for offer before switching to CALLER...');
        // Poll up to 3 times (2s interval) for the caller to write the offer
        final int maxTries = 3;
        Map<String, dynamic>? retryRoomData;
        for (int i = 0; i < maxTries; i++) {
          await Future.delayed(const Duration(seconds: 2));
          retryRoomData = await SupabaseService.client
              .from('webrtc_rooms')
              .select('offer')
              .eq('room_id', roomId)
              .maybeSingle();
          if (retryRoomData != null && retryRoomData['offer'] != null) {
            break;
          }
          print('⌛ Waiting for offer... attempt ${i + 1}/$maxTries');
        }

        if (retryRoomData == null || retryRoomData['offer'] == null) {
          print('⚠️ Still no offer after retries. Switching to CALLER mode...');
          _isInitiator = true;
          // CRITICAL FIX: Always recreate peer connection when switching modes
          print('📞 Recreating peer connection for caller mode...');
          await _peerConnection?.close();
          _peerConnection = await createPeerConnection(_webrtcConfiguration);
          _registerPeerConnectionListeners();
          _localStream?.getTracks().forEach((track) {
            _peerConnection?.addTrack(track, _localStream!);
          });
          await _createRoom(roomId);
          return;
        } else {
          // Got the offer on retry, continue with receiver flow
          print('✅ Got offer during polling, continuing as RECEIVER...');
          final offer = RTCSessionDescription(
            retryRoomData['offer']['sdp'],
            retryRoomData['offer']['type'],
          );
          print('📞 Got offer from database: ${offer.type}');
          print('📞 Setting remote description (offer)...');
          await _peerConnection!.setRemoteDescription(offer);
          print('✅ Remote description (offer) set successfully');
          _readyToAddRemoteCandidates = true;
          _scheduleFlushQueuedIceCandidates();
          // Handle Android-specific connection issues for receivers
          _handleAndroidConnectionIssues();
          // Continue with answer creation below
          final answer = await _peerConnection!.createAnswer({
            'offerToReceiveAudio': true,
            'offerToReceiveVideo': true,
          });
          await _peerConnection!.setLocalDescription(answer);
          print('📞 Answer created: ${answer.type}');
          print('📞 Storing answer in Supabase...');
          await SupabaseService.client
              .from('webrtc_rooms')
              .update({'answer': {'sdp': answer.sdp, 'type': answer.type}})
              .eq('room_id', roomId);
          print('✅ Answer stored successfully');
          // Listen for ICE candidates
          _listenForIceCandidates(roomId);
          return;
        }
      }

      final offer = RTCSessionDescription(
        roomData['offer']['sdp'],
        roomData['offer']['type'],
      );
      
      print('📞 Got offer from database: ${offer.type}');
      print('📞 Offer SDP (first 200 chars): ${offer.sdp?.substring(0, offer.sdp!.length > 200 ? 200 : offer.sdp!.length)}...');
      print('📞 Setting remote description (offer)...');
      await _peerConnection!.setRemoteDescription(offer);
      print('✅ Remote description (offer) set successfully');
      _readyToAddRemoteCandidates = true;
      // Start listening for ICE right away (caller may already be trickling)
      _listenForIceCandidates(roomId);
      
      _scheduleFlushQueuedIceCandidates();
      
      // Handle Android-specific connection issues for receivers
      _handleAndroidConnectionIssues();

      // Create answer with platform-specific codec preferences
      print('📞 Creating answer...');
      final answerConstraints = <String, dynamic>{
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
      };
      
      // Add platform-specific codec preferences
      if (_isIOS) {
        // iOS Safari requires H.264
        answerConstraints['codecPreferences'] = ['H264', 'VP8', 'VP9'];
        print('📞 iOS: Prioritizing H.264 codec');
      } else if (_isAndroid) {
        // Android prefers VP8 but supports H.264
        answerConstraints['codecPreferences'] = ['VP8', 'H264', 'VP9'];
        print('📞 Android: Prioritizing VP8 codec');
      } else if (_isWeb) {
        // Web browsers - balanced approach
        answerConstraints['codecPreferences'] = ['H264', 'VP8', 'VP9'];
        print('📞 Web: Using balanced codec preferences');
      }
      
      final answer = await _peerConnection!.createAnswer(answerConstraints);
      await _peerConnection!.setLocalDescription(answer);
      
      print('📞 Answer created: ${answer.type}');
      print('📞 Answer SDP (first 200 chars): ${answer.sdp?.substring(0, answer.sdp!.length > 200 ? 200 : answer.sdp!.length)}...');

      // Store answer in Supabase
      print('📞 Storing answer in Supabase...');
      await SupabaseService.client
          .from('webrtc_rooms')
          .update({
            'answer': {
              'sdp': answer.sdp,
              'type': answer.type,
            }
          })
          .eq('room_id', roomId);
      
      print('✅ Answer stored successfully');

      // Listen for ICE candidates from caller
      _listenForIceCandidates(roomId);
      
      // CRITICAL FIX: Listen for call state changes (disconnection detection)
      _listenForCallStateChanges(roomId);
      
      // Start receiver timeout (30 seconds to answer)
      _startReceiverTimeout();
      
    } catch (e) {
      // If we failed to join because there are 0 rows (PGRST116), try acting as caller
      final errorText = e.toString();
      if (errorText.contains('PGRST116') || errorText.contains('0 rows')) {
        print('⚠️ Join failed due to 0 rows (no offer). Acting as CALLER now...');
        _isInitiator = true;
        try {
          if (_peerConnection == null) {
            print('📞 Peer connection is null. Recreating before creating room...');
            _peerConnection = await createPeerConnection(_webrtcConfiguration);
            _registerPeerConnectionListeners();
            _localStream?.getTracks().forEach((track) {
              _peerConnection?.addTrack(track, _localStream!);
            });
          }
          await _createRoom(roomId);
          return;
        } catch (inner) {
          print('❌ Failed to recover by creating room: $inner');
        }
      } else {
        print('❌ Error joining room: $e');
      }
      _updateCallState(CallState.failed);
    }
  }

  /// CALLER: Listen for answer from receiver
  void _listenForAnswer(String roomId) {
    print('📞 Listening for answer from receiver...');
    
    _answerSubscription?.cancel();
    _answerSubscription = SupabaseService.client
        .from('webrtc_rooms')
        .stream(primaryKey: ['room_id'])
        .eq('room_id', roomId)
        .listen((data) async {
      if (data.isNotEmpty && data.first['answer'] != null) {
        print('📞 Answer received from receiver!');
        
        final answerData = data.first['answer'];
        final answer = RTCSessionDescription(
          answerData['sdp'],
          answerData['type'],
        );
        
        try {
          // Guard duplicate application (check real SDP presence, not just non-null object)
          RTCSessionDescription? currentRemote;
          try {
            currentRemote = _peerConnection != null
                ? await _peerConnection!.getRemoteDescription()
                : null;
          } catch (_) {}
          final hasRealRemoteSdp = currentRemote != null && (currentRemote.sdp != null && currentRemote.sdp!.isNotEmpty);
          if (_answerApplied || hasRealRemoteSdp) {
            print('⚠️ Answer already applied, skipping duplicate setRemoteDescription');
            _answerSubscription?.cancel();
            return;
          }
          print('📞 Got answer from database: ${answer.type}');
          print('📞 Answer SDP (first 200 chars): ${answer.sdp?.substring(0, answer.sdp!.length > 200 ? 200 : answer.sdp!.length)}...');
          print('📞 Setting remote description (answer)...');
          await _peerConnection?.setRemoteDescription(answer);
          print('✅ Remote description (answer) set successfully');
          _answerApplied = true;
          _readyToAddRemoteCandidates = true;
          _scheduleFlushQueuedIceCandidates();
          // Answer received -> cancel no-answer timeout
          _noAnswerTimeout?.cancel();
          
          // Process any queued ICE candidates
          await _processQueuedIceCandidates();
          
          // Handle Android-specific connection issues for receivers
          _handleAndroidConnectionIssues();
          
          // Now listen for ICE candidates
          _listenForIceCandidates(roomId);
          
          // Cancel this subscription as we only need the answer once
          _answerSubscription?.cancel();
        } catch (e) {
          print('❌ Error setting remote description: $e');
        }
      }
    });
  }

  /// Listen for ICE candidates from remote peer
  void _listenForIceCandidates(String roomId) {
    print('📞 ═══════════════════════════════════════════════════');
    print('📞 LISTENING FOR REMOTE ICE CANDIDATES...');
    print('📞 Room ID: $roomId');
    print('📞 ═══════════════════════════════════════════════════');
    
    _iceCandidatesSubscription?.cancel();
    _iceCandidatesSubscription = SupabaseService.client
        .from('webrtc_ice_candidates')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .listen((candidates) async {
      print('📥 Received ICE candidate batch: ${candidates.length} candidates');
      
      for (final candidateData in candidates) {
        if (candidateData['candidate'] != null) {
          try {
            final candidateStrFull = (candidateData['candidate']?.toString() ?? '');
            // Skip obvious noise candidates
            if (candidateStrFull.contains(' 127.0.0.1 ') || candidateStrFull.contains(' ::1 ') || candidateStrFull.contains(' 169.254.')) {
              print('⚠️ Skipping loopback/link-local ICE candidate');
              continue;
            }

            // Queue until remote description is ready
            if (!_readyToAddRemoteCandidates || _peerConnection?.getRemoteDescription() == null) {
              print('⚠️ Remote description not set yet, queuing ICE candidate...');
              _queuedIceCandidates ??= [];
              _queuedIceCandidates!.add(candidateData);
              continue;
            }
            
            final candidate = RTCIceCandidate(
              candidateData['candidate'],
              candidateData['sdp_mid'],
              candidateData['sdp_mline_index'],
            );
            
            print('🧊 Adding remote ICE candidate:');
            final candidateStr = candidateData['candidate']?.toString() ?? '';
            print('   - Candidate (first 80 chars): ${candidateStr.length > 80 ? candidateStr.substring(0, 80) : candidateStr}...');
            print('   - SDP MID: ${candidateData['sdp_mid']}');
            print('   - SDP MLine Index: ${candidateData['sdp_mline_index']}');
            
            await _peerConnection?.addCandidate(candidate);
            print('✅ ICE candidate added successfully');
          } catch (e) {
            print('❌ Error adding ICE candidate: $e');
            final candidateStr = candidateData['candidate']?.toString() ?? '';
            print('❌ Candidate data: ${candidateStr.length > 100 ? candidateStr.substring(0, 100) : candidateStr}');
          }
        }
      }
    }, onError: (error) {
      print('❌ Error in ICE candidates stream: $error');
    });
  }

  /// Send ICE candidate to Supabase
  void _handleIceCandidate(RTCIceCandidate candidate, String roomId) async {
    try {
      print('📤 Sending ICE candidate to Supabase...');
      await SupabaseService.client.from('webrtc_ice_candidates').insert({
        'room_id': roomId,
        'candidate': candidate.candidate,
        'sdp_mid': candidate.sdpMid,
        'sdp_mline_index': candidate.sdpMLineIndex,
        'created_at': DateTime.now().toIso8601String(),
      });
      print('✅ ICE candidate sent successfully');
    } catch (e) {
      print('❌ Error sending ICE candidate: $e');
      print('❌ This may cause connection issues!');
    }
  }

  void _handleRemoteTrack(RTCTrackEvent event) {
    print('📞 ═══════════════════════════════════════════════════');
    print('📞 REMOTE TRACK RECEIVED!');
    print('📞 ═══════════════════════════════════════════════════');
    print('📞 Track kind: ${event.track.kind}');
    print('📞 Track id: ${event.track.id}');
    print('📞 Track enabled: ${event.track.enabled}');
    print('📞 Track muted: ${event.track.muted}');
    print('📞 Number of streams: ${event.streams.length}');
    print('📞 Is Initiator: $_isInitiator');
    
    if (event.streams.isNotEmpty) {
      _remoteStream = event.streams[0];
      final audioTracks = _remoteStream!.getAudioTracks();
      final videoTracks = _remoteStream!.getVideoTracks();
      
      print('✅ Remote stream received!');
      print('   - Stream ID: ${_remoteStream!.id}');
      print('   - Total tracks: ${event.streams[0].getTracks().length}');
      print('   - Audio tracks: ${audioTracks.length}');
      print('   - Video tracks: ${videoTracks.length}');
      
      for (var track in audioTracks) {
        print('   - Remote audio track: ${track.id}, enabled: ${track.enabled}');
        // Ensure audio tracks are enabled
        if (!track.enabled) {
          track.enabled = true;
          print('   - Enabled audio track: ${track.id}');
        }
      }
      for (var track in videoTracks) {
        print('   - Remote video track: ${track.id}, enabled: ${track.enabled}, muted: ${track.muted}');
        // Ensure video tracks are enabled and unmuted
        if (!track.enabled) {
          track.enabled = true;
          print('   - Enabled video track: ${track.id}');
        }
        // Note: muted property is read-only in WebRTC, but we can ensure the track is enabled
        // The muted state should resolve once the track is properly enabled
        if (track.muted == true) {
          print('   - Video track is muted, attempting to resolve by ensuring enabled state');
          track.enabled = true;
        }
      }
      
      // Additional debugging for video tracks
      if (videoTracks.isNotEmpty) {
        print('🔍 DEBUG: Video track details:');
        for (var track in videoTracks) {
          print('   - Track ID: ${track.id}');
          print('   - Track enabled: ${track.enabled}');
          print('   - Track muted: ${track.muted}');
        }
      }
      
      // CRITICAL FIX: Ensure remote stream callback is called for BOTH caller and receiver
      print('📞 Calling onRemoteStream callback...');
      
    // CRITICAL: Force enable all video tracks before calling callback
    final remoteVideoTracks = _remoteStream!.getVideoTracks();
    final remoteAudioTracks = _remoteStream!.getAudioTracks();
    
    // CRITICAL DEBUG: Log remote stream details
    print('🎯 ===========================================');
    print('🎯 REMOTE STREAM DEBUG (${_isInitiator ? "CALLER" : "RECEIVER"})');
    print('🎯 ===========================================');
    print('🎯 Remote Audio Tracks: ${remoteAudioTracks.length}');
    print('🎯 Remote Video Tracks: ${remoteVideoTracks.length}');
    
    for (var track in remoteAudioTracks) {
      print('🎯 Remote Audio: ${track.id} - enabled: ${track.enabled}, muted: ${track.muted}');
    }
    for (var track in remoteVideoTracks) {
      if (!track.enabled) {
        track.enabled = true;
        print('📞 WebRTC: Force enabled video track: ${track.id}');
      }
      print('🎯 Remote Video: ${track.id} - enabled: ${track.enabled}, muted: ${track.muted}');
    }
    print('🎯 ===========================================');
    
    onRemoteStream?.call(_remoteStream!);
    print('✅ Remote stream callback invoked successfully');
      
      // 🔧 CRITICAL FIX: Additional safety for receiver - multiple callback attempts
      // This ensures the receiver gets the stream even if there are timing issues
      Future.delayed(Duration(milliseconds: 100), () {
        if (onRemoteStream != null) {
          print('📞 Safety callback: Re-invoking onRemoteStream...');
          onRemoteStream!(_remoteStream!);
        }
      });
      
      // 🔧 CRITICAL FIX: Extra safety for receiver - delayed callback
      Future.delayed(Duration(milliseconds: 500), () {
        if (onRemoteStream != null && _remoteStream != null) {
          print('📞 Delayed callback: Final onRemoteStream attempt...');
          onRemoteStream!(_remoteStream!);
        }
      });
      
      // 🔧 CRITICAL FIX: One more safety net for receiver
      Future.delayed(Duration(milliseconds: 1000), () {
        if (onRemoteStream != null && _remoteStream != null) {
          print('📞 Final safety callback: Last onRemoteStream attempt...');
          onRemoteStream!(_remoteStream!);
        }
      });
    } else {
      print('⚠️ Remote track received but no streams available');
    }
  }

  void _registerPeerConnectionListeners() {
    _peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      print('📞 ═══════════════════════════════════════════════════');
      print('📞 CONNECTION STATE CHANGED: $state');
      print('📞 ═══════════════════════════════════════════════════');
      
      // CRITICAL: Log current stream states when connection changes
      if (_localStream != null) {
        final localVideoTracks = _localStream!.getVideoTracks();
        print('📞 Local video tracks: ${localVideoTracks.length}');
        for (var track in localVideoTracks) {
          print('📞 Local video track: ${track.id} - enabled: ${track.enabled}, muted: ${track.muted}');
        }
      }
      
      if (_remoteStream != null) {
        final remoteVideoTracks = _remoteStream!.getVideoTracks();
        print('📞 Remote video tracks: ${remoteVideoTracks.length}');
        for (var track in remoteVideoTracks) {
          print('📞 Remote video track: ${track.id} - enabled: ${track.enabled}, muted: ${track.muted}');
        }
      }
      
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          print('✅ WebRTC connection established!');
          _updateCallState(CallState.connected);
          _updateDbStateSafe('connected');
          _noAnswerTimeout?.cancel();
          
          // Enable speaker for audio calls (app-only)
          try {
            Helper.setSpeakerphoneOn(true);
          } catch (_) {}
          break;
          
        case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
          print('📞 WebRTC connecting...');
          break;
          
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          print('⚠️ WebRTC disconnected');
          _updateCallState(CallState.disconnected);
          onCallEnded?.call();
          _updateDbStateSafe('disconnected');
          break;
          
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          print('❌ WebRTC connection failed');
          _updateCallState(CallState.failed);
          _updateDbStateSafe('failed');
          _noAnswerTimeout?.cancel();
          break;
          
        default:
          break;
      }
    };
    
    _peerConnection?.onIceConnectionState = (RTCIceConnectionState state) {
      print('🧊 ICE CONNECTION STATE: $state');
      
      if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        print('❌ ICE CONNECTION FAILED! Check:');
        print('   1. Network connectivity');
        print('   2. STUN server accessibility');
        print('   3. Firewall settings');
        print('   4. iOS/Android compatibility issues');
        
        // Try to recover from ICE connection failure
        _handleIceConnectionFailure();
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateConnected) {
        print('✅ ICE CONNECTION ESTABLISHED!');
        _iceConnectionTimeout?.cancel();
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateChecking) {
        print('🧊 ICE CONNECTION CHECKING...');
        _startIceConnectionTimeout();
        _iceQuickFallbackTimer?.cancel();
        _iceQuickFallbackTimer = Timer(const Duration(seconds: 7), () {
          if (_peerConnection != null && _callState.value == CallState.connecting) {
            print('⏱️ ICE still checking after 7s -> attempting ICE restart');
            try {
              _peerConnection!.restartIce();
            } catch (e) {
              print('❌ Quick ICE restart failed: $e');
            }
          }
        });
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        print('✅ ICE CONNECTION COMPLETED!');
        _iceConnectionTimeout?.cancel();
        _iceQuickFallbackTimer?.cancel();
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateClosed) {
        print('🔒 ICE CONNECTION CLOSED');
        _iceConnectionTimeout?.cancel();
        _iceQuickFallbackTimer?.cancel();
      }
    };
    
    _peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      print('🧊 ICE GATHERING STATE: $state');
      
      if (state == RTCIceGatheringState.RTCIceGatheringStateComplete) {
        print('✅ ICE gathering complete');
        // For cross-platform compatibility, ensure all candidates are processed
        _handleIceGatheringComplete();
      } else if (state == RTCIceGatheringState.RTCIceGatheringStateGathering) {
        print('🧊 ICE gathering in progress...');
      }
    };
    
    _peerConnection?.onSignalingState = (RTCSignalingState state) {
      print('📡 SIGNALING STATE: $state');
    };
  }

  void _updateCallState(CallState state) {
    final oldState = _callState.value;
    _callState.value = state;
    
    print('📞 ===========================================');
    print('📞 CALL STATE CHANGE: ${oldState.name} -> ${state.name}');
    print('📞 Call ID: ${_currentCallId ?? 'unknown'}');
    print('📞 Match ID: ${_currentMatchId ?? 'unknown'}');
    print('📞 Is Initiator: $_isInitiator');
    print('📞 Is Ending: $_isEnding');
    print('📞 Is Initialized: $_isInitialized');
    print('📞 ===========================================');
    
    // Log state change
    CallDebugService.logCallStateChange(
      callId: _currentCallId ?? 'unknown',
      fromState: oldState.name,
      toState: state.name,
    );
    
    // 🔧 CRITICAL FIX: Enforce appropriate audio route when call becomes connected
    if (state == CallState.connected) {
      // Check if this is a video call (has video enabled)
      if (_isVideoEnabled.value) {
        print('🍎 Video call connected - enforcing speaker');
        _forceSpeakerOn();
        
        // Additional enforcement after a short delay
        Future.delayed(Duration(milliseconds: 500), () {
          if (_callState.value == CallState.connected && _isVideoEnabled.value) {
            _forceSpeakerOn();
            print('🍎 Post-connection speaker enforcement for video call');
          }
        });
      } else {
        // Audio call - ensure earpiece is used
        print('📞 Audio call connected - ensuring earpiece');
        _forceEarpieceForAudioCall();
      }
    }
  }

  

  /// AGGRESSIVE FIX: Enforce speaker for video calls on iOS
  /// iOS audio routing is very fragile and gets reset frequently
  void _enforceSpeakerForVideoCall() {
    if (!Platform.isIOS) return;
    
    print('🍎 AGGRESSIVE FIX: Starting persistent speaker enforcement for iOS VIDEO call');
    
    // Immediate enforcement
    _forceSpeakerOn();
    
    // Multiple delayed enforcements to catch iOS audio routing resets
    final delays = [100, 200, 500, 800, 1200, 2000, 3000, 5000, 8000, 12000];
    
    for (int i = 0; i < delays.length; i++) {
      Future.delayed(Duration(milliseconds: delays[i]), () {
        // Only enforce for video calls
        if (_callState.value == CallState.connected && _isVideoEnabled.value) {
          _forceSpeakerOn();
          print('🍎 Video call speaker enforcement #${i + 1} at ${delays[i]}ms');
        }
      });
    }
    
    // Continuous enforcement every 5 seconds while VIDEO call is active
    Timer.periodic(Duration(seconds: 5), (timer) {
      if (_callState.value != CallState.connected || !_isVideoEnabled.value) {
        timer.cancel();
        print('🍎 Stopping continuous speaker enforcement - video call ended');
        return;
      }
      
      _forceSpeakerOn();
      print('🍎 Continuous speaker enforcement for video call (every 5s)');
    });
  }
  
  /// Force speaker on with error handling
  void _forceSpeakerOn() {
    try {
      Helper.setSpeakerphoneOn(true);
      _isSpeakerEnabled.value = true;
      print('🔊 Speaker forced ON');
    } catch (e) {
      print('⚠️ Failed to force speaker on: $e');
    }
  }
  
  /// Force earpiece for audio calls
  void _forceEarpieceForAudioCall() {
    try {
      Helper.setSpeakerphoneOn(false);
      _isSpeakerEnabled.value = false;
      print('📞 Earpiece forced ON for audio call');
    } catch (e) {
      print('⚠️ Failed to force earpiece on: $e');
    }
  }

  // Call control methods
  void toggleMute() {
    _isMuted.value = !_isMuted.value;
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = !_isMuted.value;
    });
    print('📞 Mute toggled: ${_isMuted.value}');
  }

  void toggleVideo() {
    _isVideoEnabled.value = !_isVideoEnabled.value;
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = _isVideoEnabled.value;
    });
    print('📞 Video toggled: ${_isVideoEnabled.value}');
  }

  void toggleSpeaker() {
    _isSpeakerEnabled.value = !_isSpeakerEnabled.value;
    try {
      Helper.setSpeakerphoneOn(_isSpeakerEnabled.value);
    } catch (e) {
      print('❌ Error toggling speaker: $e');
    }
    print('📞 Speaker toggled: ${_isSpeakerEnabled.value}');
    
    // 🔧 CRITICAL FIX: Enforce appropriate audio route based on call type
    if (_callState.value == CallState.connected) {
      if (_isVideoEnabled.value) {
        // VIDEO CALL: Always enforce speaker (all platforms)
        if (!_isSpeakerEnabled.value) {
          print('🔊 Video Call: Forcing speaker back ON (video calls must use speaker)');
          _isSpeakerEnabled.value = true;
          Helper.setSpeakerphoneOn(true);
        }
      } else {
        // AUDIO CALL: Allow user to toggle freely
        print('📞 Audio Call: Speaker toggle allowed - user preference respected');
      }
    }
  }

  void switchCamera() {
    if (_localStream != null) {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        Helper.switchCamera(videoTracks.first);
        print('📞 Camera switched');
      }
    }
  }

  Future<void> endCall() async {
    try {
      if (_isEnding) {
        print('📞 Ending call skipped (already in progress)');
        return;
      }
      _isEnding = true;
      print('📞 Ending call...');
      
      // CRITICAL FIX: Cancel all timers first to prevent race conditions
      _iceConnectionTimeout?.cancel();
      _noAnswerTimeout?.cancel();
      _relayWarnTimer?.cancel();
      _iceQuickFallbackTimer?.cancel();
      _queuedIceFlushTimer?.cancel();
      _androidRetryTimer?.cancel();
      
      // CRITICAL FIX: Cancel all subscriptions immediately to prevent further callbacks
      await _answerSubscription?.cancel();
      await _iceCandidatesSubscription?.cancel();
      await _callStateSubscription?.cancel();
      await _callSessionStateSubscription?.cancel();
      
      // CRITICAL FIX: Stop all tracks BEFORE disposing streams to prevent EglRenderer errors
      if (_localStream != null) {
        _localStream!.getTracks().forEach((track) {
          try {
            track.stop();
            print('📞 Stopped local track: ${track.kind}');
          } catch (e) {
            print('⚠️ Error stopping local track: $e');
          }
        });
      }
      
      if (_remoteStream != null) {
        _remoteStream!.getTracks().forEach((track) {
          try {
            track.stop();
            print('📞 Stopped remote track: ${track.kind}');
          } catch (e) {
            print('⚠️ Error stopping remote track: $e');
          }
        });
      }

      // CRITICAL FIX: Close peer connection BEFORE disposing streams
      if (_peerConnection != null) {
        try {
          await _peerConnection!.close();
          print('📞 Peer connection closed');
        } catch (e) {
          print('⚠️ Error closing peer connection: $e');
        }
      }

      // CRITICAL FIX: Dispose streams after tracks are stopped
      if (_localStream != null) {
        try {
          _localStream!.dispose();
          print('📞 Local stream disposed');
        } catch (e) {
          print('⚠️ Error disposing local stream: $e');
        }
      }
      
      if (_remoteStream != null) {
        try {
          _remoteStream!.dispose();
          print('📞 Remote stream disposed');
        } catch (e) {
          print('⚠️ Error disposing remote stream: $e');
        }
      }

      // CRITICAL FIX: Clear references immediately
      _localStream = null;
      _remoteStream = null;
      _peerConnection = null;
      _queuedIceCandidates = null;
      _readyToAddRemoteCandidates = false;
      _answerApplied = false;
      _hasRelayCandidate = false;
      _lastDbState = null;
      
      // Update call_sessions state after cleanup
      final isConnecting = _callState.value == CallState.connecting || _callState.value == CallState.initial;
      final terminationState = isConnecting ? 'canceled' : 'ended';
      
      try {
        _updateDbStateSafe(terminationState);
      } catch (_) {}

      // CRITICAL FIX: Clean up room data to prevent duplicate key errors on next call
      if (_currentCallId != null) {
        try {
          print('🧹 Cleaning up WebRTC room data for: $_currentCallId');
          
          // CRITICAL FIX: Clear Android notifications when call ends
          if (Platform.isAndroid) {
            try {
              // Clear the call notification
              final MethodChannel channel = MethodChannel('com.lovebug.app/notification');
              await channel.invokeMethod('clearCallNotification');
              print('✅ Android call notification cleared');
            } catch (e) {
              print('⚠️ Error clearing Android notification: $e');
            }
          }
          
          // CRITICAL FIX: Update BOTH tables to notify other participant
          // Update call_sessions (watched by real-time listener)
          await SupabaseService.client
              .from('call_sessions')
              .update({
                'state': terminationState,
                'ended_at': DateTime.now().toUtc().toIso8601String(),
              })
              .eq('id', _currentCallId!);
          print('✅ Call session state updated to $terminationState');
          
          // Update webrtc_rooms (for cleanup)
          await SupabaseService.client
              .from('webrtc_rooms')
              .update({
                'call_state': 'ended',
                'ended_at': DateTime.now().toUtc().toIso8601String(),
                'ended_by': SupabaseService.currentUser?.id,
              })
              .eq('room_id', _currentCallId!);
          print('✅ Call end state updated in database');
          
          // Delete room data (offer/answer)
          await SupabaseService.client
              .from('webrtc_rooms')
              .delete()
              .eq('room_id', _currentCallId!);
          print('✅ Cleaned up room data');
          
          // Delete ICE candidates
          await SupabaseService.client
              .from('webrtc_ice_candidates')
              .delete()
              .eq('room_id', _currentCallId!);
          print('✅ Cleaned up ICE candidates');
        } catch (e) {
          print('⚠️ Error cleaning up room data (non-critical): $e');
          // Non-critical error, continue with call cleanup
        }
      }

      // Reset speaker route back to default earpiece when ending
      try {
        Helper.setSpeakerphoneOn(false);
        _isSpeakerEnabled.value = false;
      } catch (_) {}

      // Reset microphone state after video calls to fix audio note permission issues
      try {
        await AudioRecordingService.resetMicrophoneState();
        print('🎤 Microphone state reset after call');
      } catch (e) {
        print('⚠️ Error resetting microphone state: $e');
      }

      // CRITICAL FIX: Update state and call callbacks AFTER cleanup
      _updateCallState(CallState.initial); // Reset to initial state to clear UI indicators
      onCallEnded?.call();
      
      // CRITICAL FIX: Force reset call state to prevent stuck states
      await forceResetCallState();
      
      // CRITICAL FIX: Reset ALL state flags after cleanup to prevent race conditions
      _isEnding = false;
      _isInitialized = false;  // CRITICAL: Reset initialization flag
      _currentCallId = null;
      _currentMatchId = null;
      
      print('✅ Call ended successfully - All state reset for next call');
    } catch (e) {
      print('❌ Error ending call: $e');
      // CRITICAL FIX: Always reset ending flag even on error
      _isEnding = false;
    }
  }

  /// Listen for call state changes to detect disconnection
  void _listenForCallStateChanges(String roomId) {
    print('📞 ═══════════════════════════════════════════════════');
    print('📞 LISTENING FOR CALL STATE CHANGES...');
    print('📞 Room ID: $roomId');
    print('📞 ═══════════════════════════════════════════════════');
    
    _callStateSubscription = SupabaseService.client
        .from('webrtc_rooms')
        .stream(primaryKey: ['room_id'])
        .eq('room_id', roomId)
        .listen((data) {
      if (data.isNotEmpty) {
        final room = data.first;
        final callState = room['call_state'];
        final endedBy = room['ended_by'];
        final currentUserId = SupabaseService.currentUser?.id;
        
        print('📞 Call state update received: $callState');
        print('📞 Ended by: $endedBy');
        print('📞 Current user: $currentUserId');
        
        // Check if call was ended by the other participant
        if (callState == 'ended' && endedBy != null && endedBy != currentUserId) {
          print('📞 ⚠️ Call ended by other participant!');
          _updateCallState(CallState.disconnected);
          onCallEnded?.call();
        }
      }
    });
  }

  /// Listen for call_sessions state changes (declined/canceled/ended)
  void _listenForCallSessionState(String callId) {
    try {
      _callSessionStateSubscription?.cancel();
      _callSessionStateSubscription = SupabaseService.client
          .from('call_sessions')
          .stream(primaryKey: ['id'])
          .eq('id', callId)
          .listen((rows) {
        if (rows.isEmpty) return;
        final row = rows.first;
        final state = (row['state'] ?? '').toString();
        if (state.isEmpty) return;
        print('📞 call_sessions state change: $state');
        if (state == 'declined' || state == 'canceled' || state == 'timeout' || state == 'ended' || state == 'failed' || state == 'disconnected') {
          // CRITICAL FIX: Get caller name from profiles table (caller_name doesn't exist in call_sessions)
          final receiverId = row['receiver_id']?.toString();
          final callerId = row['caller_id']?.toString();
          
          // Local clearing as backup (immediate, doesn't need caller name)
          if (Platform.isAndroid) {
            try {
              final MethodChannel channel = MethodChannel('com.lovebug.app/notification');
              channel.invokeMethod('clearCallNotification');
              print('✅ Android notification cleared locally due to state change: $state');
            } catch (e) {
              print('⚠️ Error clearing Android notification locally: $e');
            }
          }
          
          if (Platform.isIOS) {
            try {
              FlutterCallkitIncoming.endCall(callId);
              print('✅ iOS CallKit cleared locally due to state change: $state');
            } catch (e) {
              print('⚠️ Error clearing iOS CallKit locally: $e');
            }
          }
          
          // If remote signaled termination, end locally
          if (_callState.value != CallState.disconnected && _callState.value != CallState.failed) {
            print('📞 Terminating due to call_sessions state=$state');
            endCall();
          }
          
          // Fetch caller name asynchronously and clear notifications (fire and forget)
          Future.microtask(() async {
            String callerName = 'Unknown';
            if (callerId != null) {
              try {
                final callerProfile = await SupabaseService.getProfile(callerId);
                callerName = callerProfile?['name']?.toString() ?? 'Unknown';
              } catch (e) {
                print('⚠️ Error fetching caller profile in webrtc_service: $e');
              }
            }
            
            // Clear notifications for the receiver
            if (receiverId != null) {
              NotificationClearingService.clearCallNotification(
                userId: receiverId,
                callId: callId,
                callerName: callerName,
              );
            }
            
            // Also clear for caller if they're different
            if (callerId != null && callerId != receiverId) {
              NotificationClearingService.clearCallNotification(
                userId: callerId,
                callId: callId,
                callerName: callerName,
              );
            }
            
            // Send missed-call notification for canceled timeouts
            if (state == 'canceled' && receiverId != null) {
              NotificationClearingService.sendMissedCallNotification(
                userId: receiverId,
                callId: callId,
                callerName: callerName,
                callType: row['call_type']?.toString() ?? 'audio',
              );
            }
          });
        }
      });
    } catch (e) {
      print('❌ Error listening to call_sessions: $e');
    }
  }

  void _updateDbStateSafe(String state) {
    final callId = _currentCallId;
    if (callId == null) return;
    // Normalize state to comply with DB constraint
    final normalized = _normalizeDbState(state);
    if (_lastDbState == normalized) {
      // Avoid spamming identical states
      return;
    }
    _lastDbState = normalized;
    
    // Determine if this is a terminal state (call has ended)
    final isTerminalState = _isTerminalState(normalized);
    
    // Fire and forget
    SupabaseService.client
        .from('call_sessions')
        .update({
          'state': normalized,
          if (isTerminalState) 'ended_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', callId)
        .then((_) => print('✅ Call state updated in DB: $normalized'))
        .catchError((e) => print('❌ Error updating call state: $e'));
  }

  /// Normalize legacy/internal states to DB-compliant states
  /// 
  /// Allowed DB states (after migration):
  /// - Active: initial, ringing, connecting, connected
  /// - Terminal: ended, declined, canceled, timeout
  /// - Legacy (deprecated): disconnected, failed
  String _normalizeDbState(String state) {
    switch (state) {
      case 'disconnected': // Legacy state from old code
      case 'failed':       // Legacy state from old code
        return 'ended';    // Normalize to standard terminal state
      default:
        return state;      // Use state as-is (initial, ringing, connecting, connected, ended, declined, canceled, timeout)
    }
  }

  /// Check if state represents a terminal call state (call has ended)
  bool _isTerminalState(String state) {
    return state == 'ended' || 
           state == 'declined' || 
           state == 'canceled' || 
           state == 'timeout';
  }

  /// Start ICE connection timeout
  void _startIceConnectionTimeout() {
    _iceConnectionTimeout?.cancel();
    _iceConnectionTimeout = Timer(const Duration(seconds: 30), () {
      print('⏰ ICE connection timeout - no connection established in 30 seconds');
      _handleIceConnectionFailure();
    });
  }

  // Auto-cancel if no answer within 10 seconds for caller
  void _startNoAnswerTimeout() {
    _noAnswerTimeout?.cancel();
    // Only relevant for initiator while connecting
    if (!_isInitiator) return;
    
    print('⏰ DEBUG: Starting 10-second timeout for caller (no answer)');
    _noAnswerTimeout = Timer(const Duration(seconds: 10), () async {
      print('⏰ DEBUG: 10-second timeout triggered for caller');
      print('⏰ DEBUG: Current call state: ${_callState.value}');
      print('⏰ DEBUG: Answer applied: $_answerApplied');
      
      if (_callState.value == CallState.connecting && !_answerApplied) {
        print('⏰ No answer within 30s – auto-canceling invite');
        try {
          _updateDbStateSafe('timeout');
        } catch (e) {
          print('⚠️ Failed to update DB state to timeout: $e');
          // Still proceed with endCall() since local cleanup is critical
        }
        await endCall();
      } else {
        print('⏰ DEBUG: Timeout ignored - call state: ${_callState.value}, answer applied: $_answerApplied');
      }
    });
  }

  // Auto-cancel if receiver doesn't answer within 12 seconds
  void _startReceiverTimeout() {
    _noAnswerTimeout?.cancel();
    // Only relevant for receiver while connecting
    if (_isInitiator) return;
    
    print('⏰ DEBUG: Starting 12-second timeout for receiver (not answering)');
    _noAnswerTimeout = Timer(const Duration(seconds: 12), () async {
      print('⏰ DEBUG: 12-second timeout triggered for receiver');
      print('⏰ DEBUG: Current call state: ${_callState.value}');
      print('⏰ DEBUG: Answer applied: $_answerApplied');
      
      if (_callState.value == CallState.connecting && !_answerApplied) {
        print('⏰ Receiver timeout - call not answered within 30s');
        try {
          _updateDbStateSafe('timeout');
        } catch (e) {
          print('⚠️ Failed to update DB state to timeout: $e');
          // Still proceed with endCall() since local cleanup is critical
        }
        await endCall();
      } else {
        print('⏰ DEBUG: Receiver timeout ignored - call state: ${_callState.value}, answer applied: $_answerApplied');
      }
    });
  }

  /// Handle ICE connection failure with retry logic
  void _handleIceConnectionFailure() {
    print('🔄 Attempting to recover from ICE connection failure...');
    
    // For iOS to Android calls, try restarting ICE gathering
    if (_peerConnection != null) {
      try {
        // Restart ICE gathering
        _peerConnection!.restartIce();
        print('🔄 ICE gathering restarted');
        
        // Update call state to indicate we're trying to reconnect
        _updateCallState(CallState.connecting);
        
        // For Android receivers, add additional retry logic
        _scheduleAndroidRetry();
      } catch (e) {
        print('❌ Failed to restart ICE: $e');
        _updateCallState(CallState.failed);
      }
    }
  }

  /// Schedule additional retry for Android receivers with retry limit
  void _scheduleAndroidRetry() {
    // Cancel any existing retry timer
    _androidRetryTimer?.cancel();
    _androidRetryCount = 0;
    
    print('🔄 Starting Android retry mechanism (max 3 attempts)');
    
    _androidRetryTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (_peerConnection == null || 
          _callState.value != CallState.connecting ||
          _androidRetryCount >= 3) {
        print('🔄 Android retry stopped: ${_androidRetryCount >= 3 ? "max attempts reached" : "call state changed"}');
        timer.cancel();
        return;
      }
      
      _androidRetryCount++;
      print('🔄 Android retry attempt ${_androidRetryCount}/3: Attempting ICE restart...');
      
      try {
        _peerConnection!.restartIce();
      } catch (e) {
        print('❌ Android retry ${_androidRetryCount} failed: $e');
        timer.cancel();
      }
    });
  }

  /// Get platform-optimized media constraints
  Map<String, dynamic> _getPlatformOptimizedConstraints(CallType callType) {
    final baseAudioConstraints = {
      'echoCancellation': true,
      'noiseSuppression': true,
      'autoGainControl': true,
    };
    
    final baseVideoConstraints = callType == CallType.video ? {
      'facingMode': 'user',
      'width': {'ideal': 640, 'min': 320, 'max': 1280},
      'height': {'ideal': 480, 'min': 240, 'max': 720},
      'frameRate': {'ideal': 30, 'min': 15, 'max': 60},
      'aspectRatio': {'ideal': 1.7777777777777777}, // 16:9 ratio
    } : false;
    
    if (_isIOS) {
      // iOS Safari constraints
      return {
        'audio': {
          ...baseAudioConstraints,
          // iOS-specific audio optimizations
          'googEchoCancellation': true,
          'googAutoGainControl': true,
          'googNoiseSuppression': true,
        },
        'video': baseVideoConstraints,
      };
    } else if (_isAndroid) {
      // Android constraints
      return {
        'audio': {
          ...baseAudioConstraints,
          // Android-specific audio constraints
          'googEchoCancellation': true,
          'googAutoGainControl': true,
          'googNoiseSuppression': true,
          'googHighpassFilter': true,
          'googTypingNoiseDetection': true,
          'googAudioMirroring': false,
          'googDAEchoCancellation': true,
          'googNoiseReduction': true,
        },
        'video': baseVideoConstraints != false ? {
          ...(baseVideoConstraints as Map<String, dynamic>),
          // Android-specific video constraints
          'googCpuOveruseDetection': true,
          'googLeakyBucket': true,
          'googScreencastMinBitrate': 1000,
          'googCpuUnderuseThreshold': 55,
          'googCpuOveruseThreshold': 65,
        } : false,
      };
    } else if (_isWeb) {
      // Web browser constraints
      return {
        'audio': {
          ...baseAudioConstraints,
          // Web-specific audio constraints
          'googEchoCancellation': true,
          'googAutoGainControl': true,
          'googNoiseSuppression': true,
        },
        'video': baseVideoConstraints,
      };
    } else {
      // Default constraints
      return {
        'audio': baseAudioConstraints,
        'video': baseVideoConstraints,
      };
    }
  }

  /// Handle ICE gathering completion for cross-platform compatibility
  void _handleIceGatheringComplete() {
    print('🧊 ICE gathering complete - ensuring cross-platform compatibility...');
    
    // For iOS/Chrome compatibility, add a small delay to ensure all candidates are processed
    Timer(Duration(milliseconds: 100), () {
      if (_peerConnection != null && _callState.value == CallState.connecting) {
        print('🧊 ICE gathering complete - connection should be established soon');
      }
    });
  }

  /// Handle Android-specific connection issues
  void _handleAndroidConnectionIssues() {
    print('🤖 Android-specific connection handling...');
    
    // Add a delay for Android to properly initialize WebRTC
    Timer(Duration(milliseconds: 500), () {
      if (_peerConnection != null && _callState.value == CallState.connecting) {
        print('🤖 Android: Re-checking connection state...');
        
        // Force ICE gathering restart for Android
        try {
          _peerConnection!.restartIce();
          print('🤖 Android: ICE gathering restarted');
        } catch (e) {
          print('❌ Android ICE restart failed: $e');
        }
      }
    });
  }

  /// Process queued ICE candidates after remote description is set
  Future<void> _processQueuedIceCandidates() async {
    if (_queuedIceCandidates == null || _queuedIceCandidates!.isEmpty) {
      return;
    }
    
    print('📞 Processing ${_queuedIceCandidates!.length} queued ICE candidates...');
    
    // Batch add in parallel for speed
    final futures = <Future>[];
    for (final candidateData in _queuedIceCandidates!) {
      futures.add(Future(() async {
        try {
          final candidateStrFull = (candidateData['candidate']?.toString() ?? '');
          if (candidateStrFull.contains(' 127.0.0.1 ') || candidateStrFull.contains(' ::1 ') || candidateStrFull.contains(' 169.254.')) {
            print('⚠️ Skipping loopback/link-local queued ICE candidate');
            return;
          }
          final candidate = RTCIceCandidate(
            candidateData['candidate'],
            candidateData['sdp_mid'],
            candidateData['sdp_mline_index'],
          );
          print('🧊 Processing queued ICE candidate:');
          final candidateStr = candidateData['candidate']?.toString() ?? '';
          print('   - Candidate (first 80 chars): ${candidateStr.length > 80 ? candidateStr.substring(0, 80) : candidateStr}...');
          print('   - SDP MID: ${candidateData['sdp_mid']}');
          print('   - SDP MLine Index: ${candidateData['sdp_mline_index']}');
          await _peerConnection?.addCandidate(candidate);
          print('✅ Queued ICE candidate added successfully');
        } catch (e) {
          print('❌ Error adding queued ICE candidate: $e');
          final candidateStr = candidateData['candidate']?.toString() ?? '';
          print('❌ Candidate data: ${candidateStr.length > 100 ? candidateStr.substring(0, 100) : candidateStr}');
        }
      }));
    }
    await Future.wait(futures);
    _queuedIceCandidates = null;
    print('✅ All queued ICE candidates processed');
  }

  // Small delayed batch flush to avoid interleaving during SDP set
  void _scheduleFlushQueuedIceCandidates() {
    _queuedIceFlushTimer?.cancel();
    _queuedIceFlushTimer = Timer(const Duration(milliseconds: 80), () async {
      if (_readyToAddRemoteCandidates) {
        await _processQueuedIceCandidates();
      }
    });
  }

  /// CRITICAL FIX: Reset service state for new call
  Future<void> _resetServiceState() async {
    try {
      print('📞 Resetting WebRTCService state...');
      
      // Cancel all timers
      _iceConnectionTimeout?.cancel();
      _noAnswerTimeout?.cancel();
      _relayWarnTimer?.cancel();
      _iceQuickFallbackTimer?.cancel();
      _queuedIceFlushTimer?.cancel();
      
      // Cancel all subscriptions
      _answerSubscription?.cancel();
      _iceCandidatesSubscription?.cancel();
      _callStateSubscription?.cancel();
      _callSessionStateSubscription?.cancel();
      
      // Reset all state variables
      _localStream = null;
      _remoteStream = null;
      _peerConnection = null;
      _currentCallId = null;
      _currentMatchId = null;
      _isInitialized = false;
      _isEnding = false;
      _queuedIceCandidates = null;
      _readyToAddRemoteCandidates = false;
      _answerApplied = false;
      _hasRelayCandidate = false;
      _lastDbState = null;
      
      // CRITICAL FIX: Force update call state to initial to clear UI
      _updateCallState(CallState.initial);
      
      print('✅ WebRTCService state reset completed');
    } catch (e) {
      print('❌ Error resetting WebRTCService state: $e');
    }
  }

  /// CRITICAL FIX: Force reset call state (public method for external calls)
  Future<void> forceResetCallState() async {
    print('📞 FORCE RESET: Resetting call state...');
    await _resetServiceState();
    _updateCallState(CallState.initial);
    print('✅ FORCE RESET: Call state reset completed');
  }

  @override
  void onClose() {
    print('📞 WebRTCService onClose called - cleaning up...');
    
    // CRITICAL FIX: Ensure proper cleanup on service disposal
    try {
      // Cancel all timers immediately
      _iceConnectionTimeout?.cancel();
      _noAnswerTimeout?.cancel();
      _relayWarnTimer?.cancel();
      _iceQuickFallbackTimer?.cancel();
      _queuedIceFlushTimer?.cancel();
      
      // Cancel all subscriptions
      _answerSubscription?.cancel();
      _iceCandidatesSubscription?.cancel();
      _callStateSubscription?.cancel();
      _callSessionStateSubscription?.cancel();
      
      // Stop all tracks if streams exist
      if (_localStream != null) {
        _localStream!.getTracks().forEach((track) {
          try {
            track.stop();
          } catch (e) {
            print('⚠️ Error stopping track in onClose: $e');
          }
        });
      }
      
      if (_remoteStream != null) {
        _remoteStream!.getTracks().forEach((track) {
          try {
            track.stop();
          } catch (e) {
            print('⚠️ Error stopping remote track in onClose: $e');
          }
        });
      }
      
      // Close peer connection
      if (_peerConnection != null) {
        try {
          _peerConnection!.close();
        } catch (e) {
          print('⚠️ Error closing peer connection in onClose: $e');
        }
      }
      
      // Dispose streams
      _localStream?.dispose();
      _remoteStream?.dispose();
      
      // Clear all references
      _localStream = null;
      _remoteStream = null;
      _peerConnection = null;
      _queuedIceCandidates = null;
      _currentCallId = null;
      _currentMatchId = null;
      _isEnding = false;
      
      print('✅ WebRTCService cleanup completed');
    } catch (e) {
      print('❌ Error in WebRTCService onClose: $e');
    }
    
    super.onClose();
  }

  // =============================================================================
  // CALL NOTIFICATION METHODS
  // =============================================================================

  Future<void> _sendCallRejectedNotification() async {
    try {
      if (_currentMatchId == null) return;

      // Get the other participant's ID
      final otherUserId = await _getOtherParticipantId(_currentMatchId!);
      if (otherUserId == null) return;

      // Get current user's name
      final currentProfile = await SupabaseService.getProfile(SupabaseService.currentUser?.id ?? '');
      final currentUserName = currentProfile?['name'] ?? 'Unknown';

      // Determine call type
      final callType = _isVideoEnabled.value ? 'video' : 'audio';

      // Send call rejected notification
      await PushNotificationService.sendCallRejectedNotification(
        userId: otherUserId,
        callerName: currentUserName,
        callType: callType,
      );

      print('✅ Call rejected notification sent');
    } catch (e) {
      print('Error sending call rejected notification: $e');
    }
  }

  Future<void> _sendMissedCallNotification() async {
    try {
      if (_currentMatchId == null) return;

      // Get the other participant's ID
      final otherUserId = await _getOtherParticipantId(_currentMatchId!);
      if (otherUserId == null) return;

      // Get current user's name
      final currentProfile = await SupabaseService.getProfile(SupabaseService.currentUser?.id ?? '');
      final currentUserName = currentProfile?['name'] ?? 'Unknown';

      // Determine call type
      final callType = _isVideoEnabled.value ? 'video' : 'audio';

      // Send missed call notification
      await PushNotificationService.sendMissedCallNotification(
        userId: otherUserId,
        callerName: currentUserName,
        callType: callType,
      );

      print('✅ Missed call notification sent');
    } catch (e) {
      print('Error sending missed call notification: $e');
    }
  }

  Future<String?> _getOtherParticipantId(String matchId) async {
    try {
      final response = await SupabaseService.client
          .from('matches')
          .select('user_id_1, user_id_2')
          .eq('id', matchId)
          .single();

      final currentUserId = SupabaseService.currentUser?.id;
      if (currentUserId == null) return null;

      return response['user_id_1'] == currentUserId 
          ? response['user_id_2'] 
          : response['user_id_1'];
    } catch (e) {
      print('Error getting other participant ID: $e');
      return null;
    }
  }

  /// NEW METHOD: Receiver join with offer polling (iOS CallKit integration)
  Future<void> receiverJoinWithPolling({
    required String callId,
    required String callType,
    required String matchId,
  }) async {
    print('🍎 ===========================================');
    print('🍎 RECEIVER JOIN WITH POLLING');
    print('🍎 Call ID: $callId');
    print('🍎 ===========================================');
    
    try {
      // Poll for offer (2s × 3 attempts = 6s max)
      final offer = await _pollForOffer(callId, maxAttempts: 3, interval: 2000);
      
      if (offer != null) {
        print('✅ Offer found after polling - proceeding to join...');
        
        // Initialize as receiver with the offer
        await initializeCall(
          roomId: callId,
          callType: callType == 'video' ? CallType.video : CallType.audio,
          matchId: matchId,
          isBffMatch: false,
          isInitiator: false,
        );
        
        // Join with the polled offer
        await _joinRoom(callId);
        
      } else {
        print('⚠️ No offer found after 6s - flipping to caller mode...');
        
        // Fallback: become caller
        await initializeCall(
          roomId: callId,
          callType: callType == 'video' ? CallType.video : CallType.audio,
          matchId: matchId,
          isBffMatch: false,
          isInitiator: true, // Flip to caller
        );
      }
      
    } catch (e) {
      print('❌ Error in receiverJoinWithPolling: $e');
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>?> _pollForOffer(
    String callId, {
    int maxAttempts = 3,
    int interval = 2000,
  }) async {
    print('🔍 Polling for offer - max attempts: $maxAttempts, interval: ${interval}ms');
    
    for (int i = 0; i < maxAttempts; i++) {
      print('🔍 Poll attempt ${i + 1}/$maxAttempts...');
      
      try {
        // FIX: Query webrtc_rooms table for offer, not call_sessions
        final response = await SupabaseService.client
            .from('webrtc_rooms')
            .select('offer')
            .eq('room_id', callId)
            .maybeSingle();
        
        if (response != null && response['offer'] != null && response['offer'].toString().isNotEmpty) {
          print('✅ Offer found on attempt ${i + 1}');
          return response;
        }
        
        // Check if call was cancelled/declined by querying call_sessions
        final callStateResponse = await SupabaseService.client
            .from('call_sessions')
            .select('state')
            .eq('id', callId)
            .maybeSingle();
        
        if (callStateResponse != null) {
          final state = callStateResponse['state'] ?? '';
          if (state == 'declined' || state == 'canceled' || state == 'ended') {
            print('⚠️ Call state is $state - stopping poll');
            return null;
          }
        }
        
        print('⏳ No offer yet, waiting ${interval}ms...');
        
        if (i < maxAttempts - 1) {
          await Future.delayed(Duration(milliseconds: interval));
        }
        
      } catch (e) {
        print('❌ Error polling for offer: $e');
        if (i < maxAttempts - 1) {
          await Future.delayed(Duration(milliseconds: interval));
        }
      }
    }
    
    print('⚠️ No offer found after $maxAttempts attempts');
    return null;
  }
}
