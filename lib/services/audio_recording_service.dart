import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioRecordingService {
  static final AudioRecorder _recorder = AudioRecorder();
  static final AudioPlayer _player = AudioPlayer();
  
  static bool _isRecording = false;
  static bool _isPlaying = false;
  static String? _currentRecordingPath;
  static Duration _recordingDuration = Duration.zero;
  static Duration _playbackPosition = Duration.zero;
  static Duration _playbackDuration = Duration.zero;
  static String? _currentAudioUrl;

  // Getters
  static bool get isRecording => _isRecording;
  static bool get isPlaying => _isPlaying;
  static String? get currentRecordingPath => _currentRecordingPath;
  static Duration get recordingDuration => _recordingDuration;
  static Duration get playbackPosition => _playbackPosition;
  static Duration get playbackDuration => _playbackDuration;
  static String? get currentAudioUrl => _currentAudioUrl;

  // Callback registries (multiple listeners)
  static final List<void Function(Duration)> _onRecordingDurationChanged = [];
  static final List<void Function(Duration, Duration)> _onPlaybackPositionChanged = [];
  static final List<VoidCallback> _onRecordingStarted = [];
  static final List<VoidCallback> _onRecordingStopped = [];
  static final List<VoidCallback> _onPlaybackStarted = [];
  static final List<VoidCallback> _onPlaybackStopped = [];

  // Back-compat legacy callback holders (for external code assigning single callbacks)
  static void Function(Duration)? _legacyOnRecordingDurationChanged;
  static void Function(Duration, Duration)? _legacyOnPlaybackPositionChanged;
  static VoidCallback? _legacyOnRecordingStarted;
  static VoidCallback? _legacyOnRecordingStopped;
  static VoidCallback? _legacyOnPlaybackStarted;
  static VoidCallback? _legacyOnPlaybackStopped;

  // Back-compat setters/getters
  static set onRecordingDurationChanged(void Function(Duration)? cb) {
    if (_legacyOnRecordingDurationChanged != null) {
      _onRecordingDurationChanged.remove(_legacyOnRecordingDurationChanged!);
    }
    _legacyOnRecordingDurationChanged = cb;
    if (cb != null) {
      _onRecordingDurationChanged.add(cb);
    }
  }
  static void Function(Duration)? get onRecordingDurationChanged => _legacyOnRecordingDurationChanged;

  static set onPlaybackPositionChanged(void Function(Duration, Duration)? cb) {
    if (_legacyOnPlaybackPositionChanged != null) {
      _onPlaybackPositionChanged.remove(_legacyOnPlaybackPositionChanged!);
    }
    _legacyOnPlaybackPositionChanged = cb;
    if (cb != null) {
      _onPlaybackPositionChanged.add(cb);
    }
  }
  static void Function(Duration, Duration)? get onPlaybackPositionChanged => _legacyOnPlaybackPositionChanged;

  static set onRecordingStarted(VoidCallback? cb) {
    if (_legacyOnRecordingStarted != null) {
      _onRecordingStarted.remove(_legacyOnRecordingStarted!);
    }
    _legacyOnRecordingStarted = cb;
    if (cb != null) {
      _onRecordingStarted.add(cb);
    }
  }
  static VoidCallback? get onRecordingStarted => _legacyOnRecordingStarted;

  static set onRecordingStopped(VoidCallback? cb) {
    if (_legacyOnRecordingStopped != null) {
      _onRecordingStopped.remove(_legacyOnRecordingStopped!);
    }
    _legacyOnRecordingStopped = cb;
    if (cb != null) {
      _onRecordingStopped.add(cb);
    }
  }
  static VoidCallback? get onRecordingStopped => _legacyOnRecordingStopped;

  static set onPlaybackStarted(VoidCallback? cb) {
    if (_legacyOnPlaybackStarted != null) {
      _onPlaybackStarted.remove(_legacyOnPlaybackStarted!);
    }
    _legacyOnPlaybackStarted = cb;
    if (cb != null) {
      _onPlaybackStarted.add(cb);
    }
  }
  static VoidCallback? get onPlaybackStarted => _legacyOnPlaybackStarted;

  static set onPlaybackStopped(VoidCallback? cb) {
    if (_legacyOnPlaybackStopped != null) {
      _onPlaybackStopped.remove(_legacyOnPlaybackStopped!);
    }
    _legacyOnPlaybackStopped = cb;
    if (cb != null) {
      _onPlaybackStopped.add(cb);
    }
  }
  static VoidCallback? get onPlaybackStopped => _legacyOnPlaybackStopped;

  static void addPlaybackListeners({
    void Function(Duration, Duration)? onPosition,
    VoidCallback? onStarted,
    VoidCallback? onStopped,
  }) {
    if (onPosition != null) _onPlaybackPositionChanged.add(onPosition);
    if (onStarted != null) _onPlaybackStarted.add(onStarted);
    if (onStopped != null) _onPlaybackStopped.add(onStopped);
  }

  static void removePlaybackListeners({
    void Function(Duration, Duration)? onPosition,
    VoidCallback? onStarted,
    VoidCallback? onStopped,
  }) {
    if (onPosition != null) _onPlaybackPositionChanged.remove(onPosition);
    if (onStarted != null) _onPlaybackStarted.remove(onStarted);
    if (onStopped != null) _onPlaybackStopped.remove(onStopped);
  }

  static void addRecordingListeners({
    void Function(Duration)? onDuration,
    VoidCallback? onStarted,
    VoidCallback? onStopped,
  }) {
    if (onDuration != null) _onRecordingDurationChanged.add(onDuration);
    if (onStarted != null) _onRecordingStarted.add(onStarted);
    if (onStopped != null) _onRecordingStopped.add(onStopped);
  }

  static void removeRecordingListeners({
    void Function(Duration)? onDuration,
    VoidCallback? onStarted,
    VoidCallback? onStopped,
  }) {
    if (onDuration != null) _onRecordingDurationChanged.remove(onDuration);
    if (onStarted != null) _onRecordingStarted.remove(onStarted);
    if (onStopped != null) _onRecordingStopped.remove(onStopped);
  }

  /// Check and request microphone permission
  static Future<bool> checkMicrophonePermission() async {
    print('🎤 DEBUG: Checking microphone permission...');

    // First check permission_handler status
    final status = await Permission.microphone.status;
    print('🎤 DEBUG: Permission.microphone.status = $status');

    if (status.isGranted) {
      print('🎤 DEBUG: Permission granted via permission_handler');

      // Double-check with recorder's own permission check
      try {
        final has = await _recorder.hasPermission();
        print('🎤 DEBUG: AudioRecorder.hasPermission() = $has');
        if (has == true) {
          print('🎤 DEBUG: Both checks passed - permission confirmed');
          return true;
        } else {
          print('🎤 DEBUG: Recorder says no permission, but permission_handler says granted - requesting again');
        }
      } catch (e) {
        print('🎤 DEBUG: Recorder permission check failed: $e');
      }
    }

    // If not granted or recorder disagrees, request permission
    print('🎤 DEBUG: Requesting microphone permission...');
    final result = await Permission.microphone.request();
    print('🎤 DEBUG: Permission request result = $result');

    if (result.isGranted) {
      // Final check with recorder after granting
      try {
        final has = await _recorder.hasPermission();
        print('🎤 DEBUG: After granting, AudioRecorder.hasPermission() = $has');
        return has == true;
      } catch (e) {
        print('🎤 DEBUG: Recorder check failed after granting: $e');
        return true; // Assume it's granted if permission_handler says so
      }
    }

    // If permission is permanently denied, show user-friendly message
    if (status.isPermanentlyDenied) {
      print('🎤 DEBUG: Microphone permission permanently denied');
      return false;
    }

    return false;
  }

  /// Reset microphone permission state after video calls
  static Future<void> resetMicrophoneState() async {
    print('🎤 DEBUG: Resetting microphone state after video call...');
    
    try {
      // Force a fresh permission check
      final status = await Permission.microphone.status;
      print('🎤 DEBUG: Current permission status after reset: $status');
      
      if (status.isGranted) {
        // Stop any ongoing recording and reset state
        if (_isRecording) {
          await stopRecording();
        }
        print('🎤 DEBUG: Microphone state reset after video call');
      }
    } catch (e) {
      print('🎤 DEBUG: Error resetting microphone state: $e');
    }
  }

  /// Start recording audio
  static Future<bool> startRecording() async {
    try {
      // Check permission
      if (!await checkMicrophonePermission()) {
        print('❌ Microphone permission denied');
        return false;
      }

      // Stop any existing recording
      if (_isRecording) {
        await stopRecording();
      }

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${tempDir.path}/audio_$timestamp.m4a';

      // Start recording
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
      _recordingDuration = Duration.zero;
      for (final cb in _onRecordingStarted) { cb(); }

      // Start duration timer
      _startDurationTimer();

      print('🎤 Started recording: $_currentRecordingPath');
      return true;
    } catch (e) {
      print('❌ Error starting recording: $e');
      return false;
    }
  }

  /// Stop recording audio
  static Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return null;

      final path = await _recorder.stop();
      _isRecording = false;
      for (final cb in _onRecordingStopped) { cb(); }

      print('🛑 Stopped recording: $path');
      return path;
    } catch (e) {
      print('❌ Error stopping recording: $e');
      return null;
    }
  }

  /// Cancel current recording
  static Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _recorder.cancel();
        _isRecording = false;
        _currentRecordingPath = null;
        _recordingDuration = Duration.zero;
        for (final cb in _onRecordingStopped) { cb(); }
        print('❌ Recording cancelled');
      }
    } catch (e) {
      print('❌ Error cancelling recording: $e');
    }
  }

  /// Play audio file or URL
  static Future<bool> playAudio(String pathOrUrl) async {
    try {
      if (_isPlaying) {
        await stopPlayback();
      }

      // Ensure proper audio routing (iOS speaker + silent switch override; Android speakerphone)
      await _player.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: <AVAudioSessionOptions>{
              AVAudioSessionOptions.mixWithOthers,
            },
          ),
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
        ),
      );

      // Choose source based on whether it's a URL or local file path
      if (pathOrUrl.startsWith('http')) {
        print('🔊 DEBUG: Playing remote URL');
        await _player.play(UrlSource(pathOrUrl));
      } else {
        print('🔊 DEBUG: Playing local file');
        await _player.play(DeviceFileSource(pathOrUrl));
      }
      _isPlaying = true;
      _currentAudioUrl = pathOrUrl;
      for (final cb in _onPlaybackStarted) { cb(); }

      // Listen to position changes
      _player.onPositionChanged.listen((position) {
        _playbackPosition = position;
        for (final cb in _onPlaybackPositionChanged) { cb(position, _playbackDuration); }
      });

      // Listen to duration changes
      _player.onDurationChanged.listen((duration) {
        _playbackDuration = duration;
        for (final cb in _onPlaybackPositionChanged) { cb(_playbackPosition, duration); }
      });

      // Listen to completion
      _player.onPlayerComplete.listen((_) {
        _isPlaying = false;
        _playbackPosition = Duration.zero;
        for (final cb in _onPlaybackStopped) { cb(); }
      });

      print('▶️ Started playing: $pathOrUrl');
      return true;
    } catch (e) {
      print('❌ Error playing audio: $e');
      return false;
    }
  }

  /// Stop audio playback
  static Future<void> stopPlayback() async {
    try {
      if (_isPlaying) {
        await _player.stop();
        _isPlaying = false;
        _playbackPosition = Duration.zero;
        _currentAudioUrl = null;
        for (final cb in _onPlaybackStopped) { cb(); }
        print('⏹️ Stopped playback');
      }
    } catch (e) {
      print('❌ Error stopping playback: $e');
    }
  }

  /// Pause audio playback
  static Future<void> pausePlayback() async {
    try {
      if (_isPlaying) {
        await _player.pause();
        print('⏸️ Paused playback');
      }
    } catch (e) {
      print('❌ Error pausing playback: $e');
    }
  }

  /// Resume audio playback
  static Future<void> resumePlayback() async {
    try {
      if (!_isPlaying && _playbackPosition > Duration.zero) {
        await _player.resume();
        _isPlaying = true;
        for (final cb in _onPlaybackStarted) { cb(); }
        print('▶️ Resumed playback');
      }
    } catch (e) {
      print('❌ Error resuming playback: $e');
    }
  }

  /// Get audio file duration
  static Future<Duration> getAudioDuration(String filePath) async {
    try {
      final player = AudioPlayer();
      await player.setSource(DeviceFileSource(filePath));
      final duration = await player.getDuration();
      await player.dispose();
      return duration ?? Duration.zero;
    } catch (e) {
      print('❌ Error getting audio duration: $e');
      return Duration.zero;
    }
  }

  /// Get audio file size in bytes
  static Future<int> getAudioFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      print('❌ Error getting audio file size: $e');
      return 0;
    }
  }

  /// Convert audio file to bytes
  static Future<Uint8List?> getAudioBytes(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      print('❌ Error reading audio file: $e');
      return null;
    }
  }

  /// Clean up resources
  static Future<void> dispose() async {
    try {
      if (_isRecording) {
        await cancelRecording();
      }
      if (_isPlaying) {
        await stopPlayback();
      }
      await _recorder.dispose();
      await _player.dispose();
    } catch (e) {
      print('❌ Error disposing audio service: $e');
    }
  }

  /// Start duration timer for recording
  static void _startDurationTimer() {
    Future.delayed(Duration(seconds: 1), () {
      if (_isRecording) {
        _recordingDuration = Duration(seconds: _recordingDuration.inSeconds + 1);
        for (final cb in _onRecordingDurationChanged) { cb(_recordingDuration); }
        _startDurationTimer();
      }
    });
  }

  /// Format duration to MM:SS
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
