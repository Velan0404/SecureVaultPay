import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shared centered layout for short-form auth steps (Create PIN, PIN Unlock,
/// Enable Biometric) — a scrollable, centered column over the app background.
class CenteredAuthScaffold extends StatelessWidget {
  const CenteredAuthScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: child),
        ),
      ),
    );
  }
}
