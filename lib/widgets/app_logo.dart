import 'package:flutter/material.dart';
import 'package:paarisetu_app/utils/app_constants.dart';

enum LogoKind { full, icon }

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.width,
    this.height,
    this.kind = LogoKind.full,
  });

  final double? width;
  final double? height;
  final LogoKind kind;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      kind == LogoKind.icon
          ? AppConstants.logoIconAsset
          : AppConstants.logoAsset,
      width: width,
      height: height,
      fit: BoxFit.contain,
      semanticLabel: AppConstants.appName,
    );
  }
}
