import 'package:flutter/material.dart';

class Responsive {
  // Screen size breakpoints
  static const double smallMobileBreakpoint = 360;
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  // Get screen width
  static double width(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  // Get screen height
  static double height(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  // Check if device is small mobile (very small screens)
  static bool isSmallMobile(BuildContext context) {
    return width(context) < smallMobileBreakpoint;
  }

  // Check if device is mobile
  static bool isMobile(BuildContext context) {
    return width(context) < mobileBreakpoint;
  }

  // Check if device is tablet
  static bool isTablet(BuildContext context) {
    return width(context) >= mobileBreakpoint && width(context) < tabletBreakpoint;
  }

  // Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return width(context) >= tabletBreakpoint;
  }

  // Get responsive padding
  static EdgeInsets padding(BuildContext context) {
    if (isSmallMobile(context)) {
      return EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    } else if (isMobile(context)) {
      return EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    } else if (isTablet(context)) {
      return EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    } else {
      return EdgeInsets.symmetric(horizontal: 48, vertical: 24);
    }
  }

  // Get responsive font size
  static double fontSize(BuildContext context, double baseSize) {
    double scale = 1.0;
    if (isSmallMobile(context)) {
      scale = 0.9; // Slightly smaller for very small screens
    } else if (isTablet(context)) {
      scale = 1.2;
    } else if (isDesktop(context)) {
      scale = 1.4;
    }
    return baseSize * scale;
  }

  // Get responsive icon size
  static double iconSize(BuildContext context, double baseSize) {
    double scale = 1.0;
    if (isSmallMobile(context)) {
      scale = 0.9; // Slightly smaller for very small screens
    } else if (isTablet(context)) {
      scale = 1.3;
    } else if (isDesktop(context)) {
      scale = 1.5;
    }
    return baseSize * scale;
  }

  // Get responsive spacing
  static double spacing(BuildContext context, double baseSpacing) {
    double scale = 1.0;
    if (isSmallMobile(context)) {
      scale = 0.85; // Slightly smaller for very small screens
    } else if (isTablet(context)) {
      scale = 1.2;
    } else if (isDesktop(context)) {
      scale = 1.5;
    }
    return baseSpacing * scale;
  }

  // Get responsive grid cross axis count
  static int gridCrossAxisCount(BuildContext context, {int mobile = 2, int tablet = 3, int desktop = 4}) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }

  // Get responsive child aspect ratio for grids
  static double gridAspectRatio(BuildContext context, {double mobile = 1.5, double tablet = 1.3, double desktop = 1.2}) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }

  // Get responsive container width (max width for content)
  static double maxContentWidth(BuildContext context) {
    if (isMobile(context)) {
      return width(context);
    } else if (isTablet(context)) {
      return 800;
    } else {
      return 1200;
    }
  }

  // Get responsive bottom navigation height (including safe area)
  static double bottomNavHeight(BuildContext context) {
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    if (isSmallMobile(context)) {
      return 70 + safeAreaBottom;
    } else if (isMobile(context)) {
      return 75 + safeAreaBottom;
    } else if (isTablet(context)) {
      return 85 + safeAreaBottom;
    } else {
      return 95 + safeAreaBottom;
    }
  }

  // Get bottom navigation content height (without safe area)
  static double bottomNavContentHeight(BuildContext context) {
    if (isSmallMobile(context)) {
      return 70;
    } else if (isMobile(context)) {
      return 75;
    } else if (isTablet(context)) {
      return 85;
    } else {
      return 95;
    }
  }

  // Get responsive logo size
  static double logoSize(BuildContext context) {
    if (isMobile(context)) {
      return 50;
    } else if (isTablet(context)) {
      return 60;
    } else {
      return 70;
    }
  }

  // Check if in landscape mode
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  // Get responsive value based on screen size
  static T value<T>(BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }
}
