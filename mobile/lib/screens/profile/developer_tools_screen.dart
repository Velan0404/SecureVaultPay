import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';
import '../../widgets/profile_menu_tile.dart';

/// Profile -> Developer Tools — a dev/testing-only menu, separate from the
/// customer-facing Profile settings above it. Currently just the Demo QR
/// Generator (Phase 6), but kept as its own screen so future dev-only
/// utilities have a home without cluttering the main Profile screen.
class DeveloperToolsScreen extends StatelessWidget {
  const DeveloperToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Developer Tools')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ProfileMenuTile(
            icon: Icons.qr_code_2_outlined,
            iconColor: AppColors.categoryBlue,
            title: 'Demo QR Generator',
            subtitle: 'Generate a scannable demo QR for any merchant',
            onTap: () => context.push('/profile/developer-tools/demo-qr'),
          ),
        ],
      ),
    );
  }
}
