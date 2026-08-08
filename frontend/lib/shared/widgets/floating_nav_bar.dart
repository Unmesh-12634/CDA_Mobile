import 'dart:ui';
import 'package:flutter/material.dart';

class FloatingNavBarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const FloatingNavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}

class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<FloatingNavBarItem> items;
  final VoidCallback onFabTap;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    required this.onFabTap,
  });

  @override
  Widget build(BuildContext context) {
    final leftItems = items.take(2).toList();
    final rightItems = items.skip(2).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Inspired by reference UI: sleek floating dark dock ──────────────
    final dockBg = isDark
        ? const Color(0xFF121722).withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.94);
    final borderColor = isDark ? const Color(0xFF1E273A) : const Color(0xFFE2E8F0);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        height: 64,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Floating pill dock
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: dockBg,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: borderColor, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.6)
                            : const Color(0xFF0F172A).withValues(alpha: 0.08),
                        blurRadius: 28,
                        spreadRadius: 0,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Left nav items
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: leftItems.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final item = entry.value;
                            final isSelected = idx == currentIndex;
                            return _NavItem(
                              icon: isSelected ? item.activeIcon : item.icon,
                              label: item.label,
                              isSelected: isSelected,
                              isDark: isDark,
                              onTap: () => onTap(idx),
                            );
                          }).toList(),
                        ),
                      ),

                      // Gap reserved for the center floating blue FAB button
                      const SizedBox(width: 60),

                      // Right nav items
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: rightItems.asMap().entries.map((entry) {
                            final idx = entry.key + 2;
                            final item = entry.value;
                            final isSelected = idx == currentIndex;
                            return _NavItem(
                              icon: isSelected ? item.activeIcon : item.icon,
                              label: item.label,
                              isSelected: isSelected,
                              isDark: isDark,
                              onTap: () => onTap(idx),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Center floating electric blue FAB (mic = AI Interview)
            Positioned(
              top: -14,
              child: GestureDetector(
                onTap: onFabTap,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF4648D4), Color(0xFF6B6EF9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF4648D4),
                        blurRadius: 0,
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Color(0x884648D4),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF3B82F6); // electric vibrant blue
    final inactiveColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? activeColor : inactiveColor,
            size: 22,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? activeColor : inactiveColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
