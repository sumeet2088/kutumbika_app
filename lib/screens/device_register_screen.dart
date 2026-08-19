import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/error_handler.dart';
import '../utils/ui.dart';

class DeviceRegisterScreen extends StatefulWidget {
  const DeviceRegisterScreen({super.key, required this.result});

  final LoginResult result;

  @override
  State<DeviceRegisterScreen> createState() => _DeviceRegisterScreenState();
}

class _DeviceRegisterScreenState extends State<DeviceRegisterScreen> {
  bool _loading = false;

  Future<void> _register() async {
    setState(() => _loading = true);
    try {
      final api = ApiService.instance;
      if (widget.result.challenge != null) {
        await api.session.saveChallenge(
          challenge: widget.result.challenge,
          challengeRef: widget.result.challengeReferenceNumber,
        );
      }
      final result = await api.completeDeviceLogin(deviceName: 'Kutumbika Phone');
      if (!mounted) return;
      await goAfterLogin(
        context,
        LoginResult(
          token: result.token,
          isNewUser: widget.result.isNewUser || result.isNewUser,
          isNewDevice: result.isNewDevice,
          userReferenceNumber: result.userReferenceNumber,
          deviceReferenceNumber: result.deviceReferenceNumber,
        ),
      );
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Register this device',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDarkBlue,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.result.message ??
                    'New device detected. Bind this phone to finish login.',
                style: GoogleFonts.inter(color: AppColors.grey, height: 1.4),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Bind device and continue',
                loading: _loading,
                onPressed: _register,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
