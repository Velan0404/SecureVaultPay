import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/primary_button.dart';

/// Shown by [QrScannerScreen] in place of the live camera preview when
/// mobile_scanner reports the camera permission was denied — no separate
/// permission package is used (matches this project's precedent of relying
/// on the plugin's own capability check, e.g. EnableBiometricScreen).
class CameraPermissionView extends StatelessWidget {
  const CameraPermissionView({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_outlined, size: 32, color: AppColors.primaryRed),
              ),
              const SizedBox(height: 20),
              Text('Camera access needed', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'SecureVault Pay needs camera access to scan a merchant QR code. '
                'Enable it for this app in your device Settings, then try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(width: 180, child: PrimaryButton(label: 'Try Again', onPressed: onRetry)),
            ],
          ),
        ),
      ),
    );
  }
}
