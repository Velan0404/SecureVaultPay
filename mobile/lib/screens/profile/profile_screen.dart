import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/profile_menu_tile.dart';

/// Every value shown here is either real auth/wallet state already in the
/// app (name, email, biometric status, wallet count) or an honest
/// "coming soon" row — nothing on this screen is fabricated data.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    if (ref.read(walletProvider).dashboard == null) {
      ref.read(walletProvider.notifier).loadDashboard();
    }
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$feature is coming in a future update.')));
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final walletCount = ref.watch(walletProvider).purposeWallets.length;
    final initial = (user?.fullName.isNotEmpty == true ? user!.fullName[0] : 'S').toUpperCase();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          FadeSlideIn(
            child: PremiumCard.hero(
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                    child: Text(
                      initial,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? '',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ProfileMenuTile(
            icon: Icons.fingerprint,
            iconColor: AppColors.success,
            title: 'Biometric Login',
            subtitle: user?.biometricEnabled == true ? 'Enabled on this device' : 'Not enabled — using PIN only',
            onTap: () => _comingSoon('Changing biometric settings from Profile'),
          ),
          ProfileMenuTile(
            icon: Icons.account_balance_wallet_outlined,
            iconColor: AppColors.categoryPurple,
            title: 'Manage Wallets',
            subtitle: '$walletCount active wallet${walletCount == 1 ? '' : 's'}',
            onTap: () => context.go('/wallet/main'),
          ),
          ProfileMenuTile(
            icon: Icons.calendar_month_outlined,
            iconColor: AppColors.categoryGold,
            title: 'Scheduled Payments',
            subtitle: 'Coming soon',
            onTap: () => _comingSoon('Scheduled Payments'),
          ),
          ProfileMenuTile(
            icon: Icons.notifications_outlined,
            iconColor: AppColors.info,
            title: 'Notifications',
            subtitle: 'Coming soon',
            onTap: () => _comingSoon('Notification preferences'),
          ),
          ProfileMenuTile(
            icon: Icons.privacy_tip_outlined,
            iconColor: AppColors.categoryPink,
            title: 'Privacy & Data',
            subtitle: 'Coming soon',
            onTap: () => _comingSoon('Privacy & Data controls'),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            icon: const Icon(Icons.logout, color: AppColors.danger),
            label: const Text('Log out', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
