import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:reset_store/core/api/api_client.dart';
import 'package:reset_store/core/firebase/firestore_storefront_service.dart';
import 'package:reset_store/core/storage/app_storage.dart';
import 'package:reset_store/firebase_options.dart';
import 'package:reset_store/providers/bootstrap_provider.dart';
import 'test_helpers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('DefaultFirebaseOptions targets reset-store-ecommerce project', () {
    expect(DefaultFirebaseOptions.web.projectId, 'reset-store-ecommerce');
    expect(DefaultFirebaseOptions.android.projectId, 'reset-store-ecommerce');
    expect(DefaultFirebaseOptions.ios.projectId, 'reset-store-ecommerce');
    expect(
      DefaultFirebaseOptions.ios.iosBundleId,
      'store.reset.resetStore',
    );
  });

  test('FirestoreStorefrontService degrades safely when Firebase is uninitialized',
      () async {
    expect(Firebase.apps, isEmpty);
    final service = FirestoreStorefrontService();
    expect(service.isAvailable, isFalse);
    expect(await service.fetchCategories(), isEmpty);
    expect(await service.watchPublicSettings().toList(), isEmpty);
    expect(await service.watchPublishedProducts().toList(), isEmpty);
    expect(await service.watchApprovedReviews(1).toList(), isEmpty);
  });

  test('BootstrapProvider falls back cleanly to REST when Firestore is offline',
      () async {
    final storage = await AppStorage.create();
    final apiClient = ApiClient(
      storage: storage,
      httpClient: MockClient(
        (_) async => jsonMockResponse(<String, dynamic>{
          'app': {
            'name': 'RESET Store',
            'tagline': 'Start Fresh',
            'currency': 'KHR',
            'locale': 'en',
          },
          'settings': {
            'store_name': 'RESET Store',
            'exchange_rate': 4100,
            'free_shipping_threshold': 200000,
            'formatted_free_shipping_threshold': '200,000 ៛',
            'announcement_banner': 'Free delivery over 200,000 ៛',
            'announcement_banner_en': 'Free delivery over 200,000 ៛',
            'announcement_banner_km': 'ដឹកជញ្ជូនឥតគិតថ្លៃ',
            'bakong_mock': true,
            'provinces': ['Phnom Penh'],
          },
          'categories': const [],
          'size_guide': {
            'title': 'Size Guide',
            'subtitle': 'Flat measurements',
            'fit_note_title': 'Fit',
            'fit_note_body': 'Relaxed',
            'tip': 'True to size',
            'tables': const [],
            'how_to_measure_title': 'Measure',
            'how_to_measure': const [],
          },
          'pages': const [],
          'user': null,
          'cart': null,
        }),
      ),
    );

    final provider = BootstrapProvider(apiClient);
    await provider.loadBootstrap();

    expect(provider.isFirestoreLive, isFalse);
    expect(provider.exchangeRate, 4100);
    expect(provider.freeShippingThreshold, 200000);
    provider.dispose();
  });
}
