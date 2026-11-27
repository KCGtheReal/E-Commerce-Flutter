import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/bootstrap_page_models.dart';
import '../../models/catalog_models.dart';
import '../config/app_config.dart';
import '../utils/json_helpers.dart';

class FirebasePublicSettingsResponse {
  const FirebasePublicSettingsResponse({
    required this.source,
    required this.cached,
    required this.locale,
    required this.currency,
    required this.data,
    required this.raw,
  });

  final String source;
  final bool cached;
  final String locale;
  final String currency;
  final StoreBootstrapSettingsDto data;
  final Map<String, dynamic> raw;

  factory FirebasePublicSettingsResponse.fromJson(Map<String, dynamic> json) {
    return FirebasePublicSettingsResponse(
      source: asString(json['source'], fallback: 'firebase'),
      cached: asBool(json['cached']),
      locale: asString(json['locale'], fallback: 'en'),
      currency: asString(json['currency'], fallback: 'KHR'),
      data: StoreBootstrapSettingsDto.fromJson(asMap(json['data'])),
      raw: asMap(json['raw']),
    );
  }
}

class FirebaseGatewayHealth {
  const FirebaseGatewayHealth({
    required this.status,
    required this.service,
    required this.source,
    required this.projectId,
    required this.databaseId,
    required this.region,
    required this.firestoreConnected,
    required this.cacheEnabled,
    required this.cacheEntries,
    required this.uptimeSeconds,
    required this.timestamp,
  });

  final String status;
  final String service;
  final String source;
  final String projectId;
  final String databaseId;
  final String region;
  final bool firestoreConnected;
  final bool cacheEnabled;
  final int cacheEntries;
  final double uptimeSeconds;
  final String timestamp;

  bool get isHealthy => status == 'ok' && firestoreConnected;

  factory FirebaseGatewayHealth.fromJson(Map<String, dynamic> json) {
    return FirebaseGatewayHealth(
      status: asString(json['status'], fallback: 'degraded'),
      service: asString(json['service'], fallback: 'reset-firebase-gateway'),
      source: asString(json['source'], fallback: 'firebase'),
      projectId: asString(json['project_id']),
      databaseId: asString(json['database_id'], fallback: '(default)'),
      region: asString(json['region']),
      firestoreConnected: asBool(json['firestore_connected']),
      cacheEnabled: asBool(json['cache_enabled']),
      cacheEntries: asInt(json['cache_entries']),
      uptimeSeconds: asDouble(json['uptime_seconds']),
      timestamp: asString(json['timestamp']),
    );
  }
}

/// Standalone client for the Node.js + Fastify Firebase Cloud Firestore Gateway
/// (`API/`, default port `4000`).
///
/// All storefront read methods safely return `null` on network errors,
/// timeouts, malformed payloads, or non-2xx responses so [ApiClient] can fall
/// back transparently to the authoritative Laravel `/api/v1/*` backend.
class FirebaseGatewayClient {
  FirebaseGatewayClient({
    http.Client? httpClient,
    String Function()? localeResolver,
    String Function()? currencyResolver,
    String Function()? baseUrlResolver,
    Duration timeout = defaultTimeout,
  })  : _httpClient = httpClient ?? http.Client(),
        _localeResolver = localeResolver,
        _currencyResolver = currencyResolver,
        _baseUrlResolver = baseUrlResolver,
        _timeout = timeout;

  static const Duration defaultTimeout = Duration(seconds: 3);

  static const String apiPrefix = '/api/firebase';
  static const String healthPath = '/health';
  static const String bootstrapPath = '$apiPrefix/bootstrap';
  static const String homePath = '$apiPrefix/home';
  static const String productsPath = '$apiPrefix/products';
  static const String searchSuggestPath = '$apiPrefix/search/suggest';
  static const String settingsPath = '$apiPrefix/settings';

  static String productDetailPath(String slug) =>
      '$productsPath/${Uri.encodeComponent(slug)}';

  final http.Client _httpClient;
  String Function()? _localeResolver;
  String Function()? _currencyResolver;
  String Function()? _baseUrlResolver;
  final Duration _timeout;

