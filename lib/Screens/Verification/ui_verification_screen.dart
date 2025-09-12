import 'dart:io';
import 'package:boliler_plate/Common/text_constant.dart';
import 'package:boliler_plate/Common/widget_constant.dart';
import 'package:boliler_plate/ThemeController/theme_controller.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../services/supabase_service.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final ThemeController theme = Get.find<ThemeController>();
  CameraController? _controller;
  Future<void>? _initFuture;
  XFile? _video;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final cameras = await availableCameras();
    final front = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front, orElse: () => cameras.first);
    _controller = CameraController(front, ResolutionPreset.medium, enableAudio: true);
    _initFuture = _controller!.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _startRecord() async {
    if (_controller == null) return;
    if (_controller!.value.isRecordingVideo) return;
    await _controller!.prepareForVideoRecording();
    await _controller!.startVideoRecording();
    setState(() {});
  }

  Future<void> _stopRecord() async {
    if (_controller == null) return;
    if (!_controller!.value.isRecordingVideo) return;
    final file = await _controller!.stopVideoRecording();
    _video = file;
    setState(() {});
  }

  Future<void> _upload() async {
    if (_video == null) return;
    try {
      setState(() { _uploading = true; });
      final bytes = await _video!.readAsBytes();
      final uid = SupabaseService.currentUser?.id ?? 'anon';
      final path = uid + '/verification_' + DateTime.now().millisecondsSinceEpoch.toString() + '.mp4';
      await SupabaseService.uploadFile(bucket: 'profile-photos', path: path, fileBytes: bytes);
      Get.snackbar('Submitted', 'Verification uploaded. We\'ll review shortly.');
      Get.back();
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      setState(() { _uploading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.blackColor,
        title: TextConstant(title: 'Verify Profile', color: theme.whiteColor),
      ),
      backgroundColor: theme.blackColor,
      body: FutureBuilder(
        future: _initFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              Expanded(
                child: _video == null
                    ? CameraPreview(_controller!)
                    : Container(
                        color: Colors.black,
                        alignment: Alignment.center,
                        child: Text('Video recorded', style: TextStyle(color: Colors.white)),
                      ),
              ),
              Container(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _controller?.value.isRecordingVideo == true ? null : _startRecord,
                      child: Text('Record'),
                    ),
                    ElevatedButton(
                      onPressed: _controller?.value.isRecordingVideo == true ? _stopRecord : null,
                      child: Text('Stop'),
                    ),
                    ElevatedButton(
                      onPressed: (!_uploading && _video != null) ? _upload : null,
                      child: _uploading ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text('Submit'),
                    ),
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }
}


