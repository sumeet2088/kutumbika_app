import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLayout {
  const AppLayout(this.size);

  final Size size;

  factory AppLayout.of(BuildContext context) => AppLayout(MediaQuery.sizeOf(context));

  static const double tabletShortestSide = 600;

  static String detectDeviceType() {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return 'phone';
    final view = views.first;
    final shortest = view.physicalSize.shortestSide / view.devicePixelRatio;
    return shortest >= tabletShortestSide ? 'tablet' : 'phone';
  }

  static String deviceDisplayName() {
    return detectDeviceType() == 'tablet' ? 'Paarisetu Tablet' : 'Paarisetu Phone';
  }

  static Future<void> configureOrientations() {
    if (detectDeviceType() == 'tablet') {
      return SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    return SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  double get width => size.width;
  double get shortest => size.shortestSide;

  bool get isPhone => shortest < tabletShortestSide;
  bool get isTablet => shortest >= tabletShortestSide;

  double get contentWidth {
    if (width < 600) return width;
    if (width < 900) return 720;
    return 880;
  }

  double contentInset({double min = 20}) {
    final inset = (width - contentWidth) / 2;
    if (inset < min) return isTablet ? 28 : min;
    return inset;
  }

  int get vaultColumns {
    if (width >= 1100) return 4;
    if (width >= 700) return 3;
    return 2;
  }

  int get quickColumns => width >= 900 ? 3 : 2;

  double get logoHeight => isTablet ? 70 : 62;

  double get headerHeight => isTablet ? 84 : 76;

  double get drawerWidth => isTablet ? 340 : 304;

  double get quickAspectRatio => isTablet ? 2.6 : 2.2;
}
