import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Shared 6-digit numeric code entry field, used for both the App PIN and
/// the forgot-password OTP — same shape, different meaning. Renders as
/// individual boxed digits with a hidden field driving the actual input.
class CodeInputField extends StatefulWidget {
  const CodeInputField({
    super.key,
    required this.controller,
    required this.onCompleted,
    this.obscureText = false,
  });

  static const int length = 6;

  final TextEditingController controller;
  final ValueChanged<String> onCompleted;
  final bool obscureText;

  @override
  State<CodeInputField> createState() => _CodeInputFieldState();
}

class _CodeInputFieldState extends State<CodeInputField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  void _onChanged() {
    setState(() {});
    if (widget.controller.text.length == CodeInputField.length) {
      widget.onCompleted(widget.controller.text);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.text;

    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(CodeInputField.length, (index) {
              final filled = index < value.length;
              final isCurrent = index == value.length;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 44,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isCurrent
                        ? AppColors.secondaryRed
                        : (filled ? AppColors.textMuted : AppColors.divider),
                    width: isCurrent ? 1.6 : 1,
                  ),
                ),
                child: Text(
                  filled ? (widget.obscureText ? '•' : value[index]) : '',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              );
            }),
          ),
          Opacity(
            opacity: 0,
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              maxLength: CodeInputField.length,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(counterText: '', border: InputBorder.none),
            ),
          ),
        ],
      ),
    );
  }
}
