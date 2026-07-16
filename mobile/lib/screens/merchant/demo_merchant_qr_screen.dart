import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../../models/demo_qr_model.dart';
import '../../models/merchant_model.dart';
import '../../providers/qr_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/primary_button.dart';

/// Dev/demo-only "merchant terminal" — generates a fresh, single-use,
/// time-boxed QR for this merchant and renders it as a real scannable image.
/// Stands in for a physical merchant QR terminal since this project doesn't
/// integrate with UPI/NPCI; a real terminal would also regenerate its QR
/// periodically for the same replay-prevention reason.
class DemoMerchantQrScreen extends ConsumerStatefulWidget {
  const DemoMerchantQrScreen({super.key, required this.merchant});

  final MerchantModel merchant;

  @override
  ConsumerState<DemoMerchantQrScreen> createState() => _DemoMerchantQrScreenState();
}

class _DemoMerchantQrScreenState extends ConsumerState<DemoMerchantQrScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  DemoQrModel? _qr;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final qr = await ref.read(qrProvider.notifier).generateDemo(widget.merchant.id);
      if (mounted) setState(() => _qr = qr);
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
      appBar: AppBar(title: Text('${widget.merchant.merchantName} QR')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isLoading
              ? const LoadingIndicator(size: 40)
              : _errorMessage != null
                  ? EmptyState(
                      icon: Icons.error_outline,
                      title: 'Could not generate QR',
                      message: _errorMessage!,
                      onRetry: _generate,
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PremiumCard(
                          padding: const EdgeInsets.all(20),
                          child: QrImageView(data: _qr!.payload, size: 220, backgroundColor: Colors.white),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Demo QR for ${widget.merchant.merchantName}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "This QR is single-use and expires in 10 minutes — scan it with "
                          "another device's Scan QR screen to pay.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(width: 200, child: PrimaryButton(label: 'Generate New QR', onPressed: _generate)),
                      ],
                    ),
        ),
      ),
    );
  }
}
