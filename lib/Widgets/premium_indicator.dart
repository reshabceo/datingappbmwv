import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../services/supabase_service.dart';

class PremiumIndicator extends StatefulWidget {
  final Widget child;
  final PremiumIndicatorPosition position;
  final bool showInProfile;
  final bool showInChat;
  final bool showInActivity;

  const PremiumIndicator({
    Key? key,
    required this.child,
    this.position = PremiumIndicatorPosition.topRight,
    this.showInProfile = true,
    this.showInChat = true,
    this.showInActivity = true,
  }) : super(key: key);

  @override
  State<PremiumIndicator> createState() => _PremiumIndicatorState();
}

class _PremiumIndicatorState extends State<PremiumIndicator> {
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
      if (mounted) {
        setState(() {
          _isPremium = isPremium;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking premium status: $e');
      if (mounted) {
        setState(() {
          _isPremium = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || !_isPremium) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: widget.position == PremiumIndicatorPosition.topLeft ? 8.h : 8.h,
          left: widget.position == PremiumIndicatorPosition.topLeft ? 8.w : null,
          right: widget.position == PremiumIndicatorPosition.topRight ? 8.w : null,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade600, Colors.orange.shade500],
              ),
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 12.sp,
                ),
                SizedBox(width: 4.w),
                Text(
                  'Premium',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

enum PremiumIndicatorPosition {
  topLeft,
  topRight,
}

// Specialized indicators for different contexts
class ProfilePremiumIndicator extends StatelessWidget {
  final Widget child;

  const ProfilePremiumIndicator({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PremiumIndicator(
      position: PremiumIndicatorPosition.topRight,
      child: child,
    );
  }
}

class ChatPremiumIndicator extends StatelessWidget {
  final Widget child;

  const ChatPremiumIndicator({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PremiumIndicator(
      position: PremiumIndicatorPosition.topLeft,
      child: child,
    );
  }
}

class ActivityPremiumIndicator extends StatelessWidget {
  final Widget child;

  const ActivityPremiumIndicator({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PremiumIndicator(
      position: PremiumIndicatorPosition.topRight,
      child: child,
    );
  }
}

// Premium badge widget for standalone use
class PremiumBadge extends StatefulWidget {
  final double? size;
  final bool showText;

  const PremiumBadge({
    Key? key,
    this.size,
    this.showText = true,
  }) : super(key: key);

  @override
  State<PremiumBadge> createState() => _PremiumBadgeState();
}

class _PremiumBadgeState extends State<PremiumBadge> {
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
      if (mounted) {
        setState(() {
          _isPremium = isPremium;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking premium status: $e');
      if (mounted) {
        setState(() {
          _isPremium = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || !_isPremium) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.showText ? 8.w : 6.w,
        vertical: 4.h,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade600, Colors.orange.shade500],
        ),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            color: Colors.white,
            size: (widget.size ?? 12.sp),
          ),
          if (widget.showText) ...[
            SizedBox(width: 4.w),
            Text(
              'Premium',
              style: TextStyle(
                color: Colors.white,
                fontSize: (widget.size ?? 10.sp),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
