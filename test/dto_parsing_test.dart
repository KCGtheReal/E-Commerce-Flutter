import 'package:flutter_test/flutter_test.dart';
import 'package:reset_store/models/bootstrap_page_models.dart';
import 'package:reset_store/models/cart_models.dart';
import 'package:reset_store/models/catalog_models.dart';
import 'package:reset_store/models/order_payment_models.dart';

void main() {
  group('DTO JSON deserialization against contracts/api.ts', () {
    test('parses BootstrapResponse accurately', () {
      final json = <String, dynamic>{
        'locale': 'en',
        'currency': 'KHR',
        'settings': {
          'store_name': 'RESET Store',
          'store_tagline': 'Start fresh.',
          'store_tagline_km': 'ចាប់ផ្តើមថ្មី។',
          'store_email': 'support@reset.store',
          'store_phone': '+855 23 999 123',
          'store_address': 'Street 178, Daun Penh, Phnom Penh',
          'announcement_banner_en': 'Free shipping over 200,000 ៛',
          'announcement_banner_km': 'ដឹកជញ្ជូនឥតគិតថ្លៃ',
          'announcement_banner': 'Free shipping over 200,000 ៛',
          'exchange_rate': 4100,
          'free_shipping_threshold': 200000,
          'formatted_free_shipping_threshold': '200,000 ៛',
          'express_shipping_fee_khr': 12000,
          'express_shipping_province': 'Phnom Penh',
          'province_shipping_fees': {'Phnom Penh': 0, 'Siem Reap': 0},
          'provinces': ['Phnom Penh', 'Siem Reap'],
          'bakong_mock': true,
          'bakong_currency': 'KHR',
          'qr_ttl_seconds': 300,
        },
        'categories': [
          {
            'id': 1,
            'name': 'Heavyweight Tees',
            'name_en': 'Heavyweight Tees',
            'name_km': 'អាវយឺតសាច់ក្រាស់',
            'slug': 'heavyweight-tees',
            'description': 'Boxy 280 GSM tees',
            'description_en': 'Boxy 280 GSM tees',
            'description_km': 'អាវយឺត 280 GSM',
            'image_url': '/images/tees.jpg',
            'sort_order': 1,
            'products_count': 6,
          },
        ],
        'size_guide': {
          'title': 'Garment Measurements',
          'subtitle': 'Flat across in cm',
          'fit_note_title': 'Boxy Fit',
          'fit_note_body': 'Dropped shoulder',
          'tip': 'Size down for fitted look',
          'tables': [
            {
              'id': 'tees',
              'title': 'Heavyweight T-Shirts',
              'columns': {
                'size': 'Size',
                'chest': 'Chest',
                'length': 'Length',
                'shoulder': 'Shoulder',
                'sleeve': 'Sleeve',
              },
              'rows': [
                {
                  'size': 'M',
                  'chest_cm': 59,
                  'length_cm': 71,
                  'shoulder_cm': 55,
                  'sleeve_cm': 22,
                },
              ],
            },
          ],
          'how_to_measure_title': 'How to Measure',
          'how_to_measure': [
            {
              'key': 'chest',
              'label': 'Chest',
              'description': '2cm below armhole',
            },
          ],
        },
        'pages': [
          {
            'slug': 'about',
            'title': 'About Us',
            'subtitle': 'Phnom Penh',
            'endpoint': '/api/v1/pages/about',
          },
        ],
        'authenticated': false,
        'user': null,
        'cart': null,
      };

      final bootstrap = BootstrapResponse.fromJson(json);
      expect(bootstrap.settings.exchangeRate, 4100);
      expect(bootstrap.settings.bakongMock, isTrue);
      expect(bootstrap.settings.provinces, contains('Phnom Penh'));
      expect(bootstrap.categories.single.slug, 'heavyweight-tees');
      expect(bootstrap.sizeGuide.tables.single.rows.single.chestCm, 59);
    });

    test('parses ProductDetailResponse with 5 detail tabs and variants', () {
      final json = <String, dynamic>{
        'product': {
          'id': 10,
          'name': 'Boxy Heavy Tee',
          'name_en': 'Boxy Heavy Tee',
          'name_km': 'អាវយឺតធំ',
          'slug': 'boxy-heavy-tee',
          'sku_prefix': 'RST-TEE',
          'tagline': '280 GSM Organic Cotton',
          'tagline_en': '280 GSM Organic Cotton',
          'tagline_km': 'កប្បាស 280 GSM',
          'category': {
            'id': 1,
            'name': 'Tees',
            'name_en': 'Tees',
            'name_km': 'អាវយឺត',
            'slug': 'tees',
          },
          'primary_image_url': 'https://example.com/tee.jpg',
          'base_price_cents': 120000,
          'compare_at_price_cents': 150000,
          'formatted_price': '120,000 ៛',
          'formatted_compare_at_price': '150,000 ៛',
          'converted_price': 29.27,
          'converted_compare_at_price': 36.59,
          'is_on_sale': true,
          'is_featured': true,
          'is_new_arrival': true,
          'is_best_seller': false,
          'is_in_stock': true,
          'total_stock': 14,
          'average_rating': 4.8,
          'review_count': 2,
          'colors': [
            {'name': 'Onyx Black', 'code': '#111111'},
          ],
          'description': 'Heavyweight architectural tee.',
          'description_en': 'Heavyweight architectural tee.',
          'description_km': 'អាវយឺតសាច់ក្រាស់។',
          'images': [
            {
              'id': 1,
              'image_url': 'https://example.com/tee.jpg',
              'alt_text': 'Front',
              'is_primary': true,
              'sort_order': 1,
            },
          ],
          'variants': [
            {
              'id': 101,
              'product_id': 10,
              'sku': 'RST-TEE-BLK-M',
              'size': 'M',
              'color': 'Onyx Black',
              'color_code': '#111111',
              'label': 'Onyx Black / M',
              'price_cents': 120000,
              'formatted_price': '120,000 ៛',
              'converted_price': 29.27,
              'stock_quantity': 10,
              'reserved_quantity': 2,
              'available_stock': 8,
              'is_in_stock': true,
            },
          ],
          'available_sizes': ['M'],
          'available_colors': [
            {'name': 'Onyx Black', 'code': '#111111'},
          ],
          'details': {
            'fabric': '100% Organic Cotton',
            'care': 'Cold wash',
            'fit': 'Boxy relaxed',
            'shipping': '1-3 business days',
          },
          'detail_tabs': [
            {'key': 'description', 'title': 'Description', 'content': 'Desc'},
            {'key': 'fabric', 'title': 'Fabric & Material', 'content': '280 GSM'},
            {'key': 'care', 'title': 'Care Instructions', 'content': 'Cold wash'},
            {'key': 'fit', 'title': 'Fit & Sizing', 'content': 'Boxy fit'},
            {'key': 'shipping', 'title': 'Shipping & Delivery', 'content': 'Free >200k'},
          ],
          'reviews': [
            {
              'id': 5,
              'product_id': 10,
              'user_id': 2,
              'author_name': 'Sokha',
              'rating': 5,
              'title': 'Great weight',
              'body': 'Fits nicely and holds structure.',
              'is_verified_purchase': true,
              'created_at': '2026-11-20T10:00:00Z',
              'formatted_date': 'Nov 20, 2026',
            },
          ],
        },
        'has_purchased': true,
        'in_wishlist': true,
        'related_products': [],
      };

      final detail = ProductDetailResponse.fromJson(json);
      expect(detail.product.detailTabs.length, 5);
      expect(detail.product.variants.single.availableStock, 8);
      expect(detail.product.reviews.single.isVerifiedPurchase, isTrue);
      expect(detail.inWishlist, isTrue);
    });

    test('parses CartPayloadDto, CheckoutResponse, and TaxInvoiceDto', () {
      final cartJson = <String, dynamic>{
        'currency': 'KHR',
        'exchange_rate': 4100,
        'province': 'Phnom Penh',
        'shipping_method': 'express',
        'subtotal_cents': 164000,
        'formatted_subtotal': '164,000 ៛',
        'discount_cents': 0,
        'formatted_discount': '0 ៛',
        'shipping_fee_cents': 12000,
        'formatted_shipping': '12,000 ៛',
        'total_cents': 176000,
        'formatted_total': '176,000 ៛',
        'converted_total': 42.93,
        'free_shipping_threshold_cents': 200000,
        'formatted_free_shipping_threshold': '200,000 ៛',
        'free_shipping_qualified': false,
        'free_shipping_remaining_cents': 36000,
        'free_shipping_remaining_formatted': '36,000 ៛',
        'free_shipping_progress_percent': 82.0,
        'cart_token': 'guest-uuid-1234',
        'item_count': 1,
        'items': [
          {
            'id': 1,
            'product_id': 10,
            'product_slug': 'boxy-heavy-tee',
            'product_variant_id': 101,
            'product_name': 'Boxy Heavy Tee',
            'product_name_en': 'Boxy Heavy Tee',
            'product_name_km': 'អាវយឺត',
            'variant_label': 'Onyx Black / M',
            'sku': 'RST-TEE-BLK-M',
            'size': 'M',
            'color': 'Onyx Black',
            'color_code': '#111111',
            'image_url': 'https://example.com/tee.jpg',
            'price_cents': 164000,
            'formatted_price': '164,000 ៛',
            'converted_price': 40.0,
            'quantity': 1,
            'max_stock': 8,
            'subtotal_cents': 164000,
            'formatted_subtotal': '164,000 ៛',
            'converted_subtotal': 40.0,
          },
        ],
        'discount_code': null,
        'discount': null,
      };

      final cart = CartPayloadDto.fromJson(cartJson);
      expect(cart.shippingFeeCents, 12000);
      expect(cart.shippingMethod, 'express');
      expect(cart.cartToken, 'guest-uuid-1234');

      final checkoutJson = <String, dynamic>{
        'message': 'Order created',
        'order_access_token': 'signed.hmac.token',
        'order': {
          'id': 55,
          'number': 'RST-2026-00055',
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
          'shipping_fee_cents': 12000,
          'formatted_shipping': '12,000 ៛',
          'shipping_method': 'express',
          'total_cents': 176000,
          'formatted_total': '176,000 ៛',
          'total_charged_currency_amount': 176000,
          'formatted_charged_total': '176,000 ៛',
          'equivalent_khr_amount': 176000,
          'formatted_equivalent_khr': '176,000 ៛',
          'equivalent_usd_amount': 42.93,
          'formatted_equivalent_usd': '\$42.93',
          'items_count': 1,
          'preview_item_names': ['Boxy Heavy Tee'],
          'can_pay_now': true,
          'created_at': '2026-11-26T09:00:00Z',
          'formatted_created_at': 'Nov 26, 2026',
          'paid_at': null,
          'email': 'guest@example.com',
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
          'status_timeline': [
            {
              'key': 'pending_payment',
              'label': 'Pending Payment',
              'completed': false,
              'active': true,
              'timestamp': null,
            },
          ],
        },
        'payment': {
          'id': 77,
          'order_id': 55,
          'order_number': 'RST-2026-00055',
          'provider': 'bakong_khqr',
          'md5': 'abc123md5',
          'qr_string': '000201010212...',
          'account_id': 'reset_store@devb',
          'merchant_name': 'RESET Store',
          'amount': 176000,
          'currency': 'KHR',
          'formatted_amount': '176,000 ៛',
          'khr_amount': 176000,
          'formatted_khr_amount': '176,000 ៛',
          'usd_amount': 42.93,
          'formatted_usd_amount': '\$42.93',
          'exchange_rate': 4100,
          'status': 'pending',
          'status_label': 'Pending',
          'expires_at': '2026-11-26T09:05:00Z',
          'time_remaining_seconds': 300,
          'paid_at': null,
          'bakong_mock': true,
          'deeplink_url': 'bakong://qr?data=000201010212...',
        },
      };

      final checkout = CheckoutResponse.fromJson(checkoutJson);
      expect(checkout.orderAccessToken, 'signed.hmac.token');
      expect(checkout.payment.bakongMock, isTrue);
      expect(checkout.order.statusTimeline.single.active, isTrue);
    });
  });
}
