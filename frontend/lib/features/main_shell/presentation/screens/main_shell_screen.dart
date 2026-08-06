import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/floating_nav_bar.dart';

class MainShellScreen extends StatelessWidget {
  final Widget child;

  const MainShellScreen({super.key, required this.child});

  // 4 items: Home | Reels | Jobs | Profile
  // FAB in center goes to /interview/setup
  static const List<FloatingNavBarItem> _navItems = [
    FloatingNavBarItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
      route: '/home',
    ),
    FloatingNavBarItem(
      icon: Icons.play_circle_outline_rounded,
      activeIcon: Icons.play_circle_fill_rounded,
      label: 'Reels',
      route: '/learn',
    ),
    FloatingNavBarItem(
      icon: Icons.work_outline_rounded,
      activeIcon: Icons.work_rounded,
      label: 'Jobs',
      route: '/jobs',
    ),
    FloatingNavBarItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
      route: '/profile',
    ),
  ];

  int _calculateSelectedIndex(BuildContext context) {
    try {
      final String location = GoRouterState.of(context).uri.toString();
      if (location.startsWith('/learn')) return 1;
      if (location.startsWith('/jobs')) return 2;
      if (location.startsWith('/profile') || location.startsWith('/settings')) return 3;
      if (location.startsWith('/home')) return 0;
    } catch (_) {}
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/learn');
        break;
      case 2:
        context.go('/jobs');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,

      body: child,
      bottomNavigationBar: FloatingNavBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        items: _navItems,
        onFabTap: () => context.push('/interview/setup'),
      ),
    );
  }
}
