import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:reset_store/core/api/api_client.dart';
import 'package:reset_store/core/config/app_config.dart';
import 'package:reset_store/core/firebase/firebase_gateway_client.dart';
import 'package:reset_store/core/firebase/runtime_endpoint_resolver.dart';
import 'package:reset_store/core/storage/app_storage.dart';
import 'package:reset_store/core/theme/app_theme.dart';
import 'package:reset_store/models/bootstrap_page_models.dart';
import 'package:reset_store/models/catalog_models.dart';
import 'package:reset_store/providers/app_settings_provider.dart';
import 'package:reset_store/widgets/preferences_sheet.dart';
import 'test_helpers.dart';

Map<String, dynamic> _sampleCategory({int id = 1, String name = 'Tees'}) =>
    <String, dynamic>{
      'id': id,
      'name': name,
      'name_en': name,
      'name_km': 'អាវយឺត',
      'slug': 'tees',
      'description': 'Heavyweight tees',
      'description_en': 'Heavyweight tees',
      'description_km': 'អាវយឺតសាច់ក្រាស់',
      'image_url': 'https://example.com/cat.jpg',
      'sort_order': 1,
      'products_count': 4,
    };

Map<String, dynamic> _sampleProductCard({
  int id = 10,
  String name = 'RESET Boxy Tee',
  String slug = 'reset-boxy-tee',
}) =>
    <String, dynamic>{
      'id': id,
      'name': name,
      'name_en': name,
      'name_km': 'អាវយឺត RESET',
      'slug': slug,
      'sku_prefix': 'RST-TEE',
      'tagline': '280 GSM Organic Cotton',
      'tagline_en': '280 GSM Organic Cotton',
      'tagline_km': 'កប្បាស 280 GSM',
      'category': <String, dynamic>{
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
      'is_best_seller': true,
      'is_in_stock': true,
      'total_stock': 12,
      'average_rating': 4.9,
      'review_count': 3,
      'colors': <Map<String, dynamic>>[
        <String, dynamic>{'name': 'Onyx', 'code': '#111111'},
      ],
    };

Map<String, dynamic> _sampleHomePayload({
  String productName = 'Firebase Gateway Tee',
}) =>
    <String, dynamic>{
      'source': 'firebase',
      'cached': true,
      'categories': <Map<String, dynamic>>[_sampleCategory()],
      'featured_products': <Map<String, dynamic>>[
        _sampleProductCard(name: productName),
      ],
      'new_arrivals': <Map<String, dynamic>>[
        _sampleProductCard(id: 11, name: '$productName New', slug: 'new-tee'),
      ],
      'best_sellers': <Map<String, dynamic>>[
        _sampleProductCard(id: 12, name: '$productName Best', slug: 'best-tee'),
      ],
    };

Map<String, dynamic> _sampleProductsPayload({
  String productName = 'Firebase Filtered Tee',
}) =>
    <String, dynamic>{
      'source': 'firebase',
      'cached': false,
      'data': <Map<String, dynamic>>[
        _sampleProductCard(name: productName),
      ],
      'meta': <String, dynamic>{
        'current_page': 1,
        'last_page': 1,
        'per_page': 12,
        'total': 1,
        'from': 1,
        'to': 1,
        'has_more_pages': false,
      },
      'facets': <String, dynamic>{
        'all_products_count': 1,
        'categories': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 1,
            'name': 'Tees',
            'slug': 'tees',
            'products_count': 1,
          },
        ],
        'available_sizes': <String>['S', 'M', 'L'],
        'available_colors': <Map<String, dynamic>>[
          <String, dynamic>{'color': 'Onyx', 'color_code': '#111111'},
        ],
        'active_filter_count': 1,
        'currency': 'USD',
        'exchange_rate': 4100,
      },
    };

