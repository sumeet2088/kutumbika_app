import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kutumbika_app/utils/app_colors.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
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
      title: 'Kutumbika',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primaryDarkBlue,
        secondaryHeaderColor: AppColors.secondaryBlue,
        accentColor: AppColors.goldYellow,
        scaffoldBackgroundColor: AppColors.lightGrey,
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
        headline6: GoogleFonts.playfairDisplay(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: AppColors.primaryDarkBlue,
        ),
        colorScheme: const ColorScheme.light(
          primary: AppColors.primaryDarkBlue,
          secondary: AppColors.secondaryBlue,
          tertiary: AppColors.goldYellow,
          surface: AppColors.lightGrey,
          error: AppColors.error,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
