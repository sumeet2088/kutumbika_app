import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../screens/consent_gate_screen.dart';
import '../screens/create_family_screen.dart';
import '../screens/device_register_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_shell.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/layout.dart';
import '../widgets/app_logo.dart';

Future<void> goAfterLogin(BuildContext context, LoginResult result) async {
  Widget dest;
  if (result.requiresDeviceRegistration) {
    dest = DeviceRegisterScreen(result: result);
  } else {
    dest = result.isNewUser ? const CreateFamilyScreen() : const MainShell();
    if (result.hasSession) {
      try {
        final consents = await ApiService.instance.listConsents();
        if (consents['requires_consent'] == true) {
          if (!context.mounted) return;
          dest = ConsentGateScreen(
            onAccepted: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => result.isNewUser ? const CreateFamilyScreen() : const MainShell(),
                ),
                (route) => false,
              );
            },
          );
        }
      } catch (_) {}
    }
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
    this.enabled = true,
    this.readOnly = false,
    this.verified = false,
    this.onTap,
    this.minLines,
    this.maxLines = 1,
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
  final bool enabled;
  final bool readOnly;
  final bool verified;
  final VoidCallback? onTap;
  final int? minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      enabled: enabled,
      readOnly: readOnly || onTap != null,
      onTap: enabled ? onTap : null,
      keyboardType: keyboardType,
      maxLength: maxLength,
      minLines: minLines,
      maxLines: maxLines,
      validator: validator,
      style: bodyStyle(
        weight: FontWeight.w600,
        color: enabled ? AppColors.navy : AppColors.navyDeep,
      ),
      decoration: fieldDecoration(
        label: label,
        hint: hint,
        prefix: prefix,
        suffix: _suffix(),
        enabled: enabled,
      ).copyWith(counterText: ''),
    );
  }

  Widget? _suffix() {
    if (verified) {
      return const Icon(Icons.verified_rounded, color: AppColors.success);
    }
    if (onToggleObscure != null) {
      return IconButton(
        onPressed: onToggleObscure,
        icon: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppColors.grey,
        ),
      );
    }
    return suffix;
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
            padding: pagePadding(context, horizontal: 24, top: 0),
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
      clipBehavior: Clip.antiAlias,
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

InputDecoration fieldDecoration({
  String? hint,
  IconData? prefix,
  String? label,
  Widget? suffix,
  bool enabled = true,
}) {
  final radius = BorderRadius.circular(14);
  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: bodyStyle(color: AppColors.navy, size: 13, weight: FontWeight.w600),
    hintStyle: bodyStyle(color: AppColors.grey.withValues(alpha: 0.62), size: 14),
    prefixIcon: prefix == null
        ? null
        : Icon(prefix, color: enabled ? AppColors.navy : AppColors.grey, size: 22),
    suffixIcon: suffix,
    filled: true,
    fillColor: enabled ? AppColors.white : AppColors.creamDark,
    enabledBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: AppColors.navy.withValues(alpha: 0.22)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: AppColors.gold, width: 1.6),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: AppColors.navy.withValues(alpha: 0.12)),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: AppColors.error, width: 1.4),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}

EdgeInsets pagePadding(BuildContext context, {double horizontal = 20, double top = 12}) {
  final inset = AppLayout.of(context).contentInset(min: horizontal);
  return EdgeInsets.fromLTRB(
    inset,
    top,
    inset,
    AppChromeScope.embedded(context) ? 120 : 32,
  );
}

class AppDateField extends StatefulWidget {
  const AppDateField({
    super.key,
    required this.label,
    this.controller,
    this.value,
    this.onPicked,
    this.firstDate,
    this.lastDate,
    this.hint = 'Select date',
    this.enabled = true,
  });

  final String label;
  final TextEditingController? controller;
  final DateTime? value;
  final ValueChanged<DateTime>? onPicked;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String hint;
  final bool enabled;

  @override
  State<AppDateField> createState() => _AppDateFieldState();
}

class _AppDateFieldState extends State<AppDateField> {
  DateTime? get _parsed {
    if (widget.value != null) return widget.value;
    final raw = widget.controller?.text.trim() ?? '';
    return DateTime.tryParse(raw);
  }

