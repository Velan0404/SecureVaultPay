import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/payment_pin_repository.dart';
import '../services/payment_pin_service.dart';
import 'auth_provider.dart';

final paymentPinServiceProvider = Provider<PaymentPinService>(
  (ref) => PaymentPinService(ref.read(apiClientProvider)),
);

final paymentPinRepositoryProvider = Provider<PaymentPinRepository>(
  (ref) => PaymentPinRepository(ref.read(paymentPinServiceProvider)),
);
