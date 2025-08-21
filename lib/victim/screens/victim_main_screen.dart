import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import 'victim_home_screen.dart';
import 'victim_ong_screen.dart';
import 'victim_contacts_screen.dart';
import 'victim_menu_screen.dart';

/// Écran principal avec navigation bottom pour les victimes
class VictimMainScreen extends StatefulWidget {
  const VictimMainScreen({super.key});

  @override
  State<VictimMainScreen> createState() => _VictimMainScreenState();
}

class _VictimMainScreenState extends State<VictimMainScreen> {
  int _currentIndex = 0;
  
  late final List<Widget> _screens;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _screens = [
      const VictimHomeScreen(),
      const VictimOngScreen(),
      const VictimContactsScreen(),
      const VictimMenuScreen(),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppConstants.whiteColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingSmall,
              vertical: AppConstants.paddingSmall,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.home_filled,
                  label: 'Accueil',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.business,
                  label: 'ONG',
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.contacts,
                  label: 'Mes Contacts',
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.menu,
                  label: 'Menu',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppConstants.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? AppConstants.primaryColor 
                  : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected 
                    ? AppConstants.primaryColor 
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
