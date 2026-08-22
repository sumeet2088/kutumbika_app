import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/layout.dart';
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
  Size get preferredSize {
    final tablet = AppLayout.detectDeviceType() == 'tablet';
    return Size.fromHeight(tablet ? 85 : 77);
  }

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return AppBar(
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: layout.headerHeight,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      flexibleSpace: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
      title: Row(
        children: [
          IconButton(
            onPressed: onLeading,
            tooltip: showBack ? 'Back' : 'Menu',
            icon: Icon(
              showBack ? Icons.arrow_back_rounded : Icons.menu_rounded,
              color: AppColors.navy,
              size: layout.isTablet ? 28 : 26,
            ),
          ),
          Expanded(
            child: Center(
              child: AppLogo(kind: LogoKind.full, height: layout.logoHeight),
            ),
          ),
          IconButton(
            onPressed: onBell,
            tooltip: 'Notifications',
            icon: Badge(
              isLabelVisible: unread > 0,
              backgroundColor: AppColors.error,
              label: Text(
                '$unread',
                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
              ),
              child: const Icon(Icons.notifications_none_rounded, color: AppColors.navy, size: 26),
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFE6EAF0)),
      ),
    );
  }
}
