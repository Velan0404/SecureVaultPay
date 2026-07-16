import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../../models/user_qr_model.dart';
import '../../providers/personal_payment_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/secondary_button.dart';

/// Every SecureVault Pay user's permanent Personal QR — scan this to send
/// money directly into this user's Main Wallet. Unlike a Merchant QR, this
/// never expires and is never consumed by scanning or by payment.
class MyQrScreen extends ConsumerStatefulWidget {
  const MyQrScreen({super.key});

  @override
  ConsumerState<MyQrScreen> createState() => _MyQrScreenState();
}

class _MyQrScreenState extends ConsumerState<MyQrScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  UserQrModel? _qr;

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
      final qr = await ref.read(personalPaymentProvider.notifier).getMyQr();
      if (mounted) setState(() => _qr = qr);
    } on AppException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'Could not reach the server. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _shareComingSoon() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Sharing your QR is coming in a future update.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My QR')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isLoading
              ? const LoadingIndicator(size: 40)
              : _errorMessage != null
                  ? EmptyState(
                      icon: Icons.error_outline,
                      title: 'Could not load your QR',
                      message: _errorMessage!,
                      onRetry: _load,
                    )
                  : _buildQr(_qr!),
        ),
      ),
    );
  }

  Widget _buildQr(UserQrModel qr) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PremiumCard(
          padding: const EdgeInsets.all(20),
          child: QrImageView(data: qr.payload, size: 220, backgroundColor: Colors.white),
        ),
        const SizedBox(height: 20),
        Text(qr.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
          qr.phoneNumber ?? 'No mobile number on file — add one in Profile.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        Text(
          qr.secureVaultId,
          style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, letterSpacing: 1),
        ),
        const SizedBox(height: 16),
        const Text(
          'Scan this QR to send money.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: 200,
          child: SecondaryButton(label: 'Share QR', icon: Icons.share_outlined, onPressed: _shareComingSoon),
        ),
      ],
    );
  }
}
