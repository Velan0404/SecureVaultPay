import 'package:intl/intl.dart';

/// Formats decimal-string money values for display only — the underlying
/// value passed around the app (models, API calls) always stays a string, so
/// no floating-point rounding ever touches a stored or transmitted amount.
class CurrencyFormatter {
  CurrencyFormatter._();

  static final _format = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  static String format(String decimalAmount) {
    final value = double.tryParse(decimalAmount) ?? 0;
    return _format.format(value);
  }
}
