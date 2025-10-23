import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../services/premium_message_service.dart';
import '../services/supabase_service.dart';
import '../Screens/DiscoverPage/controller_discover_screen.dart';
import '../ThemeController/theme_controller.dart';

class PremiumMessageButton extends StatefulWidget {
  final String recipientId;
  final String recipientName;
  final String recipientPhoto;

  const PremiumMessageButton({
    Key? key,
    required this.recipientId,
    required this.recipientName,
    required this.recipientPhoto,
  }) : super(key: key);

  @override
  State<PremiumMessageButton> createState() => _PremiumMessageButtonState();
}

class _PremiumMessageButtonState extends State<PremiumMessageButton> {
  bool _isPremium = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    try {
      final isPremium = await SupabaseService.isPremiumUser();
      setState(() {
        _isPremium = isPremium;
        _isLoading = false;
      });
    } catch (e) {
      print('Error checking premium status: $e');
      setState(() {
        _isPremium = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox.shrink(); // Don't show while loading
    }

    // Get theme and discover controllers
    final themeController = Get.find<ThemeController>();
    bool isBffMode = false;
    if (Get.isRegistered<DiscoverController>()) {
      try {
        final discoverController = Get.find<DiscoverController>();
        isBffMode = discoverController.currentMode.value == 'bff';
      } catch (_) {}
    }

    // Gradient colors based on mode
    final List<Color> gradientColors = isBffMode
        ? [
            themeController.bffPrimaryColor.withValues(alpha: 0.7),
            themeController.bffSecondaryColor.withValues(alpha: 0.7),
          ]
        : [
            themeController.lightPinkColor.withValues(alpha: 0.7),
            Colors.purple.withValues(alpha: 0.7),
          ];

    return Positioned(
      top: 20.h,
      left: 20.w,
      child: GestureDetector(
        onTap: () {
          PremiumMessageService.showPremiumMessageDialog(
            recipientId: widget.recipientId,
            recipientName: widget.recipientName,
            recipientPhoto: widget.recipientPhoto,
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradientColors),
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: (isBffMode ? themeController.bffPrimaryColor : themeController.lightPinkColor).withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Text(
            _isPremium ? 'Send Message' : 'Premium',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// Specialized widget for profile cards
class ProfilePremiumMessageButton extends StatelessWidget {
  final String recipientId;
  final String recipientName;
  final String recipientPhoto;

  const ProfilePremiumMessageButton({
    Key? key,
    required this.recipientId,
    required this.recipientName,
    required this.recipientPhoto,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PremiumMessageButton(
      recipientId: recipientId,
      recipientName: recipientName,
      recipientPhoto: recipientPhoto,
    );
  }
}
