import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';

class CustomCropPage extends StatefulWidget {
  final Uint8List imageBytes;
  const CustomCropPage({super.key, required this.imageBytes});

  @override
  State<CustomCropPage> createState() => _CustomCropPageState();
}

class _CustomCropPageState extends State<CustomCropPage> {
  final CropController _controller = CropController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with proper padding
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(null),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Crop Image',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.white),
                    onPressed: () {
                      _controller.crop();
                    },
                  ),
                ],
              ),
            ),

            // Crop area
            Expanded(
              child: Center(
                child: Crop(
                  image: widget.imageBytes,
                  controller: _controller,
                  onCropped: (croppedBytes) {
                    Navigator.of(context).pop(croppedBytes);
                  },
                  aspectRatio: 1,
                  withCircleUi: false,
                  initialSize: 0.8,
                  baseColor: Colors.black,
                  maskColor: Colors.black.withOpacity(0.65),
                  cornerDotBuilder: (size, edgeAlignment) => Container(
                    width: size,
                    height: size,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),

            // Bottom padding
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}


