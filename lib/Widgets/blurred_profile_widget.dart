import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
import '../services/supabase_service.dart';
import '../services/payment_service.dart';
import '../Screens/SubscriptionPage/ui_subscription_screen.dart';

class BlurredProfileWidget extends StatefulWidget {
  final Widget child;
  final String? upgradeMessage;
  final bool showUpgradeButton;
  final VoidCallback? onUpgrade;

  const BlurredProfileWidget({
    Key? key,
    required this.child,
    this.upgradeMessage,
    this.showUpgradeButton = true,
    this.onUpgrade,
  }) : super(key: key);

  @override
  State<BlurredProfileWidget> createState() => _BlurredProfileWidgetState();
}

class _BlurredProfileWidgetState extends State<BlurredProfileWidget> {
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
      return widget.child; // Show normal content while loading
    }

    if (_isPremium) {
      return widget.child; // Show clear content for premium users
    }

    // Show blurred content for free users
    return Stack(
      children: [
        // Blurred content
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: widget.child,
            ),
          ),
        ),
        
        // Upgrade overlay
        if (widget.showUpgradeButton)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.9),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Lock icon
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_outline,
                        size: 32.w,
                        color: Colors.white,
                      ),
                    ),
                    
                    SizedBox(height: 16.h),
                    
                    // Upgrade message
                    Text(
                      widget.upgradeMessage ?? 'Upgrade to see full profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 2),
                            blurRadius: 4,
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: 8.h),
                    
                    Text(
                      'Get unlimited swipes, see who liked you, and more!',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14.sp,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 2,
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: 24.h),
                    
                    // Upgrade button
                    ElevatedButton(
                      onPressed: () {
                        if (widget.onUpgrade != null) {
                          widget.onUpgrade!();
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SubscriptionScreen(),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 32.w,
                          vertical: 12.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.r),
                        ),
                        elevation: 8,
                        shadowColor: Colors.pink.withOpacity(0.3),
                      ),
                      child: Text(
                        'Upgrade Now',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Specialized widget for activity feed blurring
class BlurredActivityWidget extends StatelessWidget {
  final Widget child;
  final String activityType; // 'like', 'message', 'match'
  final VoidCallback? onTap;

  const BlurredActivityWidget({
    Key? key,
    required this.child,
    required this.activityType,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Blurred content
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
            child: Container(
              color: Colors.black.withOpacity(0.2),
              child: child,
            ),
          ),
        ),
        
        // Generic message overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Activity icon
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getActivityIcon(),
                      size: 24.w,
                      color: Colors.white,
                    ),
                  ),
                  
                  SizedBox(height: 12.h),
                  
                  // Generic message
                  Text(
                    _getGenericMessage(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: 4.h),
                  
                  Text(
                    'Upgrade to see who it is',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getActivityIcon() {
    switch (activityType) {
      case 'like':
        return Icons.favorite;
      case 'super_like':
        return Icons.star;
      case 'message':
        return Icons.message;
      case 'match':
        return Icons.celebration;
      default:
        return Icons.notifications;
    }
  }

  String _getGenericMessage() {
    switch (activityType) {
      case 'like':
        return 'Someone liked your profile';
      case 'super_like':
        return 'Someone super liked you!';
      case 'message':
        return 'Someone sent you a message';
      case 'match':
        return 'You have a new match!';
      default:
        return 'New activity';
    }
  }
}
