import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/login_result.dart';
import '../screens/create_family_screen.dart';
import '../screens/device_register_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_shell.dart';
import '../utils/app_colors.dart';
import '../widgets/app_logo.dart';

Future<void> goAfterLogin(BuildContext context, LoginResult result) async {
  Widget dest;
  if (result.requiresDeviceRegistration) {
    dest = DeviceRegisterScreen(result: result);
  } else if (result.isNewUser) {
    dest = const CreateFamilyScreen();
  } else {
    dest = const MainShell();
  }
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => dest),
    (route) => false,
  );
}

Future<void> goToLogin(BuildContext context) {
  return Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}

TextStyle headingStyle({double size = 28}) {
  return GoogleFonts.playfairDisplay(
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: AppColors.navy,
    height: 1.2,
  );
}

TextStyle bodyStyle({double size = 14, Color? color, FontWeight? weight}) {
  return GoogleFonts.inter(
    fontSize: size,
    fontWeight: weight ?? FontWeight.w400,
    color: color ?? AppColors.navy,
  );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          disabledBackgroundColor: AppColors.navy.withValues(alpha: 0.5),
          elevation: 0,
          shape: const StadiumBorder(),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                ),
              )
            : Text(
                label.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.gold,
                ),
              ),
      ),
    );
  }
}

class OutlineActionButton extends StatelessWidget {
  const OutlineActionButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.navy, width: 1.2),
          shape: const StadiumBorder(),
        ),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.prefix,
    this.suffix,
    this.validator,
    this.maxLength,
    this.onToggleObscure,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final IconData? prefix;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final int? maxLength;
  final VoidCallback? onToggleObscure;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      maxLength: maxLength,
      validator: validator,
      style: bodyStyle(weight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        prefixIcon: prefix == null ? null : Icon(prefix, color: AppColors.navy),
        suffixIcon: onToggleObscure == null
            ? suffix
            : IconButton(
                onPressed: onToggleObscure,
                icon: Icon(
                  obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppColors.grey,
                ),
              ),
        labelStyle: bodyStyle(color: AppColors.navy, size: 13),
        hintStyle: bodyStyle(color: AppColors.grey.withValues(alpha: 0.55)),
        filled: true,
        fillColor: AppColors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.navy, width: 1.1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.child,
    this.showBack = true,
    this.logoKind = LogoKind.icon,
    this.logoHeight = 88,
  });

  final Widget child;
  final bool showBack;
  final LogoKind logoKind;
  final double logoHeight;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.white,
      ),
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          foregroundColor: AppColors.navy,
          automaticallyImplyLeading: showBack,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
            children: [
              Center(child: AppLogo(kind: logoKind, height: logoHeight)),
              const SizedBox(height: 20),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding, this.color});

  final Widget child;
  final EdgeInsets? padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message, this.icon});
  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon ?? Icons.inbox_outlined, size: 48, color: AppColors.grey),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: bodyStyle(color: AppColors.grey)),
          ],
        ),
      ),
    );
  }
}

InputDecoration fieldDecoration({String? hint, IconData? prefix, String? label}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    hintStyle: TextStyle(color: AppColors.grey.withValues(alpha: 0.5)),
    prefixIcon: prefix == null ? null : Icon(prefix, color: AppColors.navy),
    filled: true,
    fillColor: AppColors.white,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.navy, width: 1.1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.gold, width: 1.4),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}

class AppChromeScope extends InheritedWidget {
  const AppChromeScope({
    super.key,
    required this.unread,
    required super.child,
  });

  final int unread;

  static AppChromeScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppChromeScope>();
  }

  static bool embedded(BuildContext context) => maybeOf(context) != null;

  @override
  bool updateShouldNotify(AppChromeScope oldWidget) => unread != oldWidget.unread;
}

PreferredSizeWidget navyAppBar(String title, {List<Widget>? actions, bool implyLeading = true}) {
  return AppBar(
    title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
    backgroundColor: AppColors.white,
    foregroundColor: AppColors.navy,
    elevation: 0,
    scrolledUnderElevation: 0,
    automaticallyImplyLeading: implyLeading,
    actions: actions,
  );
}

String displayFirstName(Map<String, dynamic>? user) {
  final first = '${user?['first_name'] ?? ''}'.trim();
  if (first.isNotEmpty) return first;
  return displayName(user);
}

String relativeTime(dynamic raw) {
  if (raw == null || '$raw'.isEmpty) return '';
  final dt = DateTime.tryParse('$raw');
  if (dt == null) return '$raw';
  final diff = DateTime.now().difference(dt.toLocal());
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  return '${dt.day}/${dt.month}/${dt.year}';
}

String displayName(Map<String, dynamic>? user) {
  final name = '${user?['first_name'] ?? ''} ${user?['last_name'] ?? ''}'.trim();
  return name.isEmpty ? 'there' : name;
}

String bytesLabel(num bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}
