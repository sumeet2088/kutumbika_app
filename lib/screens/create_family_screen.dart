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
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        foregroundColor: AppColors.primaryDarkBlue,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Create Family',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDarkBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A family is required to store and share documents.',
            style: GoogleFonts.inter(color: AppColors.grey),
          ),
          const SizedBox(height: 24),
          Center(
            child: GestureDetector(
              onTap: _pick,
              child: CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.secondaryBlue,
                backgroundImage: _photo == null ? null : FileImage(_photo!),
                child: _photo == null
                    ? const Icon(Icons.camera_alt, color: Colors.white)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 24),
          AppTextField(
            controller: _name,
            label: 'Family name',
            hint: 'Singh Family',
            prefix: Icons.family_restroom,
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            label: 'Create Family',
            loading: _loading,
            onPressed: _create,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _skip,
            child: const Text('Skip for now'),
          ),
        ],
      ),
    );
  }
}
