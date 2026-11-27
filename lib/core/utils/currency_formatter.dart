import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static const int defaultExchangeRate = 4100;
  static const int expressShippingFeeKhr = 12000;

  static final NumberFormat _khrFormat = NumberFormat('#,##0', 'en_US');
  static final NumberFormat _usdFormat = NumberFormat('#,##0.00', 'en_US');

  /// Converts base KHR integer (`*_cents` in RESET Store DB) to USD rounded to 2 decimals.
  static double toUsd(
    int baseKhrCents, {
    int exchangeRate = defaultExchangeRate,
  }) {
    final safeRate = exchangeRate <= 0 ? defaultExchangeRate : exchangeRate;
    final raw = baseKhrCents / safeRate;
    return (raw * 100).round() / 100.0;
  }

  static String formatKhr(int baseKhrCents) {
    return '${_khrFormat.format(baseKhrCents)} ៛';
  }

  static String formatUsd(num usdAmount) {
    return '\$${_usdFormat.format(usdAmount)}';
  }

  static String formatCents(
    int baseKhrCents, {
    required String currency,
    int exchangeRate = defaultExchangeRate,
  }) {
    if (currency.toUpperCase() == 'USD') {
      return formatUsd(toUsd(baseKhrCents, exchangeRate: exchangeRate));
    }
    return formatKhr(baseKhrCents);
  }

  static String formatEquivalent(
    int baseKhrCents, {
    required String primaryCurrency,
    int exchangeRate = defaultExchangeRate,
  }) {
    if (primaryCurrency.toUpperCase() == 'USD') {
      return '≈ ${formatKhr(baseKhrCents)} KHR';
    }
    return '≈ ${formatUsd(toUsd(baseKhrCents, exchangeRate: exchangeRate))} USD';
  }
}
