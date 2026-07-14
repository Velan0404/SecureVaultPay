import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Draws the SecureVault Pay mark — a minimal shield with a wallet/card glyph.
/// Shared by the splash screen and the app-icon generator so both stay
/// visually identical. Coordinates are fractions of [size], so it scales
/// cleanly to any resolution.
class BrandMarkPainter extends CustomPainter {
  const BrandMarkPainter({this.shieldColor});

  final Color? shieldColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final shieldPath = Path()
      ..moveTo(w * 0.5, h * 0.06)
      ..lineTo(w * 0.84, h * 0.18)
      ..lineTo(w * 0.84, h * 0.5)
      ..cubicTo(w * 0.84, h * 0.74, w * 0.70, h * 0.90, w * 0.5, h * 0.96)
      ..cubicTo(w * 0.30, h * 0.90, w * 0.16, h * 0.74, w * 0.16, h * 0.5)
      ..lineTo(w * 0.16, h * 0.18)
      ..close();

    final shieldPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: shieldColor != null
            ? [shieldColor!, shieldColor!]
            : const [AppColors.secondaryRed, AppColors.accentCrimson],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(shieldPath, shieldPaint);

    final walletRect = Rect.fromLTWH(w * 0.30, h * 0.40, w * 0.40, h * 0.26);
    final walletRRect = RRect.fromRectAndRadius(walletRect, Radius.circular(w * 0.04));
    final walletPaint = Paint()..color = Colors.white;
    canvas.drawRRect(walletRRect, walletPaint);

    final stripeRect = Rect.fromLTWH(w * 0.30, h * 0.46, w * 0.40, h * 0.045);
    canvas.drawRect(stripeRect, Paint()..color = (shieldColor ?? AppColors.secondaryRed));

    final claspCenter = Offset(w * 0.62, h * 0.53);
    canvas.drawCircle(claspCenter, w * 0.035, Paint()..color = (shieldColor ?? AppColors.secondaryRed));
  }

  @override
  bool shouldRepaint(covariant BrandMarkPainter oldDelegate) => oldDelegate.shieldColor != shieldColor;
}

/// Convenience widget wrapping [BrandMarkPainter] at a given square [size].
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, required this.size, this.shieldColor});

  final double size;
  final Color? shieldColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: BrandMarkPainter(shieldColor: shieldColor)),
    );
  }
}
