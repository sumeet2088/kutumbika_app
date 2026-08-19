import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/error_handler.dart';
import '../widgets/app_logo.dart';
import 'login_screen.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final api = ApiService.instance;
    try {
      await api.session.load();
      if (api.session.hasUser) {
        try {
          await api.getUserDetails();
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainShell()),
          );
          return;
        } catch (_) {
          await api.session.clearUser();
        }
      }
      await api.initializeApp();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = ErrorHandler.getErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.logoBlack,
        systemNavigationBarColor: AppColors.logoBlack,
      ),
      child: Scaffold(
        backgroundColor: AppColors.logoBlack,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: AppLogo(width: MediaQuery.sizeOf(context).width * 0.72),
              ),
              const SizedBox(height: 40),
              if (_error == null)
                const CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.goldYellow),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() => _error = null);
                    _bootstrap();
                  },
                  child: const Text('Retry',
                      style: TextStyle(color: AppColors.goldYellow)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
