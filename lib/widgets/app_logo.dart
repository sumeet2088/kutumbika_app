import 'package:flutter/material.dart';
import 'package:kutumbika_app/utils/app_constants.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppConstants.logoAsset,
      width: width,
      height: height,
      fit: BoxFit.contain,
      semanticLabel: AppConstants.appName,
    );
  }
}
