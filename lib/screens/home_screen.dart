import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/category_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Search Bar
            _buildSearchBar(),

            // Welcome Message
            _buildWelcomeMessage(),

            // Categories
            Expanded(
              child: _buildCategories(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.primaryDarkBlue,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConstants.appName,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.goldYellow,
                ),
              ),
              Text(
                'Secure Family Vault',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondaryBlue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.notifications_none,
              color: Color(0xFFD4AF37),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search documents, reminders...',
          hintStyle: const TextStyle(color: AppColors.grey),
          prefixIcon: const Icon(Icons.search, color: AppColors.grey),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        'Welcome back!',
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryDarkBlue,
        ),
      ),
    );
  }

  Widget _buildCategories() {
    final categories = [
      {
        'name': 'Documents',
        'icon': Icons.description,
        'color': AppColors.secondaryBlue
      },
      {'name': 'Reminders', 'icon': Icons.alarm, 'color': AppColors.goldYellow},
      {
        'name': 'Family',
        'icon': Icons.people,
        'color': AppColors.primaryDarkBlue
      },
      {
        'name': 'Passwords',
        'icon': Icons.lock,
        'color': AppColors.secondaryBlue
      },
      {
        'name': 'Medical',
        'icon': Icons.local_hospital,
        'color': AppColors.goldYellow
      },
      {
        'name': 'Property',
        'icon': Icons.home,
        'color': AppColors.primaryDarkBlue
      },
      {
        'name': 'Vehicle',
        'icon': Icons.directions_car,
        'color': AppColors.secondaryBlue
      },
      {'name': 'More', 'icon': Icons.more_horiz, 'color': AppColors.grey},
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return CategoryCard(
          name: categories[index]['name'] as String,
          icon: categories[index]['icon'] as IconData,
          color: categories[index]['color'] as Color,
        );
      },
    );
  }
}
