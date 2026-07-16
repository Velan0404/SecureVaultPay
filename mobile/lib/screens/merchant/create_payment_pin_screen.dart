import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/currency_formatter.dart';
import '../../models/merchant_model.dart';
import '../../models/purpose_wallet_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/centered_auth_scaffold.dart';
import '../../widgets/code_input_field.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/premium_card.dart';
import 'confirm_payment_pin_screen.dart';

/// Carries a Personal Payment's receiver + optional note through the
/// Payment PIN step — the User -> User counterpart to [MerchantModel] in
/// [PaymentPinFlowArgs]. Defined here (rather than in the personal_payment
/// screens folder) so this file — and confirm/enter — need only one import
/// to know about every payment kind they can be reached from.
class PersonalPaymentTarget {
  const PersonalPaymentTarget({required this.receiverId, required this.receiverName, this.note});

  final String receiverId;
  final String receiverName;
  final String? note;
}

/// Carries a Scheduled Payment draft (create) or edit through the Payment
/// PIN step (Phase 7 — Scheduled Payments) — Payment PIN is required only
/// at creation/editing, never at automatic execution time. [isEdit] selects
/// which repository call the PIN screens make; `paymentType`/destination
/// fields are only meaningful (and only sent) on create, since editing a
/// schedule can never change who it pays.
class ScheduledPaymentAuthTarget {
  const ScheduledPaymentAuthTarget.create({
    required this.title,
    required this.paymentType,
    required this.frequency,
    this.customIntervalDays,
    this.merchantId,
    this.receiverUserId,
    required this.destinationName,
    this.note,
    required this.startDate,
    this.endDate,
  }) : existingScheduleId = null;

  const ScheduledPaymentAuthTarget.edit({
    required this.existingScheduleId,
    required this.title,
    required this.frequency,
    this.customIntervalDays,
    required this.destinationName,
    this.note,
    this.endDate,
  })  : paymentType = null,
        merchantId = null,
        receiverUserId = null,
        startDate = null;

  final String? existingScheduleId;
  final String title;
  final String? paymentType;
  final String frequency;
  final int? customIntervalDays;
  final String? merchantId;
  final String? receiverUserId;
  final String destinationName;
  final String? note;
  final DateTime? startDate;
  final DateTime? endDate;

  bool get isEdit => existingScheduleId != null;
}

/// Router `extra` payload for `/payment-pin/create` and `/payment-pin/enter`
/// — carries the payment details forward through the Payment PIN step so
/// the actual payment can be executed once the PIN is ready. Exactly one of
/// [merchant] / [personalTarget] / [scheduleTarget] is set, depending on
/// which flow this is for.
class PaymentPinFlowArgs {
  const PaymentPinFlowArgs({
    this.merchant,
    required this.wallet,
    required this.amount,
    this.qrId,
    this.personalTarget,
    this.scheduleTarget,
  }) : assert(
         merchant != null || personalTarget != null || scheduleTarget != null,
         'Either merchant, personalTarget, or scheduleTarget must be set.',
       );

  final MerchantModel? merchant;
  final PurposeWalletModel wallet;
  final String amount;

  /// Null for the tap-to-pay Merchant List flow (original behavior,
  /// unchanged). Set when this payment was authorized via a scanned Merchant
  /// QR — the eventual pay call goes through POST /qr/:qrId/pay instead of
  /// POST /merchant/:id/pay.
  final String? qrId;

  /// Set only for a Personal QR (User -> User) payment — mutually exclusive
  /// with [merchant]. The eventual pay call goes through
  /// POST /personal-payment/:receiverId/pay instead.
  final PersonalPaymentTarget? personalTarget;

  /// Set only for creating/editing a Scheduled Payment — mutually exclusive
  /// with [merchant]/[personalTarget]. Unlike those two, a successful PIN
  /// step here does not complete a payment; it saves a recurring
  /// instruction, so the flow navigates back to the Scheduled Payments list
  /// instead of a payment-result screen.
  final ScheduledPaymentAuthTarget? scheduleTarget;

  /// Display name for "Authorize this payment to X" — whichever of
  /// merchant/personalTarget/scheduleTarget this flow is for.
  String get payeeName => scheduleTarget?.destinationName ?? personalTarget?.receiverName ?? merchant!.merchantName;
}

/// First payment only — creating a brand new Payment PIN. Matches the App
/// PIN's Create screen design; unlike the App PIN, this is a separate
/// two-screen flow (Create, then Confirm) rather than one screen managing
/// both steps, and it authorizes money movement rather than unlocking the
/// app.
class CreatePaymentPinScreen extends StatefulWidget {
  const CreatePaymentPinScreen({super.key, required this.args});

  final PaymentPinFlowArgs args;

  @override
  State<CreatePaymentPinScreen> createState() => _CreatePaymentPinScreenState();
}

class _CreatePaymentPinScreenState extends State<CreatePaymentPinScreen> {
  final _pinController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _onCompleted(String pin) {
    context.push(
      '/payment-pin/confirm',
      extra: ConfirmPaymentPinArgs(
        merchant: widget.args.merchant,
        wallet: widget.args.wallet,
        amount: widget.args.amount,
        firstPin: pin,
        qrId: widget.args.qrId,
        personalTarget: widget.args.personalTarget,
        scheduleTarget: widget.args.scheduleTarget,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CenteredAuthScaffold(
      child: FadeSlideIn(
        child: PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.secondaryRed.withValues(alpha: 0.08), shape: BoxShape.circle),
                child: const Icon(Icons.password_outlined, color: AppColors.secondaryRed, size: 28),
              ),
              const SizedBox(height: 20),
              Text('Create your Payment PIN', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Choose a 6-digit PIN to authorize payments of ${CurrencyFormatter.format(widget.args.amount)} to ${widget.args.payeeName}. '
                'This is separate from your App PIN.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              CodeInputField(controller: _pinController, obscureText: true, onCompleted: _onCompleted),
            ],
          ),
        ),
      ),
    );
  }
}
