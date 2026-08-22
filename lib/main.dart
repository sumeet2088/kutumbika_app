import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paarisetu_app/services/env_service.dart';
import 'package:paarisetu_app/utils/app_colors.dart';
import 'package:paarisetu_app/utils/app_constants.dart';
import 'package:paarisetu_app/utils/layout.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvService.instance.initialize();
  await AppLayout.configureOrientations();
  runApp(const PaarisetuApp());
}

class PaarisetuApp extends StatelessWidget {
  const PaarisetuApp({super.key});

  @override
  Widget build(BuildContext context) {
    final inter = GoogleFonts.interTextTheme(ThemeData.light().textTheme);
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.white,
        colorScheme: const ColorScheme.light(
          primary: AppColors.navy,
          secondary: AppColors.gold,
          tertiary: AppColors.goldSoft,
          surface: AppColors.white,
          error: AppColors.error,
        ),
        textTheme: inter.apply(
          bodyColor: AppColors.navy,
          displayColor: AppColors.navy,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.navy,
          foregroundColor: AppColors.white,
          elevation: 0,
          centerTitle: false,
        ),
        chipTheme: ChipThemeData(
          selectedColor: AppColors.navy,
          backgroundColor: AppColors.white,
          labelStyle: GoogleFonts.inter(color: AppColors.navy),
          secondaryLabelStyle: GoogleFonts.inter(color: AppColors.gold),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
