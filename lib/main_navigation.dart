import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'request_screen.dart';
import 'alerts_screen.dart';
import 'profile_screen.dart';
import 'utils/responsive.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    MapScreen(),
    RequestScreen(),
    AlertsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildInnovativeBottomNav(),
    );
  }

  Widget _buildInnovativeBottomNav() {
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final contentHeight = Responsive.bottomNavContentHeight(context);
    
    return Container(
      height: Responsive.bottomNavHeight(context),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: contentHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, 'Home', 0),
              _buildNavItem(Icons.map_rounded, 'Map', 1),
              _buildNavItem(Icons.add_circle_rounded, 'Request', 2, isCenter: true),
              _buildNavItem(Icons.notifications_rounded, 'Alerts', 3),
              _buildNavItem(Icons.person_rounded, 'Profile', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, {bool isCenter = false}) {
    final isSelected = _currentIndex == index;
    final iconSize = Responsive.isSmallMobile(context)
      ? Responsive.iconSize(context, isSelected ? 22 : 20)
      : Responsive.iconSize(context, isSelected ? 26 : 24);
    final centerIconSize = Responsive.isSmallMobile(context)
      ? Responsive.iconSize(context, isSelected ? 26 : 24)
      : Responsive.iconSize(context, isSelected ? 30 : 28);
    final fontSize = Responsive.fontSize(context, Responsive.isSmallMobile(context) ? 10 : 11);
    final centerButtonSize = Responsive.isSmallMobile(context)
      ? (isSelected ? 52.0 : 50.0)
      : Responsive.value(
          context,
          mobile: isSelected ? 58.0 : 55.0,
          tablet: isSelected ? 70.0 : 65.0,
          desktop: isSelected ? 80.0 : 75.0,
        );
    
    if (isCenter) {
      // Special center button with elevated design
      return GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: centerButtonSize,
          height: centerButtonSize,
          decoration: BoxDecoration(
            color: isSelected ? Colors.red : Colors.red.shade100,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(isSelected ? 0.4 : 0.2),
                blurRadius: isSelected ? 15 : 12,
                offset: Offset(0, isSelected ? 6 : 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : Colors.red,
            size: centerIconSize,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.isSmallMobile(context) 
            ? Responsive.spacing(context, 8) 
            : Responsive.spacing(context, 14),
          vertical: Responsive.isSmallMobile(context)
            ? Responsive.spacing(context, 6)
            : Responsive.spacing(context, 10),
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  padding: EdgeInsets.all(isSelected ? 6 : 0),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.red.withOpacity(0.1) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.red : Colors.grey.shade600,
                    size: iconSize,
                  ),
                ),
                if (index == 3) // Alerts badge
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: Responsive.value(context, mobile: 10.0, tablet: 12.0, desktop: 14.0),
                      height: Responsive.value(context, mobile: 10.0, tablet: 12.0, desktop: 14.0),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: Responsive.isSmallMobile(context) 
              ? Responsive.spacing(context, 4) 
              : Responsive.spacing(context, 6)),
            AnimatedDefaultTextStyle(
              duration: Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.red : Colors.grey.shade600,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