  String get _display {
    final date = _parsed;
    if (date == null) return widget.hint;
    return DateFormat.yMMMd().format(date);
  }

  Future<void> _pick() async {
    if (!widget.enabled) return;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _parsed ?? now,
      firstDate: widget.firstDate ?? DateTime(1900),
      lastDate: widget.lastDate ?? DateTime(now.year + 30),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.navy,
              onPrimary: AppColors.white,
              secondary: AppColors.gold,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    widget.controller?.text = DateFormat('yyyy-MM-dd').format(picked);
    widget.onPicked?.call(picked);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.enabled ? _pick : null,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: fieldDecoration(
          label: widget.label,
          prefix: Icons.calendar_month_rounded,
          suffix: Icon(
            Icons.event_available_rounded,
            color: widget.enabled ? AppColors.sky : AppColors.grey,
          ),
          enabled: widget.enabled,
        ),
        child: Text(
          _display,
          style: bodyStyle(
            weight: FontWeight.w600,
            color: _parsed == null ? AppColors.grey : AppColors.navy,
          ),
        ),
      ),
    );
  }
}

class AppTimeField extends StatelessWidget {
  const AppTimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onPicked,
    this.enabled = true,
  });

  final String label;
  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onPicked;
  final bool enabled;

  Future<void> _pick(BuildContext context) async {
    if (!enabled) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: value,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.navy,
              onPrimary: AppColors.white,
              secondary: AppColors.gold,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => _pick(context) : null,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: fieldDecoration(
          label: label,
          prefix: Icons.schedule_rounded,
          suffix: Icon(
            Icons.access_time_filled_rounded,
            color: enabled ? AppColors.orange : AppColors.grey,
          ),
          enabled: enabled,
        ),
        child: Text(value.format(context), style: bodyStyle(weight: FontWeight.w600)),
      ),
    );
  }
}

class AppIconBadge extends StatelessWidget {
  const AppIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 40,
    this.iconSize = 20,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

(IconData, Color) categoryLook(String name) {
  final n = name.toLowerCase();
  if (n.contains('aadhaar') || n.contains('id')) return (Icons.badge_rounded, AppColors.sky);
  if (n.contains('pan')) return (Icons.credit_card_rounded, AppColors.orange);
  if (n.contains('passport')) return (Icons.flight_takeoff_rounded, AppColors.teal);
  if (n.contains('insurance') || n.contains('policy')) {
    return (Icons.health_and_safety_rounded, AppColors.purple);
  }
  if (n.contains('vehicle') || n.contains('rc')) {
    return (Icons.directions_car_rounded, AppColors.sky);
  }
  if (n.contains('bank')) return (Icons.account_balance_rounded, AppColors.emerald);
  if (n.contains('property') || n.contains('home')) {
    return (Icons.home_work_rounded, AppColors.navyDeep);
  }
  return (Icons.folder_rounded, AppColors.navy);
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
  return NavyAppBar(title: title, actions: actions, implyLeading: implyLeading);
}

class NavyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NavyAppBar({
    super.key,
    required this.title,
    this.actions,
    this.implyLeading = true,
  });

  final String title;
  final List<Widget>? actions;
  final bool implyLeading;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final hideLeading = AppChromeScope.embedded(context);
    return AppBar(
      title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18)),
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.navy,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: implyLeading && !hideLeading,
      actions: actions,
    );
  }
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

DateTime? parseAppDate(dynamic raw) {
  if (raw == null) return null;
  final text = '$raw'.trim();
  if (text.isEmpty || text == 'null') return null;
  return DateTime.tryParse(text)?.toLocal();
}

String formatDisplayDate(dynamic raw, {String fallback = '—'}) {
  final dt = parseAppDate(raw);
  if (dt == null) return fallback;
  return DateFormat('d MMM yyyy').format(dt);
}

String formatDisplayMonth(DateTime date) {
  return DateFormat('MMM').format(date).toUpperCase();
}

String shortUserRef(dynamic raw) {
  final value = '$raw'.trim();
  if (value.isEmpty || value == 'null') return 'Family member';
  if (value.length <= 10) return value;
  return '${value.substring(0, 6)}…${value.substring(value.length - 4)}';
}
