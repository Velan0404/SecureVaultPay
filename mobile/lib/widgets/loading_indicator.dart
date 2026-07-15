import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The app's one loading indicator — a softly pulsing ring in the brand red,
/// used everywhere a bare [CircularProgressIndicator] would otherwise appear.
/// [size] covers everything from an inline button spinner (18-22) to a
/// full-screen loading state (40+).
class LoadingIndicator extends StatefulWidget {
  const LoadingIndicator({super.key, this.size = 28, this.color});

  final double size;
  final Color? color;

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.primaryRed;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: RotationTransition(
        turns: _controller,
        child: CustomPaint(painter: _RingPainter(color: color)),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [color.withValues(alpha: 0), color],
        startAngle: 0,
        endAngle: 3.6,
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -1.6, 4.8, false, paint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.color != color;
}

/// A full-bleed centered loading state for whole-screen fetches.
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: LoadingIndicator(size: 40));
  }
}
