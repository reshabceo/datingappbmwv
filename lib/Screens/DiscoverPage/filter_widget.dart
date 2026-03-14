import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/widget_constant.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/Screens/DiscoverPage/controller_discover_screen.dart';
import 'package:lovebug/services/supabase_service.dart';

class FilterWidget extends StatefulWidget {
  const FilterWidget({Key? key}) : super(key: key);

  @override
  State<FilterWidget> createState() => _FilterWidgetState();
}

class _FilterWidgetState extends State<FilterWidget> {
  final ThemeController themeController = Get.find<ThemeController>();
  final DiscoverController controller = Get.find<DiscoverController>();
  
  final List<String> genderOptions = ['male', 'female', 'non-binary', 'other'];
  final List<String> ageRanges = ['18-25', '26-35', '36-45', '46+'];
  // No local premium state, use controller.isPremium
  bool get _isPremium => controller.isPremium.value;

  List<String> get _distanceOptions => _isPremium
      ? ['5 km', '10 km', '25 km', '50 km', '200 km', '300 km', '500 km', '750 km', '10726 km']
      : ['5 km', '10 km', '25 km', '50 km', '100 km', '150 km', '200 km'];


  @override
  void initState() {
    super.initState();
    // No need to load premium manually, controller handles it
  }

  void _clampMaxDistanceToTier() {
    final int maxAllowed = _isPremium ? 10726 : 200;
    if (controller.maxDistanceKm.value > maxAllowed) {
      controller.maxDistanceKm.value = maxAllowed.toDouble();
      // Save the clamped value to preferences
      controller.saveFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    final modeAccent = themeController.getAccentColor();
    final modeSecondary = themeController.getSecondaryColor();
    
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 20.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0F172A), // Dark slate/navy
            themeController.blackColor,
            const Color(0xFF1E1E1E),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30.r),
          topRight: Radius.circular(30.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: EdgeInsets.only(bottom: 15.h),
              width: 40.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: themeController.whiteColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2.5.r),
              ),
            ),
          ),
          
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: modeAccent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.tune,
                  color: modeAccent,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              TextConstant(
                title: 'filters',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: themeController.whiteColor,
              ),
              Spacer(),
              TextButton(
                onPressed: () {
                  controller.gender.value = 'Everyone';
                  controller.minAge.value = 18;
                  controller.maxAge.value = 99;
                  controller.maxDistanceKm.value = 50.0;
                  controller.saveFilters();
                },
                child: TextConstant(
                  title: 'reset',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: modeAccent.withOpacity(0.8),
                ),
              ),
            ],
          ),
          
          Divider(
            color: themeController.whiteColor.withOpacity(0.1),
            height: 30.h,
          ),
          
          // Gender Filter
          _buildGenderFilter(modeAccent),
          SizedBox(height: 24.h),
          
          // Age Range Filter
          _buildAgeRangeFilter(modeAccent),
          SizedBox(height: 24.h),
          
          // Distance Filter
          _buildDistanceFilter(modeAccent),
          SizedBox(height: 30.h),
          
          // Apply Button
          ElevatedButton(
            onPressed: () {
              controller.saveFilters();
              controller.reloadWithFilters();
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.r),
              ),
              elevation: 8,
              shadowColor: modeAccent.withOpacity(0.4),
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [modeAccent, modeSecondary],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(25.r),
              ),
              child: Container(
                width: double.infinity,
                height: 55.h,
                alignment: Alignment.center,
                child: TextConstant(
                  title: 'apply_filters',
                  color: themeController.whiteColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 10.h),
        ],
      ),
    );
  }

  Widget _buildGenderFilter(Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextConstant(
          title: 'gender',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: themeController.whiteColor,
        ),
        SizedBox(height: 12.h),
        Obx(() => Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: genderOptions.map((gender) {
            final isSelected = controller.gender.value.toLowerCase() == gender.toLowerCase();
            return GestureDetector(
              onTap: () {
                if (isSelected) {
                  controller.gender.value = 'Everyone';
                } else {
                  controller.gender.value = gender;
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? accent.withOpacity(0.15)
                      : themeController.blackColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(15.r),
                  border: Border.all(
                    color: isSelected 
                        ? accent
                        : themeController.whiteColor.withOpacity(0.1),
                    width: 1.5.w,
                  ),
                ),
                child: TextConstant(
                  title: gender.replaceAll('_', ' ').toUpperCase(),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected 
                      ? accent
                      : themeController.whiteColor.withOpacity(0.6),
                ),
              ),
            );
          }).toList(),
        )),
      ],
    );
  }

  Widget _buildAgeRangeFilter(Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextConstant(
          title: 'age_range',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: themeController.whiteColor,
        ),
        SizedBox(height: 12.h),
        Obx(() {
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextConstant(
                    title: 'min_age',
                    fontSize: 12,
                    color: themeController.whiteColor.withOpacity(0.4),
                  ),
                  TextConstant(
                    title: '${controller.minAge.value} - ${controller.maxAge.value}',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                  TextConstant(
                    title: 'max_age',
                    fontSize: 12,
                    color: themeController.whiteColor.withOpacity(0.4),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: accent,
                  inactiveTrackColor: themeController.whiteColor.withOpacity(0.05),
                  thumbColor: themeController.whiteColor,
                  overlayColor: accent.withOpacity(0.2),
                  rangeThumbShape: RoundRangeSliderThumbShape(
                    enabledThumbRadius: 10.r,
                    elevation: 4,
                    pressedElevation: 8,
                  ),
                  rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
                  trackHeight: 6.h,
                ),
                child: RangeSlider(
                  values: RangeValues(
                    controller.minAge.value.toDouble(),
                    controller.maxAge.value.toDouble(),
                  ),
                  min: 18.0,
                  max: 99.0,
                  divisions: 81,
                  onChanged: (values) {
                    controller.minAge.value = values.start.round();
                    controller.maxAge.value = values.end.round();
                  },
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildDistanceFilter(Color accent) {
    // Premium accounts: max distance 10726 km
    // Normal accounts: max distance 200 km
    final double maxAllowedVal = _isPremium ? 10726.0 : 200.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextConstant(
          title: 'maximum_distance',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: themeController.whiteColor,
        ),
        SizedBox(height: 12.h),
        Obx(() {
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextConstant(
                    title: '0 km',
                    fontSize: 12,
                    color: themeController.whiteColor.withOpacity(0.4),
                  ),
                  TextConstant(
                    title: '${controller.maxDistanceKm.value.round()} km',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                  TextConstant(
                    title: '${maxAllowedVal.round()} km',
                    fontSize: 12,
                    color: themeController.whiteColor.withOpacity(0.4),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: accent,
                  inactiveTrackColor: themeController.whiteColor.withOpacity(0.05),
                  thumbColor: themeController.whiteColor,
                  overlayColor: accent.withOpacity(0.2),
                  thumbShape: RoundSliderThumbShape(
                    enabledThumbRadius: 10.r,
                    elevation: 4,
                    pressedElevation: 8,
                  ),
                  trackHeight: 6.h,
                ),
                child: Slider(
                  value: controller.maxDistanceKm.value.clamp(0.0, maxAllowedVal).toDouble(),
                  min: 0.0,
                  max: maxAllowedVal,
                  divisions: maxAllowedVal > 1000 ? 100 : maxAllowedVal.toInt(),
                  activeColor: accent,
                  onChanged: (value) {
                    controller.maxDistanceKm.value = value;
                  },
                ),
              ),
            ],
          );
        }),
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
