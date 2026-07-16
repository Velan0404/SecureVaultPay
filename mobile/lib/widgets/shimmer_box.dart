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

/// A shimmering stand-in for one [StatTile]-shaped card — same footprint so
/// a grid doesn't reflow once real figures arrive (Analytics' loading state).
class ShimmerStatTile extends StatelessWidget {
  const ShimmerStatTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.surfaceElevated.withValues(alpha: 0.5), borderRadius: AppRadius.mdRadius),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ShimmerBox(width: 60, height: 10),
          SizedBox(height: 8),
          ShimmerBox(width: 90, height: 16),
        ],
      ),
    );
  }
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
