import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/centered_auth_scaffold.dart';
import '../../widgets/code_input_field.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/premium_card.dart';

class PinUnlockScreen extends ConsumerStatefulWidget {
  const PinUnlockScreen({super.key});

  @override
  ConsumerState<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends ConsumerState<PinUnlockScreen> {
  final _pinController = TextEditingController();

  bool _isCheckingBiometrics = true;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometricUnlock());
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _tryBiometricUnlock() async {
    final unlocked = await ref.read(authProvider.notifier).unlockWithBiometrics();
    if (mounted && !unlocked) {
      setState(() => _isCheckingBiometrics = false);
    }
  }

  Future<void> _onPinCompleted(String pin) async {
    setState(() => _isVerifying = true);

    final result = await ref.read(authProvider.notifier).unlockWithPin(pin);

    if (!mounted) return;

    switch (result) {
      case PinUnlockResult.success:
        break;
      case PinUnlockResult.incorrect:
        showAppSnackBar(context, 'Incorrect PIN. Please try again.');
        setState(() {
          _isVerifying = false;
          _pinController.clear();
        });
      case PinUnlockResult.lockedOut:
        showAppSnackBar(context, 'Too many incorrect attempts. Please log in again.');
        setState(() => _isVerifying = false);
      case PinUnlockResult.networkError:
        showAppSnackBar(context, 'Could not reach the server. Check your connection and try again.');
        setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CenteredAuthScaffold(
      child: FadeSlideIn(
        child: PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline, color: AppColors.primaryRed, size: 28),
              ),
              const SizedBox(height: 20),
              Text('Enter your PIN', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('Unlock SecureVault Pay to continue.', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 32),
              if (_isCheckingBiometrics || _isVerifying)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: LoadingIndicator()),
                )
              else
                CodeInputField(controller: _pinController, obscureText: true, onCompleted: _onPinCompleted),
              if (!_isCheckingBiometrics && !_isVerifying) ...[
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () => ref.read(authProvider.notifier).logout(),
                    child: const Text('Log out instead'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
