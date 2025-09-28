import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/Common/text_constant.dart';

class ImageGalleryWidget extends StatefulWidget {
  final List<String> images;
  final ThemeController themeController;
  final double? height;
  final double? width;

  const ImageGalleryWidget({
    super.key,
    required this.images,
    required this.themeController,
    this.height,
    this.width,
  });

  @override
  State<ImageGalleryWidget> createState() => _ImageGalleryWidgetState();
}

class _ImageGalleryWidgetState extends State<ImageGalleryWidget> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(
        height: widget.height,
        width: widget.width,
        color: widget.themeController.blackColor,
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: widget.themeController.whiteColor.withValues(alpha: 0.6),
            size: 36.sp,
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Main image gallery
        SizedBox(
          height: widget.height,
          width: widget.width,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return Image.network(
                widget.images[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) {
                  return Container(
                    color: widget.themeController.blackColor,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: widget.themeController.whiteColor.withValues(alpha: 0.6),
                      size: 36.sp,
                    ),
                  );
                },
              );
            },
          ),
        ),
        
        // Photo count indicator (top right)
        if (widget.images.length > 1)
          Positioned(
            top: 15.h,
            right: 15.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: widget.themeController.blackColor.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: widget.themeController.lightPinkColor.withValues(alpha: 0.5),
                  width: 1.w,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.photo_library,
                    color: widget.themeController.whiteColor,
                    size: 16.sp,
                  ),
                  SizedBox(width: 4.w),
                  TextConstant(
                    title: '${_currentIndex + 1}/${widget.images.length}',
                    fontSize: 12.sp,
                    color: widget.themeController.whiteColor,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
            ),
          ),
        
        // Page indicators (bottom center)
        if (widget.images.length > 1)
          Positioned(
            bottom: 15.h,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.images.length,
                (index) => Container(
                  margin: EdgeInsets.symmetric(horizontal: 3.w),
                  width: _currentIndex == index ? 20.w : 8.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? widget.themeController.lightPinkColor
                        : widget.themeController.whiteColor.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
