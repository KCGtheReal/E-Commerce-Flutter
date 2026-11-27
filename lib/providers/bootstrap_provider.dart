import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/api/api_exceptions.dart';
import '../core/firebase/firestore_storefront_service.dart';
import '../models/bootstrap_page_models.dart';
import '../models/catalog_models.dart';

class BootstrapProvider extends ChangeNotifier {
  BootstrapProvider(
    this._apiClient, {
    FirestoreStorefrontService? firestoreService,
  }) : _firestoreService = firestoreService ?? FirestoreStorefrontService();

  final ApiClient _apiClient;
  final FirestoreStorefrontService _firestoreService;

  StreamSubscription<Map<String, dynamic>>? _firestoreSettingsSub;
  StreamSubscription<List<Map<String, dynamic>>>? _firestoreProductsSub;
  Map<String, dynamic> _firestoreSettings = const <String, dynamic>{};
  int? _firestorePublishedProductCount;

  static const List<String> defaultCambodiaProvinces = <String>[
    'Phnom Penh',
    'Kandal',
    'Siem Reap',
    'Preah Sihanouk',
    'Battambang',
    'Kampong Cham',
    'Kampong Chhnang',
    'Kampong Speu',
    'Kampong Thom',
    'Kampot',
    'Kep',
    'Koh Kong',
    'Kratie',
    'Mondulkiri',
    'Oddar Meanchey',
    'Pailin',
    'Preah Vihear',
    'Prey Veng',
    'Pursat',
    'Ratanakiri',
    'Stung Treng',
    'Svay Rieng',
    'Takeo',
    'Tboung Khmum',
    'Banteay Meanchey',
  ];

  BootstrapResponse? _data;
  bool _isLoading = false;
  String? _errorMessage;

  BootstrapResponse? get data => _data;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  StoreBootstrapSettingsDto? get settings => _data?.settings;
  List<CategoryDto> get categories => _data?.categories ?? const <CategoryDto>[];
  SizeGuideDataDto? get sizeGuide => _data?.sizeGuide;
  List<PageSummaryDto> get pages => _data?.pages ?? const <PageSummaryDto>[];

  bool get isFirestoreLive => _firestoreService.isAvailable;
  int? get firestorePublishedProductCount => _firestorePublishedProductCount;

  int get exchangeRate =>
      _parsePositiveInt(_firestoreSettings['exchange_rate']) ??
      _data?.settings.exchangeRate ??
      4100;
  int get freeShippingThreshold =>
      _parsePositiveInt(_firestoreSettings['free_shipping_threshold']) ??
      _data?.settings.freeShippingThreshold ??
      200000;
  String get formattedFreeShippingThreshold =>
      _data?.settings.formattedFreeShippingThreshold ?? '200,000 ៛';
  bool get bakongMock => _data?.settings.bakongMock ?? false;

  List<String> get provinces {
    final remote = _data?.settings.provinces;
    if (remote != null && remote.isNotEmpty) {
      return remote;
    }
    return defaultCambodiaProvinces;
  }

  String announcementBanner(String locale) {
    final liveKm = _firestoreSettings['announcement_banner_km']?.toString();
    final liveEn = _firestoreSettings['announcement_banner_en']?.toString();
    if (locale == 'km' && liveKm != null && liveKm.isNotEmpty) {
      return liveKm;
    }
    if (locale == 'en' && liveEn != null && liveEn.isNotEmpty) {
      return liveEn;
    }

    final s = _data?.settings;
    if (s == null) {
      return locale == 'km'
          ? 'ដឹកជញ្ជូនឥតគិតថ្លៃទូទាំងប្រទេសសម្រាប់ការបញ្ជាទិញចាប់ពី 200,000 ៛ • ទូទាត់ភ្លាមៗតាមបាគង KHQR'
          : 'Free nationwide delivery on orders over 200,000 ៛ • Instant Bakong KHQR Checkout';
    }
    if (locale == 'km' && s.announcementBannerKm.isNotEmpty) {
      return s.announcementBannerKm;
    }
    if (locale == 'en' && s.announcementBannerEn.isNotEmpty) {
      return s.announcementBannerEn;
    }
    return s.announcementBanner;
  }

  Future<BootstrapResponse?> loadBootstrap({bool silent = false}) async {
    _startFirestoreListenersIfNeeded();
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }
    try {
      final response = await _apiClient.getBootstrap();
      _data = response;
      _errorMessage = null;
      return response;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return null;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startFirestoreListenersIfNeeded() {
    if (!_firestoreService.isAvailable) {
      return;
    }
    _firestoreSettingsSub ??= _firestoreService.watchPublicSettings().listen(
      (settingsMap) {
        if (settingsMap.isEmpty) {
          return;
        }
        _firestoreSettings = settingsMap;
        notifyListeners();
      },
      onError: (Object error) {
        debugPrint('Firestore settings stream warning: $error');
      },
    );
    _firestoreProductsSub ??=
        _firestoreService.watchPublishedProducts().listen(
      (products) {
        _firestorePublishedProductCount = products.length;
        notifyListeners();
      },
      onError: (Object error) {
        debugPrint('Firestore products stream warning: $error');
      },
    );
  }

  int? _parsePositiveInt(Object? raw) {
    if (raw is int && raw > 0) {
      return raw;
    }
    if (raw is num && raw > 0) {
      return raw.round();
    }
    if (raw is String) {
      final parsed = int.tryParse(raw.trim());
      if (parsed != null && parsed > 0) {
        return parsed;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _firestoreSettingsSub?.cancel();
    _firestoreProductsSub?.cancel();
    super.dispose();
  }
}
