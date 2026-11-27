import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/api/api_exceptions.dart';
import '../core/storage/app_storage.dart';
import '../models/auth_account_models.dart';
import 'cart_provider.dart';
import 'wishlist_provider.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required ApiClient apiClient,
    required AppStorage storage,
    CartProvider? cartProvider,
    WishlistProvider? wishlistProvider,
  })  : _apiClient = apiClient,
        _storage = storage,
        _cartProvider = cartProvider,
        _wishlistProvider = wishlistProvider {
    _token = _storage.getAuthToken();
    final cachedUser = _storage.getUserJson();
    if (cachedUser != null && _token != null) {
      _user = UserDto.fromJson(cachedUser);
    }
  }

  final ApiClient _apiClient;
  final AppStorage _storage;
  CartProvider? _cartProvider;
  WishlistProvider? _wishlistProvider;

  UserDto? _user;
  String? _token;
  bool _isLoading = false;
  bool _isInitialized = false;

  UserDto? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _user != null;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  void attachDependencies({
    CartProvider? cartProvider,
    WishlistProvider? wishlistProvider,
  }) {
    _cartProvider = cartProvider ?? _cartProvider;
    _wishlistProvider = wishlistProvider ?? _wishlistProvider;
  }

  void hydrateFromBootstrap(UserDto? bootstrapUser) {
    if (_token != null && bootstrapUser != null) {
      _user = bootstrapUser;
      _storage.setUserJson(bootstrapUser.toJson());
      notifyListeners();
    } else if (bootstrapUser == null && _token != null) {
      // Token expired or invalid on server
      _token = null;
      _user = null;
      _storage.clearAuth();
      _wishlistProvider?.clear();
      notifyListeners();
    }
  }

  Future<void> init({bool skipUserRefresh = false}) async {
    if (_token == null) {
      _isInitialized = true;
      notifyListeners();
      return;
    }
    try {
      if (!skipUserRefresh || _user == null) {
        final fetchedUser = await _apiClient.me();
        _user = fetchedUser;
      }
      await _wishlistProvider?.loadWishlist(silent: true);
    } on ApiException catch (e) {
      if (e.isUnauthenticated) {
        await handleUnauthorized();
      }
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _apiClient.login(
        LoginRequest(email: email.trim(), password: password),
      );
      _token = res.token;
      _user = res.user;
      _cartProvider?.hydrateFromPayload(res.cart);
      await _wishlistProvider?.loadWishlist(silent: true);
      return res;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AuthResponse> register(RegisterRequest request) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _apiClient.register(request);
      _token = res.token;
      _user = res.user;
      _cartProvider?.hydrateFromPayload(res.cart);
      await _wishlistProvider?.loadWishlist(silent: true);
      return res;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiClient.logout();
    } catch (_) {
      await _storage.clearAuth();
    } finally {
      _token = null;
      _user = null;
      _wishlistProvider?.clear();
      _isLoading = false;
      notifyListeners();
    }
    await _cartProvider?.refreshCart(silent: true);
  }

  Future<ForgotPasswordResponse> forgotPassword(String email) async {
    _isLoading = true;
    notifyListeners();
    try {
      return await _apiClient.forgotPassword(email);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UpdateProfileResponse> updateProfile({
    required String name,
    String? phone,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _apiClient.updateProfile(
        UpdateProfileRequest(name: name.trim(), phone: phone?.trim()),
      );
      _user = res.user;
      return res;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> updatePassword(UpdatePasswordRequest request) async {
    _isLoading = true;
    notifyListeners();
    try {
      return await _apiClient.updatePassword(request);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> handleUnauthorized() async {
    _token = null;
    _user = null;
    await _storage.clearAuth();
    _wishlistProvider?.clear();
    notifyListeners();
  }
}
