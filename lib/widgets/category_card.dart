import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/ui.dart';

class CategoryCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;

  const CategoryCard({
    super.key,
    required this.name,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          AppIconBadge(icon: icon, color: color, size: 36, iconSize: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
