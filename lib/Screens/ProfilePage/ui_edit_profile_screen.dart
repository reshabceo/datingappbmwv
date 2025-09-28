import 'dart:io';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:gradient_borders/gradient_borders.dart';
import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/widget_constant.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lovebug/Common/textfield_constant.dart';
import 'package:lovebug/Common/common_gradient_appbar.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/Screens/ProfilePage/controller_profile_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

class EditProfileScreen extends StatelessWidget {
  EditProfileScreen({super.key});

  final ThemeController themeController = Get.find<ThemeController>();
  final ProfileController controller = Get.find<ProfileController>();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        GestureDetector(
          onTap: () {
            controller.textInputEmoji.value = false;
          },
          child: Scaffold(
            appBar: GradientCommonAppBar(isCenterTitle: true, showBackButton: true, isNotificationShow: false),
            bottomNavigationBar: Container(
              color: Theme
                  .of(context)
                  .scaffoldBackgroundColor,
              width: Get.width,
              child: Padding(
                padding: EdgeInsets.all(15.w),
                child: Row(
                  spacing: 10.w,
                  children: [
                    Expanded(
                      child: elevatedButton(
                        title: 'cancel'.tr,
                        isGradient: false,
                        isBorder: true,
                        backGroundColor: themeController.transparentColor,
                        onPressed: () {
                          Get.back();
                        },
                      ),
                    ),
                    Expanded(
                      child: elevatedButton(
                        title: 'save_changes'.tr,textColor: themeController.whiteColor,
                        onPressed: () {},
                        colorsGradient: [themeController.lightPinkColor, themeController.purpleColor],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            body: Obx(() {
              return Container(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        heightBox(15),
                        Center(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              TextConstant(fontSize: 21.sp, title: 'edit_profile'.tr, fontWeight: FontWeight.w700),
                              heightBox(20),
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Obx(() {
                                    controller.selectedImage;
                                    return Container(
                                      height: 110.h,
                                      width: 110.h,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                          image: controller.selectedImage.value != null
                                              ? FileImage(File(controller.selectedImage.value!.path))
                                              : NetworkImage(
                                            'https://images.stockcake.com/public/a/3/7/a372ef04-fa6c-49f8-bf42-d89f023edff5_large/handsome-man-posing-stockcake.jpg',
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                        border: GradientBoxBorder(
                                          width: 2.w,
                                          gradient: LinearGradient(
                                            colors: [themeController.lightPinkColor, themeController.purpleColor],
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                  InkWell(
                                    onTap: () {
                                      showImagePickerSheet(
                                        themeController: themeController,
                                        onTapCamera: () {
                                          Get.back();
                                          controller.pickImageFromCamera(ImageSource.camera);
                                        },
                                        onTapGallery: () {
                                          Get.back();
                                          controller.pickImageFromCamera(ImageSource.gallery);
                                        },
                                      );
                                    },
                                    child: Container(
                                      height: 30.h,
                                      width: 30.h,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: themeController.lightPinkColor,
                                        border: Border.all(color: themeController.primaryColor.value, width: 2.w),
                                      ),
                                      child: Icon(Icons.camera_alt, color: themeController.whiteColor, size: 14.sp),
                                    ),
                                  ),
                                ],
                              ),
                              heightBox(10),
                              TextConstant(
                                title: 'profile_photo'.tr,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w400,
                              ),
                              heightBox(8),
                              InkWell(
                                onTap: () {
                                  showImagePickerSheet(
                                    themeController: themeController,
                                    onTapCamera: () {
                                      Get.back();
                                      controller.pickImageFromCamera(ImageSource.camera);
                                    },
                                    onTapGallery: () {
                                      Get.back();
                                      controller.pickImageFromCamera(ImageSource.gallery);
                                    },
                                  );
                                },
                                child: IntrinsicWidth(
                                  child: Container(
                                    alignment: Alignment.center,
                                    padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: themeController.purpleColor.withValues(alpha: 0.4), width: 1.w),
                                      borderRadius: BorderRadius.circular(4.r),
                                      gradient: LinearGradient(
                                        colors: [
                                          themeController.lightPinkColor.withValues(alpha: 0.2),
                                          themeController.purpleColor.withValues(alpha: 0.2),
                                        ],
                                      ),
                                    ),
                                    child: TextConstant(
                                      title: 'change_photo'.tr,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        heightBox(25),
                        TextConstant(title: 'basic_information'.tr, fontWeight: FontWeight.bold, fontSize: 16),
                        Divider(color: themeController.purpleColor.withValues(alpha: 0.4)),
                        TextConstant(title: 'name'.tr, fontSize: 14, fontWeight: FontWeight.bold),
                        heightBox(8),
                        TextFieldConstant(
                          height: 44.h,
                          hintFontSize: 14,
                          hintText: 'your_name'.tr,
                          borderColor: themeController.purpleColor.withValues(alpha: 0.4),
                          hintFontWeight: FontWeight.bold,
                          keyboardType: TextInputType.name,
                          controller: controller.nameController,
                        ),
                        heightBox(15),
                        TextConstant(title: 'age'.tr, fontSize: 14, fontWeight: FontWeight.bold),
                        heightBox(8),
                        TextFieldConstant(
                          height: 44.h,
                          hintFontSize: 14,
                          hintText: 'your_age'.tr,
                          borderColor: themeController.purpleColor.withValues(alpha: 0.4),
                          hintFontWeight: FontWeight.bold,
                          keyboardType: TextInputType.number,
                          controller: controller.ageController,
                          inputFormatters: [LengthLimitingTextInputFormatter(3), FilteringTextInputFormatter.digitsOnly],
                        ),
                        heightBox(15),
                        TextConstant(title: 'location'.tr, fontSize: 14, fontWeight: FontWeight.bold),
                        heightBox(8),
                        TextFieldConstant(
                          height: 44.h,
                          hintFontSize: 14,
                          isReadOnly: true,
                          hintText: 'your_location'.tr,
                          focusNode: controller.focusNode,
                          suffixIconColor: themeController.lightPinkColor,
                          borderColor: themeController.purpleColor.withValues(alpha: 0.4),
                          hintFontWeight: FontWeight.bold,
                          controller: controller.locationController,
                          suffixIcon: Icons.location_pin,
                          onTap: () {
                            CustomBottomSheet.show(
                              title: 'select_country'.tr,
                              backgroundColor: themeController.isDarkMode.value ?  themeController.appBar1Color : themeController.whiteColor,
                              child: Padding(
                                padding: EdgeInsets.only(top: 15.h, bottom: 10.h),
                                child: Obx(() {
                                  controller.selectedCountry.value;
                                  return ListView.separated(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemCount: controller.countries.length,
                                    separatorBuilder: (_, __) =>
                                        Divider(color: themeController.whiteColor.withValues(alpha: 0.2)),
                                    itemBuilder: (context, index) {
                                      final country = controller.countries[index];
                                      final isSelected = controller.selectedCountry.value == country;
                                      return InkWell(
                                        onTap: () {
                                          controller.locationController.text = country;
                                          controller.selectedCountry.value = country;
                                          Get.back();
                                        },
                                        child: Row(
                                          children: [
                                            TextConstant(fontSize: 18, title: country),
                                            Spacer(),
                                            if (isSelected) ...[
                                              widthBox(8),
                                              Icon(LucideIcons.circleCheck, size: 18, color: themeController.lightPinkColor),
                                            ],
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                }),
                              ),
                            );
                          },
                        ),
                        heightBox(15),
                        TextConstant(title: 'gender'.tr, fontSize: 14, fontWeight: FontWeight.bold),
                        heightBox(8),
                        Obx(() {
                          controller.selectedGenderIndex.value;
                          return Row(
                            children: List.generate(controller.genderType.length, (index) {
                              final isSelected = controller.selectedGenderIndex.value == index;
                              return Expanded(
                                child: InkWell(
                                  onTap: () {
                                    controller.selectedGenderIndex.value = index;
                                  },
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 400),
                                    alignment: Alignment.center,
                                    padding: EdgeInsets.symmetric(vertical: 10.h),
                                    margin: EdgeInsets.only(right: index != 2 ? 7.w : 0),
                                    // spacing between items
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isSelected
                                            ? themeController.lightPinkColor
                                            : themeController.purpleColor.withValues(alpha: 0.7),
                                        width: 1.w,
                                      ),
                                      color: isSelected ? null : themeController.transparentColor,
                                      borderRadius: BorderRadius.circular(4.r),
                                      gradient: isSelected
                                          ? LinearGradient(
                                        colors: [
                                          themeController.lightPinkColor.withValues(alpha: 0.2),
                                          themeController.purpleColor.withValues(alpha: 0.2),
                                        ],
                                      )
                                          : null,
                                    ),
                                    child: TextConstant(
                                      title: controller.genderType[index],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          );
                        }),
                        heightBox(15),
                        TextConstant(title: 'looking_for'.tr, fontSize: 14, fontWeight: FontWeight.bold),
                        heightBox(8),
                        Obx(() {
                          controller.selectedLookingIndex.value;
                          return Row(
                            children: List.generate(controller.lookingType.length, (index) {
                              final isSelected = controller.selectedLookingIndex.value == index;
                              return Expanded(
                                child: InkWell(
                                  onTap: () {
                                    controller.selectedLookingIndex.value = index;
                                  },
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 400),
                                    alignment: Alignment.center,
                                    padding: EdgeInsets.symmetric(vertical: 10.h),
                                    margin: EdgeInsets.only(right: index != 2 ? 7.w : 0),
                                    // spacing between items
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isSelected
                                            ? themeController.lightPinkColor
                                            : themeController.purpleColor.withValues(alpha: 0.7),
                                        width: 1.w,
                                      ),
                                      color: isSelected ? null : themeController.transparentColor,
                                      borderRadius: BorderRadius.circular(4.r),
                                      gradient: isSelected
                                          ? LinearGradient(
                                        colors: [
                                          themeController.lightPinkColor.withValues(alpha: 0.2),
                                          themeController.purpleColor.withValues(alpha: 0.2),
                                        ],
                                      )
                                          : null,
                                    ),
                                    child: TextConstant(
                                      title: controller.lookingType[index],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          );
                        }),
                        heightBox(25),
                        TextConstant(title: 'about_me'.tr, fontSize: 14, fontWeight: FontWeight.bold),
                        Divider(color: themeController.purpleColor.withValues(alpha: 0.4), height: 20.h),
                        Obx(() {
                          controller.textInputBold.value;
                          controller.textInputItalic.value;
                          return TextFieldConstant(
                            maxLines: 5,
                            height: 44.h,
                            hintFontSize: 14,
                            hintText: 'describe_yourself'.tr,
                            onTap: () {
                              controller.focusNode.requestFocus();
                            },
                            focusNode: controller.focusNode,
                            keyboardType: TextInputType.multiline,
                            controller: controller.aboutController,
                            fontStyle: controller.textInputItalic.value ? FontStyle.italic : FontStyle.normal,
                            borderColor: themeController.purpleColor.withValues(alpha: 0.4),
                            hintFontWeight: controller.textInputBold.value ? FontWeight.bold : FontWeight.normal,
                            key: ValueKey('${controller.textInputBold.value}_${controller.textInputItalic.value}'),
                          );
                        }),
                        heightBox(10),
                        Obx(() {
                          return Row(
                            spacing: 8.w,
                            children: [
                              ButtonSquare(
                                height: 40,
                                width: 30,
                                onTap: () {
                                  controller.textInputBold.toggle();
                                },
                                iconSize: 25,
                                icon: Icons.format_bold_rounded,
                                backgroundColor: controller.textInputBold.value
                                    ? themeController.lightPinkColor.withValues(alpha: 0.3)
                                    : themeController.lightPinkColor.withValues(alpha: 0.1),
                                iconColor: themeController.lightPinkColor,
                                borderColor: themeController.lightPinkColor.withValues(alpha: 0.2),
                              ),
                              ButtonSquare(
                                height: 40,
                                width: 30,
                                onTap: () {
                                  controller.textInputItalic.toggle();
                                },
                                iconSize: 25,
                                icon: Icons.format_italic_rounded,
                                backgroundColor: controller.textInputItalic.value
                                    ? themeController.lightPinkColor.withValues(alpha: 0.3)
                                    : themeController.lightPinkColor.withValues(alpha: 0.1),
                                iconColor: themeController.lightPinkColor,
                                borderColor: themeController.lightPinkColor.withValues(alpha: 0.2),
                              ),
                              ButtonSquare(
                                height: 40,
                                width: 30,
                                onTap: () {
                                  controller.textInputEmoji.toggle();
                                  controller.focusNode.unfocus();
                                  controller.focusNode.canRequestFocus = true;
                                },
                                iconSize: 22,
                                icon: Icons.emoji_emotions_rounded,
                                backgroundColor: controller.textInputEmoji.value
                                    ? themeController.lightPinkColor.withValues(alpha: 0.3)
                                    : themeController.lightPinkColor.withValues(alpha: 0.1),
                                iconColor: themeController.lightPinkColor,
                                borderColor: themeController.lightPinkColor.withValues(alpha: 0.2),
                              ),
                            ],
                          );
                        }),
                        heightBox(25),
                        TextConstant(title: 'my_photos'.tr, fontSize: 14, fontWeight: FontWeight.bold),
                        Divider(color: themeController.purpleColor.withValues(alpha: 0.4), height: 20.h),
                        TextConstant(
                          title: 'add_personality'.tr,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                        heightBox(10),

                        /// reorder grid View
                        Obx(() {
                          controller.isReorderMode.value;
                          return ReorderableGridView.count(
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                            crossAxisCount: 3,
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            semanticChildCount: controller.myPhotos.length,
                            childAspectRatio: 110 / 150,
                            onReorder: (oldIndex, newIndex) {
                              final element = controller.myPhotos.removeAt(oldIndex);
                              controller.myPhotos.insert(newIndex, element);
                            },
                            dragEnabled: controller.isReorderMode.value ? true : false,
                            footer: controller.myPhotos.length < 6
                                ? [
                              GestureDetector(
                                onTap: () {
                                  showImagePickerSheet(
                                    themeController: themeController,
                                    onTapCamera: () {
                                      Get.back();
                                      controller.pickImageList(ImageSource.camera);
                                    },
                                    onTapGallery: () {
                                      Get.back();
                                      controller.pickImageList(ImageSource.gallery);
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
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.r)),
                                    child: Center(
                                      child: HugeIcon(
                                        icon: HugeIcons.strokeRoundedPlusSign,
                                        color: Theme.of(context).iconTheme.color!,
                                        size: 30,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ]
                                : null,
                            children: controller.myPhotos
                                .asMap()
                                .entries
                                .map((entry) {
                              final index = entry.key;
                              final photo = entry.value;
                              return Stack(
                                key: ValueKey(index),
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10.r),
                                    child: photo.startsWith('http')
                                        ? Image.network(photo, width: double.infinity, height: double.infinity, fit: BoxFit.cover)
                                        : File(photo).existsSync()
                                        ? Image.file(
                                      File(photo),
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                        : Container(color: Colors.grey, child: Icon(Icons.broken_image)),
                                  ),
                                  Positioned(
                                    top: 5.h,
                                    right: 5.w,
                                    child: GestureDetector(
                                      onTap: () {
                                        controller.myPhotos.removeAt(index);
                                        controller.myPhotos.refresh();
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: themeController.blackColor.withValues(alpha: 0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        padding: EdgeInsets.all(4),
                                        child: Icon(LucideIcons.x, color: themeController.whiteColor, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          );
                        }),
                        heightBox(15),
                        Row(
                          spacing: 8.w,
                          children: [
                            Expanded(
                              child: elevatedButton2(
                                icon: LucideIcons.plus,
                                title: 'add_photo'.tr,
                                onPressed: () {
                                  if (controller.myPhotos.length < 6) {
                                    showImagePickerSheet(
                                      themeController: themeController,
                                      onTapCamera: () {
                                        Get.back();
                                        controller.pickImageList(ImageSource.camera);
                                      },
                                      onTapGallery: () {
                                        Get.back();
                                        controller.pickImageList(ImageSource.gallery);
                                      },
                                    );
                                  } else {
                                    Get.snackbar('limit_reached'.tr, '6_photos.'.tr);
                                  }
                                },
                              ),
                            ),
                            Obx(() {
                              return Expanded(
                                child: elevatedButton2(
                                  icon: LucideIcons.shuffle,
                                  title: 'reorder'.tr,
                                  borderColor: controller.isReorderMode.value ? themeController.lightPinkColor : null,
                                  onPressed: () {
                                    controller.isReorderMode.toggle();
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                        heightBox(8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(Icons.info_rounded, color: Colors.pinkAccent, size: 14),
                            SizedBox(width: 6),
                            Expanded(
                              child: TextConstant(
                                title: 'avoid_140'.tr,
                                fontSize: 10,
                                softWrap: true,
                                color: themeController.greyColor,
                              ),
                            ),
                          ],
                        ),
                        heightBox(25),
                        TextConstant(title: 'my_interests'.tr, fontSize: 14, fontWeight: FontWeight.bold),
                        Divider(color: themeController.purpleColor.withValues(alpha: 0.4), height: 20.h),
                        TextConstant(
                          title: 'add_matches'.tr,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                        heightBox(10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Obx(() {
                            return Wrap(
                              spacing: 10.w,
                              children: List.generate(controller.myInterestList.length, (index) {
                                return AnimatedContainer(
                                  curve: Curves.easeIn,
                                  duration: Duration(milliseconds: 400),
                                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                  margin: EdgeInsets.only(bottom: 10.h),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        themeController.lightPinkColor.withValues(alpha: 0.2),
                                        themeController.purpleColor.withValues(alpha: 0.2),
                                      ],
                                    ),
                                    border: Border.all(color: themeController.purpleColor.withValues(alpha: 0.3), width: 0.8.w),
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  child: Row(
                                    spacing: 8.w,
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TextConstant(
                                        title: controller.myInterestList[index],
                                        fontSize: 16,
                                      ),
                                      InkWell(
                                        onTap: () {
                                          controller.myInterestList.removeAt(index);
                                          controller.myInterestList.refresh();
                                        },
                                        child: HugeIcon(
                                            icon: LucideIcons.circleX, color: themeController.lightPinkColor, size: 20),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            );
                          }),
                        ),
                        heightBox(10),
                        TextFieldConstant(
                          height: 44.h,
                          hintFontSize: 14,
                          hintText: 'add_new_interest'.tr,
                          suffixIconColor: themeController.lightPinkColor,
                          borderColor: themeController.purpleColor.withValues(alpha: 0.4),
                          hintFontWeight: FontWeight.bold,
                          controller: controller.interestController,
                          onFieldSubmit: (v) {
                            if (v.isEmpty) {
                              return;
                            }
                            if (controller.myInterestList.length >= 10) {
                              Get.snackbar('limit_reached'.tr, '10_interest'.tr);
                            } else if (controller.myInterestList.any((item) {
                              return (item.trim().toLowerCase() == v.trim().toLowerCase() ||
                                  item.trim().toUpperCase() == v.trim().toUpperCase());
                            })) {
                              Get.snackbar('already_added'.tr, 'already_addedthis'.tr);
                            } else {
                              controller.myInterestList.add(v.trim());
                              controller.interestController.clear();
                              controller.myInterestList.refresh();
                            }
                          },
                          suffixIcon: Padding(
                            padding: EdgeInsets.all(8.w),
                            child: Container(
                              height: 28.w,
                              width: 28.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: themeController.lightPinkColor.withValues(alpha: 0.2),
                              ),
                              child: Icon(LucideIcons.plus, color: themeController.lightPinkColor, size: 20),
                            ),
                          ),
                        ),
                        heightBox(20),
                        TextConstant(title: 'popular_interests'.tr, fontSize: 14, fontWeight: FontWeight.bold),
                        heightBox(10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Obx(() {
                            return Wrap(
                              spacing: 10.w,
                              children: List.generate(controller.popularInterestList.length, (index) {
                                return InkWell(
                                  onTap: () {
                                    if (controller.myInterestList.length >= 10) {
                                      Get.snackbar('limit_reached'.tr, '10_interest'.tr);
                                    } else if (!controller.myInterestList.contains(controller.popularInterestList[index])) {
                                      controller.myInterestList.add(controller.popularInterestList[index]);
                                      controller.myInterestList.refresh();
                                    } else {
                                      Get.snackbar('already_added'.tr, 'already_addedthis'.tr);
                                    }
                                  },
                                  child: AnimatedContainer(
                                    curve: Curves.easeIn,
                                    duration: Duration(milliseconds: 400),
                                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                    margin: EdgeInsets.only(bottom: 10.h),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: themeController.purpleColor.withValues(alpha: 0.5), width: 0.8.w),
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                    child: Row(
                                      spacing: 8.w,
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        HugeIcon(icon: LucideIcons.plus, color: Theme.of(context).iconTheme.color!, size: 16),
                                        TextConstant(
                                          title: controller.popularInterestList[index],
                                          fontSize: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            );
                          }),
                        ),
                        heightBox(25),
                        TextConstant(title: 'privacy_settings'.tr, fontSize: 14, fontWeight: FontWeight.bold),
                        Divider(color: themeController.purpleColor.withValues(alpha: 0.4), height: 20.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                spacing: 3.h,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextConstant(
                                    title: 'profile_visibility'.tr,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  TextConstant(
                                    title: 'allow_profile'.tr,
                                    fontSize: 11,
                                  ),
                                ],
                              ),
                            ),
                            widthBox(10),
                            Obx(() {
                              controller.isProfileVisibility.value;
                              return Switch.adaptive(
                                value: controller.isProfileVisibility.value,
                                onChanged: (v) {
                                  controller.profileVisibility();
                                },
                                trackOutlineWidth: WidgetStatePropertyAll(0.1),
                                activeTrackColor: themeController.lightPinkColor.withValues(alpha: 0.3),
                                inactiveTrackColor: themeController.greyColor.withValues(alpha: 0.3),
                                thumbColor: controller.isProfileVisibility.value
                                    ? WidgetStateProperty.all(themeController.lightPinkColor)
                                    : WidgetStateProperty.all(themeController.whiteColor.withValues(alpha: 0.7)),
                              );
                            }),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                spacing: 3.h,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextConstant(
                                    title: 'show_age'.tr,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  TextConstant(
                                    title: 'display_profile'.tr,
                                    fontSize: 11,
                                  ),
                                ],
                              ),
                            ),
                            widthBox(10),
                            Obx(() {
                              controller.isShowAge.value;
                              return Switch.adaptive(
                                value: controller.isShowAge.value,
                                onChanged: (v) {
                                  controller.showAge();
                                },
                                trackOutlineWidth: WidgetStatePropertyAll(0.1),
                                activeTrackColor: themeController.lightPinkColor.withValues(alpha: 0.3),
                                inactiveTrackColor: themeController.greyColor.withValues(alpha: 0.3),
                                thumbColor: controller.isShowAge.value
                                    ? WidgetStateProperty.all(themeController.lightPinkColor)
                                    : WidgetStateProperty.all(themeController.whiteColor.withValues(alpha: 0.7)),
                              );
                            }),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                spacing: 3.h,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextConstant(
                                    title: 'show_distance'.tr,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  TextConstant(
                                    title: 'display_others'.tr,
                                    fontSize: 11,
                                  ),
                                ],
                              ),
                            ),
                            widthBox(10),
                            Obx(() {
                              controller.isShowDistance.value;
                              return Switch.adaptive(
                                value: controller.isShowDistance.value,
                                onChanged: (v) {
                                  controller.showDistance();
                                },
                                trackOutlineWidth: WidgetStatePropertyAll(0.1),
                                activeTrackColor: themeController.lightPinkColor.withValues(alpha: 0.3),
                                inactiveTrackColor: themeController.greyColor.withValues(alpha: 0.3),
                                thumbColor: controller.isShowDistance.value
                                    ? WidgetStateProperty.all(themeController.lightPinkColor)
                                    : WidgetStateProperty.all(themeController.whiteColor.withValues(alpha: 0.7)),
                              );
                            }),
                          ],
                        ),
                        heightBox(30),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        Obx(
              () =>
              Offstage(
                offstage: !controller.textInputEmoji.value,
                child: Material(
                  child: SizedBox(
                    height: 300,
                    child: EmojiPicker(
                      onEmojiSelected: (category, emoji) {
                        controller.aboutController.text = controller.aboutController.text + emoji.emoji;
                      },
                      onBackspacePressed: () {
                        final text = controller.aboutController.text;
                        if (text.isNotEmpty) {
                          final runes = text.runes.toList();
                          final newText = String.fromCharCodes(runes.sublist(0, runes.length - 1));
                          controller.aboutController.text = newText;
                          controller.aboutController.selection = TextSelection.fromPosition(TextPosition(offset: newText.length));
                        }
                      },
                    ),
                  ),
                ),
              ),
        ),
      ],
    );
  }
}

/// basic grid view with last index add photos
// Obx(() {
//   return GridView.builder(
//     shrinkWrap: true,
//     physics: NeverScrollableScrollPhysics(),
//     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//       crossAxisCount: 3,
//       crossAxisSpacing: 15,
//       mainAxisSpacing: 15,
//       childAspectRatio: 110 / 150,
//     ),
//     itemCount: controller.myPhotos.length < 6 ? controller.myPhotos.length + 1 : 6,
//     itemBuilder: (context, index) {
//       if (index < controller.myPhotos.length) {
//         return Stack(
//           children: [
//             ClipRRect(
//               borderRadius: BorderRadius.circular(10.r),
//               child: controller.myPhotos[index].startsWith('http')
//                   ? Image.network(
//                 controller.myPhotos[index],
//                 width: double.infinity,
//                 height: double.infinity,
//                 fit: BoxFit.cover,
//               )
//                   : File(controller.myPhotos[index]).existsSync()
//                   ? Image.file(
//                 File(controller.myPhotos[index]),
//                 width: double.infinity,
//                 height: double.infinity,
//                 fit: BoxFit.cover,
//               )
//                   : Container(color: Colors.grey, child: Icon(Icons.broken_image)),
//             ),
//             Positioned(
//               top: 5.h,
//               right: 5.w,
//               child: GestureDetector(
//                 onTap: () {
//                   controller.myPhotos.removeAt(index);
//                   controller.myPhotos.refresh();
//                 },
//                 child: Container(
//                   decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
//                   padding: EdgeInsets.all(4),
//                   child: Icon(LucideIcons.x, color: themeController.whiteColor, size: 16),
//                 ),
//               ),
//             ),
//           ],
//         );
//       }
//
//       return GestureDetector(
//         onTap: () {
//           showImagePickerSheet(
//             themeController: themeController,
//             onTapCamera: () {
//               Get.back();
//               controller.pickImageList(ImageSource.camera);
//             },
//             onTapGallery: () {
//               Get.back();
//               controller.pickImageList(ImageSource.gallery);
//             },
//           );
//         },
//         child: DottedBorder(
//           options: RoundedRectDottedBorderOptions(
//             dashPattern: [10, 5],
//             strokeWidth: 1,
//             radius: Radius.circular(10.r),
//             color: themeController.greyColor,
//           ),
//           child: Container(
//             decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.r)),
//             child: Center(
//               child: HugeIcon(icon: HugeIcons.strokeRoundedPlusSign, color: themeController.whiteColor, size: 30),
//             ),
//           ),
//         ),
//       );
//     },
//   );
// }),

