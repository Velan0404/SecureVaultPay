import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/centered_auth_scaffold.dart';
import '../../widgets/code_input_field.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/premium_card.dart';

class CreatePinScreen extends ConsumerStatefulWidget {
  const CreatePinScreen({super.key});

  @override
  ConsumerState<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends ConsumerState<CreatePinScreen> {
  final _firstPinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  String? _firstPin;
  bool _isSaving = false;

  @override
  void dispose() {
    _firstPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _onFirstPinCompleted(String pin) {
    setState(() => _firstPin = pin);
  }

  Future<void> _onConfirmPinCompleted(String pin) async {
    if (_firstPin == null) return;

    if (pin != _firstPin) {
      showAppSnackBar(context, 'PINs do not match. Try again.');
      setState(() {
        _firstPin = null;
        _firstPinController.clear();
        _confirmPinController.clear();
      });
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(authProvider.notifier).setPin(pin);
      if (mounted) context.go('/enable-biometric');
    } on AppException catch (e) {
      if (mounted) {
        showAppSnackBar(context, e.message);
        setState(() => _confirmPinController.clear());
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
                  color: AppColors.secondaryRed.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pin_outlined, color: AppColors.secondaryRed, size: 28),
              ),
              const SizedBox(height: 20),
              Text('Create your App PIN', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                _firstPin == null
                    ? 'Choose a 6-digit PIN to quickly unlock the app.'
                    : 'Re-enter your PIN to confirm.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              if (_isSaving)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_firstPin == null)
                CodeInputField(
                  key: const ValueKey('first-pin'),
                  controller: _firstPinController,
                  obscureText: true,
                  onCompleted: _onFirstPinCompleted,
                )
              else
                CodeInputField(
                  key: const ValueKey('confirm-pin'),
                  controller: _confirmPinController,
                  obscureText: true,
                  onCompleted: _onConfirmPinCompleted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
