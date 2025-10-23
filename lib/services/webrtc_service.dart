import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:lovebug/models/call_models.dart';
import 'package:flutter/material.dart';

class WebRTCService extends GetxController {
  static WebRTCService get instance => Get.find<WebRTCService>();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  
  final Rx<CallState> _callState = CallState.initial.obs;
  final RxBool _isMuted = false.obs;
  final RxBool _isVideoEnabled = true.obs;
  final RxBool _isSpeakerEnabled = false.obs;

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

  // WebRTC Configuration
  final Map<String, dynamic> _webrtcConfiguration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
  };

  @override
  void onInit() {
    super.onInit();
    _callState.listen((state) {
      onCallStateChanged?.call(state);
    });
  }

  Future<void> initializeCall({
    required String roomId,
    required CallType callType,
    required String matchId,
    required bool isBffMatch,
  }) async {
    try {
      _updateCallState(CallState.connecting);
      
      // Initialize local stream
      await _initializeLocalStream(callType);
      
      // Create peer connection
      _peerConnection = await createPeerConnection(_webrtcConfiguration);
      _registerPeerConnectionListeners();
      
      // Add local stream tracks
      _localStream?.getTracks().forEach((track) {
        _peerConnection?.addTrack(track, _localStream!);
      });

      // Set up ICE candidate handling
      _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
        _handleIceCandidate(candidate, roomId);
      };

      // Listen for remote stream
      _peerConnection?.onTrack = (RTCTrackEvent event) {
        _handleRemoteTrack(event);
      };

      // Create or join room based on call action
      await _createOrJoinRoom(roomId);
      
    } catch (e) {
      print('Error initializing call: $e');
      _updateCallState(CallState.failed);
    }
  }

  Future<void> _initializeLocalStream(CallType callType) async {
    final constraints = {
      'audio': true,
      'video': callType == CallType.video,
    };
    
    _localStream = await Helper.openCamera(constraints);
  }

  Future<void> _createOrJoinRoom(String roomId) async {
    try {
      // Check if room exists in Supabase
      final roomData = await SupabaseService.client
          .from('webrtc_rooms')
          .select('*')
          .eq('room_id', roomId)
          .maybeSingle();

      if (roomData == null) {
        // Create new room
        await _createRoom(roomId);
      } else {
        // Join existing room
        await _joinRoom(roomId);
      }
    } catch (e) {
      print('Error in createOrJoinRoom: $e');
      _updateCallState(CallState.failed);
    }
  }

  Future<void> _createRoom(String roomId) async {
    try {
      // Create offer
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      // Store offer in Supabase
      await SupabaseService.client.from('webrtc_rooms').insert({
        'room_id': roomId,
        'offer': offer.toMap(),
        'created_at': DateTime.now().toIso8601String(),
      });

      // Listen for answer
      _listenForAnswer(roomId);
      
    } catch (e) {
      print('Error creating room: $e');
      _updateCallState(CallState.failed);
    }
  }

  Future<void> _joinRoom(String roomId) async {
    try {
      // Get offer from Supabase
      final roomData = await SupabaseService.client
          .from('webrtc_rooms')
          .select('offer')
          .eq('room_id', roomId)
          .single();

      final offer = RTCSessionDescription(
        roomData['offer']['sdp'],
        roomData['offer']['type'],
      );

      await _peerConnection!.setRemoteDescription(offer);

      // Create answer
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      // Store answer in Supabase
      await SupabaseService.client
          .from('webrtc_rooms')
          .update({'answer': answer.toMap()})
          .eq('room_id', roomId);

      // Listen for ICE candidates
      _listenForIceCandidates(roomId);
      
    } catch (e) {
      print('Error joining room: $e');
      _updateCallState(CallState.failed);
    }
  }

  void _listenForAnswer(String roomId) {
    SupabaseService.client
        .from('webrtc_rooms')
        .stream(primaryKey: ['room_id'])
        .eq('room_id', roomId)
        .listen((data) {
      if (data.isNotEmpty && data.first['answer'] != null) {
        final answer = RTCSessionDescription(
          data.first['answer']['sdp'],
          data.first['answer']['type'],
        );
        _peerConnection?.setRemoteDescription(answer);
        _listenForIceCandidates(roomId);
      }
    });
  }

  void _listenForIceCandidates(String roomId) {
    SupabaseService.client
        .from('webrtc_ice_candidates')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .listen((candidates) {
      for (final candidate in candidates) {
        if (candidate['candidate'] != null) {
          _peerConnection?.addCandidate(RTCIceCandidate(
            candidate['candidate'],
            candidate['sdp_mid'],
            candidate['sdp_mline_index'],
          ));
        }
      }
    });
  }

  void _handleIceCandidate(RTCIceCandidate candidate, String roomId) {
    SupabaseService.client.from('webrtc_ice_candidates').insert({
      'room_id': roomId,
      'candidate': candidate.candidate,
      'sdp_mid': candidate.sdpMid,
      'sdp_mline_index': candidate.sdpMLineIndex,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  void _handleRemoteTrack(RTCTrackEvent event) {
    _remoteStream = event.streams[0];
    onRemoteStream?.call(_remoteStream!);
  }

  void _registerPeerConnectionListeners() {
    _peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          _updateCallState(CallState.connected);
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          _updateCallState(CallState.disconnected);
          onCallEnded?.call();
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          _updateCallState(CallState.failed);
          break;
        default:
          break;
      }
    };
  }

  void _updateCallState(CallState state) {
    _callState.value = state;
  }

  // Call control methods
  void toggleMute() {
    _isMuted.value = !_isMuted.value;
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = !_isMuted.value;
    });
  }

  void toggleVideo() {
    _isVideoEnabled.value = !_isVideoEnabled.value;
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = _isVideoEnabled.value;
    });
  }

  void toggleSpeaker() {
    _isSpeakerEnabled.value = !_isSpeakerEnabled.value;
    // Note: Speaker control might need platform-specific implementation
  }

  Future<void> endCall() async {
    try {
      // Stop all tracks
      _localStream?.getTracks().forEach((track) => track.stop());
      _remoteStream?.getTracks().forEach((track) => track.stop());

      // Close peer connection
      await _peerConnection?.close();

      // Clean up
      _localStream?.dispose();
      _remoteStream?.dispose();
      _peerConnection = null;

      _updateCallState(CallState.disconnected);
      onCallEnded?.call();
      
    } catch (e) {
      print('Error ending call: $e');
    }
  }

  @override
  void onClose() {
    endCall();
    super.onClose();
  }
}
