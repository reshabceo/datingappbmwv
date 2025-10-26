import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/widget_constant.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lovebug/Common/textfield_constant.dart';
import 'package:lovebug/Common/common_gradient_appbar.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/Screens/BottomBarPage/bottombar_screen.dart';
import 'package:lovebug/Screens/ProfileFormPage/controller_profile_form_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProfileFormScreen extends StatelessWidget {
  ProfileFormScreen({super.key});

  final ThemeController themeController = Get.find<ThemeController>();
  final ProfileFormController controller = Get.put(ProfileFormController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientCommonAppBar(
        isCenterTitle: false,
        isActionWidget: false,
        showBackButton: false,
      ),
      bottomNavigationBar: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        width: Get.width,
        child: Padding(
          padding: EdgeInsets.all(15.w),
          child: elevatedButton(
            title: 'complete_profile'.tr,textColor: themeController.whiteColor,
            onPressed: () {
              Get.offAll(() => BottombarScreen());
            },
            colorsGradient: [
              themeController.lightPinkColor,
              themeController.purpleColor,
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
        width: Get.width,
        height: Get.height,
        decoration: BoxDecoration(
          color: themeController.isDarkMode.value ? null : themeController.lightTheme.scaffoldBackgroundColor,
          gradient: themeController.isDarkMode.value
              ? LinearGradient(
            colors: [themeController.blackColor, themeController.bgGradient1, themeController.blackColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
              : null,
        ),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: screenPadding(
            customPadding: EdgeInsets.symmetric(horizontal: 15.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                heightBox(10),
                TextConstant(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  title: 'complete_profile'.tr,
                ),
                heightBox(20),
                TextConstant(
                  fontSize: 14,
                  title: 'name'.tr,
                  fontWeight: FontWeight.bold,
                ),
                heightBox(8),
                TextFieldConstant(
                  height: 44.h,
                  hintFontSize: 14,
                  hintText: 'your_name'.tr,
                  hintFontWeight: FontWeight.bold,
                  keyboardType: TextInputType.name,
                  controller: controller.nameController,
                ),
                heightBox(15),
                TextConstant(
                  fontSize: 14,
                  title: 'age'.tr,
                  fontWeight: FontWeight.bold,
                ),
                heightBox(8),
                TextFieldConstant(
                  height: 44.h,
                  hintFontSize: 14,
                  hintText: 'your_age'.tr,
                  hintFontWeight: FontWeight.bold,
                  controller: controller.dateOfBirthController,
                  isReadOnly: true,
                  onTap: () {
                    print('🗓️ DEBUG: DOB field tapped');
                    controller.showBirthDatePicker(context);
                  },
                  suffixIcon: Icons.calendar_today,
                  suffixIconColor: Colors.grey[600],
                  suffixOnTap: () {
                    print('🗓️ DEBUG: Calendar icon tapped');
                    controller.showBirthDatePicker(context);
                  },
                ),
                heightBox(8),
                // Temporary debug button to isolate issues with onTap
                ElevatedButton(
                  onPressed: () {
                    print('🗓️ DEBUG: Debug button pressed');
                    controller.showBirthDatePicker(context);
                  },
                  child: const Text('Pick DOB (debug)'),
                ),
                heightBox(30),
                TextConstant(
                  fontSize: 14,
                  title: 'add_photos'.tr,
                  fontWeight: FontWeight.bold,
                ),
                heightBox(10),
                Obx(() {
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          childAspectRatio: 110 / 150,
                        ),
                    itemCount: controller.selectedImages.length < 6
                        ? controller.selectedImages.length + 1
                        : 6,
                    itemBuilder: (context, index) {
                      if (index < controller.selectedImages.length) {
                        return Stack(
                          children: [
                            ClipRRect(
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
                            Positioned(
                              top: 5.h,
                              right: 5.w,
                              child: GestureDetector(
                                onTap: () {
                                  controller.selectedImages.removeAt(index);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    LucideIcons.x,
                                    color: themeController.whiteColor,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      return GestureDetector(
                        onTap: () {
                          showImagePickerSheet(
                            themeController: themeController,
                            onTapCamera: () {
                              Get.back();
                              controller.pickImageFromCamera(
                                ImageSource.camera,
                              );
                            },
                            onTapGallery: () {
                              Get.back();
                              controller.pickImageFromCamera(
                                ImageSource.gallery,
                              );
                            },
                          );
                        },
                        child: DottedBorder(
                          options: RoundedRectDottedBorderOptions(
                            dashPattern: [10, 5],
                            strokeWidth: 1,
                            radius: Radius.circular(10.r),
                            color: themeController.greyColor,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Center(
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedPlusSign,color: Theme.of(Get.context!).iconTheme.color!,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
                heightBox(30),
                TextConstant(
                  fontSize: 14,
                  title: 'add_photos'.tr,
                  fontWeight: FontWeight.bold,
                ),
                heightBox(8),
                TextFieldConstant(
                  maxLines: 5,
                  height: 44.h,
                  hintFontSize: 14,
                  hintText: 'tell_us'.tr,
                  hintFontWeight: FontWeight.bold,
                  keyboardType: TextInputType.multiline,
                  controller: controller.aboutController,
                ),
                heightBox(30),
                TextConstant(
                  fontSize: 14,
                  title: 'languages'.tr,
                  fontWeight: FontWeight.bold,
                ),
                heightBox(10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 10.w,
                    children: List.generate(controller.languageList.length, (
                      index,
                    ) {
                      return Obx(() {
                        final isSelected = controller.selectedLanguage.contains(
                          controller.languageList[index],
                        );
                        return GestureDetector(
                          onTap: () {
                            if (isSelected) {
                              controller.selectedLanguage.remove(
                                controller.languageList[index],
                              );
                            } else {
                              controller.selectedLanguage.add(
                                controller.languageList[index],
                              );
                            }
                          },
                          child: AnimatedContainer(
                            curve: Curves.easeIn,
                            duration: Duration(milliseconds: 400),
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 8.h,
                            ),
                            margin: EdgeInsets.only(bottom: 10.h),
                            decoration: BoxDecoration(
                              color: themeController.transparentColor,
                              border: Border.all(
                                color: isSelected
                                    ? themeController.lightPinkColor
                                    : Theme.of(Get.context!).colorScheme.outline,
                                width: 0.8.w,
                              ),
                              borderRadius: BorderRadius.circular(5.r),
                            ),
                            child: Row(
                              spacing: 5.w,
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isSelected)
                                  HugeIcon(
                                    icon: HugeIcons.strokeRoundedTick01,
                                    color: themeController.lightPinkColor,
                                    size: 18,
                                  ),
                                TextConstant(
                                  title: controller.languageList[index],
                                  color: isSelected
                                      ? themeController.lightPinkColor
                                      : null,
                                  fontSize: 16,
                                ),
                              ],
                            ),
                          ),
                        );
                      });
                    }),
                  ),
                ),
                heightBox(30),
                TextConstant(
                  fontSize: 14,
                  title: 'interests'.tr,
                  fontWeight: FontWeight.bold,
                ),
                heightBox(10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 10.w,
                    children: List.generate(controller.interestsList.length, (
                      index,
                    ) {
                      return Obx(() {
                        final isSelected = controller.selectedInterests
                            .contains(controller.interestsList[index]);
                        return GestureDetector(
                          onTap: () {
                            if (isSelected) {
                              controller.selectedInterests.remove(
                                controller.interestsList[index],
                              );
                            } else {
                              controller.selectedInterests.add(
                                controller.interestsList[index],
                              );
                            }
                          },
                          child: AnimatedContainer(
                            curve: Curves.easeIn,
                            duration: Duration(milliseconds: 400),
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 8.h,
                            ),
                            margin: EdgeInsets.only(bottom: 10.h),
                            decoration: BoxDecoration(
                              color: themeController.transparentColor,
                              border: Border.all(
                                color: isSelected
                                    ? themeController.lightPinkColor
                                    : Theme.of(Get.context!).colorScheme.outline,
                                width: 0.8.w,
                              ),
                              borderRadius: BorderRadius.circular(5.r),
                            ),
                            child: Row(
                              spacing: 5.w,
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isSelected)
                                  HugeIcon(
                                    icon: HugeIcons.strokeRoundedTick01,
                                    color: themeController.lightPinkColor,
                                    size: 18,
                                  ),
                                TextConstant(
                                  title: controller.interestsList[index],
                                  color: isSelected
                                      ? themeController.lightPinkColor
                                      : null,
                                  fontSize: 16,
                                ),
                              ],
                            ),
                          ),
                        );
                      });
                    }),
                  ),
                ),

                heightBox(30),
              ],
            ),
          ),
        ),
          ),
        ),
      ),
    );
  }
}
