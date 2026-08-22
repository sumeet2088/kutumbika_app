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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE6EAF0))),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomAppBar(
        color: AppColors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _item(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
              _item(1, Icons.search_rounded, Icons.search_rounded, 'Search'),
              const SizedBox(width: 56),
              _item(2, Icons.shield_outlined, Icons.shield_rounded, 'Alerts', badge: unread),
              _item(3, Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(int index, IconData icon, IconData activeIcon, String label, {int badge = 0}) {
    final selected = currentIndex == index;
    final color = selected ? AppColors.sky : const Color(0xFF8A93A0);
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Badge(
              isLabelVisible: badge > 0,
              backgroundColor: AppColors.error,
              label: Text(
                '$badge',
                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
              ),
              child: Icon(selected ? activeIcon : icon, color: color, size: selected ? 26 : 23),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
