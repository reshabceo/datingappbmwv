import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../Common/widget_constant.dart';
import '../../Common/textfield_constant.dart';
import '../../ThemeController/theme_controller.dart';
import 'controller_profile_form_screen.dart';

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (text.length <= 2) {
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    } else if (text.length <= 4) {
      return TextEditingValue(
        text: '${text.substring(0, 2)}/${text.substring(2)}',
        selection: TextSelection.collapsed(offset: '${text.substring(0, 2)}/${text.substring(2)}'.length),
      );
    } else if (text.length <= 8) {
      return TextEditingValue(
        text: '${text.substring(0, 2)}/${text.substring(2, 4)}/${text.substring(4)}',
        selection: TextSelection.collapsed(offset: '${text.substring(0, 2)}/${text.substring(2, 4)}/${text.substring(4)}'.length),
      );
    } else {
      return TextEditingValue(
        text: '${text.substring(0, 2)}/${text.substring(2, 4)}/${text.substring(4, 8)}',
        selection: TextSelection.collapsed(offset: '${text.substring(0, 2)}/${text.substring(2, 4)}/${text.substring(4, 8)}'.length),
      );
    }
  }
}

class MultiStepProfileForm extends StatefulWidget {
  const MultiStepProfileForm({super.key});

  @override
  State<MultiStepProfileForm> createState() => _MultiStepProfileFormState();
}

class _MultiStepProfileFormState extends State<MultiStepProfileForm> {
  late final ProfileFormController controller;
  final ThemeController themeController = Get.find<ThemeController>();
  
  @override
  void initState() {
    super.initState();
    controller = Get.put(ProfileFormController());
    // Add listener to date controller to trigger rebuilds
    controller.dateOfBirthController.addListener(() {
      setState(() {});
    });
  }
  
  @override
  void dispose() {
    controller.dateOfBirthController.removeListener(() {});
    super.dispose();
  }
  
