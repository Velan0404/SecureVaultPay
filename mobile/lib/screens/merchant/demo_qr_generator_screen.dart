import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../models/merchant_model.dart';
import '../../providers/merchant_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/merchant_icons.dart';

/// Profile -> Developer Tools -> Demo QR Generator — a direct testing entry
/// point into DemoMerchantQrScreen that doesn't require an existing Purpose
/// Wallet or browsing through a wallet's merchant list first (unlike the
/// customer-facing "Show QR" action on Merchant Details). Lists every demo
/// merchant; tapping one reuses the exact same `/merchants/:id/qr` route.
class DemoQrGeneratorScreen extends ConsumerStatefulWidget {
  const DemoQrGeneratorScreen({super.key});

  @override
  ConsumerState<DemoQrGeneratorScreen> createState() => _DemoQrGeneratorScreenState();
}

class _DemoQrGeneratorScreenState extends ConsumerState<DemoQrGeneratorScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<MerchantModel> _merchants = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final merchants = await ref.read(merchantRepositoryProvider).listMerchants();
      if (mounted) setState(() => _merchants = merchants);
    } on AppException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'Could not reach the server. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demo QR Generator')),
      body: _isLoading
          ? const LoadingScreen()
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: EmptyState(
                      icon: Icons.error_outline,
                      title: 'Could not load merchants',
                      message: _errorMessage!,
                      onRetry: _load,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _merchants.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final merchant = _merchants[index];
                    return Container(
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryRed.withValues(alpha: 0.12),
                          child: Icon(MerchantIcons.resolve(merchant.merchantLogo), color: AppColors.primaryRed),
                        ),
                        title: Text(merchant.merchantName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(MerchantCategories.label(merchant.merchantCategory)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                        onTap: () => context.push('/merchants/${merchant.id}/qr', extra: merchant),
                      ),
                    );
                  },
                ),
    );
  }
}
