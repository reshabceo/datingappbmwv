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
    // Only log when images change to reduce noise
    if (widget.images.isNotEmpty) {
      print('🖼️ ImageGalleryWidget: images.length = ${widget.images.length}');
    }
    
    if (widget.images.isEmpty) {
      print('🖼️ No images available, showing placeholder');
      return Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey.shade800,
              Colors.grey.shade900,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person,
                color: Colors.white.withValues(alpha: 0.8),
                size: 80.sp,
              ),
              SizedBox(height: 16.h),
              Text(
                'No Photos Available',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
              // Unique key per image to avoid showing stale image during reuse
              return Image.network(
                widget.images[index],
                key: ValueKey('img_${widget.images[index]}_${index}'),
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.grey.shade800,
                          Colors.grey.shade900,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: widget.themeController.lightPinkColor,
                            strokeWidth: 2.0,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'Loading photo...',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stack) {
                  print('🖼️ Image load error: $error');
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.grey.shade800,
                          Colors.grey.shade900,
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 60.sp,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'Photo Unavailable',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
