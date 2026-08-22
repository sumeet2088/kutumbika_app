import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/error_handler.dart';
import '../utils/ui.dart';
import 'main_shell.dart';

class CreateFamilyScreen extends StatefulWidget {
  const CreateFamilyScreen({super.key, this.asOnboarding = true});

  final bool asOnboarding;

  @override
  State<CreateFamilyScreen> createState() => _CreateFamilyScreenState();
}

class _CreateFamilyScreenState extends State<CreateFamilyScreen> {
  final _name = TextEditingController();
  final _api = ApiService.instance;
  File? _photo;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  Future<void> _create() async {
    if (_name.text.trim().isEmpty) {
      ErrorHandler.showError(context, 'Enter a family name');
      return;
    }
    setState(() => _loading = true);
    try {
      await _api.createFamily(familyName: _name.text.trim(), photo: _photo);
      if (!mounted) return;
      if (widget.asOnboarding) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainShell()),
          (route) => false,
        );
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _skip() {
    if (widget.asOnboarding) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBack: !widget.asOnboarding,
      child: Column(
        children: [
          Text('Create Family', textAlign: TextAlign.center, style: headingStyle()),
          const SizedBox(height: 8),
          Text(
            'Add your family photo and give your family a name.',
            textAlign: TextAlign.center,
            style: bodyStyle(color: AppColors.grey),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: _pick,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.navy, width: 1.4),
                image: _photo == null
                    ? null
                    : DecorationImage(image: FileImage(_photo!), fit: BoxFit.cover),
              ),
              child: _photo == null
                  ? const Icon(Icons.photo_camera_outlined, color: AppColors.gold, size: 36)
                  : null,
            ),
          ),
          const SizedBox(height: 28),
          AppTextField(
            controller: _name,
            label: 'Family Name',
            hint: 'Enter family name',
            prefix: Icons.home_rounded,
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            label: 'Submit Family',
            loading: _loading,
            onPressed: _create,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _skip,
            child: Text(
              'Skip for now',
              style: GoogleFonts.inter(
                decoration: TextDecoration.underline,
                color: const Color(0xFF4A90E2),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
