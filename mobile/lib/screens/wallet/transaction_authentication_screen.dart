import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/currency_formatter.dart';
import '../../models/purpose_wallet_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/code_input_field.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/wallet_icons.dart';

/// Router `extra` payload for `/wallet/transaction-auth` — bundles the
/// Purpose Wallet and the amount collected by TransferMoneyScreen.
class TransactionAuthRouteArgs {
  const TransactionAuthRouteArgs({required this.wallet, required this.amount});

  final PurposeWalletModel wallet;
  final String amount;
}

/// The mandatory security layer between "Transfer Details" and an executed
/// Main Wallet -> Purpose Wallet transfer: fingerprint, then a Twilio-backed
/// OTP, then the transfer itself. This screen is the ONLY place a transfer
/// can be authorized — TransferMoneyScreen only collects the wallet+amount
/// and hands off here.
class TransactionAuthenticationScreen extends ConsumerStatefulWidget {
  const TransactionAuthenticationScreen({
    super.key,
    required this.purposeWalletId,
    required this.purposeWalletName,
    required this.purposeWalletIcon,
    required this.purposeWalletColor,
    required this.amount,
  });

  final String purposeWalletId;
  final String purposeWalletName;
  final String purposeWalletIcon;
  final String purposeWalletColor;
  final String amount;

  @override
  ConsumerState<TransactionAuthenticationScreen> createState() => _TransactionAuthenticationScreenState();
}

