import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AppStorage {
  AppStorage(this._prefs);

  static const String _keyLocale = 'reset_locale';
  static const String _keyCurrency = 'reset_currency';
  static const String _keyThemeMode = 'reset_theme_mode';
  static const String _keyAuthToken = 'reset_auth_token';
  static const String _keyUserJson = 'reset_user_json';
  static const String _keyCartToken = 'reset_cart_token';
  static const String _keyOrderTokens = 'reset_order_tokens';
  static const String _keyBaseUrl = 'reset_api_base_url';

  final SharedPreferences _prefs;

  static Future<AppStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return AppStorage(prefs);
  }

  String getLocale() {
    final value = _prefs.getString(_keyLocale);
    return value == 'km' ? 'km' : 'en';
  }

  Future<void> setLocale(String locale) async {
    await _prefs.setString(_keyLocale, locale == 'km' ? 'km' : 'en');
  }

  String getCurrency() {
    final value = _prefs.getString(_keyCurrency);
    return value == 'USD' ? 'USD' : 'KHR';
  }

  Future<void> setCurrency(String currency) async {
    await _prefs.setString(_keyCurrency, currency == 'USD' ? 'USD' : 'KHR');
  }

  String getThemeMode() {
    final value = _prefs.getString(_keyThemeMode);
    return value == 'dark' ? 'dark' : 'light';
  }

  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(_keyThemeMode, mode == 'dark' ? 'dark' : 'light');
  }

  String? getAuthToken() {
    final token = _prefs.getString(_keyAuthToken);
    if (token == null || token.trim().isEmpty) {
      return null;
    }
    return token;
  }

  Future<void> setAuthToken(String? token) async {
    if (token == null || token.trim().isEmpty) {
      await _prefs.remove(_keyAuthToken);
      return;
    }
    await _prefs.setString(_keyAuthToken, token.trim());
  }

  Map<String, dynamic>? getUserJson() {
    final raw = _prefs.getString(_keyUserJson);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<void> setUserJson(Map<String, dynamic>? user) async {
    if (user == null) {
      await _prefs.remove(_keyUserJson);
      return;
    }
    await _prefs.setString(_keyUserJson, jsonEncode(user));
  }

  Future<void> clearAuth() async {
    await _prefs.remove(_keyAuthToken);
    await _prefs.remove(_keyUserJson);
  }

  String? getCartToken() {
    final token = _prefs.getString(_keyCartToken);
    if (token == null || token.trim().isEmpty) {
      return null;
    }
    return token;
  }

  Future<void> setCartToken(String? token) async {
    if (token == null || token.trim().isEmpty) {
      await _prefs.remove(_keyCartToken);
      return;
    }
    await _prefs.setString(_keyCartToken, token.trim());
  }

  Map<String, String> getOrderTokens() {
    final raw = _prefs.getString(_keyOrderTokens);
    if (raw == null || raw.isEmpty) {
      return <String, String>{};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        );
      }
    } catch (_) {
      return <String, String>{};
    }
    return <String, String>{};
  }

  String? getOrderToken(String orderNumber) {
    return getOrderTokens()[orderNumber];
  }

  Future<void> saveOrderToken(String orderNumber, String token) async {
    if (orderNumber.trim().isEmpty || token.trim().isEmpty) {
      return;
    }
    final current = getOrderTokens();
    current[orderNumber.trim()] = token.trim();
    // Keep last 25 order tokens to bound storage footprint
    if (current.length > 25) {
      final keysToRemove = current.keys.take(current.length - 25).toList();
      for (final key in keysToRemove) {
        current.remove(key);
      }
    }
    await _prefs.setString(_keyOrderTokens, jsonEncode(current));
  }

  String? getCustomBaseUrl() {
    final value = _prefs.getString(_keyBaseUrl);
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value.trim();
  }

  Future<void> setCustomBaseUrl(String? url) async {
    if (url == null || url.trim().isEmpty) {
      await _prefs.remove(_keyBaseUrl);
      return;
    }
    await _prefs.setString(_keyBaseUrl, url.trim());
  }
}
