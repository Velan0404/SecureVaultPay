import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_theme.dart';
import 'loading_indicator.dart';

class PrimaryButton extends StatefulWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.isLoading = false});

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  bool get _disabled => widget.isLoading || widget.onPressed == null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _disabled ? null : (_) => setState(() => _pressed = true),
      onTapCancel: _disabled ? null : () => setState(() => _pressed = false),
      onTapUp: _disabled ? null : (_) => setState(() => _pressed = false),
      onTap: _disabled ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _disabled && !widget.isLoading ? 0.5 : 1,
          duration: const Duration(milliseconds: 200),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.buttonGradient,
              borderRadius: AppRadius.mdRadius,
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondaryRed.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: widget.isLoading
                ? const LoadingIndicator(size: 22, color: Colors.white)
                : Text(
                    widget.label,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ),
    );
  }
}
