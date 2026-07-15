import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_theme.dart';

/// A shimmering placeholder box for skeleton loading states — a lighter band
/// sweeps left-to-right across a dark surface, on a continuous loop.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({super.key, this.width, this.height = 16, this.borderRadius});

  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? AppRadius.smRadius,
            gradient: LinearGradient(
              begin: Alignment(-1 + _controller.value * 3, 0),
              end: Alignment(_controller.value * 3, 0),
              colors: const [AppColors.surface, AppColors.surfaceElevated, AppColors.surface],
            ),
          ),
        );
      },
    );
  }
}
