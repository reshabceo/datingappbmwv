import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Screens/VerificationPage/verification_screen.dart';

class VerificationBadge extends StatelessWidget {
  final String verificationStatus;
  final VoidCallback? onTap;

  const VerificationBadge({
    Key? key,
    required this.verificationStatus,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    switch (verificationStatus) {
      case 'verified':
        badgeColor = Colors.green;
        badgeText = 'Verified';
        badgeIcon = Icons.verified;
        break;
      case 'pending':
        badgeColor = Colors.orange;
        badgeText = 'Under Review';
        badgeIcon = Icons.hourglass_empty;
        break;
      case 'rejected':
        badgeColor = Colors.red;
        badgeText = 'Rejected';
        badgeIcon = Icons.cancel;
        break;
      default:
        badgeColor = Colors.grey;
        badgeText = 'Not Verified';
        badgeIcon = Icons.person_off;
    }

    return GestureDetector(
      onTap: onTap ?? () => Get.to(() => const VerificationScreen()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: badgeColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: badgeColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              badgeIcon,
              color: badgeColor,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              badgeText,
              style: TextStyle(
                color: badgeColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (verificationStatus == 'unverified' || verificationStatus == 'rejected')
              const SizedBox(width: 4),
            if (verificationStatus == 'unverified' || verificationStatus == 'rejected')
              Icon(
                Icons.arrow_forward_ios,
                color: badgeColor,
                size: 12,
              ),
          ],
        ),
      ),
    );
  }
}
