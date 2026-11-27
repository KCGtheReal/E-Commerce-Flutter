import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:reset_store/core/api/api_client.dart';
import 'package:reset_store/core/storage/app_storage.dart';
import 'package:reset_store/core/theme/app_theme.dart';
import 'package:reset_store/models/order_payment_models.dart';
import 'package:reset_store/providers/app_navigation_provider.dart';
import 'package:reset_store/providers/app_settings_provider.dart';
import 'package:reset_store/providers/auth_provider.dart';
import 'package:reset_store/providers/bootstrap_provider.dart';
import 'package:reset_store/providers/cart_provider.dart';
import 'package:reset_store/providers/wishlist_provider.dart';
import 'package:reset_store/screens/order_success/order_success_screen.dart';
import 'package:reset_store/screens/payment/khqr_payment_screen.dart';
import 'test_helpers.dart';

OrderDetailDto _sampleOrder({String status = 'pending_payment'}) {
  return OrderDetailDto.fromJson(<String, dynamic>{
    'id': 1,
    'number': 'RST-2026-00001',
    'status': status,
    'status_label': status == 'paid' ? 'Payment Confirmed' : 'Pending Payment',
    'status_color': status == 'paid' ? 'success' : 'warning',
    'currency': 'KHR',
    'exchange_rate': 4100,
    'subtotal_cents': 164000,
    'formatted_subtotal': '164,000 ៛',
    'discount_cents': 0,
    'formatted_discount': '0 ៛',
    'discount_code': null,
    'shipping_fee_cents': 0,
    'formatted_shipping': '0 ៛',
    'shipping_method': 'standard',
    'total_cents': 164000,
    'formatted_total': '164,000 ៛',
    'total_charged_currency_amount': 164000,
    'formatted_charged_total': '164,000 ៛',
    'equivalent_khr_amount': 164000,
    'formatted_equivalent_khr': '164,000 ៛',
    'equivalent_usd_amount': 40.0,
    'formatted_equivalent_usd': '\$40.00',
    'items_count': 1,
    'preview_item_names': ['Boxy Tee'],
    'can_pay_now': status != 'paid',
    'created_at': '2026-11-26T10:00:00Z',
    'formatted_created_at': 'Nov 26, 2026',
    'paid_at': status == 'paid' ? '2026-11-26T10:01:00Z' : null,
    'email': 'customer@reset.store',
    'phone': '012345678',
    'shipping_address': {
      'name': 'Dara',
      'full_name': 'Dara',
      'first_name': 'Dara',
      'last_name': '',
      'phone': '012345678',
      'province': 'Phnom Penh',
      'district': 'Daun Penh',
      'commune': 'Chaktomuk',
      'street_address': 'St 178',
    },
    'billing_address': {
      'name': 'Dara',
      'full_name': 'Dara',
      'first_name': 'Dara',
      'last_name': '',
      'phone': '012345678',
      'province': 'Phnom Penh',
      'district': 'Daun Penh',
      'commune': 'Chaktomuk',
      'street_address': 'St 178',
    },
    'tracking_number': null,
    'shipping_carrier': null,
    'customer_notes': null,
    'shipped_at': null,
    'delivered_at': null,
    'cancelled_at': null,
    'items': [],
    'latest_payment': null,
    'status_timeline': [],
  });
}

PaymentDto _samplePayment({
  required bool bakongMock,
  String status = 'pending',
  int remaining = 300,
}) {
  return PaymentDto.fromJson(<String, dynamic>{
    'id': 88,
    'order_id': 1,
    'order_number': 'RST-2026-00001',
    'provider': 'bakong_khqr',
    'md5': 'md5_sample_88',
    'qr_string': '00020101021229180014reset_store@devb52045999530311654061640005802KH5911RESET Store6010Phnom Penh6304ABCD',
    'account_id': 'reset_store@devb',
    'merchant_name': 'RESET Store',
    'amount': 164000,
    'currency': 'KHR',
    'formatted_amount': '164,000 ៛',
    'khr_amount': 164000,
    'formatted_khr_amount': '164,000 ៛',
    'usd_amount': 40.0,
    'formatted_usd_amount': '\$40.00',
    'exchange_rate': 4100,
    'status': status,
    'status_label': status,
    'expires_at': '2026-11-26T10:05:00Z',
    'time_remaining_seconds': remaining,
    'paid_at': status == 'paid' ? '2026-11-26T10:01:00Z' : null,
    'bakong_mock': bakongMock,
    'deeplink_url': 'bakong://qr?data=000201',
  });
}

