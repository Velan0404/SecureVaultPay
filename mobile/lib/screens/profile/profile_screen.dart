import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';
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

  Future<void> _editTransferPhoneNumber() async {
    final controller = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Phone number for transfers'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Main Wallet transfers require a one-time code sent by SMS. Enter your number in international format.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: '+919876543210', prefixIcon: Icon(Icons.phone_outlined)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => context.pop(true), child: const Text('Save')),
        ],
      ),
    );

    if (saved != true || !mounted) return;

    try {
      await ref.read(transactionAuthRepositoryProvider).setPhoneNumber(controller.text.trim());
      if (mounted) showAppSnackBar(context, 'Phone number saved for transfer verification.', isError: false);
    } on AppException catch (e) {
      if (mounted) showAppSnackBar(context, e.message);
    } catch (_) {
      if (mounted) showAppSnackBar(context, 'Could not reach the server. Check your connection and try again.');
    }
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
                  const SizedBox(width: 8),
                  _MyQrButton(onTap: () => context.push('/my-qr')),
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
            icon: Icons.sms_outlined,
            iconColor: AppColors.primaryRed,
            title: 'Transfer Verification Number',
            subtitle: 'Required for Main Wallet transfers',
            onTap: _editTransferPhoneNumber,
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
          ProfileMenuTile(
            icon: Icons.developer_mode_outlined,
            iconColor: AppColors.categoryGold,
            title: 'Developer Tools',
            subtitle: 'Demo QR Generator and other testing utilities',
            onTap: () => context.push('/profile/developer-tools'),
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

/// The "My QR" shortcut on the right side of the Profile hero card — every
/// user's permanent Personal QR (see MyQrScreen), styled to sit on top of
/// the hero gradient like the avatar circle next to it.
class _MyQrButton extends StatelessWidget {
  const _MyQrButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.mdRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: AppRadius.mdRadius,
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_2, color: Colors.white, size: 22),
            SizedBox(height: 2),
            Text('My QR', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
