import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/currency_formatter.dart';
import '../../models/purpose_wallet_model.dart';
import '../../providers/wallet_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/wallet_icons.dart';
import 'transaction_authentication_screen.dart';

/// Main Wallet -> Purpose Wallet transfer. If [preselectedWallet] is passed
/// (from the Wallet Details screen), the target is fixed; otherwise the user
/// picks from their existing Purpose Wallets.
class TransferMoneyScreen extends ConsumerStatefulWidget {
  const TransferMoneyScreen({super.key, this.preselectedWallet});

  final PurposeWalletModel? preselectedWallet;

  @override
  ConsumerState<TransferMoneyScreen> createState() => _TransferMoneyScreenState();
}

class _TransferMoneyScreenState extends ConsumerState<TransferMoneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  // Keyed by wallet id (a plain String has proper value equality) rather than
  // the PurposeWalletModel instance itself — every dashboard refresh parses a
  // brand new list of model objects, and DropdownButtonFormField compares its
  // value by `==`, which is identity-based for a plain Dart class. Holding
  // onto a stale instance made the dropdown crash the moment the list
  // refreshed underneath it (confirmed live on-device).
  String? _selectedWalletId;

  @override
  void initState() {
    super.initState();
    _selectedWalletId = widget.preselectedWallet?.id;
    if (ref.read(walletProvider).dashboard == null) {
      ref.read(walletProvider.notifier).loadDashboard();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  // This screen only collects the target wallet and amount — the transfer
  // itself is never called from here. Continuing hands off to the mandatory
  // Transaction Authentication flow (fingerprint, then OTP), which is the
  // only place a transfer can actually be executed.
  void _continue() {
    if (!_formKey.currentState!.validate() || _selectedWalletId == null) return;

    final walletId = _selectedWalletId!;
    PurposeWalletModel? wallet = widget.preselectedWallet;
    if (wallet == null) {
      for (final w in ref.read(walletProvider).purposeWallets) {
        if (w.id == walletId) {
          wallet = w;
          break;
        }
      }
    }
    if (wallet == null) return;

    context.push(
      '/wallet/transaction-auth',
      extra: TransactionAuthRouteArgs(wallet: wallet, amount: _amountController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletProvider).purposeWallets;
    final mainBalance = ref.watch(walletProvider).dashboard?.mainWalletBalance;
    final preselected = widget.preselectedWallet;

    return Scaffold(
      appBar: AppBar(title: const Text('Transfer Money')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: FadeSlideIn(
          child: Form(
            key: _formKey,
            child: PremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('From', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(
                    mainBalance != null ? 'Main Wallet · ${CurrencyFormatter.format(mainBalance)} available' : 'Main Wallet',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  const Text('To', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  if (preselected != null)
                    Row(
                      children: [
                        Icon(WalletIcons.resolve(preselected.icon), color: WalletColors.fromHex(preselected.color)),
                        const SizedBox(width: 10),
                        Text(preselected.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: _selectedWalletId,
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.account_balance_wallet_outlined)),
                      items: wallets.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name))).toList(),
                      onChanged: (value) => setState(() => _selectedWalletId = value),
                      validator: (value) => value == null ? 'Select a wallet.' : null,
                      hint: const Text('Select a purpose wallet'),
                    ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Amount', prefixIcon: Icon(Icons.currency_rupee), prefixText: '₹ '),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Amount is required.';
                      if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(value.trim())) {
                        return 'Enter a valid amount (up to 2 decimals).';
                      }
                      if (double.parse(value.trim()) <= 0) return 'Amount must be greater than zero.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(label: 'Continue', onPressed: _continue),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
