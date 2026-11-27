import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  static const String definedApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String definedFirebaseApiBaseUrl = String.fromEnvironment(
    'FIREBASE_API_URL',
    defaultValue: '',
  );

  static String get defaultBaseUrl {
    final envUrl = definedApiBaseUrl.trim();
    if (envUrl.isNotEmpty) {
      return _normalizeBaseUrl(envUrl);
    }

    if (kIsWeb) {
      final host = Uri.base.host.toLowerCase();
      if (host.isEmpty || host == 'localhost' || host == '127.0.0.1') {
        return 'http://127.0.0.1:8000';
      }
      if (Uri.base.hasScheme && Uri.base.host.isNotEmpty) {
        return _normalizeBaseUrl(Uri.base.origin);
      }
      return 'http://127.0.0.1:8000';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }

    return 'http://127.0.0.1:8000';
  }

  static String resolveBaseUrl(String? overrideBaseUrl) {
    final trimmed = overrideBaseUrl?.trim() ?? '';
    if (trimmed.isNotEmpty) {
      return _normalizeBaseUrl(trimmed);
    }
    return defaultBaseUrl;
  }

  static String defaultFirebaseApiBaseUrl() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:4000';
    }
    return 'http://127.0.0.1:4000';
  }

  static String resolveFirebaseApiBaseUrl(
    String? savedBackendUrl, {
    String? customFirebaseApiUrl,
  }) {
    final customOverride = customFirebaseApiUrl?.trim() ?? '';
    if (customOverride.isNotEmpty) {
      return _normalizeBaseUrl(customOverride);
    }

    final envUrl = definedFirebaseApiBaseUrl.trim();
    if (envUrl.isNotEmpty) {
      return _normalizeBaseUrl(envUrl);
    }

    final backendTrimmed = savedBackendUrl?.trim() ?? '';
    if (backendTrimmed.isNotEmpty) {
      final parsed = Uri.tryParse(backendTrimmed);
      if (parsed != null && parsed.hasScheme && parsed.host.isNotEmpty) {
        final hostLower = parsed.host.toLowerCase();
        const localHosts = <String>{'127.0.0.1', 'localhost', '10.0.2.2'};
        if (!localHosts.contains(hostLower)) {
          return Uri(
            scheme: 'http',
            host: parsed.host,
            port: 4000,
          ).toString();
        }
      }
    }

    return defaultFirebaseApiBaseUrl();
  }

  static String resolveUrl(String? rawUrl, {String? baseUrl}) {
    final value = rawUrl?.trim() ?? '';
    if (value.isEmpty) {
      return '';
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    final resolvedBase = resolveBaseUrl(baseUrl);
    if (value.startsWith('/')) {
      return '$resolvedBase$value';
    }
    return '$resolvedBase/$value';
  }

  static String adminPanelUrl({String? baseUrl}) {
    return '${resolveBaseUrl(baseUrl)}/admin';
  }

  static String openApiDocsUrl({String? baseUrl}) {
    return '${resolveBaseUrl(baseUrl)}/api/docs';
  }

  static String firebaseSwaggerDocsUrl({
    String? baseUrl,
    String? customFirebaseApiUrl,
  }) {
    return '${resolveFirebaseApiBaseUrl(baseUrl, customFirebaseApiUrl: customFirebaseApiUrl)}/docs';
  }

  static String webInvoiceUrl(
    String orderNumber, {
    String? orderToken,
    String? baseUrl,
  }) {
    final base = resolveBaseUrl(baseUrl);
    final encodedOrder = Uri.encodeComponent(orderNumber);
    if (orderToken != null && orderToken.isNotEmpty) {
      return '$base/orders/$encodedOrder/invoice?order_token=${Uri.encodeQueryComponent(orderToken)}';
    }
    return '$base/orders/$encodedOrder/invoice';
  }

  static String _normalizeBaseUrl(String url) {
    var normalized = url.trim();
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }
}
