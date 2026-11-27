import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:reset_store/core/api/api_client.dart';
import 'package:reset_store/core/api/api_exceptions.dart';
import 'package:reset_store/core/storage/app_storage.dart';
import 'package:reset_store/models/order_payment_models.dart';
import 'package:reset_store/providers/auth_provider.dart';
import 'package:reset_store/providers/cart_provider.dart';
import 'test_helpers.dart';

Map<String, dynamic> _cartJson({
  String province = 'Phnom Penh',
  String shippingMethod = 'standard',
  int shippingFeeCents = 0,
  String formattedShipping = '0 ៛',
  String? cartToken = 'guest-cart-token-123',
}) {
  return <String, dynamic>{
    'currency': 'KHR',
    'exchange_rate': 4100,
    'province': province,
    'shipping_method': shippingMethod,
    'subtotal_cents': 164000,
    'formatted_subtotal': '164,000 ៛',
    'discount_cents': 0,
    'formatted_discount': '0 ៛',
    'shipping_fee_cents': shippingFeeCents,
    'formatted_shipping': formattedShipping,
    'total_cents': 164000 + shippingFeeCents,
    'formatted_total': shippingFeeCents == 12000 ? '176,000 ៛' : '164,000 ៛',
    'converted_total': 40.0,
    'free_shipping_threshold_cents': 200000,
    'formatted_free_shipping_threshold': '200,000 ៛',
    'free_shipping_qualified': false,
    'free_shipping_remaining_cents': 36000,
    'free_shipping_remaining_formatted': '36,000 ៛',
    'free_shipping_progress_percent': 82,
    'cart_token': cartToken,
    'item_count': 1,
    'items': [
      {
        'id': 1,
        'product_id': 1,
        'product_slug': 'tee-01',
        'product_variant_id': 10,
        'product_name': 'RESET Tee',
        'product_name_en': 'RESET Tee',
        'product_name_km': 'អាវយឺត RESET',
        'variant_label': 'Black / M',
        'sku': 'RST-01-M',
        'size': 'M',
        'color': 'Black',
        'color_code': '#111111',
        'image_url': 'https://example.com/tee.jpg',
        'price_cents': 164000,
        'formatted_price': '164,000 ៛',
        'converted_price': 40.0,
        'quantity': 1,
        'max_stock': 5,
        'subtotal_cents': 164000,
        'formatted_subtotal': '164,000 ៛',
        'converted_subtotal': 40.0,
      },
    ],
    'discount_code': null,
    'discount': null,
  };
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('ApiClient injects required headers, persists tokens, and handles 422',
      () async {
    final capturedHeaders = <String, Map<String, String>>{};
    final mockHttp = MockClient((request) async {
      capturedHeaders[request.url.path] = Map<String, String>.from(
        request.headers,
      );

      if (request.url.path == '/api/v1/cart') {
        return jsonMockResponse(<String, dynamic>{'cart': _cartJson()});
      }

      if (request.url.path == '/api/v1/auth/login') {
        return jsonMockResponse(<String, dynamic>{
          'token': 'rst_test_bearer_token',
          'token_type': 'Bearer',
          'expires_at': null,
          'user': {
            'id': 2,
            'name': 'Dara',
            'email': 'customer@reset.store',
            'phone': '012345678',
            'role': 'customer',
            'email_verified_at': null,
            'created_at': '2026-11-26T00:00:00Z',
          },
          'cart': _cartJson(cartToken: null),
        });
      }

      if (request.url.path == '/api/v1/checkout') {
        return jsonMockResponse(<String, dynamic>{
          'message': 'Order placed',
          'order_access_token': 'hmac_order_token_xyz',
          'order': {
            'id': 99,
            'number': 'RST-2026-00099',
            'status': 'pending_payment',
            'status_label': 'Pending Payment',
            'status_color': 'warning',
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
            'preview_item_names': ['RESET Tee'],
            'can_pay_now': true,
            'created_at': '2026-11-26T09:00:00Z',
            'formatted_created_at': 'Nov 26, 2026',
            'paid_at': null,
            'email': 'guest@reset.store',
            'phone': '012345678',
            'shipping_address': {
              'name': 'Guest',
              'full_name': 'Guest',
              'first_name': 'Guest',
              'last_name': '',
              'phone': '012345678',
              'province': 'Phnom Penh',
              'district': 'Daun Penh',
              'commune': 'Chaktomuk',
              'street_address': 'St 178',
            },
            'billing_address': {
              'name': 'Guest',
              'full_name': 'Guest',
              'first_name': 'Guest',
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
            'id': 501,
            'order_id': 99,
            'order_number': 'RST-2026-00099',
            'provider': 'bakong_khqr',
            'md5': 'md5hash',
            'qr_string': '000201...',
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
            'status': 'pending',
            'status_label': 'Pending',
            'expires_at': '2026-11-26T09:05:00Z',
            'time_remaining_seconds': 300,
            'paid_at': null,
            'bakong_mock': true,
            'deeplink_url': 'bakong://qr?data=000201...',
          },
        }, 201);
      }

      if (request.url.path == '/api/v1/payments/501/status') {
        return jsonMockResponse(<String, dynamic>{
          'payment_id': 501,
          'order_number': 'RST-2026-00099',
          'order_status': 'pending_payment',
          'status': 'pending',
          'time_remaining_seconds': 295,
          'paid_at': null,
          'message': null,
        });
      }

      if (request.url.path == '/api/v1/cart/discount') {
        return jsonMockResponse(<String, dynamic>{
          'success': false,
          'message': 'Invalid discount code.',
          'code': 'INVALID_DISCOUNT',
          'errors': {
            'code': ['Promo code EXPIRED50 is invalid or expired.'],
          },
        }, 422);
      }

      return jsonMockResponse(<String, dynamic>{}, 404);
    });

    final storage = await AppStorage.create();
    final api = ApiClient(
      storage: storage,
      httpClient: mockHttp,
      localeResolver: () => 'km',
      currencyResolver: () => 'USD',
    );
    final cartProvider = CartProvider(api);
    final authProvider = AuthProvider(
      apiClient: api,
      storage: storage,
      cartProvider: cartProvider,
    );

    // 1. Guest cart call captures X-Cart-Token and sends context headers
    await cartProvider.refreshCart();
    expect(storage.getCartToken(), 'guest-cart-token-123');
    expect(capturedHeaders['/api/v1/cart']?['X-Locale'], 'km');
    expect(capturedHeaders['/api/v1/cart']?['X-Currency'], 'USD');

    // 2. Login passes X-Cart-Token for server-side merge and persists Bearer token
    await authProvider.login(
      email: 'customer@reset.store',
      password: 'password',
    );
    expect(
      capturedHeaders['/api/v1/auth/login']?['X-Cart-Token'],
      'guest-cart-token-123',
    );
    expect(authProvider.isAuthenticated, isTrue);
    expect(storage.getAuthToken(), 'rst_test_bearer_token');

    // 3. Checkout persists X-Order-Token, then status check sends X-Order-Token
    await api.checkout(
      const CheckoutRequest(
        name: 'Guest',
        email: 'guest@reset.store',
        phone: '012345678',
        province: 'Phnom Penh',
        streetAddress: 'St 178',
        shippingMethod: 'standard',
      ),
    );
    expect(storage.getOrderToken('RST-2026-00099'), 'hmac_order_token_xyz');

    await api.getPaymentStatus(501, orderNumber: 'RST-2026-00099');
    expect(
      capturedHeaders['/api/v1/payments/501/status']?['X-Order-Token'],
      'hmac_order_token_xyz',
    );
    expect(
      capturedHeaders['/api/v1/payments/501/status']?['Authorization'],
      'Bearer rst_test_bearer_token',
    );

    // 4. 422 validation error parses field errors cleanly
    await expectLater(
      () => cartProvider.applyDiscount('EXPIRED50'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.isValidation, 'isValidation', isTrue)
            .having(
              (e) => e.fieldError('code'),
              'fieldError(code)',
              'Promo code EXPIRED50 is invalid or expired.',
            ),
      ),
    );
  });

  test('CartProvider strictly enforces Express shipping Phnom Penh reset rule',
      () async {
    final mockHttp = MockClient((request) async {
      final province = request.url.queryParameters['province'] ?? 'Phnom Penh';
      final method =
          request.url.queryParameters['shipping_method'] ?? 'standard';
      final fee = (province == 'Phnom Penh' && method == 'express') ? 12000 : 0;
      return jsonMockResponse(<String, dynamic>{
        'cart': _cartJson(
          province: province,
          shippingMethod: method,
          shippingFeeCents: fee,
          formattedShipping: fee == 12000 ? '12,000 ៛' : '0 ៛',
        ),
      });
    });

    final storage = await AppStorage.create();
    final api = ApiClient(storage: storage, httpClient: mockHttp);
    final cartProvider = CartProvider(api);

    // Selecting Express in Phnom Penh works
    final reset1 = await cartProvider.setShippingContext(
      province: 'Phnom Penh',
      shippingMethod: 'express',
    );
    expect(reset1, isFalse);
    expect(cartProvider.selectedShippingMethod, 'express');
    expect(cartProvider.canUseExpressShipping, isTrue);
    expect(cartProvider.cart?.shippingFeeCents, 12000);

    // Switching province away from Phnom Penh automatically resets Express -> Standard
    final reset2 = await cartProvider.setShippingContext(
      province: 'Siem Reap',
    );
    expect(reset2, isTrue);
    expect(cartProvider.selectedProvince, 'Siem Reap');
    expect(cartProvider.selectedShippingMethod, 'standard');
    expect(cartProvider.canUseExpressShipping, isFalse);
    expect(cartProvider.cart?.shippingFeeCents, 0);
  });
}