Future<Widget> _wrapPaymentScreen({
  required ApiClient apiClient,
  required AppStorage storage,
  required Widget child,
}) async {
  return MultiProvider(
    providers: [
      Provider<AppStorage>.value(value: storage),
      Provider<ApiClient>.value(value: apiClient),
      ChangeNotifierProvider(create: (_) => AppNavigationProvider()),
      ChangeNotifierProvider(create: (_) => AppSettingsProvider(storage)),
      ChangeNotifierProvider(create: (_) => BootstrapProvider(apiClient)),
      ChangeNotifierProvider(create: (_) => CartProvider(apiClient)),
      ChangeNotifierProvider(create: (_) => WishlistProvider(apiClient)),
      ChangeNotifierProvider(
        create: (_) => AuthProvider(apiClient: apiClient, storage: storage),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.build(brightness: Brightness.light, locale: 'en'),
      home: child,
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('hides Simulate Pay when bakongMock is false and renders QR + dual currency',
      (tester) async {
    final storage = await AppStorage.create();
    final apiClient = ApiClient(
      storage: storage,
      httpClient: MockClient((_) async => jsonMockResponse(<String, dynamic>{})),
    );

    await tester.pumpWidget(
      await _wrapPaymentScreen(
        apiClient: apiClient,
        storage: storage,
        child: KhqrPaymentScreen(
          orderNumber: 'RST-2026-00001',
          initialOrder: _sampleOrder(),
          initialPayment: _samplePayment(bakongMock: false),
        ),
      ),
    );

    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('164,000 ៛ KHR'), findsOneWidget);
    expect(find.textContaining('\$40.00 USD'), findsOneWidget);
    expect(find.text('Simulate Instant Payment'), findsNothing);
    expect(find.text('DEV / TEST MODE (BAKONG_MOCK=true)'), findsNothing);
  });

  testWidgets('shows Simulate Pay when bakongMock is true and transitions to OrderSuccess',
      (tester) async {
    final storage = await AppStorage.create();
    var simulateCalled = false;
    final apiClient = ApiClient(
      storage: storage,
      httpClient: MockClient((request) async {
        if (request.url.path == '/api/v1/payments/88/simulate-pay') {
          simulateCalled = true;
          return jsonMockResponse(<String, dynamic>{
            'success': true,
            'message': 'Paid!',
            'order': {
              'id': 1,
              'number': 'RST-2026-00001',
              'status': 'paid',
              'status_label': 'Payment Confirmed',
              'status_color': 'success',
              'currency': 'KHR',
              'exchange_rate': 4100,
              'subtotal_cents': 164000,
              'formatted_subtotal': '164,000 ៛',
              'discount_cents': 0,
              'formatted_discount': '0 ៛',
              'discount_code': null,
              'shipping_fee_cents': 0,
              'formatted_shipping': '0 ៛',
              'shipping_method': 'standard',
              'total_cents': 164000,
              'formatted_total': '164,000 ៛',
              'total_charged_currency_amount': 164000,
              'formatted_charged_total': '164,000 ៛',
              'equivalent_khr_amount': 164000,
              'formatted_equivalent_khr': '164,000 ៛',
              'equivalent_usd_amount': 40.0,
              'formatted_equivalent_usd': '\$40.00',
              'items_count': 1,
              'preview_item_names': ['Boxy Tee'],
              'can_pay_now': false,
              'created_at': '2026-11-26T10:00:00Z',
              'formatted_created_at': 'Nov 26, 2026',
              'paid_at': '2026-11-26T10:01:00Z',
              'email': 'customer@reset.store',
              'phone': '012345678',
              'shipping_address': {
                'name': 'Dara',
                'full_name': 'Dara',
                'first_name': 'Dara',
                'last_name': '',
                'phone': '012345678',
                'province': 'Phnom Penh',
                'district': 'Daun Penh',
                'commune': 'Chaktomuk',
                'street_address': 'St 178',
              },
              'billing_address': {
                'name': 'Dara',
                'full_name': 'Dara',
                'first_name': 'Dara',
                'last_name': '',
                'phone': '012345678',
                'province': 'Phnom Penh',
                'district': 'Daun Penh',
                'commune': 'Chaktomuk',
                'street_address': 'St 178',
              },
              'tracking_number': null,
              'shipping_carrier': null,
              'customer_notes': null,
              'shipped_at': null,
              'delivered_at': null,
              'cancelled_at': null,
              'items': [],
              'latest_payment': null,
              'status_timeline': [],
            },
            'payment': {
              'id': 88,
              'order_id': 1,
              'order_number': 'RST-2026-00001',
              'provider': 'bakong_khqr',
              'md5': 'md5_sample_88',
              'qr_string': '000201',
              'account_id': 'reset_store@devb',
              'merchant_name': 'RESET Store',
              'amount': 164000,
              'currency': 'KHR',
              'formatted_amount': '164,000 ៛',
              'khr_amount': 164000,
              'formatted_khr_amount': '164,000 ៛',
              'usd_amount': 40.0,
              'formatted_usd_amount': '\$40.00',
              'exchange_rate': 4100,
              'status': 'paid',
              'status_label': 'Paid',
              'expires_at': '2026-11-26T10:05:00Z',
              'time_remaining_seconds': 0,
              'paid_at': '2026-11-26T10:01:00Z',
              'bakong_mock': true,
              'deeplink_url': 'bakong://qr?data=000201',
            },
          });
        }
        return jsonMockResponse(<String, dynamic>{});
      }),
    );

    await tester.pumpWidget(
      await _wrapPaymentScreen(
        apiClient: apiClient,
        storage: storage,
        child: KhqrPaymentScreen(
          orderNumber: 'RST-2026-00001',
          initialOrder: _sampleOrder(),
          initialPayment: _samplePayment(bakongMock: true),
        ),
      ),
    );

    expect(find.text('Simulate Instant Payment'), findsOneWidget);
    await tester.ensureVisible(find.text('Simulate Instant Payment'));
    await tester.tap(find.text('Simulate Instant Payment'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(simulateCalled, isTrue);
    expect(find.byType(OrderSuccessScreen), findsOneWidget);
  });

  testWidgets('shows Expired overlay and Generate New QR Code button when expired',
      (tester) async {
    final storage = await AppStorage.create();
    final apiClient = ApiClient(
      storage: storage,
      httpClient: MockClient((_) async => jsonMockResponse(<String, dynamic>{})),
    );

    await tester.pumpWidget(
      await _wrapPaymentScreen(
        apiClient: apiClient,
        storage: storage,
        child: KhqrPaymentScreen(
          orderNumber: 'RST-2026-00001',
          initialOrder: _sampleOrder(status: 'expired'),
          initialPayment: _samplePayment(
            bakongMock: true,
            status: 'expired',
            remaining: 0,
          ),
        ),
      ),
    );

    expect(find.text('This payment QR has expired.'), findsOneWidget);
    expect(find.text('Generate New QR Code'), findsOneWidget);
  });
}
