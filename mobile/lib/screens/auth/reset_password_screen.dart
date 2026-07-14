import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/auth_scaffold.dart';
import '../../widgets/code_input_field.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/primary_button.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _otpController = TextEditingController();
  final _passwordFormKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();

  String? _otp;
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_otp == null || !_passwordFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).resetPassword(
            email: widget.email,
            otp: _otp!,
            newPassword: _newPasswordController.text,
          );
      if (mounted) context.go('/login');
    } on AppException catch (e) {
      if (mounted) {
        showAppSnackBar(context, e.message);
        setState(() {
          _otp = null;
          _otpController.clear();
        });
      }
    } catch (_) {
      if (mounted) showAppSnackBar(context, 'Could not reach the server. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Enter verification code',
      subtitle: 'We sent a 6-digit code to ${widget.email}.',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: FadeSlideIn(
          child: Form(
            key: _passwordFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CodeInputField(
                  controller: _otpController,
                  onCompleted: (value) => setState(() => _otp = value),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 8) return 'At least 8 characters.';
                    if (!RegExp(r'[A-Za-z]').hasMatch(value) || !RegExp(r'[0-9]').hasMatch(value)) {
                      return 'Include at least one letter and one number.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                PrimaryButton(label: 'Reset password', onPressed: _submit, isLoading: _isLoading),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
