import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:reset_store/core/api/api_client.dart';
import 'package:reset_store/core/storage/app_storage.dart';
import 'package:reset_store/core/theme/app_theme.dart';
import 'package:reset_store/providers/app_navigation_provider.dart';
import 'package:reset_store/providers/app_settings_provider.dart';
import 'package:reset_store/providers/auth_provider.dart';
import 'package:reset_store/providers/bootstrap_provider.dart';
import 'package:reset_store/providers/cart_provider.dart';
import 'package:reset_store/providers/wishlist_provider.dart';
import 'package:reset_store/screens/checkout/checkout_screen.dart';
import 'package:reset_store/screens/home/home_screen.dart';
import 'package:reset_store/screens/product/product_detail_screen.dart';
import 'package:reset_store/screens/shop/shop_screen.dart';
import 'package:reset_store/widgets/reset_scaffold.dart';
import 'test_helpers.dart';

Future<Widget> _wrapApp({
  required ApiClient apiClient,
  required AppStorage storage,
  required Widget child,
  CartProvider? cartProvider,
}) async {
  final cart = cartProvider ?? CartProvider(apiClient);
  return MultiProvider(
    providers: [
      Provider<AppStorage>.value(value: storage),
      Provider<ApiClient>.value(value: apiClient),
      ChangeNotifierProvider(create: (_) => AppNavigationProvider()),
      ChangeNotifierProvider(create: (_) => AppSettingsProvider(storage)),
      ChangeNotifierProvider(create: (_) => BootstrapProvider(apiClient)),
      ChangeNotifierProvider<CartProvider>.value(value: cart),
      ChangeNotifierProvider(create: (_) => WishlistProvider(apiClient)),
      ChangeNotifierProvider(
        create: (_) => AuthProvider(apiClient: apiClient, storage: storage),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.build(brightness: Brightness.light, locale: 'en'),
      home: Scaffold(body: child),
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

  testWidgets('ShopScreen renders seed:clean empty state safely',
      (tester) async {
    final storage = await AppStorage.create();
    final apiClient = ApiClient(
      storage: storage,
      httpClient: MockClient((request) async {
        return jsonMockResponse(<String, dynamic>{
          'data': [],
          'meta': {
            'current_page': 1,
            'last_page': 1,
            'per_page': 12,
            'total': 0,
            'from': null,
            'to': null,
            'has_more_pages': false,
          },
          'facets': {
            'all_products_count': 0,
            'categories': [],
            'available_sizes': [],
            'available_colors': [],
            'active_filter_count': 0,
            'currency': 'KHR',
            'exchange_rate': 4100,
          },
        });
      }),
    );

    await tester.pumpWidget(
      await _wrapApp(
        apiClient: apiClient,
        storage: storage,
        child: const ShopScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No products match your selected filters.'), findsOneWidget);
    expect(find.text('Clear All Filters'), findsOneWidget);
  });

  testWidgets(
      'ShopScreen renders seed:stress 200-char Khmer Unicode & XSS strings without RenderFlex overflow',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final adversarialTitle =
        'អាវយឺត RESET 🔥✨ <script>alert("xss")</script> ' * 5;
    final storage = await AppStorage.create();
    final apiClient = ApiClient(
      storage: storage,
      httpClient: MockClient((request) async {
        return jsonMockResponse(<String, dynamic>{
          'data': [
            {
              'id': 1,
              'name': adversarialTitle,
              'name_en': adversarialTitle,
              'name_km': adversarialTitle,
              'slug': 'stress-tee',
              'sku_prefix': 'RST-STRESS',
              'tagline': 'Khmer Unicode tagline 🔥 សាច់ក្រណាត់ក្រាស់ 280GSM ' * 3,
              'tagline_en': 'Stress tagline',
              'tagline_km': 'Stress tagline KM',
              'category': {
                'id': 1,
                'name': 'Heavyweight Tees & Architectural Streetwear',
                'name_en': 'Heavyweight Tees',
                'name_km': 'អាវយឺតសាច់ក្រាស់',
                'slug': 'tees',
              },
              'primary_image_url': '',
              'base_price_cents': 185000,
              'compare_at_price_cents': 220000,
              'formatted_price': '185,000 ៛',
              'formatted_compare_at_price': '220,000 ៛',
              'converted_price': 45.12,
              'converted_compare_at_price': 53.66,
              'is_on_sale': true,
              'is_featured': true,
              'is_new_arrival': true,
              'is_best_seller': true,
              'is_in_stock': true,
              'total_stock': 5,
              'average_rating': 5.0,
              'review_count': 12,
              'colors': [
                {'name': 'Black', 'code': '#111111'},
                {'name': 'Bone', 'code': '#F5F4F0'},
              ],
            },
          ],
          'meta': {
            'current_page': 1,
            'last_page': 1,
            'per_page': 12,
            'total': 1,
            'from': 1,
            'to': 1,
            'has_more_pages': false,
          },
          'facets': {
            'all_products_count': 1,
            'categories': [
              {'id': 1, 'name': 'Tees', 'slug': 'tees', 'products_count': 1},
            ],
            'available_sizes': ['S', 'M', 'L'],
            'available_colors': [
              {'color': 'Black', 'color_code': '#111111'},
            ],
            'active_filter_count': 0,
            'currency': 'KHR',
            'exchange_rate': 4100,
          },
        });
      }),
    );

    await tester.pumpWidget(
      await _wrapApp(
        apiClient: apiClient,
        storage: storage,
        child: const ShopScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('អាវយឺត RESET'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('CheckoutScreen hides Express shipping when province is not Phnom Penh',
      (tester) async {
    final storage = await AppStorage.create();
    final apiClient = ApiClient(
      storage: storage,
      httpClient: MockClient((request) async {
        final province =
            request.url.queryParameters['province'] ?? 'Phnom Penh';
        final method =
            request.url.queryParameters['shipping_method'] ?? 'standard';
        final fee =
            (province == 'Phnom Penh' && method == 'express') ? 12000 : 0;
        return jsonMockResponse(<String, dynamic>{
          'cart': {
            'currency': 'KHR',
            'exchange_rate': 4100,
            'province': province,
            'shipping_method': method,
            'subtotal_cents': 120000,
            'formatted_subtotal': '120,000 ៛',
            'discount_cents': 0,
            'formatted_discount': '0 ៛',
            'shipping_fee_cents': fee,
            'formatted_shipping': fee == 12000 ? '12,000 ៛' : '0 ៛',
            'total_cents': 120000 + fee,
            'formatted_total': fee == 12000 ? '132,000 ៛' : '120,000 ៛',
            'converted_total': 29.27,
            'free_shipping_threshold_cents': 200000,
            'formatted_free_shipping_threshold': '200,000 ៛',
            'free_shipping_qualified': false,
            'free_shipping_remaining_cents': 80000,
            'free_shipping_remaining_formatted': '80,000 ៛',
            'free_shipping_progress_percent': 60,
            'cart_token': 'guest-1',
            'item_count': 1,
            'items': [
              {
                'id': 1,
                'product_id': 1,
                'product_slug': 'tee',
                'product_variant_id': 1,
                'product_name': 'RESET Tee',
                'product_name_en': 'RESET Tee',
                'product_name_km': 'អាវយឺត',
                'variant_label': 'Black / M',
                'sku': 'RST-1',
                'size': 'M',
                'color': 'Black',
                'color_code': '#111111',
                'image_url': '',
                'price_cents': 120000,
                'formatted_price': '120,000 ៛',
                'converted_price': 29.27,
                'quantity': 1,
                'max_stock': 5,
                'subtotal_cents': 120000,
                'formatted_subtotal': '120,000 ៛',
                'converted_subtotal': 29.27,
              },
            ],
            'discount_code': null,
            'discount': null,
          },
        });
      }),
    );

    final cartProvider = CartProvider(apiClient);
    await cartProvider.refreshCart();

    await tester.pumpWidget(
      await _wrapApp(
        apiClient: apiClient,
        storage: storage,
        cartProvider: cartProvider,
        child: const CheckoutScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Express Same-Day Delivery (Phnom Penh only)'),
      findsOneWidget,
    );

    // Switch province to Siem Reap
    await cartProvider.setShippingContext(
      province: 'Phnom Penh',
      shippingMethod: 'express',
    );
    await tester.pump();
    expect(cartProvider.selectedShippingMethod, 'express');

    await cartProvider.setShippingContext(province: 'Siem Reap');
    await tester.pumpAndSettle();

    expect(
      find.text('Express Same-Day Delivery (Phnom Penh only)'),
      findsNothing,
    );
    expect(cartProvider.selectedShippingMethod, 'standard');
  });

  testWidgets('HomeScreen renders seed:clean empty catalog gracefully',
      (tester) async {
    final storage = await AppStorage.create();
    final apiClient = ApiClient(
      storage: storage,
      httpClient: MockClient((request) async {
        return jsonMockResponse(<String, dynamic>{
          'categories': [],
          'featured_products': [],
          'new_arrivals': [],
          'best_sellers': [],
        });
      }),
    );

    await tester.pumpWidget(
      await _wrapApp(
        apiClient: apiClient,
        storage: storage,
        child: const HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Collection Refreshing'), findsOneWidget);
    expect(find.text('Explore Collection'), findsOneWidget);
  });

  testWidgets('ProductDetailScreen renders 5 tabs, Verified Buyer badge, and Size Guide',
      (tester) async {
    final storage = await AppStorage.create();
    final apiClient = ApiClient(
      storage: storage,
      httpClient: MockClient((request) async {
        return jsonMockResponse(<String, dynamic>{
          'product': {
            'id': 10,
            'name': 'Architectural Heavyweight Tee',
            'name_en': 'Architectural Heavyweight Tee',
            'name_km': 'អាវយឺតសាច់ក្រាស់',
            'slug': 'arch-tee',
            'sku_prefix': 'RST-ARCH',
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
            'primary_image_url': '',
            'base_price_cents': 140000,
            'compare_at_price_cents': null,
            'formatted_price': '140,000 ៛',
            'formatted_compare_at_price': null,
            'converted_price': 34.15,
            'converted_compare_at_price': null,
            'is_on_sale': false,
            'is_featured': true,
            'is_new_arrival': true,
            'is_best_seller': false,
            'is_in_stock': true,
            'total_stock': 6,
            'average_rating': 5.0,
            'review_count': 1,
            'colors': [
              {'name': 'Onyx', 'code': '#111111'},
            ],
            'description': 'Heavyweight architectural tee.',
            'description_en': 'Heavyweight architectural tee.',
            'description_km': 'អាវយឺតសាច់ក្រាស់។',
            'images': [],
            'variants': [
              {
                'id': 101,
                'product_id': 10,
                'sku': 'RST-ARCH-M',
                'size': 'M',
                'color': 'Onyx',
                'color_code': '#111111',
                'label': 'Onyx / M',
                'price_cents': 140000,
                'formatted_price': '140,000 ៛',
                'converted_price': 34.15,
                'stock_quantity': 6,
                'reserved_quantity': 0,
                'available_stock': 6,
                'is_in_stock': true,
              },
            ],
            'available_sizes': ['M'],
            'available_colors': [
              {'name': 'Onyx', 'code': '#111111'},
            ],
            'details': {
              'fabric': '100% Organic Cotton',
              'care': 'Cold wash',
              'fit': 'Boxy',
              'shipping': 'Free >200k',
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
                'author_name': 'Vannak',
                'rating': 5,
                'title': 'Solid drape',
                'body': 'Super clean collar and heavy fabric.',
                'is_verified_purchase': true,
                'created_at': '2026-11-20T10:00:00Z',
                'formatted_date': 'Nov 20, 2026',
              },
            ],
          },
          'has_purchased': true,
          'in_wishlist': false,
          'related_products': [],
        });
      }),
    );

    await tester.pumpWidget(
      await _wrapApp(
        apiClient: apiClient,
        storage: storage,
        child: const ProductDetailScreen(slug: 'arch-tee'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Architectural Heavyweight Tee'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Fabric & Material'), findsOneWidget);
    expect(find.text('Care Instructions'), findsOneWidget);
    expect(find.text('Fit & Sizing'), findsOneWidget);
    expect(find.text('Shipping & Delivery'), findsOneWidget);
    expect(find.text('Verified Buyer'), findsOneWidget);

    await tester.ensureVisible(find.text('Size Guide').first);
    await tester.tap(find.text('Size Guide').first);
    await tester.pumpAndSettle();
    expect(find.text('Heavyweight T-Shirts & Tops (S–XL)'), findsOneWidget);
  });

  testWidgets('ResetScaffold enforces white status bar icons in Light Mode',
      (tester) async {
    final storage = await AppStorage.create();
    final apiClient = ApiClient(
      storage: storage,
      httpClient: MockClient((_) async => jsonMockResponse(<String, dynamic>{})),
    );

    await tester.pumpWidget(
      await _wrapApp(
        apiClient: apiClient,
        storage: storage,
        child: const ResetScaffold(
          body: SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump();

    final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
    );
    expect(region.value.statusBarColor, Colors.transparent);
    expect(region.value.statusBarIconBrightness, Brightness.light);
    expect(region.value.statusBarBrightness, Brightness.dark);
    expect(region.value.systemNavigationBarIconBrightness, Brightness.dark);
  });
}
