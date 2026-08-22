import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/error_handler.dart';
import '../utils/ui.dart';
import '../widgets/app_logo.dart';
import 'main_shell.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _error;
  bool _ready = false;

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
      setState(() => _ready = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = ErrorHandler.getErrorMessage(e));
    }
  }

  void _continue() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logoWidth = MediaQuery.sizeOf(context).width * 0.86;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.white,
      ),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              children: [
                const Spacer(),
                Center(
                  child: AppLogo(kind: LogoKind.full, width: logoWidth),
                ),
                const Spacer(),
                if (_error == null && !_ready)
                  Column(
                    children: [
                      const SizedBox(
                        width: 42,
                        height: 42,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppColors.gold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading Your Family Secure Place...',
                        style: bodyStyle(color: AppColors.grey, size: 13),
                      ),
                    ],
                  )
                else if (_error != null) ...[
                  Text(_error!, textAlign: TextAlign.center, style: bodyStyle(color: AppColors.error)),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Retry',
                    onPressed: () {
                      setState(() => _error = null);
                      _bootstrap();
                    },
                  ),
                ] else
                  PrimaryButton(label: 'Get Started', onPressed: _continue),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
