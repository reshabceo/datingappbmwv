import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/widget_constant.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/Screens/DiscoverPage/enhanced_discover_controller.dart';
import 'package:lovebug/services/supabase_service.dart';

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
  // Removed fixed distanceOptions; use dynamic options based on premium
  bool _isPremium = false;
  bool _isLoadingPremium = true;

  List<String> get _distanceOptions => _isPremium
      ? ['5 km', '10 km', '25 km', '50 km', '200 km', '500 km', '1000 km', '5000 km', '10726 km']
      : ['5 km', '10 km', '25 km', '50 km', '200 km'];

  @override
  void initState() {
    super.initState();
    _loadPremium();
  }

  Future<void> _loadPremium() async {
    try {
      final isPremium = await SupabaseService.isPremiumUser();
      if (!mounted) return;
      setState(() {
        _isPremium = isPremium;
        _isLoadingPremium = false;
      });
      _clampMaxDistanceToTier();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isPremium = false;
        _isLoadingPremium = false;
      });
      _clampMaxDistanceToTier();
    }
  }

  void _clampMaxDistanceToTier() {
    final int maxAllowed = _isPremium ? 10726 : 200;
    if (controller.maxDistance.value > maxAllowed) {
      controller.maxDistance.value = maxAllowed;
      // Save the clamped value to preferences
      controller.saveUserPreferences();
    }
  }

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
                title: 'filters',
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
                  // Reset distance based on premium status
                  final int defaultDistance = _isPremium ? 50 : 50; // Default to 50 km for both
                  controller.maxDistance.value = defaultDistance;
                  controller.saveUserPreferences();
                },
                child: TextConstant(
                  title: 'reset',
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
                title: 'apply_filters',
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
          title: 'gender',
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
          title: 'age_range',
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
                    title: 'min_age',
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
                    title: 'max_age',
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
    // Premium accounts: max distance 10726 km (unlimited)
    // Normal accounts: max distance 200 km
    // Only show distance options that are allowed for the current tier
    final int maxAllowed = _isPremium ? 10726 : 200;
    final filteredOptions = _distanceOptions.where((distance) {
      final distanceValue = _parseDistance(distance);
      return distanceValue <= maxAllowed;
    }).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextConstant(
          title: 'maximum_distance',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: themeController.whiteColor,
        ),
        SizedBox(height: 10.h),
        if (_isLoadingPremium)
          Center(
            child: Padding(
              padding: EdgeInsets.all(16.h),
              child: CircularProgressIndicator(
                color: themeController.primaryColor.value,
              ),
            ),
          )
        else
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: filteredOptions.map((distance) {
              final distanceValue = _parseDistance(distance);
              final isSelected = controller.maxDistance.value == distanceValue;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    // Ensure the selected distance doesn't exceed the tier limit
                    final int selectedDistance = distanceValue > maxAllowed ? maxAllowed : distanceValue;
                    controller.maxDistance.value = selectedDistance;
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
    // Extract digits robustly, supports formats like '200 km', '10726 km'
    final match = RegExp(r'\d+').firstMatch(distance);
    if (match != null) {
      return int.parse(match.group(0)!);
    }
    // Fallbacks (legacy)
    if (distance.contains('100+')) return 100; 
    return 0;
  }
}
