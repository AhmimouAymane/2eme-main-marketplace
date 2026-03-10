import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../providers/shop_providers.dart';

class CloviBottomNav extends ConsumerWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CloviBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadMessagesCountProvider);

    return SafeArea(
      top: false,
      child: Padding(
        // IMPROVEMENT: Smaller margin → bar sits closer to screen edge, less intrusive
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        child: Container(
          height: 58, // IMPROVEMENT: Reduced from 70 → more compact
          decoration: BoxDecoration(
            color: AppColors.cloviGreen,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.cloviGreen.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, index: 0, selectedIndex: selectedIndex, onTap: onItemTapped),
              _NavItem(icon: Icons.search_outlined, activeIcon: Icons.search_rounded, index: 1, selectedIndex: selectedIndex, onTap: onItemTapped),

              // Central "+" button
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: () => onItemTapped(2),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: AppColors.cloviGreen,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),

              // Messages with badge
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    _NavItem(
                      icon: Icons.chat_bubble_outline_rounded,
                      activeIcon: Icons.chat_bubble_rounded,
                      index: 3,
                      selectedIndex: selectedIndex,
                      onTap: onItemTapped,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        top: 8,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              _NavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                index: 4,
                selectedIndex: selectedIndex,
                onTap: onItemTapped,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// IMPROVEMENT: Extracted to its own widget — no more passing 5 args to a method
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final int index;
  final int selectedIndex;
  final Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isActive ? activeIcon : icon,
              key: ValueKey(isActive),
              // IMPROVEMENT: Active icon is full white + slightly larger, inactive is dimmed
              color: isActive ? Colors.white : Colors.white.withOpacity(0.45),
              size: isActive ? 26 : 23,
            ),
          ),
        ),
      ),
    );
  }
}