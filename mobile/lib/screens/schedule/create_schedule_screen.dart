import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/currency_formatter.dart';
import '../../models/merchant_model.dart';
import '../../models/personal_payment_receiver_model.dart';
import '../../models/purpose_wallet_model.dart';
import '../../providers/payment_pin_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/scheduled_payment_tile.dart';
import '../merchant/create_payment_pin_screen.dart';

const _paymentTypes = [
  'RENT',
  'ELECTRICITY',
  'WATER',
  'INTERNET',
  'MOBILE_RECHARGE',
  'SUBSCRIPTION',
  'EMI',
  'INSURANCE',
  'SAVINGS',
  'CUSTOM',
];

const _frequencies = ['DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY', 'CUSTOM'];

/// Sets up a new automated Purpose Wallet -> Merchant/User payment. Destination
/// is picked once here (a merchant from a list, or a person via the existing
/// QrScannerScreen's select-only mode) and never changes again — editing a
/// schedule later can only adjust amount/frequency/endDate/title/note.
class CreateScheduleScreen extends ConsumerStatefulWidget {
  const CreateScheduleScreen({super.key});

  @override
  ConsumerState<CreateScheduleScreen> createState() => _CreateScheduleScreenState();
}

class _CreateScheduleScreenState extends ConsumerState<CreateScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _customIntervalController = TextEditingController();
  final _noteController = TextEditingController();

  String _paymentType = 'CUSTOM';
  String _frequency = 'MONTHLY';
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  PurposeWalletModel? _wallet;
  MerchantModel? _merchant;
  PersonalPaymentReceiverModel? _receiver;
  bool _isChecking = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _customIntervalController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickMerchant() async {
    final merchant = await context.push<MerchantModel>('/schedule/create/select-merchant');
    if (merchant != null) {
      setState(() {
        _merchant = merchant;
        _receiver = null;
      });
    }
  }

  Future<void> _pickReceiver() async {
    final receiver = await context.push<PersonalPaymentReceiverModel>('/schedule/create/select-receiver');
    if (receiver != null) {
      setState(() {
        _receiver = receiver;
        _merchant = null;
      });
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    if (_wallet == null) {
      showAppSnackBar(context, 'Choose a Purpose Wallet to fund this schedule.');
      return;
    }
    if (_merchant == null && _receiver == null) {
      showAppSnackBar(context, 'Choose who gets paid — a merchant or a person.');
      return;
    }
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
    final target = ScheduledPaymentAuthTarget.create(
      title: _titleController.text.trim(),
      paymentType: _paymentType,
      frequency: _frequency,
      customIntervalDays: customIntervalDays,
      merchantId: _merchant?.id,
      receiverUserId: _receiver?.userId,
      destinationName: _merchant?.merchantName ?? _receiver!.fullName,
      note: note.isEmpty ? null : note,
      startDate: _startDate,
      endDate: _endDate,
    );
    final args = PaymentPinFlowArgs(wallet: _wallet!, amount: _amountController.text.trim(), scheduleTarget: target);

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

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletProvider).purposeWallets;

    return Scaffold(
      appBar: AppBar(title: const Text('New Scheduled Payment')),
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
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. Monthly Rent'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Title is required.' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _paymentType,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: _paymentTypes
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(iconForPaymentType(type), size: 18, color: AppColors.primaryRed),
                                  const SizedBox(width: 8),
                                  Text(labelForPaymentType(type)),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _paymentType = value ?? _paymentType),
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
                  const SizedBox(height: 20),
                  const Text('From', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<PurposeWalletModel>(
                    initialValue: _wallet,
                    decoration: const InputDecoration(hintText: 'Select a Purpose Wallet'),
                    items: wallets
                        .map((w) => DropdownMenuItem(
                              value: w,
                              child: Text('${w.name} · ${CurrencyFormatter.format(w.balance)}'),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _wallet = value),
                  ),
                  const SizedBox(height: 20),
                  const Text('Pay to', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  if (_merchant != null || _receiver != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _merchant != null ? Icons.storefront_outlined : Icons.person_outline,
                            color: AppColors.primaryRed,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _merchant?.merchantName ?? _receiver!.fullName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(() {
                              _merchant = null;
                              _receiver = null;
                            }),
                            child: const Text('Change'),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickMerchant,
                            icon: const Icon(Icons.storefront_outlined, size: 18),
                            label: const Text('Pay a Merchant'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickReceiver,
                            icon: const Icon(Icons.qr_code_scanner, size: 18),
                            label: const Text('Send to a Person'),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _pickStartDate,
                          child: Text('Starts ${_startDate.day}/${_startDate.month}/${_startDate.year}'),
                        ),
                      ),
                      const SizedBox(width: 10),
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
                    ],
                  ),
                  if (_endDate != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(onPressed: () => setState(() => _endDate = null), child: const Text('Clear end date')),
                    ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _noteController,
                    maxLength: 140,
                    decoration: const InputDecoration(labelText: 'Note (optional)', prefixIcon: Icon(Icons.edit_note_outlined)),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(label: 'Continue', onPressed: _continue, isLoading: _isChecking),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