Map<String, dynamic> _sampleSearchSuggestPayload({
  String productName = 'Firebase Search Tee',
}) =>
    <String, dynamic>{
      'source': 'firebase',
      'cached': true,
      'query': 'boxy',
      'popular_searches': <String>['Heavyweight Boxy Tee', 'Oversized'],
      'categories': <Map<String, dynamic>>[
        <String, dynamic>{'name': 'Tees', 'slug': 'tees'},
      ],
      'products': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 10,
          'name': productName,
          'slug': 'reset-boxy-tee',
          'image_url': 'https://example.com/tee.jpg',
          'price': '\$29.27',
          'compare_at_price': null,
          'price_cents': 120000,
          'compare_at_price_cents': null,
          'category': 'Tees',
          'is_in_stock': true,
        },
      ],
      'total': 1,
    };

Map<String, dynamic> _sampleProductDetailPayload({
  String productName = 'Firebase Detail Tee',
  bool hasPurchased = false,
  bool inWishlist = false,
}) =>
    <String, dynamic>{
      'source': 'firebase',
      'cached': false,
      'product': <String, dynamic>{
        ..._sampleProductCard(name: productName),
        'description': 'Heavyweight architectural tee.',
        'description_en': 'Heavyweight architectural tee.',
        'description_km': 'អាវយឺតសាច់ក្រាស់។',
        'images': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 1,
            'image_url': 'https://example.com/tee.jpg',
            'alt_text': 'Front',
            'is_primary': true,
            'sort_order': 1,
          },
        ],
        'variants': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 101,
            'product_id': 10,
            'sku': 'RST-TEE-BLK-M',
            'size': 'M',
            'color': 'Onyx',
            'color_code': '#111111',
            'label': 'Onyx / M',
            'price_cents': 120000,
            'formatted_price': '120,000 ៛',
            'converted_price': 29.27,
            'stock_quantity': 12,
            'reserved_quantity': 0,
            'available_stock': 12,
            'is_in_stock': true,
          },
        ],
        'available_sizes': <String>['M'],
        'available_colors': <Map<String, dynamic>>[
          <String, dynamic>{'name': 'Onyx', 'code': '#111111'},
        ],
        'details': <String, dynamic>{
          'fabric': '280 GSM Organic Cotton',
          'care': 'Cold wash',
          'fit': 'Boxy fit',
          'shipping': '1-3 business days',
        },
        'detail_tabs': <Map<String, dynamic>>[
          <String, dynamic>{
            'key': 'description',
            'title': 'Description',
            'content': 'Desc',
          },
        ],
        'reviews': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 5,
            'product_id': 10,
            'user_id': null,
            'author_name': 'Dara',
            'rating': 5,
            'title': 'Clean drape',
            'body': 'Zero-PII Firestore review.',
            'is_verified_purchase': true,
            'created_at': '2026-11-26T10:00:00Z',
            'formatted_date': 'Nov 26, 2026',
          },
        ],
      },
      'has_purchased': hasPurchased,
      'in_wishlist': inWishlist,
      'related_products': <Map<String, dynamic>>[],
    };

