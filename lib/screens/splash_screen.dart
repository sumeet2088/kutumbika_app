import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kutumbika_app/utils/app_colors.dart';
import 'package:kutumbika_app/utils/app_constants.dart';
import 'package:kutumbika_app/utils/error_handler.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Call the /app endpoint to initialize the app
      await _apiService.initializeApp();

      // Navigate to login screen after successful initialization
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      // Handle error - you might want to show an error screen
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDarkBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo placeholder - replace with actual logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.goldYellow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.security,
                size: 60,
                color: AppColors.primaryDarkBlue,
              ),
            ),
            const SizedBox(height: 24),

            // App name
            Text(
              AppConstants.appName,
              style: GoogleFonts.playfairDisplay(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.goldYellow,
              ),
            ),
            const SizedBox(height: 8),

            // Tagline
            Text(
              AppConstants.appTagline,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.grey,
              ),
            ),
            const SizedBox(height: 48),

            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.goldYellow),
            ),
          ],
        ),
      ),
    );
  }
}
