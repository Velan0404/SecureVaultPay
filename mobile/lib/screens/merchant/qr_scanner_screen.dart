import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/errors/app_exception.dart';
import '../../models/personal_payment_receiver_model.dart';
import '../../models/purpose_wallet_model.dart';
import '../../providers/personal_payment_provider.dart';
import '../../providers/qr_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/loading_indicator.dart';
import '../personal_payment/personal_payment_preview_screen.dart';
import 'camera_permission_view.dart';
import 'qr_merchant_preview_screen.dart';

/// "Pay Merchant" or "Send Money" via QR — the camera preview + live scan,
/// shared by both Merchant QR (Phase 6) and Personal QR (Phase 7) since a
/// user shouldn't have to pre-declare which kind they're about to scan.
/// Reads the scanned payload client-side only far enough to tell the two
/// kinds apart and extract an id; every actual validity check happens
/// server-side (GET /qr/validate/:qrId or GET /personal-payment/lookup/:id).
///
/// [preselectedWallet] is set when entered from Wallet Details (that
/// wallet is implicit, same shortcut as the existing "Pay a Merchant"
/// button there) — null for the Dashboard/general "Scan QR" entry point.
///
/// [onPersonalReceiverSelected] is a third mode (Phase 7 — Scheduled
/// Payments): when set, a scanned Personal QR is resolved and handed back
/// via this callback + `context.pop()` instead of pushing to Personal
/// Payment Preview — used by Create Schedule to pick a recurring "Send to a
/// Person" destination once, rather than paying immediately. A Merchant QR
/// scanned in this mode is rejected with a clarifying message, since this
/// mode is specifically for picking a person.
class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key, this.preselectedWallet, this.onPersonalReceiverSelected});

  final PurposeWalletModel? preselectedWallet;
  final ValueChanged<PersonalPaymentReceiverModel>? onPersonalReceiverSelected;

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final _controller = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Decodes a scanned payload just far enough to tell a Merchant QR from a
  /// Personal QR apart. Returns `null` for anything unrecognized — actual
  /// validity (expired, tampered, inactive) is always checked server-side.
  _ScannedQr? _decode(String rawValue) {
    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is! Map<String, dynamic>) return null;
      switch (decoded['type']) {
        case 'SVP_MERCHANT_QR':
          final qrId = decoded['qrId'] as String?;
          return qrId == null ? null : _ScannedQr.merchant(qrId);
        case 'USER_PAYMENT':
          final userId = decoded['userId'] as String?;
          return userId == null ? null : _ScannedQr.personal(userId, decoded['secureVaultId'] as String?);
        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || capture.barcodes.isEmpty) return;
    final rawValue = capture.barcodes.first.rawValue;
    if (rawValue == null) return;

    final scanned = _decode(rawValue);
    if (scanned == null) {
      showAppSnackBar(context, "That doesn't look like a SecureVault Pay QR code.");
      return;
    }

    setState(() => _isProcessing = true);
    try {
      if (scanned.qrId != null) {
        if (widget.onPersonalReceiverSelected != null) {
          showAppSnackBar(context, "Scan a person's QR here, not a merchant's.");
          return;
        }
        final validation = await ref.read(qrProvider.notifier).validate(scanned.qrId!);
        if (mounted) {
          context.push(
            '/qr/preview',
            extra: QrPreviewRouteArgs(validation: validation, preselectedWallet: widget.preselectedWallet),
          );
        }
      } else {
        final receiver = await ref
            .read(personalPaymentProvider.notifier)
            .lookupReceiver(userId: scanned.userId!, secureVaultId: scanned.secureVaultId);
        if (mounted) {
          if (widget.onPersonalReceiverSelected != null) {
            widget.onPersonalReceiverSelected!(receiver);
            context.pop();
          } else {
            context.push(
              '/personal-payment/preview',
              extra: PersonalPaymentScanArgs(receiver: receiver, preselectedWallet: widget.preselectedWallet),
            );
          }
        }
      }
    } on AppException catch (e) {
      if (mounted) showAppSnackBar(context, e.message);
    } catch (_) {
      if (mounted) showAppSnackBar(context, 'Could not reach the server. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Merchant QR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_outlined),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              if (error.errorCode == MobileScannerErrorCode.permissionDenied) {
                return CameraPermissionView(onRetry: () => _controller.start());
              }
              return ColoredBox(
                color: AppColors.background,
                child: Center(
                  child: Text(error.errorCode.message, style: const TextStyle(color: Colors.white)),
                ),
              );
            },
          ),
          const IgnorePointer(child: _ScanWindowOutline()),
          if (_isProcessing)
            const ColoredBox(
              color: Colors.black54,
              child: Center(child: LoadingIndicator(size: 40, color: Colors.white)),
            ),
        ],
      ),
    );
  }
}

class _ScannedQr {
  const _ScannedQr.merchant(this.qrId) : userId = null, secureVaultId = null;
  const _ScannedQr.personal(this.userId, this.secureVaultId) : qrId = null;

  final String? qrId;
  final String? userId;
  final String? secureVaultId;
}

class _ScanWindowOutline extends StatelessWidget {
  const _ScanWindowOutline();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primaryRed, width: 3),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}