  int currentStep = 0;
  final int totalSteps = 6; // Increased to 6 steps to include gender selection

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: currentStep > 0 
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: themeController.whiteColor),
              onPressed: () {
                setState(() {
                  currentStep--;
                });
              },
            )
          : null,
        title: Text(
          'Complete Your Profile',
          style: TextStyle(
            color: themeController.whiteColor,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: Get.width,
        height: Get.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              themeController.blackColor,
              themeController.bgGradient1,
              themeController.blackColor,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Status Bar Spacing
            SizedBox(height: MediaQuery.of(context).padding.top + 60.h),
            // Progress Indicator
            Container(
              padding: EdgeInsets.all(20.w),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Step ${currentStep + 1} of $totalSteps',
                        style: TextStyle(
                          color: themeController.whiteColor,
                          fontSize: 14.sp,
                        ),
                      ),
                      Spacer(),
                      Text(
                        '${((currentStep + 1) / totalSteps * 100).round()}%',
                        style: TextStyle(
                          color: themeController.lightPinkColor,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  LinearProgressIndicator(
                    value: (currentStep + 1) / totalSteps,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      themeController.lightPinkColor,
                    ),
                  ),
                ],
              ),
            ),
            
            // Step Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: _buildStepContent(),
              ),
            ),
            
            // Navigation Buttons
            Container(
              padding: EdgeInsets.all(24.w),
              child: Row(
                children: [
                  if (currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            currentStep--;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: themeController.whiteColor),
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                        ),
                        child: Text(
                          'Back',
                          style: TextStyle(
                            color: themeController.whiteColor,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    ),
                  if (currentStep > 0) SizedBox(width: 16.w),
                  Expanded(
                    child: elevatedButton(
                      title: currentStep == totalSteps - 1 ? 'Complete' : 'Next',
                      textColor: themeController.whiteColor,
                      onPressed: () {
                        if (_validateCurrentStep()) {
                          if (currentStep == totalSteps - 1) {
                            controller.saveProfile();
                          } else {
                            setState(() {
                              currentStep++;
                            });
                          }
                        }
                      },
                      colorsGradient: [
                        themeController.lightPinkColor,
                        themeController.purpleColor,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (currentStep) {
      case 0:
        return _buildGenderStep();
      case 1:
        return _buildBasicInfoStep();
      case 2:
        return _buildPhotosStep();
      case 3:
        return _buildBioStep();
      case 4:
        return _buildInterestsStep();
      case 5:
        return _buildLocationStep();
      default:
        return Container();
    }
  }

  Widget _buildGenderStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I am a',
          style: TextStyle(
            color: themeController.whiteColor,
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'This helps us show you relevant matches',
          style: TextStyle(
            color: themeController.whiteColor.withValues(alpha: 0.7),
            fontSize: 16.sp,
          ),
        ),
        SizedBox(height: 40.h),
        
        // Gender selection buttons
        Obx(() => Column(
          children: [
            // Male option
            GestureDetector(
              onTap: () {
                controller.selectedGender.value = 'Male';
              },
              child: Container(
                width: double.infinity,
                height: 80.h,
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                  color: controller.selectedGender.value == 'Male' 
                    ? themeController.lightPinkColor.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: controller.selectedGender.value == 'Male' 
                      ? themeController.lightPinkColor
                      : Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 20.w),
                    Icon(
                      Icons.male,
                      color: controller.selectedGender.value == 'Male' 
                        ? themeController.lightPinkColor
                        : themeController.whiteColor,
                      size: 32.sp,
                    ),
                    SizedBox(width: 20.w),
                    Text(
                      'Male',
                      style: TextStyle(
                        color: controller.selectedGender.value == 'Male' 
                          ? themeController.lightPinkColor
                          : themeController.whiteColor,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Female option
            GestureDetector(
              onTap: () {
                controller.selectedGender.value = 'Female';
              },
              child: Container(
                width: double.infinity,
                height: 80.h,
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                  color: controller.selectedGender.value == 'Female' 
                    ? themeController.lightPinkColor.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: controller.selectedGender.value == 'Female' 
                      ? themeController.lightPinkColor
                      : Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 20.w),
                    Icon(
                      Icons.female,
                      color: controller.selectedGender.value == 'Female' 
                        ? themeController.lightPinkColor
                        : themeController.whiteColor,
                      size: 32.sp,
                    ),
                    SizedBox(width: 20.w),
                    Text(
                      'Female',
                      style: TextStyle(
                        color: controller.selectedGender.value == 'Female' 
                          ? themeController.lightPinkColor
                          : themeController.whiteColor,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Non-binary option
            GestureDetector(
              onTap: () {
                controller.selectedGender.value = 'Non-binary';
              },
              child: Container(
                width: double.infinity,
                height: 80.h,
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                  color: controller.selectedGender.value == 'Non-binary' 
                    ? themeController.lightPinkColor.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: controller.selectedGender.value == 'Non-binary' 
                      ? themeController.lightPinkColor
                      : Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 20.w),
                    Icon(
                      Icons.transgender,
                      color: controller.selectedGender.value == 'Non-binary' 
                        ? themeController.lightPinkColor
                        : themeController.whiteColor,
                      size: 32.sp,
                    ),
                    SizedBox(width: 20.w),
                    Text(
                      'Non-binary',
                      style: TextStyle(
                        color: controller.selectedGender.value == 'Non-binary' 
                          ? themeController.lightPinkColor
                          : themeController.whiteColor,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        )),
      ],
    );
  }

  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tell us about yourself',
          style: TextStyle(
            color: themeController.whiteColor,
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'This information will help others find you',
          style: TextStyle(
            color: themeController.whiteColor.withValues(alpha: 0.7),
            fontSize: 16.sp,
          ),
        ),
        SizedBox(height: 40.h),
        
        TextFieldConstant(
          height: 56.h,
          hintFontSize: 16.sp,
          hintText: 'Your name',
          hintFontWeight: FontWeight.w500,
          controller: controller.nameController,
        ),
        SizedBox(height: 20.h),
        
        TextFieldConstant(
          height: 56.h,
          hintFontSize: 16.sp,
          hintText: 'Date of Birth (DD/MM/YYYY)',
          hintFontWeight: FontWeight.w500,
          controller: controller.dateOfBirthController,
          keyboardType: TextInputType.datetime,
          inputFormatters: [
            DateInputFormatter(),
          ],
        ),
        SizedBox(height: 12.h),
        // Age display - removed Obx as it's not needed for text controller changes
        if (controller.dateOfBirthController.text.isNotEmpty)
          Builder(
            builder: (context) {
              // Parse DD/MM/YYYY format
              final text = controller.dateOfBirthController.text;
              final parts = text.split('/');
              if (parts.length == 3) {
                try {
                  final day = int.parse(parts[0]);
                  final month = int.parse(parts[1]);
                  final year = int.parse(parts[2]);
                  final birthDate = DateTime(year, month, day);
                  final age = controller.calculateAge(birthDate);
                  return Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      'Age: $age years old',
                      style: TextStyle(
                        color: themeController.whiteColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                } catch (e) {
                  return Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      'Invalid date format',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }
              }
              return SizedBox.shrink();
            },
          ),
      ],
    );
  }

  Widget _buildPhotosStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add your photos',
          style: TextStyle(
            color: themeController.whiteColor,
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Add up to 6 photos to show your personality',
          style: TextStyle(
            color: themeController.whiteColor.withValues(alpha: 0.7),
            fontSize: 16.sp,
          ),
        ),
        SizedBox(height: 40.h),
        
        Expanded(
          child: GetBuilder<ProfileFormController>(
            builder: (controller) => GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.w,
                mainAxisSpacing: 16.h,
                childAspectRatio: 1,
              ),
              itemCount: 6,
            itemBuilder: (context, index) {
              // Add bounds checking to prevent RangeError
              if (index < controller.selectedImages.length && 
                  index < controller.uploadedImageUrls.length) {
                return _buildPhotoItem(index);
              } else {
                return _buildAddPhotoItem();
              }
            },
            ),
          ),
        ),
        SizedBox(height: 16.h),
        GetBuilder<ProfileFormController>(
          builder: (controller) => controller.isUploading.value
            ? Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          themeController.lightPinkColor,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Uploading photos...',
                      style: TextStyle(
                        color: themeController.whiteColor,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              )
            : SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildPhotoItem(int index) {
    // Add bounds checking to prevent RangeError
    if (index >= controller.selectedImages.length || 
        index >= controller.uploadedImageUrls.length) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: Colors.grey,
            width: 2,
          ),
        ),
        child: Center(
          child: Icon(Icons.error, color: Colors.grey),
        ),
      );
    }

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: themeController.lightPinkColor,
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: kIsWeb 
              ? Image.network(
                  controller.uploadedImageUrls[index],
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.error),
                    );
                  },
                )
              : Image.file(
                  File(controller.selectedImages[index].path),
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
          ),
        ),
        Positioned(
          top: 8.h,
          right: 8.w,
          child: GestureDetector(
            onTap: () => controller.removeImage(index),
            child: Container(
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: 16.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddPhotoItem() {
    return GestureDetector(
      onTap: () => controller.pickMultipleImages(),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: themeController.whiteColor.withValues(alpha: 0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              color: themeController.whiteColor.withValues(alpha: 0.7),
              size: 32.sp,
            ),
            SizedBox(height: 8.h),
            Text(
              'Add Photo',
              style: TextStyle(
                color: themeController.whiteColor.withValues(alpha: 0.7),
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBioStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tell us about yourself',
          style: TextStyle(
            color: themeController.whiteColor,
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Write a short bio to help others get to know you',
          style: TextStyle(
            color: themeController.whiteColor.withValues(alpha: 0.7),
            fontSize: 16.sp,
          ),
        ),
        SizedBox(height: 40.h),
        
        Container(
          height: 200.h,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: themeController.whiteColor.withValues(alpha: 0.3),
            ),
          ),
          child: TextField(
            controller: controller.aboutController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            style: TextStyle(
              color: themeController.whiteColor,
              fontSize: 16.sp,
            ),
            decoration: InputDecoration(
              hintText: 'Tell us about yourself...',
              hintStyle: TextStyle(
                color: themeController.whiteColor.withValues(alpha: 0.5),
                fontSize: 16.sp,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16.w),
              filled: true,
              fillColor: Colors.transparent,
            ),
            cursorColor: themeController.whiteColor,
          ),
        ),
      ],
    );
  }

  Widget _buildInterestsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your interests',
          style: TextStyle(
            color: themeController.whiteColor,
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Select your interests to find like-minded people',
          style: TextStyle(
            color: themeController.whiteColor.withValues(alpha: 0.7),
            fontSize: 16.sp,
          ),
        ),
        SizedBox(height: 40.h),
        
        Expanded(
          child: GetBuilder<ProfileFormController>(
            builder: (controller) => GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 12.h,
                childAspectRatio: 3,
              ),
              itemCount: controller.interestsList.length,
              itemBuilder: (context, index) {
                final interest = controller.interestsList[index];
                final isSelected = controller.selectedInterests.contains(interest);
                
                return GestureDetector(
                  onTap: () {
                    if (isSelected) {
                      controller.selectedInterests.remove(interest);
                    } else {
                      if (controller.selectedInterests.length < 5) {
                        controller.selectedInterests.add(interest);
                      } else {
                        Get.snackbar('Limit Reached', 'You can select maximum 5 interests');
                      }
                    }
                    controller.update(); // Trigger rebuild
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected 
                        ? themeController.lightPinkColor
                        : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: isSelected 
                          ? themeController.lightPinkColor
                          : themeController.whiteColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        interest,
                        style: TextStyle(
                          color: isSelected 
                            ? Colors.white
                            : themeController.whiteColor,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        SizedBox(height: 16.h),
        GetBuilder<ProfileFormController>(
          builder: (controller) => Text(
            'Selected: ${controller.selectedInterests.length}/5 (Minimum 2 required)',
            style: TextStyle(
              color: themeController.whiteColor.withValues(alpha: 0.7),
              fontSize: 12.sp,
            ),
          ),
        ),
      ],
    );
  }

  bool _validateCurrentStep() {
    switch (currentStep) {
      case 0: // Gender Selection
        if (controller.selectedGender.value.isEmpty) {
          Get.snackbar('Error', 'Please select your gender');
          return false;
        }
        return true;
      case 1: // Basic Info
        if (controller.nameController.text.isEmpty) {
          Get.snackbar('Error', 'Name is required');
          return false;
        }
        if (controller.dateOfBirthController.text.isEmpty) {
          Get.snackbar('Error', 'Date of birth is required');
          return false;
        }
        // Parse DD/MM/YYYY format
        final text = controller.dateOfBirthController.text;
        final parts = text.split('/');
        if (parts.length != 3) {
          Get.snackbar('Error', 'Invalid date format. Use DD/MM/YYYY');
          return false;
        }
        try {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          final birthDate = DateTime(year, month, day);
          final age = controller.calculateAge(birthDate);
          if (age < 18) {
            Get.snackbar('Error', 'You must be 18 or older');
            return false;
          }
        } catch (e) {
          Get.snackbar('Error', 'Invalid date format. Use DD/MM/YYYY');
          return false;
        }
        return true;
      case 2: // Photos
        if (controller.uploadedImageUrls.isEmpty) {
          Get.snackbar('Error', 'Please upload at least one photo');
          return false;
        }
        return true;
      case 3: // Bio (optional)
        return true;
      case 4: // Interests
        if (controller.selectedInterests.length < 2) {
          Get.snackbar('Error', 'Please select at least 2 interests');
          return false;
        }
        if (controller.selectedInterests.length > 5) {
          Get.snackbar('Error', 'You can select maximum 5 interests');
          return false;
        }
        return true;
      case 5: // Location
        return true;
      default:
        return true;
    }
  }

  Widget _buildLocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your location',
          style: TextStyle(
            color: themeController.whiteColor,
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Help others find you nearby',
          style: TextStyle(
            color: themeController.whiteColor.withValues(alpha: 0.7),
            fontSize: 16.sp,
          ),
        ),
        SizedBox(height: 40.h),
        
        Container(
          height: 200.h,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: themeController.whiteColor.withValues(alpha: 0.3),
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on,
                  color: themeController.lightPinkColor,
                  size: 48.sp,
                ),
                SizedBox(height: 16.h),
                Text(
                  'Location services will be enabled',
                  style: TextStyle(
                    color: themeController.whiteColor,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'We\'ll use your location to show you people nearby',
                  style: TextStyle(
                    color: themeController.whiteColor.withValues(alpha: 0.7),
                    fontSize: 14.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}