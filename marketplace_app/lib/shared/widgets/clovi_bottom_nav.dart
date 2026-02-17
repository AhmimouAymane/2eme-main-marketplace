import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class CloviBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CloviBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home, 'Home', 0, active: selectedIndex == 0),
          _buildNavItem(Icons.search, 'Search', 1, active: selectedIndex == 1),
          // Central button
          GestureDetector(
            onTap: () => onItemTapped(2),
            child: Container(
              height: 50,
              width: 50,
              decoration: const BoxDecoration(
                color: AppColors.cloviDarkGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            ),
          ),
          _buildNavItem(Icons.chat_bubble_outline, 'Messages', 3, active: selectedIndex == 3),
          _buildNavItem(Icons.person_outline, 'Profile', 4, active: selectedIndex == 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, {bool active = false}) {
    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: active ? AppColors.cloviGreen : AppColors.textSecondaryLight,
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: active ? AppColors.cloviGreen : AppColors.textSecondaryLight,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
