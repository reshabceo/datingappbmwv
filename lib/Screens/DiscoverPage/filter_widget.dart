import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/widget_constant.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/Screens/DiscoverPage/enhanced_discover_controller.dart';

class FilterWidget extends StatefulWidget {
  const FilterWidget({Key? key}) : super(key: key);

  @override
  State<FilterWidget> createState() => _FilterWidgetState();
}

class _FilterWidgetState extends State<FilterWidget> {
  final ThemeController themeController = Get.find<ThemeController>();
  final EnhancedDiscoverController controller = Get.find<EnhancedDiscoverController>();
  
  final List<String> genderOptions = ['male', 'female', 'non-binary', 'other'];
  final List<String> ageRanges = ['18-25', '26-35', '36-45', '46+'];
  final List<String> distanceOptions = ['5 km', '10 km', '25 km', '50 km', '100+ km'];
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: themeController.blackColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: themeController.whiteColor.withOpacity(0.2),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.filter_list,
                color: themeController.primaryColor.value,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              TextConstant(
                title: 'Filters',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeController.whiteColor,
              ),
              Spacer(),
              TextButton(
                onPressed: () {
                  // Reset all filters
                  controller.selectedGenders.clear();
                  controller.minAge.value = 18;
                  controller.maxAge.value = 100;
                  controller.maxDistance.value = 50;
                  controller.saveUserPreferences();
                },
                child: TextConstant(
                  title: 'Reset',
                  fontSize: 14,
                  color: themeController.primaryColor.value,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          
          // Gender Filter
          _buildGenderFilter(),
          SizedBox(height: 20.h),
          
          // Age Range Filter
          _buildAgeRangeFilter(),
          SizedBox(height: 20.h),
          
          // Distance Filter
          _buildDistanceFilter(),
          SizedBox(height: 20.h),
          
          // Apply Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                controller.saveUserPreferences();
                Get.back();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeController.primaryColor.value,
                padding: EdgeInsets.symmetric(vertical: 15.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.r),
                ),
              ),
              child: TextConstant(
                title: 'Apply Filters',
                color: themeController.whiteColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextConstant(
          title: 'Gender',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: themeController.whiteColor,
        ),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: genderOptions.map((gender) {
            final isSelected = controller.selectedGenders.contains(gender);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    controller.selectedGenders.remove(gender);
                  } else {
                    controller.selectedGenders.add(gender);
                  }
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? themeController.primaryColor.value
                      : themeController.transparentColor,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isSelected 
                        ? themeController.primaryColor.value
                        : themeController.whiteColor.withOpacity(0.3),
                    width: 1.w,
                  ),
                ),
                child: TextConstant(
                  title: gender.toUpperCase(),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected 
                      ? themeController.whiteColor
                      : themeController.whiteColor.withOpacity(0.7),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAgeRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextConstant(
          title: 'Age Range',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: themeController.whiteColor,
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextConstant(
                    title: 'Min Age',
                    fontSize: 14,
                    color: themeController.whiteColor.withOpacity(0.8),
                  ),
                  SizedBox(height: 5.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: themeController.transparentColor,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: themeController.whiteColor.withOpacity(0.3),
                        width: 1.w,
                      ),
                    ),
                    child: DropdownButton<int>(
                      value: controller.minAge.value,
                      isExpanded: true,
                      underline: SizedBox(),
                      style: TextStyle(
                        color: themeController.whiteColor,
                        fontSize: 14.sp,
                      ),
                      dropdownColor: themeController.blackColor,
                      items: List.generate(83, (index) => index + 18)
                          .map((age) => DropdownMenuItem(
                                value: age,
                                child: Text('$age'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          controller.minAge.value = value;
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextConstant(
                    title: 'Max Age',
                    fontSize: 14,
                    color: themeController.whiteColor.withOpacity(0.8),
                  ),
                  SizedBox(height: 5.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: themeController.transparentColor,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: themeController.whiteColor.withOpacity(0.3),
                        width: 1.w,
                      ),
                    ),
                    child: DropdownButton<int>(
                      value: controller.maxAge.value,
                      isExpanded: true,
                      underline: SizedBox(),
                      style: TextStyle(
                        color: themeController.whiteColor,
                        fontSize: 14.sp,
                      ),
                      dropdownColor: themeController.blackColor,
                      items: List.generate(83, (index) => index + 18)
                          .map((age) => DropdownMenuItem(
                                value: age,
                                child: Text('$age'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          controller.maxAge.value = value;
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDistanceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextConstant(
          title: 'Maximum Distance',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: themeController.whiteColor,
        ),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: distanceOptions.map((distance) {
            final distanceValue = _parseDistance(distance);
            final isSelected = controller.maxDistance.value == distanceValue;
            return GestureDetector(
              onTap: () {
                setState(() {
                  controller.maxDistance.value = distanceValue;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? themeController.primaryColor.value
                      : themeController.transparentColor,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isSelected 
                        ? themeController.primaryColor.value
                        : themeController.whiteColor.withOpacity(0.3),
                    width: 1.w,
                  ),
                ),
                child: TextConstant(
                  title: distance,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected 
                      ? themeController.whiteColor
                      : themeController.whiteColor.withOpacity(0.7),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  int _parseDistance(String distance) {
    if (distance == '100+ km') return 1000; // Use 1000 for unlimited
    return int.parse(distance.replaceAll(' km', ''));
  }
}