Map<String, dynamic> _sampleBootstrapPayload({bool bakongMock = false}) =>
    <String, dynamic>{
      'source': 'firebase',
      'cached': true,
      'locale': 'en',
      'currency': 'KHR',
      'settings': <String, dynamic>{
        'store_name': 'RESET Store',
        'store_tagline': 'Start fresh.',
        'store_tagline_km': 'ចាប់ផ្តើមថ្មី។',
        'store_email': 'support@reset.store',
        'store_phone': '+855 23 999 123',
        'store_address': 'Street 178, Phnom Penh',
        'announcement_banner_en': 'Free nationwide delivery over 200,000 ៛',
        'announcement_banner_km': 'ដឹកជញ្ជូនឥតគិតថ្លៃ',
        'announcement_banner': 'Free nationwide delivery over 200,000 ៛',
        'exchange_rate': 4100,
        'free_shipping_threshold': 200000,
        'formatted_free_shipping_threshold': '200,000 ៛',
        'express_shipping_fee_khr': 12000,
        'express_shipping_province': 'Phnom Penh',
        'province_shipping_fees': <String, dynamic>{'Phnom Penh': 0},
        'provinces': <String>['Phnom Penh', 'Siem Reap'],
        'bakong_mock': bakongMock,
        'bakong_currency': 'KHR',
        'qr_ttl_seconds': 600,
      },
      'categories': <Map<String, dynamic>>[_sampleCategory()],
      'size_guide': <String, dynamic>{
        'title': 'Garment Measurements',
        'subtitle': 'Flat cm',
        'fit_note_title': 'Boxy Fit',
        'fit_note_body': 'Dropped shoulder',
        'tip': 'True to size',
        'tables': <Map<String, dynamic>>[],
        'how_to_measure_title': 'How to Measure',
        'how_to_measure': <Map<String, dynamic>>[],
      },
      'pages': <Map<String, dynamic>>[
        <String, dynamic>{
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

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('AppConfig Firebase Gateway URL resolution', () {
    test('resolves defaults across desktop/iOS and Android platforms', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        expect(AppConfig.defaultFirebaseApiBaseUrl(), 'http://127.0.0.1:4000');
        expect(
          AppConfig.resolveFirebaseApiBaseUrl(null),
          'http://127.0.0.1:4000',
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        expect(AppConfig.defaultFirebaseApiBaseUrl(), 'http://10.0.2.2:4000');
        expect(
          AppConfig.resolveFirebaseApiBaseUrl(null),
          'http://10.0.2.2:4000',
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    test('derives LAN port 4000 from savedBackendUrl and normalizes overrides',
        () {
      expect(
        AppConfig.resolveFirebaseApiBaseUrl('http://192.168.1.50:8000'),
        'http://192.168.1.50:4000',
      );
      expect(
        AppConfig.resolveFirebaseApiBaseUrl('http://192.168.1.50:8000/api/'),
        'http://192.168.1.50:4000',
      );
      expect(
        AppConfig.resolveFirebaseApiBaseUrl('http://localhost:8000'),
        AppConfig.defaultFirebaseApiBaseUrl(),
      );
      expect(
        AppConfig.resolveFirebaseApiBaseUrl(
          'http://192.168.1.50:8000',
          customFirebaseApiUrl: 'http://10.0.0.25:4500///',
        ),
        'http://10.0.0.25:4500',
      );
      expect(
        AppConfig.firebaseSwaggerDocsUrl(baseUrl: 'http://192.168.1.50:8000'),
        'http://192.168.1.50:4000/docs',
      );
    });
  });

  group('FirebaseGatewayClient', () {
    test(
        'parses home, products, search/suggest, product detail, bootstrap, settings, and health with locale/currency headers',
        () async {
      final capturedRequests = <http.Request>[];
      final mockHttp = MockClient((request) async {
        capturedRequests.add(request);
        switch (request.url.path) {
          case '/api/firebase/home':
            return jsonMockResponse(_sampleHomePayload());
          case '/api/firebase/products':
            return jsonMockResponse(_sampleProductsPayload());
          case '/api/firebase/search/suggest':
            return jsonMockResponse(_sampleSearchSuggestPayload());
          case '/api/firebase/products/reset-boxy-tee':
            return jsonMockResponse(_sampleProductDetailPayload());
          case '/api/firebase/bootstrap':
            return jsonMockResponse(_sampleBootstrapPayload());
          case '/api/firebase/settings':
            return jsonMockResponse(<String, dynamic>{
              'source': 'firebase',
              'cached': true,
              'locale': 'km',
              'currency': 'USD',
              'data': _sampleBootstrapPayload()['settings'],
              'raw': <String, dynamic>{'exchange_rate': 4100},
            });
          case '/health':
            return jsonMockResponse(<String, dynamic>{
              'status': 'ok',
              'service': 'reset-firebase-gateway',
              'source': 'firebase',
              'project_id': 'reset-store-ecommerce',
              'database_id': '(default)',
              'region': 'asia-southeast1',
              'firestore_connected': true,
              'cache_enabled': true,
              'cache_entries': 3,
              'uptime_seconds': 12.5,
              'timestamp': '2026-11-27T05:00:00.000Z',
            });
          default:
            return jsonMockResponse(<String, dynamic>{}, 404);
        }
      });

      final client = FirebaseGatewayClient(
        httpClient: mockHttp,
        localeResolver: () => 'km',
        currencyResolver: () => 'USD',
        baseUrlResolver: () => 'http://192.168.1.50:4000/',
      );

      final home = await client.getHome();
      expect(home, isNotNull);
      expect(home!.featuredProducts.single.name, 'Firebase Gateway Tee');

      final products = await client.getProducts(
        const ProductsQuery(
          q: 'boxy',
          category: 'tees',
          sizes: <String>['S', 'M'],
          inStock: true,
          sort: 'price_low',
        ),
      );
      expect(products, isNotNull);
      expect(products!.data.single.name, 'Firebase Filtered Tee');
      expect(products.facets.currency, 'USD');

      final suggest = await client.searchSuggest('boxy');
      expect(suggest, isNotNull);
      expect(suggest!.products.single.name, 'Firebase Search Tee');

      final detail = await client.getProductDetail('reset-boxy-tee');
      expect(detail, isNotNull);
      expect(detail!.product.name, 'Firebase Detail Tee');
      expect(detail.product.reviews.single.userId, 0);

      final bootstrap = await client.getBootstrap();
      expect(bootstrap, isNotNull);
      expect(bootstrap!.settings.exchangeRate, 4100);

      final settings = await client.getSettings();
      expect(settings, isNotNull);
      expect(settings!.currency, 'USD');
      expect(settings.data.storeName, 'RESET Store');

      final health = await client.checkHealth(ping: true);
      expect(health, isNotNull);
      expect(health!.isHealthy, isTrue);
      expect(health.projectId, 'reset-store-ecommerce');

      expect(capturedRequests, hasLength(7));
      for (final req in capturedRequests) {
        expect(req.url.host, '192.168.1.50');
        expect(req.url.port, 4000);
        expect(req.headers['X-Locale'], 'km');
        expect(req.headers['Accept-Language'], 'km');
        expect(req.headers['X-Currency'], 'USD');
        expect(req.headers['Accept'], 'application/json');
        expect(req.headers.containsKey('Authorization'), isFalse);
        expect(req.headers.containsKey('X-Cart-Token'), isFalse);
      }

      final productsReq = capturedRequests[1];
      expect(productsReq.url.queryParameters['q'], 'boxy');
      expect(productsReq.url.queryParameters['category'], 'tees');
      expect(productsReq.url.queryParametersAll['size[]'], <String>['S', 'M']);
      expect(productsReq.url.queryParameters['in_stock'], '1');
      expect(productsReq.url.queryParameters['sort'], 'price_low');

      final healthReq = capturedRequests.last;
      expect(healthReq.url.queryParameters['ping'], '1');
    });

    test('returns null safely on 500, 404, network exceptions, and timeouts',
        () async {
      final serverErrorClient = FirebaseGatewayClient(
        httpClient: MockClient(
          (_) async => jsonMockResponse(<String, dynamic>{'message': 'err'}, 500),
        ),
      );
      expect(await serverErrorClient.getHome(), isNull);
      expect(await serverErrorClient.getProducts(), isNull);
      expect(await serverErrorClient.searchSuggest('tee'), isNull);

      final notFoundClient = FirebaseGatewayClient(
        httpClient: MockClient(
          (_) async => jsonMockResponse(<String, dynamic>{}, 404),
        ),
      );
      expect(await notFoundClient.getProductDetail('un-synced-slug'), isNull);

      final offlineClient = FirebaseGatewayClient(
        httpClient: MockClient(
          (_) async => throw http.ClientException('Connection refused'),
        ),
      );
      expect(await offlineClient.getBootstrap(), isNull);
      expect(await offlineClient.checkHealth(), isNull);

      final timeoutClient = FirebaseGatewayClient(
        timeout: const Duration(milliseconds: 20),
        httpClient: MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 120));
          return jsonMockResponse(_sampleHomePayload());
        }),
      );
      expect(await timeoutClient.getHome(), isNull);
    });
  });

  group('ApiClient + FirebaseGatewayClient orchestration & fallback', () {
    test('disables FirebaseGatewayClient when mock httpClient is injected alone',
        () async {
      final storage = await AppStorage.create();
      final mockOnly = ApiClient(
        storage: storage,
        httpClient: MockClient((_) async => jsonMockResponse(<String, dynamic>{})),
      );
      expect(mockOnly.firebaseGateway, isNull);

      final runtimeApi = ApiClient(storage: storage);
      expect(runtimeApi.firebaseGateway, isNotNull);
    });

    test(
        'prefers FirebaseGatewayClient when online for guest storefront reads and preserves attached context',
        () async {
      final storage = await AppStorage.create();
      var laravelCalls = 0;
      final laravelMock = MockClient((request) async {
        laravelCalls += 1;
        return jsonMockResponse(<String, dynamic>{}, 500);
      });

      final gatewayRequests = <http.Request>[];
      final gateway = FirebaseGatewayClient(
        httpClient: MockClient((request) async {
          gatewayRequests.add(request);
          switch (request.url.path) {
            case '/api/firebase/home':
              return jsonMockResponse(_sampleHomePayload());
            case '/api/firebase/products':
              return jsonMockResponse(_sampleProductsPayload());
            case '/api/firebase/search/suggest':
              return jsonMockResponse(_sampleSearchSuggestPayload());
            case '/api/firebase/products/reset-boxy-tee':
              return jsonMockResponse(_sampleProductDetailPayload());
            default:
              return jsonMockResponse(<String, dynamic>{}, 404);
          }
        }),
      );

      final api = ApiClient(
        storage: storage,
        httpClient: laravelMock,
        firebaseGatewayClient: gateway,
      );
      api.attachContext(
        localeResolver: () => 'km',
        currencyResolver: () => 'USD',
        baseUrlResolver: () => 'http://192.168.1.50:8000',
      );

      final home = await api.getHome();
      final products = await api.getProducts();
      final suggest = await api.searchSuggest('boxy');
      final detail = await api.getProductDetail('reset-boxy-tee');

      expect(laravelCalls, 0);
      expect(home.featuredProducts.single.name, 'Firebase Gateway Tee');
      expect(products.data.single.name, 'Firebase Filtered Tee');
      expect(suggest.products.single.name, 'Firebase Search Tee');
      expect(detail.product.name, 'Firebase Detail Tee');
      expect(api.firebaseSwaggerDocsUrl, 'http://192.168.1.50:4000/docs');

      for (final req in gatewayRequests) {
        expect(req.url.host, '192.168.1.50');
        expect(req.url.port, 4000);
        expect(req.headers['X-Locale'], 'km');
        expect(req.headers['X-Currency'], 'USD');
      }
    });

    test(
        'falls back cleanly to Laravel /api/v1/* when Firebase Gateway returns 500 or times out',
        () async {
      final storage = await AppStorage.create();
      final laravelPaths = <String>[];
      final laravelMock = MockClient((request) async {
        laravelPaths.add(request.url.path);
        switch (request.url.path) {
          case '/api/v1/home':
            return jsonMockResponse(
              _sampleHomePayload(productName: 'Laravel Fallback Tee'),
            );
          case '/api/v1/products':
            return jsonMockResponse(
              _sampleProductsPayload(productName: 'Laravel Filtered Tee'),
            );
          case '/api/v1/search/suggest':
            return jsonMockResponse(
              _sampleSearchSuggestPayload(productName: 'Laravel Search Tee'),
            );
          case '/api/v1/products/reset-boxy-tee':
            return jsonMockResponse(
              _sampleProductDetailPayload(productName: 'Laravel Detail Tee'),
            );
          default:
            return jsonMockResponse(<String, dynamic>{}, 404);
        }
      });

      final failingGateway = FirebaseGatewayClient(
        httpClient: MockClient(
          (_) async => jsonMockResponse(<String, dynamic>{'error': 'down'}, 500),
        ),
      );

      final apiAfter500 = ApiClient(
        storage: storage,
        httpClient: laravelMock,
        firebaseGatewayClient: failingGateway,
      );

      expect(
        (await apiAfter500.getHome()).featuredProducts.single.name,
        'Laravel Fallback Tee',
      );
      expect(
        (await apiAfter500.getProducts()).data.single.name,
        'Laravel Filtered Tee',
      );
      expect(
        (await apiAfter500.searchSuggest('boxy')).products.single.name,
        'Laravel Search Tee',
      );
      expect(
        (await apiAfter500.getProductDetail('reset-boxy-tee')).product.name,
        'Laravel Detail Tee',
      );
      expect(
        laravelPaths,
        <String>[
          '/api/v1/home',
          '/api/v1/products',
          '/api/v1/search/suggest',
          '/api/v1/products/reset-boxy-tee',
        ],
      );

      // Also verify TimeoutException fallback
      final timeoutGateway = FirebaseGatewayClient(
        timeout: const Duration(milliseconds: 20),
        httpClient: MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 120));
          return jsonMockResponse(_sampleHomePayload());
        }),
      );
      final apiAfterTimeout = ApiClient(
        storage: storage,
        httpClient: laravelMock,
        firebaseGatewayClient: timeoutGateway,
      );
      final homeAfterTimeout = await apiAfterTimeout.getHome();
      expect(
        homeAfterTimeout.featuredProducts.single.name,
        'Laravel Fallback Tee',
      );
    });

    test(
        'authenticated product detail prefers Laravel for has_purchased/in_wishlist, and bootstrap falls back to Firebase when Laravel is offline',
        () async {
      final storage = await AppStorage.create();
      await storage.setAuthToken('rst_auth_token');

      var gatewayDetailCalls = 0;
      var gatewayBootstrapCalls = 0;
      var laravelOnline = true;

      final laravelMock = MockClient((request) async {
        if (!laravelOnline) {
          throw http.ClientException('Laravel offline');
        }
        if (request.url.path == '/api/v1/products/reset-boxy-tee') {
          return jsonMockResponse(
            _sampleProductDetailPayload(
              productName: 'Laravel Auth Detail',
              hasPurchased: true,
              inWishlist: true,
            ),
          );
        }
        if (request.url.path == '/api/v1/bootstrap') {
          return jsonMockResponse(_sampleBootstrapPayload(bakongMock: true));
        }
        return jsonMockResponse(<String, dynamic>{}, 404);
      });

      final gateway = FirebaseGatewayClient(
        httpClient: MockClient((request) async {
          if (request.url.path == '/api/firebase/products/reset-boxy-tee') {
            gatewayDetailCalls += 1;
            return jsonMockResponse(
              _sampleProductDetailPayload(productName: 'Firebase Detail Tee'),
            );
          }
          if (request.url.path == '/api/firebase/bootstrap') {
            gatewayBootstrapCalls += 1;
            return jsonMockResponse(_sampleBootstrapPayload(bakongMock: false));
          }
          return jsonMockResponse(<String, dynamic>{}, 404);
        }),
      );

      final api = ApiClient(
        storage: storage,
        httpClient: laravelMock,
        firebaseGatewayClient: gateway,
      );

      // Authenticated product detail goes to Laravel first for personalized flags
      final authDetail = await api.getProductDetail('reset-boxy-tee');
      expect(gatewayDetailCalls, 0);
      expect(authDetail.product.name, 'Laravel Auth Detail');
      expect(authDetail.hasPurchased, isTrue);
      expect(authDetail.inWishlist, isTrue);

      // Online bootstrap goes to Laravel first to preserve bakong_mock & cart
      final laravelBootstrap = await api.getBootstrap();
      expect(gatewayBootstrapCalls, 0);
      expect(laravelBootstrap.settings.bakongMock, isTrue);

      // Offline Laravel falls back cleanly to Firebase Gateway for bootstrap
      laravelOnline = false;
      final firebaseBootstrap = await api.getBootstrap();
      expect(gatewayBootstrapCalls, 1);
      expect(firebaseBootstrap.settings.exchangeRate, 4100);
      expect(firebaseBootstrap.categories.single.slug, 'tees');
    });
  });

  testWidgets(
      'PreferencesSheet renders Firebase API Docs button and derived Gateway URL without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await SharedPreferences.getInstance().then(
      (prefs) => prefs.setString(
        'reset_api_base_url',
        'http://192.168.1.50:8000',
      ),
    );
    final storage = await AppStorage.create();
    final api = ApiClient(
      storage: storage,
      httpClient: MockClient((_) async => jsonMockResponse(<String, dynamic>{})),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AppStorage>.value(value: storage),
          Provider<ApiClient>.value(value: api),
          ChangeNotifierProvider<AppSettingsProvider>(
            create: (_) => AppSettingsProvider(storage),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.build(brightness: Brightness.light, locale: 'en'),
          home: const Scaffold(body: PreferencesSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Firebase API Docs'), findsOneWidget);
    await tester.tap(find.byTooltip('API Server URL'));
    await tester.pumpAndSettle();

    expect(
      find.text('Firebase Gateway: http://192.168.1.50:4000'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  group('RuntimeEndpointResolver zero-config mobile discovery', () {
    tearDown(() {
      AppConfig.clearDiscoveredEndpoints();
    });

    test('prefers reachable LAN IP + LAN Gateway on same Wi-Fi', () async {
      final mockHttp = MockClient((request) async {
        final full = request.url.toString();
        if (full == 'http://10.30.0.158:8000/api/v1/pages/about') {
          return jsonMockResponse(<String, dynamic>{
            'slug': 'about',
            'locale': 'en',
            'title': 'Form. Substance. Renewal.',
          });
        }
        if (full == 'http://10.30.0.158:4000/health') {
          return jsonMockResponse(<String, dynamic>{'status': 'ok'});
        }
        return jsonMockResponse(<String, dynamic>{}, 503);
      });

      final resolver = RuntimeEndpointResolver(
        httpClient: mockHttp,
        endpointsFetcher: () async => const DiscoveredRuntimeEndpoints(
          lanApiUrl: 'http://10.30.0.158:8000',
          lanGatewayUrl: 'http://10.30.0.158:4000',
          tunnelUrl: 'https://demo.trycloudflare.com',
        ),
      );

      final selected = await resolver.resolve(
        platformOverride: TargetPlatform.android,
        isWebOverride: false,
      );
      expect(selected, isNotNull);
      expect(selected!.backendUrl, 'http://10.30.0.158:8000');
      expect(selected.gatewayUrl, 'http://10.30.0.158:4000');
    });

    test(
        'falls back to Cloudflare HTTPS tunnel and skips :4000 timeout when LAN unreachable',
        () async {
      final mockHttp = MockClient((request) async {
        final full = request.url.toString();
        if (full == 'https://demo.trycloudflare.com/api/v1/pages/about') {
          expect(request.headers['Bypass-Tunnel-Reminder'], 'true');
          return jsonMockResponse(<String, dynamic>{
            'slug': 'about',
            'locale': 'en',
            'title': 'Form. Substance. Renewal.',
          });
        }
        return http.Response('Network unreachable', 504);
      });

      final resolver = RuntimeEndpointResolver(
        httpClient: mockHttp,
        localProbeTimeout: const Duration(milliseconds: 50),
        endpointsFetcher: () async =>
            DiscoveredRuntimeEndpoints.fromFirestoreDoc(<String, dynamic>{
          'key': 'runtime_endpoints',
          'value': <String, dynamic>{
            'lan_api_url': 'http://10.30.0.158:8000',
            'lan_gateway_url': 'http://10.30.0.158:4000',
            'tunnel_url': 'https://demo.trycloudflare.com/',
            'localtunnel_url': 'https://reset-store-cambodia.loca.lt',
          },
        }),
      );

      final selected = await resolver.resolve(
        platformOverride: TargetPlatform.android,
        isWebOverride: false,
      );
      expect(selected, isNotNull);
      expect(selected!.backendUrl, 'https://demo.trycloudflare.com');
      expect(selected.gatewayUrl, '');

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        AppConfig.setDiscoveredEndpoints(
          baseUrl: selected.backendUrl,
          firebaseBaseUrl: selected.gatewayUrl,
        );
        expect(AppConfig.resolveBaseUrl(null), 'https://demo.trycloudflare.com');
        expect(AppConfig.resolveFirebaseApiBaseUrl(null), '');
        expect(
          AppConfig.resolveFirebaseApiBaseUrl('https://demo.trycloudflare.com'),
          '',
        );
        expect(
          AppConfig.firebaseSwaggerDocsUrl(),
          'https://demo.trycloudflare.com/api/docs',
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    test(
        'ApiClient coalesces discovery before Home/Bootstrap and does not race 10.0.2.2',
        () async {
      var resolveCount = 0;
      final requestedUrls = <String>[];

      final probeHttp = MockClient((request) async {
        if (request.url.toString() ==
            'https://live-cf.trycloudflare.com/api/v1/pages/about') {
          return jsonMockResponse(<String, dynamic>{
            'slug': 'about',
            'title': 'Form. Substance. Renewal.',
          });
        }
        return http.Response('offline', 504);
      });

      final resolver = RuntimeEndpointResolver(
        httpClient: probeHttp,
        localProbeTimeout: const Duration(milliseconds: 20),
        endpointsFetcher: () async {
          resolveCount += 1;
          await Future<void>.delayed(const Duration(milliseconds: 25));
          return const DiscoveredRuntimeEndpoints(
            lanApiUrl: 'http://10.30.0.158:8000',
            tunnelUrl: 'https://live-cf.trycloudflare.com',
          );
        },
      );

      final apiHttp = MockClient((request) async {
        requestedUrls.add(request.url.toString());
        if (request.url.path == '/api/v1/bootstrap') {
          return jsonMockResponse(_sampleBootstrapPayload());
        }
        if (request.url.path == '/api/v1/home') {
          return jsonMockResponse(_sampleHomePayload());
        }
        return jsonMockResponse(<String, dynamic>{}, 404);
      });

      final storage = await AppStorage.create();
      final client = ApiClient(
        storage: storage,
        httpClient: apiHttp,
        runtimeEndpointResolver: resolver,
      );

      final results = await Future.wait<Object>(<Future<Object>>[
        client.getBootstrap(),
        client.getHome(),
      ]);

      expect(resolveCount, 1);
      expect(results[0], isA<BootstrapResponse>());
      expect(results[1], isA<HomeResponse>());
      expect(requestedUrls, <String>[
        'https://live-cf.trycloudflare.com/api/v1/bootstrap',
        'https://live-cf.trycloudflare.com/api/v1/home',
      ]);
    });
  });
}
