import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../ThemeController/theme_controller.dart';
import '../shared_prefrence_helper.dart';

/// Full-screen EULA gate shown inline (not as a dialog route) to avoid
/// stacked dialogs and navigator pop issues.
class EULATermsModal extends StatefulWidget {
  final VoidCallback onAccepted;

  const EULATermsModal({
    super.key,
    required this.onAccepted,
  });

  @override
  State<EULATermsModal> createState() => _EULATermsModalState();
}

class _EULATermsModalState extends State<EULATermsModal> {
  bool _hasAccepted = false;
  bool _isSubmitting = false;

  Future<void> _onAccept() async {
    if (!_hasAccepted || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    await SharedPreferenceHelper.setBool(
      SharedPreferenceHelper.eulaTermsAccepted,
      true,
    );

    if (!mounted) return;
    widget.onAccepted();
  }

  void _setAccepted(bool value) {
    if (_isSubmitting || _hasAccepted == value) return;
    setState(() => _hasAccepted = value);
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDarkMode.value;
    final bgColor = isDark ? themeController.dialogBGColor1 : themeController.whiteColor;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Material(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _buildHeader(themeController),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: _buildTermsContent(themeController, isDark),
                      ),
                    ),
                    _buildFooter(themeController, isDark),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeController themeController) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [themeController.lightPinkColor, themeController.purpleColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.description, color: themeController.whiteColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Terms of Service & Privacy Policy',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: themeController.whiteColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsContent(ThemeController themeController, bool isDark) {
    final textColor = isDark ? themeController.whiteColor : themeController.blackColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'End User License Agreement (EULA)',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: textColor),
        ),
        const SizedBox(height: 12),
        Text(
          'By using this application, you agree to the following terms and conditions:',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: textColor.withOpacity(0.85),
          ),
        ),
        const SizedBox(height: 16),
        _buildSection(themeController, '1. Acceptance of Terms',
            'By accessing and using this dating application, you accept and agree to be bound by the terms and provision of this agreement.'),
        _buildSection(themeController, '2. User Conduct',
            'You agree to use the application in a lawful manner and in accordance with all applicable laws and regulations. You will not engage in any activity that could harm, disable, or impair the application.'),
        _buildSection(themeController, '3. Privacy and Data',
            'Your privacy is important to us. We collect and use your information as described in our Privacy Policy. By using this app, you consent to the collection and use of your information.'),
        _buildSection(themeController, '4. User Content',
            'You are responsible for all content you post or share through the application. You grant us a license to use, modify, and display such content in connection with the service.'),
        _buildSection(themeController, '5. Prohibited Activities',
            'You agree not to: harass, abuse, or harm other users; post false or misleading information; use the service for any illegal purpose; or attempt to gain unauthorized access to the application.'),
        _buildSection(themeController, '6. Account Security',
            'You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account.'),
        _buildSection(themeController, '7. Service Modifications',
            'We reserve the right to modify, suspend, or discontinue any aspect of the service at any time without prior notice.'),
        _buildSection(themeController, '8. Limitation of Liability',
            'To the maximum extent permitted by law, we shall not be liable for any indirect, incidental, special, or consequential damages arising from your use of the application.'),
        const SizedBox(height: 16),
        Text(
          'Privacy Policy',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: textColor),
        ),
        const SizedBox(height: 12),
        _buildSection(themeController, 'Data Collection',
            'We collect information you provide directly, including profile information, photos, location data, and messages. We also collect technical information about your device and usage patterns.'),
        _buildSection(themeController, 'Data Usage',
            'We use your information to provide, maintain, and improve our services, to communicate with you, and to ensure the safety and security of our platform.'),
        _buildSection(themeController, 'Data Sharing',
            'We may share your information with other users as part of the service functionality, with service providers who assist us, and as required by law.'),
        _buildSection(themeController, 'Your Rights',
            'You have the right to access, update, or delete your personal information. You can manage your privacy settings within the application.'),
      ],
    );
  }

  Widget _buildFooter(ThemeController themeController, bool isDark) {
    final footerColor = isDark ? themeController.dialogBGColor2 : Colors.grey.shade100;
    final labelColor = isDark
        ? themeController.whiteColor.withOpacity(0.9)
        : themeController.blackColor.withOpacity(0.8);

    return ColoredBox(
      color: footerColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _hasAccepted,
                  onChanged: _isSubmitting
                      ? null
                      : (value) => _setAccepted(value ?? false),
                  activeColor: themeController.lightPinkColor,
                  checkColor: themeController.whiteColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _isSubmitting
                        ? null
                        : () => _setAccepted(!_hasAccepted),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10, right: 4),
                      child: Text(
                        'I have read and agree to the Terms of Service and Privacy Policy',
                        style: TextStyle(fontSize: 13.sp, color: labelColor),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _hasAccepted && !_isSubmitting ? _onAccept : null,
                style: FilledButton.styleFrom(
                  backgroundColor: themeController.lightPinkColor,
                  disabledBackgroundColor: Colors.grey.shade400,
                  foregroundColor: themeController.whiteColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _isSubmitting ? 'Please wait...' : 'Accept & Continue',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(ThemeController themeController, String title, String content) {
    final isDark = themeController.isDarkMode.value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: themeController.lightPinkColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w400,
              height: 1.5,
              color: isDark
                  ? themeController.whiteColor.withOpacity(0.8)
                  : themeController.blackColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
