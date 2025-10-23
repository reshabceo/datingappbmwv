import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lovebug/services/rewind_service.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:lovebug/Screens/SubscriptionPage/ui_subscription_screen.dart';

class RewindButton extends StatefulWidget {
  final VoidCallback? onRewindSuccess;
  final VoidCallback? onRewindError;

  const RewindButton({
    Key? key,
    this.onRewindSuccess,
    this.onRewindError,
  }) : super(key: key);

  @override
  State<RewindButton> createState() => _RewindButtonState();
}

class _RewindButtonState extends State<RewindButton> {
  bool _isPremium = false;
  bool _canRewind = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkRewindStatus();
  }

  Future<void> _checkRewindStatus() async {
    try {
      final isPremium = await SupabaseService.isPremiumUser();
      final canRewind = await RewindService.canRewind();
      
      setState(() {
        _isPremium = isPremium;
        _canRewind = canRewind;
        _isLoading = false;
      });
    } catch (e) {
      print('Error checking rewind status: $e');
      setState(() {
        _isPremium = false;
        _canRewind = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRewind() async {
    if (!_isPremium) {
      RewindService.showRewindUpgradeDialog();
      return;
    }

    if (!_canRewind) {
      Get.snackbar(
        'No Rewind Available',
        'No swipes available to rewind',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // Show confirmation dialog
    RewindService.showRewindDialog(
      onRewind: () async {
        try {
          final result = await RewindService.performRewind();
          
          if (result.containsKey('error')) {
            Get.snackbar('Error', result['error']);
            widget.onRewindError?.call();
            return;
          }

          Get.snackbar(
            'Rewind Successful! 🔄',
            'Your last swipe has been undone',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: Duration(seconds: 2),
          );

          // Refresh rewind status
          await _checkRewindStatus();
          widget.onRewindSuccess?.call();
        } catch (e) {
          Get.snackbar('Error', 'Failed to rewind: $e');
          widget.onRewindError?.call();
        }
      },
      onUpgrade: () {
        Get.to(() => SubscriptionScreen());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox.shrink(); // Don't show while loading
    }

    // ALWAYS show button, but indicate premium status
    return Positioned(
      bottom: 20.h,
      left: 20.w,
      child: GestureDetector(
        onTap: _handleRewind,
        child: Stack(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isPremium 
                    ? [Colors.blue.shade600, Colors.blue.shade400]
                    : [Colors.grey.shade600, Colors.grey.shade500],
                ),
                borderRadius: BorderRadius.circular(25.r),
                boxShadow: [
                  BoxShadow(
                    color: (_isPremium ? Colors.blue : Colors.grey).withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.undo,
                    color: Colors.white,
                    size: 18.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Rewind',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Premium badge for non-premium users
            if (!_isPremium)
              Positioned(
                top: -4.h,
                right: -4.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade600,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 10.sp, color: Colors.white),
                      SizedBox(width: 2.w),
                      Text(
                        'PRO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Specialized widget for discover screen
class DiscoverRewindButton extends StatelessWidget {
  final VoidCallback? onRewindSuccess;

  const DiscoverRewindButton({
    Key? key,
    this.onRewindSuccess,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RewindButton(
      onRewindSuccess: onRewindSuccess,
    );
  }
}