  void attachContext({
    String Function()? localeResolver,
    String Function()? currencyResolver,
    String Function()? baseUrlResolver,
  }) {
    _localeResolver ??= localeResolver;
    _currencyResolver ??= currencyResolver;
    _baseUrlResolver ??= baseUrlResolver;
  }

  String get currentBaseUrl {
    if (_baseUrlResolver != null) {
      return _normalizeBaseUrl(_baseUrlResolver!());
    }
    return AppConfig.resolveFirebaseApiBaseUrl(null);
  }

  String get swaggerDocsUrl => '$currentBaseUrl/docs';

  Future<BootstrapResponse?> getBootstrap() async {
    final json = await _getJson(bootstrapPath);
    if (json == null || json['settings'] is! Map) {
      return null;
    }
    try {
      return BootstrapResponse.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<HomeResponse?> getHome() async {
    final json = await _getJson(homePath);
    if (json == null ||
        (!json.containsKey('categories') &&
            !json.containsKey('featured_products'))) {
      return null;
    }
    try {
      return HomeResponse.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<ProductsResponse?> getProducts([
    ProductsQuery query = const ProductsQuery(),
  ]) async {
    final json = await _getJson(
      productsPath,
      queryParameters: query.toQueryParameters(),
    );
    if (json == null || json['data'] is! List || json['meta'] is! Map) {
      return null;
    }
    try {
      return ProductsResponse.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<SearchSuggestResponse?> searchSuggest(String query) async {
    final trimmed = query.trim();
    final json = await _getJson(
      searchSuggestPath,
      queryParameters: <String, dynamic>{
        if (trimmed.isNotEmpty) 'q': trimmed,
      },
    );
    if (json == null || json['products'] is! List) {
      return null;
    }
    try {
      return SearchSuggestResponse.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<ProductDetailResponse?> getProductDetail(String slug) async {
    final trimmed = slug.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final json = await _getJson(productDetailPath(trimmed));
    if (json == null || json['product'] is! Map) {
      return null;
    }
    try {
      return ProductDetailResponse.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<FirebasePublicSettingsResponse?> getSettings() async {
    final json = await _getJson(settingsPath);
    if (json == null || json['data'] is! Map) {
      return null;
    }
    try {
      return FirebasePublicSettingsResponse.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<FirebaseGatewayHealth?> checkHealth({bool ping = false}) async {
    final json = await _getJson(
      healthPath,
      queryParameters: ping ? const <String, dynamic>{'ping': '1'} : null,
    );
    if (json == null || json['status'] == null) {
      return null;
    }
    try {
      return FirebaseGatewayHealth.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Map<String, String> _buildHeaders() {
    final rawLocale = (_localeResolver?.call() ?? 'en').trim().toLowerCase();
    final locale = rawLocale == 'km' ? 'km' : 'en';
    final rawCurrency =
        (_currencyResolver?.call() ?? 'KHR').trim().toUpperCase();
    final currency = rawCurrency == 'USD' ? 'USD' : 'KHR';

    return <String, String>{
      'Accept': 'application/json',
      'X-Locale': locale,
      'Accept-Language': locale,
      'X-Currency': currency,
    };
  }

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final base = Uri.parse(currentBaseUrl);
    final combinedPath = '${base.path}$path'.replaceAll('//', '/');
    return base.replace(
      path: combinedPath,
      queryParameters: (queryParameters == null || queryParameters.isEmpty)
          ? null
          : queryParameters,
    );
  }

  Future<Map<String, dynamic>?> _getJson(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final baseUrl = currentBaseUrl;
    if (baseUrl.isEmpty) {
      return null;
    }
    try {
      final uri = _buildUri(path, queryParameters);
      final response = await _httpClient
          .get(uri, headers: _buildHeaders())
          .timeout(_timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final bodyText = response.bodyBytes.isNotEmpty
          ? utf8.decode(response.bodyBytes)
          : response.body;
      if (bodyText.trim().isEmpty) {
        return null;
      }

      final decoded = asMap(jsonDecode(bodyText));
      if (decoded.isEmpty) {
        return null;
      }
      return decoded;
    } catch (_) {
      return null;
    }
  }

  static String _normalizeBaseUrl(String url) {
    var normalized = url.trim();
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }
}
