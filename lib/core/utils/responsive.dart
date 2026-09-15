import 'package:flutter/material.dart';

/// Breakpoints define layout *structure* changes (nav style, columns,
/// content width) — separate from flutter_screenutil, which only scales
/// sizes proportionally and stays in charge of phone-to-phone scaling.
enum DeviceType { mobile, tablet, desktop }

class Breakpoints {
  Breakpoints._();
  static const double tablet = 600;
  static const double desktop = 1024;

  static DeviceType of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).shortestSide;
    if (width >= desktop) return DeviceType.desktop;
    if (width >= tablet) return DeviceType.tablet;
    return DeviceType.mobile;
  }
}

extension ResponsiveContext on BuildContext {
  DeviceType get deviceType => Breakpoints.of(this);
  bool get isMobile => deviceType == DeviceType.mobile;
  bool get isTablet => deviceType == DeviceType.tablet;
  bool get isDesktop => deviceType == DeviceType.desktop;
}

/// Centers content and caps its width on large screens so pages don't
/// stretch edge-to-edge on a tablet/PC. No-op on mobile.
class ResponsiveContentWidth extends StatelessWidget {
  const ResponsiveContentWidth({
    super.key,
    required this.child,
    this.maxWidth = 640,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}