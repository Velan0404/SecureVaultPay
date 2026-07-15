import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_bottom_nav.dart';

/// Wraps the 5 tab branches (Home/Wallets/Schedule/Analytics/Profile) with
/// the floating [AppBottomNav]. `go_router`'s [StatefulNavigationShell]
/// keeps each branch's own navigation stack and scroll position alive across
/// tab switches.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
