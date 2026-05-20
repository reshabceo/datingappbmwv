import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/models/call_models.dart';

class IncomingCallModal extends StatefulWidget {
  final String callerName;
  final String? callerImage;
  final String callType;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const IncomingCallModal({
    super.key,
    required this.callerName,
    this.callerImage,
    required this.callType,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<IncomingCallModal> createState() => _IncomingCallModalState();
}

class _IncomingCallModalState extends State<IncomingCallModal> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isVideo = widget.callType == 'video';
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                themeController.dialogBGColor1.withValues(alpha: 0.85),
                themeController.dialogBGColor2.withValues(alpha: 0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(
              color: themeController.getAccentColor().withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: themeController.getAccentColor().withValues(alpha: 0.15),
                blurRadius: 25,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Premium Header with Gradient
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 20.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      themeController.getAccentColor(),
                      themeController.getSecondaryColor(),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.r),
                    topRight: Radius.circular(30.r),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                      color: Colors.white,
                      size: 32.sp,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Incoming ${isVideo ? 'Video' : 'Audio'} Call',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  children: [
                    // Caller avatar with pulse effect
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: 110.w,
                        height: 110.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: themeController.getAccentColor(),
                            width: 3.w,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: themeController.getAccentColor().withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: widget.callerImage != null && widget.callerImage!.isNotEmpty
                              ? Image.network(
                                  widget.callerImage!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildDefaultAvatar(themeController),
                                )
                              : _buildDefaultAvatar(themeController),
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    
                    // Caller name
                    Text(
                      widget.callerName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26.sp,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'wants to connect with you',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14.sp,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 32.h),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            label: 'Decline',
                            color: Colors.redAccent,
                            icon: Icons.close_rounded,
                            onTap: widget.onDecline,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: _buildActionButton(
                            label: 'Accept',
                            color: Colors.greenAccent.shade700,
                            icon: Icons.check_rounded,
                            onTap: widget.onAccept,
                            isPrimary: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    final themeController = Get.find<ThemeController>();
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          color: isPrimary ? null : color.withValues(alpha: 0.15),
          gradient: isPrimary ? LinearGradient(
            colors: [
              themeController.getAccentColor(),
              themeController.getSecondaryColor(),
            ],
          ) : null,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: isPrimary ? themeController.getAccentColor().withValues(alpha: 0.5) : color.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(ThemeController themeController) {
    return Container(
      color: themeController.getAccentColor().withValues(alpha: 0.2),
      child: Center(
        child: Text(
          widget.callerName.isNotEmpty ? widget.callerName[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 40.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