class _TransactionAuthenticationScreenState extends ConsumerState<TransactionAuthenticationScreen> {
  final _otpController = TextEditingController();
  bool _isAuthenticating = false;
  Timer? _resendTimer;
  int _resendSecondsRemaining = 30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(transactionAuthProvider.notifier).start(
            purposeWalletId: widget.purposeWalletId,
            amount: widget.amount,
          );
      if (mounted) _attemptFingerprint();
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _resendSecondsRemaining = 30);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSecondsRemaining <= 1) {
        timer.cancel();
        setState(() => _resendSecondsRemaining = 0);
      } else {
        setState(() => _resendSecondsRemaining -= 1);
      }
    });
  }

  Future<void> _attemptFingerprint() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);

    final biometricService = ref.read(biometricServiceProvider);
    final success = await biometricService.authenticate(reason: 'Confirm transfer of ${CurrencyFormatter.format(widget.amount)}');

    if (!mounted) return;

    // _isAuthenticating deliberately stays true until the *entire* success
    // path (confirm-fingerprint + send-otp) finishes, not just the biometric
    // prompt — otherwise the "Try Again" button reappears mid-flight and a
    // second tap fires a second confirm-fingerprint call for a session
    // that's already past that step, crashing with an unhandled exception
    // (found live on-device: rapid repeat fingerprint reads on this sensor
    // triggered exactly this race).
    if (success) {
      await ref.read(transactionAuthProvider.notifier).onFingerprintSuccess();
      if (mounted) {
        setState(() => _isAuthenticating = false);
        if (ref.read(transactionAuthProvider).step == TransactionAuthStep.otp) {
          _startResendCountdown();
        }
      }
    } else {
      setState(() => _isAuthenticating = false);
      final canRetry = await ref.read(transactionAuthProvider.notifier).onFingerprintFailure();
      if (mounted && canRetry) {
        showAppSnackBar(context, biometricService.failureMessage);
      }
    }
  }

  Future<void> _onOtpCompleted(String code) async {
    final error = await ref.read(transactionAuthProvider.notifier).verifyOtpAndTransfer(
          code: code,
          purposeWalletId: widget.purposeWalletId,
          amount: widget.amount,
        );
    if (!mounted) return;
    if (error != null) {
      showAppSnackBar(context, error);
      _otpController.clear();
    }
  }

  Future<void> _resendOtp() async {
    await ref.read(transactionAuthProvider.notifier).resendOtp();
    if (mounted) {
      _startResendCountdown();
      showAppSnackBar(context, 'A new OTP has been sent.', isError: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionAuthProvider);
    final color = WalletColors.fromHex(widget.purposeWalletColor);

    return PopScope(
      canPop: state.step == TransactionAuthStep.success || state.step == TransactionAuthStep.failed,
      child: Scaffold(
        appBar: AppBar(title: const Text('Confirm Transfer'), automaticallyImplyLeading: false),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FadeSlideIn(
                  child: PremiumCard(
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
                          child: Icon(WalletIcons.resolve(widget.purposeWalletIcon), color: color),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('To ${widget.purposeWalletName}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              const SizedBox(height: 2),
                              Text(
                                CurrencyFormatter.format(widget.amount),
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Expanded(child: Center(child: _buildStepContent(context, state))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(BuildContext context, TransactionAuthState state) {
    switch (state.step) {
      case TransactionAuthStep.fingerprint:
        return _FingerprintStep(
          isAuthenticating: _isAuthenticating,
          attemptsRemaining: kMaxFingerprintAttempts - state.fingerprintAttempts,
          onRetry: _attemptFingerprint,
        );
      case TransactionAuthStep.otp:
        return _OtpStep(
          controller: _otpController,
          maskedPhoneNumber: state.maskedPhoneNumber,
          isVerifying: state.isProcessing,
          secondsRemaining: _resendSecondsRemaining,
          onCompleted: _onOtpCompleted,
          onResend: _resendSecondsRemaining == 0 ? _resendOtp : null,
        );
      case TransactionAuthStep.processing:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LoadingIndicator(size: 40),
            SizedBox(height: 20),
            Text('Processing your transfer…', style: TextStyle(color: AppColors.textSecondary)),
          ],
        );
      case TransactionAuthStep.success:
        return _SuccessStep(
          amount: widget.amount,
          walletName: widget.purposeWalletName,
          onDone: () => context.go('/dashboard'),
        );
      case TransactionAuthStep.failed:
        return _FailedStep(
          message: state.errorMessage ?? 'This transfer could not be authorized.',
          onCancel: () => context.pop(),
        );
    }
  }
}

class _FingerprintStep extends StatelessWidget {
  const _FingerprintStep({required this.isAuthenticating, required this.attemptsRemaining, required this.onRetry});

  final bool isAuthenticating;
  final int attemptsRemaining;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 88,
          height: 88,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.primaryRed.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: isAuthenticating
              ? const LoadingIndicator(size: 32)
              : const Icon(Icons.fingerprint, color: AppColors.primaryRed, size: 44),
        ),
        const SizedBox(height: 24),
        Text(
          isAuthenticating ? 'Waiting for fingerprint…' : 'Confirm with your fingerprint',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'This confirms it\'s really you before we send a one-time code to your phone.',
          style: const TextStyle(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        if (!isAuthenticating) PrimaryButton(label: 'Try Again', onPressed: onRetry),
        const SizedBox(height: 10),
        Text('$attemptsRemaining attempt${attemptsRemaining == 1 ? '' : 's'} remaining', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
      ],
    );
  }
}

class _OtpStep extends StatelessWidget {
  const _OtpStep({
    required this.controller,
    required this.maskedPhoneNumber,
    required this.isVerifying,
    required this.secondsRemaining,
    required this.onCompleted,
    required this.onResend,
  });

  final TextEditingController controller;
  final String maskedPhoneNumber;
  final bool isVerifying;
  final int secondsRemaining;
  final ValueChanged<String> onCompleted;
  final VoidCallback? onResend;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.sms_outlined, color: AppColors.primaryRed, size: 40),
        const SizedBox(height: 20),
        Text('Enter the 6-digit code', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          maskedPhoneNumber.isEmpty ? 'OTP sent to your registered number' : 'OTP sent to\n$maskedPhoneNumber',
          style: const TextStyle(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        if (isVerifying)
          const LoadingIndicator(size: 32)
        else
          CodeInputField(controller: controller, onCompleted: onCompleted),
        const SizedBox(height: 20),
        if (onResend != null)
          TextButton(onPressed: onResend, child: const Text('Resend OTP'))
        else
          Text('Resend OTP in ${secondsRemaining}s', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
      ],
    );
  }
}

class _SuccessStep extends StatelessWidget {
  const _SuccessStep({required this.amount, required this.walletName, required this.onDone});

  final String amount;
  final String walletName;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 450),
          curve: Curves.elasticOut,
          builder: (context, value, child) => Transform.scale(scale: value, child: child),
          child: Container(
            width: 88,
            height: 88,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: AppColors.success, size: 48),
          ),
        ),
        const SizedBox(height: 24),
        Text('Transfer Successful', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          '${CurrencyFormatter.format(amount)} sent to $walletName.',
          style: const TextStyle(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        PrimaryButton(label: 'Done', onPressed: onDone),
      ],
    );
  }
}

class _FailedStep extends StatelessWidget {
  const _FailedStep({required this.message, required this.onCancel});

  final String message;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 88,
          height: 88,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close_rounded, color: AppColors.danger, size: 44),
        ),
        const SizedBox(height: 24),
        Text('Transfer Cancelled', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(message, style: const TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
        const SizedBox(height: 28),
        PrimaryButton(label: 'Back to Transfer', onPressed: onCancel),
      ],
    );
  }
}
