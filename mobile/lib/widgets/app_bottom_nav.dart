import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_theme.dart';

class _NavItemData {
  const _NavItemData(this.icon, this.activeIcon, this.label);
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

const _items = [
  _NavItemData(Icons.home_outlined, Icons.home_rounded, 'Home'),
  _NavItemData(Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded, 'Wallets'),
  _NavItemData(Icons.calendar_today_outlined, Icons.calendar_today_rounded, 'Schedule'),
  _NavItemData(Icons.pie_chart_outline_rounded, Icons.pie_chart_rounded, 'Analytics'),
  _NavItemData(Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
];

/// The app's floating premium bottom navigation — a rounded, elevated dark
/// bar with 5 tabs, the active one lifted onto a red icon pill. Replaces
/// Flutter's default [BottomNavigationBar] entirely.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.pillRadius,
            border: Border.all(color: AppColors.divider),
            boxShadow: AppShadows.floating,
          ),
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final selected = index == currentIndex;
              return Expanded(
                child: _NavItem(item: item, selected: selected, onTap: () => onTap(index)),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.item, required this.selected, required this.onTap});

  final _NavItemData item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.pillRadius,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: selected ? AppColors.primaryRed.withValues(alpha: 0.18) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              selected ? item.activeIcon : item.icon,
              size: 20,
              color: selected ? AppColors.primaryRed : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.primaryRed : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
