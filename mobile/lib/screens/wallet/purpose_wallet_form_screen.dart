import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../models/purpose_wallet_model.dart';
import '../../providers/wallet_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/wallet_icons.dart';

/// Shared Create/Edit form — [existingWallet] null means Create, non-null
/// means Edit. One screen instead of two near-identical ones, per the
/// project's "no duplicated code" coding standard.
class PurposeWalletFormScreen extends ConsumerStatefulWidget {
  const PurposeWalletFormScreen({super.key, this.existingWallet});

  final PurposeWalletModel? existingWallet;

  bool get isEditing => existingWallet != null;

  @override
  ConsumerState<PurposeWalletFormScreen> createState() => _PurposeWalletFormScreenState();
}

class _PurposeWalletFormScreenState extends ConsumerState<PurposeWalletFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _purposeController;
  late final TextEditingController _spendingLimitController;
  late String _selectedIcon;
  late String _selectedColor;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingWallet;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _purposeController = TextEditingController(text: existing?.purpose ?? '');
    _spendingLimitController = TextEditingController(text: existing?.spendingLimit ?? '');
    _selectedIcon = existing?.icon ?? WalletIcons.byName.keys.first;
    _selectedColor = existing?.color ?? WalletColors.palette.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _purposeController.dispose();
    _spendingLimitController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final purpose = _purposeController.text.trim();
    final spendingLimit = _spendingLimitController.text.trim();

    try {
      if (widget.isEditing) {
        // An empty field here means "leave unchanged", matching the create
        // form's null-means-omit semantics — the update endpoint has no way
        // to distinguish "clear this value" from "don't touch it" yet.
        await ref.read(walletProvider.notifier).updatePurposeWallet(
              widget.existingWallet!.id,
              name: name,
              icon: _selectedIcon,
              color: _selectedColor,
              purpose: purpose.isEmpty ? null : purpose,
              spendingLimit: spendingLimit.isEmpty ? null : spendingLimit,
            );
      } else {
        await ref.read(walletProvider.notifier).createPurposeWallet(
              name: name,
              icon: _selectedIcon,
              color: _selectedColor,
              purpose: purpose.isEmpty ? null : purpose,
              spendingLimit: spendingLimit.isEmpty ? null : spendingLimit,
            );
      }
      if (mounted) context.pop();
    } on AppException catch (e) {
      if (mounted) showAppSnackBar(context, e.message);
    } catch (_) {
      if (mounted) showAppSnackBar(context, 'Could not reach the server. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit Wallet' : 'Create Wallet')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: FadeSlideIn(
          child: Form(
            key: _formKey,
            child: PremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Wallet name', prefixIcon: Icon(Icons.label_outline)),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Name is required.' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _purposeController,
                    decoration: const InputDecoration(labelText: 'Purpose (optional)', prefixIcon: Icon(Icons.notes_outlined)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _spendingLimitController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Spending limit (optional)',
                      prefixIcon: Icon(Icons.speed_outlined),
                      prefixText: '₹ ',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(value.trim())) {
                        return 'Enter a valid amount (up to 2 decimals).';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text('Icon', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: WalletIcons.byName.entries.map((entry) {
                      final selected = entry.key == _selectedIcon;
                      final color = WalletColors.fromHex(_selectedColor);
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIcon = entry.key),
                        child: Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected ? color.withValues(alpha: 0.18) : AppColors.surfaceElevated,
                            shape: BoxShape.circle,
                            border: selected ? Border.all(color: color, width: 2) : null,
                          ),
                          child: Icon(entry.value, color: selected ? color : AppColors.textSecondary),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text('Color', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: WalletColors.palette.map((hex) {
                      final selected = hex == _selectedColor;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = hex),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: WalletColors.fromHex(hex),
                            shape: BoxShape.circle,
                            border: selected ? Border.all(color: Colors.white, width: 2) : null,
                          ),
                          child: selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: widget.isEditing ? 'Save changes' : 'Create wallet',
                    onPressed: _submit,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
