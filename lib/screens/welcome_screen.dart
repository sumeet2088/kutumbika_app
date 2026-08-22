import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/app_colors.dart';
import '../utils/ui.dart';
import '../widgets/app_logo.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _page = PageController();
  int _index = 0;

  void _next() {
    if (_index == 0) {
      _page.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _page,
                  onPageChanged: (i) => setState(() => _index = i),
                  children: const [
                    _WelcomePage(
                      title: 'Welcome to Paarisetu.',
                      kicker: 'SECURE FAMILY LIFE',
                      body:
                          'One private place for your family to keep documents, identities, and memories safe across generations.',
                      detail:
                          'Invite parents, spouse, and children with Owner, Editor, or Viewer roles. Everyone sees only what they should.',
                      flows: [
                        _FlowItem(Icons.groups_outlined, 'Family'),
                        _FlowItem(Icons.lock_outline, 'Vault'),
                        _FlowItem(Icons.verified_user_outlined, 'Secure'),
                      ],
                    ),
                    _WelcomePage(
                      title: 'Your Digital Family Vault.',
                      kicker: 'STORE. ORGANIZE. SHARE.',
                      body:
                          'Upload passports, property papers, insurance, and medical records. Reminders watch expiry dates for you.',
                      detail:
                          'Access stays with the family even if a member leaves. Upgrade anytime for more storage, seats, and devices.',
                      flows: [
                        _FlowItem(Icons.description_outlined, 'Documents'),
                        _FlowItem(Icons.alarm_outlined, 'Reminders'),
                        _FlowItem(Icons.share_outlined, 'Share'),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(2, (i) {
                  final active = i == _index;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 10 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active ? AppColors.gold : Colors.transparent,
                      border: Border.all(color: AppColors.gold, width: 1.4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: _index == 0 ? 'Continue' : 'Login',
                onPressed: _next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlowItem {
  const _FlowItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({
    required this.title,
    required this.body,
    required this.kicker,
    required this.detail,
    required this.flows,
  });

  final String title;
  final String body;
  final String kicker;
  final String detail;
  final List<_FlowItem> flows;

  @override
  Widget build(BuildContext context) {
    final logoWidth = MediaQuery.sizeOf(context).width * 0.58;
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Center(child: AppLogo(kind: LogoKind.icon, width: logoWidth)),
          const SizedBox(height: 28),
          Text(
            kicker,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 10),
          Text(title, textAlign: TextAlign.center, style: headingStyle(size: 26)),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: bodyStyle(size: 14, color: AppColors.navyDeep),
          ),
          const SizedBox(height: 10),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: bodyStyle(size: 13, color: AppColors.grey),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              for (final item in flows)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.lightGrey,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(item.icon, color: AppColors.navy, size: 26),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: bodyStyle(size: 12, weight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
