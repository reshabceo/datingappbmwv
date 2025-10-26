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

  // Getters
  static bool get isRecording => _isRecording;
  static bool get isPlaying => _isPlaying;
  static String? get currentRecordingPath => _currentRecordingPath;
  static Duration get recordingDuration => _recordingDuration;
  static Duration get playbackPosition => _playbackPosition;
  static Duration get playbackDuration => _playbackDuration;

  // Callbacks
  static Function(Duration)? onRecordingDurationChanged;
  static Function(Duration, Duration)? onPlaybackPositionChanged;
  static Function()? onRecordingStarted;
  static Function()? onRecordingStopped;
  static Function()? onPlaybackStarted;
  static Function()? onPlaybackStopped;

  /// Check and request microphone permission
  static Future<bool> checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) {
      return true;
    }
    
    final result = await Permission.microphone.request();
    return result.isGranted;
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
      onRecordingStarted?.call();

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
      onRecordingStopped?.call();

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
        onRecordingStopped?.call();
        print('❌ Recording cancelled');
      }
    } catch (e) {
      print('❌ Error cancelling recording: $e');
    }
  }

  /// Play audio file
  static Future<bool> playAudio(String filePath) async {
    try {
      if (_isPlaying) {
        await stopPlayback();
      }

      await _player.play(DeviceFileSource(filePath));
      _isPlaying = true;
      onPlaybackStarted?.call();

      // Listen to position changes
      _player.onPositionChanged.listen((position) {
        _playbackPosition = position;
        onPlaybackPositionChanged?.call(position, _playbackDuration);
      });

      // Listen to duration changes
      _player.onDurationChanged.listen((duration) {
        _playbackDuration = duration;
        onPlaybackPositionChanged?.call(_playbackPosition, duration);
      });

      // Listen to completion
      _player.onPlayerComplete.listen((_) {
        _isPlaying = false;
        _playbackPosition = Duration.zero;
        onPlaybackStopped?.call();
      });

      print('▶️ Started playing: $filePath');
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
        onPlaybackStopped?.call();
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
        onPlaybackStarted?.call();
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
        onRecordingDurationChanged?.call(_recordingDuration);
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
