import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'request_screen.dart';
import 'alerts_screen.dart';
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
    RequestScreen(),
    AlertsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Ensure index is within valid range
    final safeIndex = _currentIndex.clamp(0, _screens.length - 1);
    
    return Scaffold(
      body: IndexedStack(
        key: ValueKey('main_navigation_stack'),
        index: safeIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildInnovativeBottomNav(),
    );
  }

  Widget _buildInnovativeBottomNav() {
    return Container(
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
          height: 65,
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, 'Home', 0),
              _buildNavItem(Icons.list_alt_rounded, 'My Request', 1),
              _buildNavItem(Icons.notifications_rounded, 'Alerts', 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    // Ensure index is valid
    if (index >= _screens.length) return SizedBox.shrink();
    
    final isSelected = _currentIndex == index;
    final iconSize = Responsive.isSmallMobile(context)
      ? (isSelected ? 20.0 : 18.0)
      : (isSelected ? 22.0 : 20.0);
    final fontSize = Responsive.isSmallMobile(context) ? 10.0 : 11.0;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        child: Container(
          height: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.all(isSelected ? 6 : 4),
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
              SizedBox(height: 3),
              Flexible(
                child: AnimatedDefaultTextStyle(
                  duration: Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.red : Colors.grey.shade600,
                    height: 1.0,
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
