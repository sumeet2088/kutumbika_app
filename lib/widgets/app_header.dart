import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../widgets/app_logo.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    required this.unread,
    required this.showBack,
    required this.onLeading,
    required this.onBell,
  });

  final int unread;
  final bool showBack;
  final VoidCallback onLeading;
  final VoidCallback onBell;

  @override
  Size get preferredSize => const Size.fromHeight(92);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 92,
      automaticallyImplyLeading: false,
      titleSpacing: 8,
      title: Row(
        children: [
          IconButton(
            onPressed: onLeading,
            icon: Icon(showBack ? Icons.arrow_back_ios_new : Icons.menu, color: AppColors.navy),
          ),
          Expanded(
            child: Column(
              children: [
                const AppLogo(kind: LogoKind.full, height: 46),
                Text(
                  AppConstants.appTagline,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onBell,
            icon: Badge(
              isLabelVisible: unread > 0,
              backgroundColor: AppColors.error,
              label: Text('$unread', style: const TextStyle(fontSize: 10)),
              child: const Icon(Icons.notifications_none_rounded, color: AppColors.navy, size: 26),
            ),
          ),
        ],
      ),
    );
  }
}
