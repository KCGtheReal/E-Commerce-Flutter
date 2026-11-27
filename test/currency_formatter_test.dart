import 'package:flutter_test/flutter_test.dart';
import 'package:reset_store/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter', () {
    test('formats base KHR *_cents integers accurately in KHR and USD', () {
      expect(
        CurrencyFormatter.formatCents(155800, currency: 'KHR', exchangeRate: 4100),
        '155,800 ៛',
      );
      expect(
        CurrencyFormatter.formatCents(155800, currency: 'USD', exchangeRate: 4100),
        '\$38.00',
      );
      expect(
        CurrencyFormatter.formatCents(200000, currency: 'KHR', exchangeRate: 4100),
        '200,000 ៛',
      );
      expect(
        CurrencyFormatter.formatCents(200000, currency: 'USD', exchangeRate: 4100),
        '\$48.78',
      );
    });

    test('computes rounded USD conversion and dual equivalent labels', () {
      expect(CurrencyFormatter.toUsd(12000, exchangeRate: 4100), 2.93);
      expect(
        CurrencyFormatter.formatEquivalent(
          164000,
          primaryCurrency: 'KHR',
          exchangeRate: 4100,
        ),
        '≈ \$40.00 USD',
      );
      expect(
        CurrencyFormatter.formatEquivalent(
          164000,
          primaryCurrency: 'USD',
          exchangeRate: 4100,
        ),
        '≈ 164,000 ៛ KHR',
      );
    });
  });
}
