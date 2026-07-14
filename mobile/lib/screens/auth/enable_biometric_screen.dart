import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/centered_auth_scaffold.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/primary_button.dart';

class EnableBiometricScreen extends ConsumerStatefulWidget {
  const EnableBiometricScreen({super.key});

  @override
  ConsumerState<EnableBiometricScreen> createState() => _EnableBiometricScreenState();
}

class _EnableBiometricScreenState extends ConsumerState<EnableBiometricScreen> {
  bool _isChecking = true;
  bool _isAvailable = false;
  bool _isProcessing = false;
  String _label = 'Biometric login';
  IconData _icon = Icons.fingerprint;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final notifier = ref.read(authProvider.notifier);
    final available = await notifier.canUseBiometrics();

    String label = 'Biometric login';
    IconData icon = Icons.fingerprint;
    if (available) {
      final types = await ref.read(biometricServiceProvider).availableBiometrics();
      if (types.contains(BiometricType.face)) {
        label = 'Face ID';
        icon = Icons.face_retouching_natural;
      } else if (types.contains(BiometricType.fingerprint)) {
        label = 'Fingerprint';
        icon = Icons.fingerprint;
      }
    }

    if (mounted) {
      setState(() {
        _isAvailable = available;
        _label = label;
        _icon = icon;
        _isChecking = false;
      });
    }
  }

  Future<void> _enable() async {
    setState(() => _isProcessing = true);
    final biometricService = ref.read(biometricServiceProvider);
    final success = await biometricService.authenticate(reason: 'Confirm to enable $_label');

    if (success) {
      await ref.read(authProvider.notifier).setBiometricEnabled(true);
    }

    if (mounted) {
      ref.read(authProvider.notifier).completeOnboarding();
    }
  }

  void _skip() {
    ref.read(authProvider.notifier).completeOnboarding();
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
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: const BoxDecoration(gradient: AppColors.buttonGradient, shape: BoxShape.circle),
                child: Icon(_icon, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 20),
              Text('Enable $_label', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                _isAvailable
                    ? 'Use $_label to unlock SecureVault Pay instead of your PIN.'
                    : 'No biometric hardware was detected on this device — you can continue with your PIN.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              if (_isChecking)
                const Center(child: CircularProgressIndicator())
              else ...[
                if (_isAvailable)
                  PrimaryButton(label: 'Enable $_label', onPressed: _enable, isLoading: _isProcessing),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _isProcessing ? null : _skip,
                    child: const Text('Skip for now'),
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
