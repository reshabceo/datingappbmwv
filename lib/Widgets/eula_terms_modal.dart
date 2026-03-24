import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../ThemeController/theme_controller.dart';
import '../Common/text_constant.dart';
import '../Common/widget_constant.dart';
import '../shared_prefrence_helper.dart';

class EULATermsModal extends StatefulWidget {
  const EULATermsModal({super.key});

  @override
  State<EULATermsModal> createState() => _EULATermsModalState();
}

class _EULATermsModalState extends State<EULATermsModal> {
  bool _hasAccepted = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onAccept() async {
    if (!_hasAccepted) return;
    
    // Save acceptance status
    await SharedPreferenceHelper.setBool('eula_terms_accepted', true);
    
    // Close the modal
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    
    // CRITICAL FIX: Make modal iPad-friendly with proper constraints
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    
    // Adjust padding for iPad
    final horizontalPadding = isTablet ? 100.w : 20.w;
    final verticalPadding = isTablet ? 60.h : 40.h;
    final maxWidth = isTablet ? 600.w : screenWidth - 40.w;
    final maxHeight = isTablet ? screenHeight * 0.8 : screenHeight - 80.h;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: themeController.isDarkMode.value 
                ? themeController.dialogBGColor1 
                : themeController.whiteColor,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: themeController.lightPinkColor.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    themeController.lightPinkColor,
                    themeController.purpleColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.description,
                    color: themeController.whiteColor,
                    size: 28.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Terms of Service & Privacy Policy',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: themeController.whiteColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'End User License Agreement (EULA)',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: themeController.isDarkMode.value
                            ? themeController.whiteColor
                            : themeController.blackColor,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'By using this application, you agree to the following terms and conditions:',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: themeController.isDarkMode.value
                            ? themeController.whiteColor.withOpacity(0.9)
                            : themeController.blackColor.withOpacity(0.8),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    _buildSection(
                      themeController,
                      '1. Acceptance of Terms',
                      'By accessing and using this dating application, you accept and agree to be bound by the terms and provision of this agreement.',
                    ),
                    _buildSection(
                      themeController,
                      '2. User Conduct',
                      'You agree to use the application in a lawful manner and in accordance with all applicable laws and regulations. You will not engage in any activity that could harm, disable, or impair the application.',
                    ),
                    _buildSection(
                      themeController,
                      '3. Privacy and Data',
                      'Your privacy is important to us. We collect and use your information as described in our Privacy Policy. By using this app, you consent to the collection and use of your information.',
                    ),
                    _buildSection(
                      themeController,
                      '4. User Content',
                      'You are responsible for all content you post or share through the application. You grant us a license to use, modify, and display such content in connection with the service.',
                    ),
                    _buildSection(
                      themeController,
                      '5. Prohibited Activities',
                      'You agree not to: harass, abuse, or harm other users; post false or misleading information; use the service for any illegal purpose; or attempt to gain unauthorized access to the application.',
                    ),
                    _buildSection(
                      themeController,
                      '6. Account Security',
                      'You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account.',
                    ),
                    _buildSection(
                      themeController,
                      '7. Service Modifications',
                      'We reserve the right to modify, suspend, or discontinue any aspect of the service at any time without prior notice.',
                    ),
                    _buildSection(
                      themeController,
                      '8. Limitation of Liability',
                      'To the maximum extent permitted by law, we shall not be liable for any indirect, incidental, special, or consequential damages arising from your use of the application.',
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Privacy Policy',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: themeController.isDarkMode.value
                            ? themeController.whiteColor
                            : themeController.blackColor,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    _buildSection(
                      themeController,
                      'Data Collection',
                      'We collect information you provide directly, including profile information, photos, location data, and messages. We also collect technical information about your device and usage patterns.',
                    ),
                    _buildSection(
                      themeController,
                      'Data Usage',
                      'We use your information to provide, maintain, and improve our services, to communicate with you, and to ensure the safety and security of our platform.',
                    ),
                    _buildSection(
                      themeController,
                      'Data Sharing',
                      'We may share your information with other users as part of the service functionality, with service providers who assist us, and as required by law.',
                    ),
                    _buildSection(
                      themeController,
                      'Your Rights',
                      'You have the right to access, update, or delete your personal information. You can manage your privacy settings within the application.',
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),

            // Checkbox and Accept Button
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: themeController.isDarkMode.value
                    ? themeController.dialogBGColor2
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20.r),
                  bottomRight: Radius.circular(20.r),
                ),
              ),
              child: Column(
                children: [
                  // Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _hasAccepted,
                        onChanged: (value) {
                          setState(() {
                            _hasAccepted = value ?? false;
                          });
                        },
                        activeColor: themeController.lightPinkColor,
                        checkColor: themeController.whiteColor,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _hasAccepted = !_hasAccepted;
                            });
                          },
                          child: Text(
                            'I have read and agree to the Terms of Service and Privacy Policy',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: themeController.isDarkMode.value
                                  ? themeController.whiteColor.withOpacity(0.9)
                                  : themeController.blackColor.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  // Accept Button
                  SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: elevatedButton(
                      height: 50.h,
                      fontSize: 16,
                      title: 'Accept & Continue',
                      onPressed: _hasAccepted ? _onAccept : null,
                      isGradient: _hasAccepted,
                      backGroundColor: _hasAccepted ? null : Colors.grey,
                    ),
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

  Widget _buildSection(ThemeController themeController, String title, String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
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
          SizedBox(height: 6.h),
          Text(
            content,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w400,
              height: 1.5,
              color: themeController.isDarkMode.value
                  ? themeController.whiteColor.withOpacity(0.8)
                  : themeController.blackColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

