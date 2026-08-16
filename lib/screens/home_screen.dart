import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: const Color(0xFFF2F4F7),
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
        color: Color(0xFF0D1B2A),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kutumbika',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFD4AF37),
                ),
              ),
              Text(
                'Secure Family Vault',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF687280),
                ),
              ),
            ],
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1B3A6D),
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
          hintStyle: TextStyle(color: Color(0xFF687280)),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF687280)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          color: const Color(0xFF0D1B2A),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    final categories = [
      {'name': 'Documents', 'icon': Icons.description, 'color': const Color(0xFF1B3A6D)},
      {'name': 'Reminders', 'icon': Icons.alarm, 'color': const Color(0xFFD4AF37)},
      {'name': 'Family', 'icon': Icons.people, 'color': const Color(0xFF0D1B2A)},
      {'name': 'Passwords', 'icon': Icons.lock, 'color': const Color(0xFF1B3A6D)},
      {'name': 'Medical', 'icon': Icons.local_hospital, 'color': const Color(0xFFD4AF37)},
      {'name': 'Property', 'icon': Icons.home, 'color': const Color(0xFF0D1B2A)},
      {'name': 'Vehicle', 'icon': Icons.directions_car, 'color': const Color(0xFF1B3A6D)},
      {'name': 'More', 'icon': Icons.more_horiz, 'color': const Color(0xFF687280)},
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
