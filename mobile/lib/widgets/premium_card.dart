import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_theme.dart';

/// The base surface for every card in the app — a rounded dark card with a
/// soft drop shadow. Use [PremiumCard.hero] for the maroon-gradient "credit
/// card" treatment (Main Wallet balance, Profile header).
class PremiumCard extends StatelessWidget {
  const PremiumCard({super.key, required this.child, this.padding, this.onTap})
      : _isHero = false,
        _border = null;

  const PremiumCard.hero({super.key, required this.child, this.padding, this.onTap})
      : _isHero = true,
        _border = null;

  /// A flat card with a subtle border instead of a shadow — used where cards
  /// sit directly next to each other (grids) and a shadow per-tile would be
  /// visually noisy.
  const PremiumCard.flat({super.key, required this.child, this.padding, this.onTap})
      : _isHero = false,
        _border = const Border.fromBorderSide(BorderSide(color: AppColors.divider));

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool _isHero;
  final Border? _border;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _isHero ? null : AppColors.surface,
        gradient: _isHero ? AppColors.heroGradient : null,
        borderRadius: AppRadius.xlRadius,
        border: _border,
        boxShadow: _isHero ? AppShadows.card : (_border != null ? null : AppShadows.card),
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.xlRadius,
      child: InkWell(borderRadius: AppRadius.xlRadius, onTap: onTap, child: content),
    );
  }
}
