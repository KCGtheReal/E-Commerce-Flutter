import 'package:flutter/material.dart';

import '../core/storage/app_storage.dart';
import '../l10n/app_strings.dart';

class AppSettingsProvider extends ChangeNotifier {
  AppSettingsProvider(this._storage)
      : _locale = _storage.getLocale(),
        _currency = _storage.getCurrency(),
        _themeMode = _storage.getThemeMode() == 'dark'
            ? ThemeMode.dark
            : ThemeMode.light,
        _customBaseUrl = _storage.getCustomBaseUrl();

  final AppStorage _storage;

  String _locale;
  String _currency;
  ThemeMode _themeMode;
  String? _customBaseUrl;

  String get locale => _locale;
  String get currency => _currency;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isKm => _locale == 'km';
  String? get customBaseUrl => _customBaseUrl;
  AppStrings get strings => AppStrings(_locale);

  Future<void> setLocale(String locale) async {
    final normalized = locale == 'km' ? 'km' : 'en';
    if (_locale == normalized) {
      return;
    }
    _locale = normalized;
    await _storage.setLocale(normalized);
    notifyListeners();
  }

  Future<void> toggleLocale() async {
    await setLocale(_locale == 'en' ? 'km' : 'en');
  }

  Future<void> setCurrency(String currency) async {
    final normalized = currency.toUpperCase() == 'USD' ? 'USD' : 'KHR';
    if (_currency == normalized) {
      return;
    }
    _currency = normalized;
    await _storage.setCurrency(normalized);
    notifyListeners();
  }

  Future<void> toggleCurrency() async {
    await setCurrency(_currency == 'KHR' ? 'USD' : 'KHR');
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) {
      return;
    }
    _themeMode = mode;
    await _storage.setThemeMode(mode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    await setThemeMode(
      _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }

  Future<void> setCustomBaseUrl(String? url) async {
    final trimmed = url?.trim();
    _customBaseUrl = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    await _storage.setCustomBaseUrl(_customBaseUrl);
    notifyListeners();
  }
}
