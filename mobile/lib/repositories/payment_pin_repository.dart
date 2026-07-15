import '../services/payment_pin_service.dart';

/// Domain-facing layer over [PaymentPinService] — trivial today (no JSON
/// shape to map beyond a bool), kept as its own file to match every other
/// module's Service -> Repository -> Provider layering.
class PaymentPinRepository {
  PaymentPinRepository(this._service);

  final PaymentPinService _service;

  Future<bool> hasPaymentPin() => _service.status();

  Future<void> createPaymentPin(String pin) => _service.create(pin);
}
