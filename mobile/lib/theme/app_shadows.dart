import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Shared elevation presets. Dark surfaces read depth mostly through subtle
/// black drop-shadows and the occasional brand-colored glow (for the hero
/// balance card and the floating nav) rather than heavy Material elevation.
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get card => [
        BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 10)),
      ];

  static List<BoxShadow> get floating => [
        BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 28, offset: const Offset(0, 14)),
      ];

  static List<BoxShadow> get redGlow => [
        BoxShadow(color: AppColors.primaryRed.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10)),
      ];
}
