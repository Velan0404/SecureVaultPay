import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/currency_formatter.dart';
import '../../models/purpose_wallet_model.dart';
import '../../models/scheduled_payment_model.dart';
import '../../providers/payment_pin_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/scheduled_payment_tile.dart';
import '../merchant/create_payment_pin_screen.dart';

const _frequencies = ['DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY', 'CUSTOM'];

/// Only amount/frequency/endDate/title/note/purposeWalletId are editable —
/// the destination (who gets paid) and category are fixed at creation and
/// shown read-only here. Changing who gets paid means cancelling this
/// schedule and creating a new one instead.
class EditScheduleScreen extends ConsumerStatefulWidget {
  const EditScheduleScreen({super.key, required this.schedule});

  final ScheduledPaymentModel schedule;

  @override
  ConsumerState<EditScheduleScreen> createState() => _EditScheduleScreenState();
}

class _EditScheduleScreenState extends ConsumerState<EditScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _customIntervalController;
  late final TextEditingController _noteController;

  late String _frequency;
  DateTime? _endDate;
  PurposeWalletModel? _wallet;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.schedule.title);
    _amountController = TextEditingController(text: widget.schedule.amount);
    _customIntervalController = TextEditingController(text: widget.schedule.customIntervalDays?.toString() ?? '');
    _noteController = TextEditingController(text: widget.schedule.note ?? '');
    _frequency = widget.schedule.frequency;
    _endDate = widget.schedule.endDate;
    for (final w in ref.read(walletProvider).purposeWallets) {
      if (w.id == widget.schedule.purposeWalletId) {
        _wallet = w;
        break;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _customIntervalController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    int? customIntervalDays;
    if (_frequency == 'CUSTOM') {
      customIntervalDays = int.tryParse(_customIntervalController.text.trim());
      if (customIntervalDays == null || customIntervalDays < 1) {
        showAppSnackBar(context, 'Enter how many days between payments.');
        return;
      }
    }

    setState(() => _isChecking = true);
    final note = _noteController.text.trim();
    final target = ScheduledPaymentAuthTarget.edit(
      existingScheduleId: widget.schedule.id,
      title: _titleController.text.trim(),
      frequency: _frequency,
      customIntervalDays: customIntervalDays,
      destinationName: widget.schedule.destinationName,
      note: note.isEmpty ? null : note,
      endDate: _endDate,
    );
    final wallet = _wallet;
    final args = PaymentPinFlowArgs(
      wallet: wallet ?? _fallbackWallet(),
      amount: _amountController.text.trim(),
      scheduleTarget: target,
    );

    try {
      final hasPaymentPin = await ref.read(paymentPinRepositoryProvider).hasPaymentPin();
      if (!mounted) return;
      context.push(hasPaymentPin ? '/payment-pin/enter' : '/payment-pin/create', extra: args);
    } catch (_) {
      if (mounted) showAppSnackBar(context, 'Could not reach the server. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  // PaymentPinFlowArgs.wallet is only read for its `.id` on an edit (the
  // service call only needs purposeWalletId) — falls back to a placeholder
  // built from the schedule's existing wallet id if the dropdown wasn't
  // touched, so switching wallets is optional on edit.
  PurposeWalletModel _fallbackWallet() {
    final existing = ref.read(walletProvider).purposeWallets.where((w) => w.id == widget.schedule.purposeWalletId);
    if (existing.isNotEmpty) return existing.first;
    final now = widget.schedule.updatedAt;
    return PurposeWalletModel(
      id: widget.schedule.purposeWalletId,
      name: '',
      icon: 'category',
      color: '#E53935',
      balance: '0',
      status: PurposeWalletStatus.active,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletProvider).purposeWallets;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Scheduled Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: FadeSlideIn(
          child: Form(
            key: _formKey,
            child: PremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Icon(iconForPaymentType(widget.schedule.paymentType), color: AppColors.primaryRed),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${labelForPaymentType(widget.schedule.paymentType)} · ${widget.schedule.destinationName}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Title is required.' : null,
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _frequency,
                    decoration: const InputDecoration(labelText: 'Frequency'),
                    items: _frequencies
                        .map((f) => DropdownMenuItem(
                              value: f,
                              child: Text(
                                switch (f) {
                                  'DAILY' => 'Daily',
                                  'WEEKLY' => 'Weekly',
                                  'MONTHLY' => 'Monthly',
                                  'YEARLY' => 'Yearly',
                                  _ => 'Custom (every N days)',
                                },
                              ),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _frequency = value ?? _frequency),
                  ),
                  if (_frequency == 'CUSTOM') ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _customIntervalController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Repeat every (days)'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  DropdownButtonFormField<PurposeWalletModel>(
                    initialValue: _wallet,
                    decoration: const InputDecoration(labelText: 'Purpose Wallet'),
                    items: wallets
                        .map((w) => DropdownMenuItem(
                              value: w,
                              child: Text('${w.name} · ${CurrencyFormatter.format(w.balance)}'),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _wallet = value),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _pickEndDate,
                          child: Text(
                            _endDate == null
                                ? 'No end date'
                                : 'Ends ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                          ),
                        ),
                      ),
                      if (_endDate != null)
                        TextButton(onPressed: () => setState(() => _endDate = null), child: const Text('Clear')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _noteController,
                    maxLength: 140,
                    decoration: const InputDecoration(labelText: 'Note (optional)', prefixIcon: Icon(Icons.edit_note_outlined)),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(label: 'Save Changes', onPressed: _continue, isLoading: _isChecking),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
