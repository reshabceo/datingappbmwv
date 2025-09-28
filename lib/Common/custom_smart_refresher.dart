import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

class CustomSmartRefresher extends StatelessWidget {
  final bool enablePullDown;
  final bool enablePullUp;
  final RefreshController controller;
  final VoidCallback? onRefresh;
  final VoidCallback? onLoading;
  final Widget child;
  final Color? loaderColor;

  const CustomSmartRefresher({
    super.key,
    this.enablePullDown = true,
    this.enablePullUp = true,
    required this.controller,
    required this.onRefresh,
    required this.onLoading,
    required this.child,
    this.loaderColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveLoaderColor =
        loaderColor ?? ThemeController().primaryColor.value;

    return SmartRefresher(
      enablePullDown: enablePullDown,
      enablePullUp: enablePullUp,
      controller: controller,
      header: const WaterDropHeader(),
      onRefresh: onRefresh,
      onLoading: onLoading,
      footer: CustomFooter(
        builder: (BuildContext context, LoadStatus? mode) {
          Widget body;
          if (mode == LoadStatus.idle) {
            body = const SizedBox.shrink();
          } else if (mode == LoadStatus.loading) {
            body = Center(
              child: Container(
                margin: const EdgeInsets.only(top: 14),
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: effectiveLoaderColor,
                  strokeWidth: 3.0,
                ),
              ),
            );
          } else if (mode == LoadStatus.failed) {
            body = const Align(
              alignment: Alignment.center,
              child: Text("Load Failed! Click retry!"),
            );
          } else if (mode == LoadStatus.canLoading) {
            body = const Padding(
              padding: EdgeInsets.only(top: 14),
              child: Align(
                alignment: Alignment.center,
                child: Text("Release to load more"),
              ),
            );
          } else {
            body = const SizedBox.shrink();
          }
          return body;
        },
      ),
      child: child,
    );
  }
}
