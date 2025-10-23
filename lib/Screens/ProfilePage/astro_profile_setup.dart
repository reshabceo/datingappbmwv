import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/widget_constant.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/services/astro_service.dart';
import 'package:lovebug/services/supabase_service.dart';

class AstroProfileSetup extends StatefulWidget {
  const AstroProfileSetup({Key? key}) : super(key: key);

  @override
  State<AstroProfileSetup> createState() => _AstroProfileSetupState();
}

class _AstroProfileSetupState extends State<AstroProfileSetup> {
  final ThemeController themeController = Get.find<ThemeController>();
  final PageController pageController = PageController();
  int currentPage = 0;
  
  DateTime? selectedBirthDate;
  String? selectedGender;
  bool isLoading = false;

  final List<String> genders = ['male', 'female', 'non-binary', 'other', 'prefer not to say'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: themeController.blackColor,
      appBar: AppBar(
        backgroundColor: themeController.transparentColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: themeController.whiteColor),
          onPressed: () => Get.back(),
        ),
        title: TextConstant(
          title: 'Complete Your Profile',
          color: themeController.whiteColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: true,
      ),
      body: PageView(
        controller: pageController,
        onPageChanged: (page) {
          setState(() {
            currentPage = page;
          });
        },
        children: [
          _buildBirthDatePage(),
          _buildGenderPage(),
          _buildSummaryPage(),
        ],
      ),
    );
  }

  Widget _buildBirthDatePage() {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 40.h),
          Center(
            child: Icon(
              Icons.cake,
              size: 80.sp,
              color: themeController.primaryColor.value,
            ),
          ),
          SizedBox(height: 30.h),
          TextConstant(
            title: 'When\'s your birthday?',
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: themeController.whiteColor,
          ),
          SizedBox(height: 10.h),
          TextConstant(
            title: 'We\'ll use this to calculate your zodiac sign and show you astrological compatibility with your matches!',
            fontSize: 16,
            color: themeController.whiteColor.withOpacity(0.8),
            height: 1.4,
          ),
          SizedBox(height: 40.h),
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: themeController.transparentColor,
              borderRadius: BorderRadius.circular(15.r),
              border: Border.all(
                color: themeController.whiteColor.withOpacity(0.2),
                width: 1.w,
              ),
            ),
            child: Column(
              children: [
                if (selectedBirthDate != null) ...[
                  TextConstant(
                    title: 'Selected Date',
                    fontSize: 16,
                    color: themeController.whiteColor.withOpacity(0.8),
                  ),
                  SizedBox(height: 10.h),
                  TextConstant(
                    title: _formatDate(selectedBirthDate!),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: themeController.primaryColor.value,
                  ),
                  SizedBox(height: 10.h),
                  TextConstant(
                    title: 'Zodiac Sign: ${AstroService.getZodiacEmoji(AstroService.calculateZodiacSign(selectedBirthDate!))} ${AstroService.calculateZodiacSign(selectedBirthDate!).toUpperCase()}',
                    fontSize: 16,
                    color: themeController.whiteColor,
                  ),
                ] else ...[
                  TextConstant(
                    title: 'Tap to select your birth date',
                    fontSize: 16,
                    color: themeController.whiteColor.withOpacity(0.6),
                  ),
                ],
                SizedBox(height: 20.h),
                ElevatedButton(
                  onPressed: _selectBirthDate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeController.primaryColor.value,
                    padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 15.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25.r),
                    ),
                  ),
                  child: TextConstant(
                    title: selectedBirthDate != null ? 'Change Date' : 'Select Date',
                    color: themeController.whiteColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Spacer(),
          _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildGenderPage() {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 40.h),
          Center(
            child: Icon(
              Icons.person,
              size: 80.sp,
              color: themeController.primaryColor.value,
            ),
          ),
          SizedBox(height: 30.h),
          TextConstant(
            title: 'What\'s your gender?',
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: themeController.whiteColor,
          ),
          SizedBox(height: 10.h),
          TextConstant(
            title: 'This helps us show you more relevant matches and compatibility insights.',
            fontSize: 16,
            color: themeController.whiteColor.withOpacity(0.8),
            height: 1.4,
          ),
          SizedBox(height: 40.h),
          ...genders.map((gender) => _buildGenderOption(gender)),
          Spacer(),
          _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildGenderOption(String gender) {
    final isSelected = selectedGender == gender;
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedGender = gender;
          });
        },
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isSelected 
                ? themeController.primaryColor.value.withOpacity(0.2)
                : themeController.transparentColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected 
                  ? themeController.primaryColor.value
                  : themeController.whiteColor.withOpacity(0.2),
              width: isSelected ? 2.w : 1.w,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected 
                    ? themeController.primaryColor.value
                    : themeController.whiteColor.withOpacity(0.6),
                size: 20.sp,
              ),
              SizedBox(width: 12.w),
              TextConstant(
                title: gender.toUpperCase(),
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected 
                    ? themeController.primaryColor.value
                    : themeController.whiteColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryPage() {
    final zodiacSign = selectedBirthDate != null 
        ? AstroService.calculateZodiacSign(selectedBirthDate!)
        : 'Unknown';
    
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 40.h),
          Center(
            child: Icon(
              Icons.auto_awesome,
              size: 80.sp,
              color: themeController.primaryColor.value,
            ),
          ),
          SizedBox(height: 30.h),
          TextConstant(
            title: 'Perfect! You\'re all set!',
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: themeController.whiteColor,
          ),
          SizedBox(height: 10.h),
          TextConstant(
            title: 'Now you\'ll see astrological compatibility and personalized ice breakers in your chats!',
            fontSize: 16,
            color: themeController.whiteColor.withOpacity(0.8),
            height: 1.4,
          ),
          SizedBox(height: 40.h),
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  themeController.primaryColor.value.withOpacity(0.2),
                  themeController.primaryColor.value.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15.r),
              border: Border.all(
                color: themeController.primaryColor.value.withOpacity(0.3),
                width: 1.w,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      AstroService.getZodiacEmoji(zodiacSign),
                      style: TextStyle(fontSize: 30.sp),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextConstant(
                            title: 'Your Zodiac Sign',
                            fontSize: 14,
                            color: themeController.whiteColor.withOpacity(0.8),
                          ),
                          TextConstant(
                            title: zodiacSign.toUpperCase(),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: themeController.whiteColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: themeController.primaryColor.value,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    TextConstant(
                      title: 'Gender: ${selectedGender?.toUpperCase() ?? 'Not specified'}',
                      fontSize: 16,
                      color: themeController.whiteColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Spacer(),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    final canProceed = currentPage == 0 
        ? selectedBirthDate != null
        : currentPage == 1 
            ? selectedGender != null
            : true;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canProceed ? _nextPage : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canProceed 
              ? themeController.primaryColor.value
              : themeController.whiteColor.withOpacity(0.3),
          padding: EdgeInsets.symmetric(vertical: 15.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.r),
          ),
        ),
        child: TextConstant(
          title: currentPage < 2 ? 'Next' : 'Complete',
          color: themeController.whiteColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: themeController.primaryColor.value,
          padding: EdgeInsets.symmetric(vertical: 15.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.r),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 20.h,
                width: 20.w,
                child: CircularProgressIndicator(
                  color: themeController.whiteColor,
                  strokeWidth: 2,
                ),
              )
            : TextConstant(
                title: 'Save & Continue',
                color: themeController.whiteColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
      ),
    );
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedBirthDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: themeController.primaryColor.value,
              onPrimary: themeController.whiteColor,
              surface: themeController.blackColor,
              onSurface: themeController.whiteColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedBirthDate = picked;
      });
    }
  }

  void _nextPage() {
    if (currentPage < 2) {
      pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _saveProfile() async {
    if (selectedBirthDate == null || selectedGender == null) {
      Get.snackbar('Error', 'Please complete all fields');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Compute zodiac and update profile with birth date, gender and zodiac
      final zodiac = AstroService.calculateZodiacSign(selectedBirthDate!);
      final response = await SupabaseService.client
          .from('profiles')
          .update({
            'birth_date': selectedBirthDate!.toIso8601String().split('T')[0],
            'gender': selectedGender,
            'zodiac_sign': zodiac,
          })
          .eq('id', currentUser.id);

      if (response.error != null) {
        throw response.error!;
      }

      Get.snackbar('Success', 'Profile updated successfully!');
      Get.back();
    } catch (e) {
      print('Error saving profile: $e');
      Get.snackbar('Error', 'Failed to save profile. Please try again.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
