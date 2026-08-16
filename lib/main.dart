import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kutumbika_app/services/env_service.dart';
import 'package:kutumbika_app/utils/app_colors.dart';
import 'package:kutumbika_app/utils/app_constants.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment service
  await EnvService.instance.initialize();

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const KutumbikaApp());
}

class KutumbikaApp extends StatelessWidget {
  const KutumbikaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primaryDarkBlue,
          secondary: AppColors.secondaryBlue,
          tertiary: AppColors.goldYellow,
          surface: AppColors.lightGrey,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.lightGrey,
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
