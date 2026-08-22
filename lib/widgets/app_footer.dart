import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/app_colors.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({
    super.key,
    required this.currentIndex,
    required this.unread,
    required this.onTap,
  });

  final int currentIndex;
  final int unread;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppColors.white,
      elevation: 12,
      shadowColor: AppColors.navy.withValues(alpha: 0.12),
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            _item(0, Icons.home_outlined, Icons.home, 'Home'),
            _item(1, Icons.search, Icons.search, 'Search'),
            const SizedBox(width: 56),
            _item(2, Icons.shield_outlined, Icons.shield, 'Alerts', badge: unread),
            _item(3, Icons.person_outline, Icons.person, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _item(int index, IconData icon, IconData activeIcon, String label, {int badge = 0}) {
    final selected = currentIndex == index;
    final color = selected ? AppColors.sky : AppColors.grey;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Badge(
              isLabelVisible: badge > 0,
              backgroundColor: AppColors.error,
              label: Text('$badge', style: const TextStyle(fontSize: 10)),
              child: Icon(selected ? activeIcon : icon, color: color, size: 24),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
