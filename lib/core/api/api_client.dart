import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../models/auth_account_models.dart';
import '../../models/bootstrap_page_models.dart';
import '../../models/cart_models.dart';
import '../../models/catalog_models.dart';
import '../../models/order_payment_models.dart';
import '../config/app_config.dart';
import '../firebase/firebase_gateway_client.dart';
import '../firebase/runtime_endpoint_resolver.dart';
import '../storage/app_storage.dart';
import '../utils/json_helpers.dart';
import 'api_endpoints.dart';
import 'api_exceptions.dart';

class ApiClient {
  ApiClient({
    required this.storage,
    http.Client? httpClient,
    FirebaseGatewayClient? firebaseGatewayClient,
    RuntimeEndpointResolver? runtimeEndpointResolver,
    String Function()? localeResolver,
    String Function()? currencyResolver,
    String? Function()? baseUrlResolver,
    VoidCallback? onUnauthorized,
  })  : _httpClient = httpClient ?? http.Client(),
        _hasInjectedHttpClient = httpClient != null,
        _runtimeEndpointResolver = runtimeEndpointResolver,
        _localeResolver = localeResolver,
        _currencyResolver = currencyResolver,
        _baseUrlResolver = baseUrlResolver,
        _onUnauthorized = onUnauthorized {
    if (firebaseGatewayClient != null) {
      firebaseGatewayClient.attachContext(
        localeResolver: _resolveLocale,
        currencyResolver: _resolveCurrency,
        baseUrlResolver: () => currentFirebaseBaseUrl,
      );
      _firebaseGateway = firebaseGatewayClient;
    } else if (httpClient == null) {
      _firebaseGateway = FirebaseGatewayClient(
        localeResolver: _resolveLocale,
        currencyResolver: _resolveCurrency,
        baseUrlResolver: () => currentFirebaseBaseUrl,
      );
    } else {
      _firebaseGateway = null;
    }
  }

  final AppStorage storage;
  final http.Client _httpClient;
  final bool _hasInjectedHttpClient;
  final RuntimeEndpointResolver? _runtimeEndpointResolver;
  late final FirebaseGatewayClient? _firebaseGateway;
  bool _runtimeDiscoveryAttempted = false;
  Future<void>? _inFlightDiscovery;
  String Function()? _localeResolver;
  String Function()? _currencyResolver;
  String? Function()? _baseUrlResolver;
  VoidCallback? _onUnauthorized;

  static const Duration defaultTimeout = Duration(seconds: 15);

  void attachContext({
    String Function()? localeResolver,
    String Function()? currencyResolver,
    String? Function()? baseUrlResolver,
    VoidCallback? onUnauthorized,
  }) {
    _localeResolver = localeResolver ?? _localeResolver;
    _currencyResolver = currencyResolver ?? _currencyResolver;
    _baseUrlResolver = baseUrlResolver ?? _baseUrlResolver;
    _onUnauthorized = onUnauthorized ?? _onUnauthorized;
  }

  String _resolveLocale() => _localeResolver?.call() ?? storage.getLocale();

  String _resolveCurrency() =>
      _currencyResolver?.call() ?? storage.getCurrency();

  FirebaseGatewayClient? get firebaseGateway => _firebaseGateway;

  String get currentBaseUrl => AppConfig.resolveBaseUrl(
        _baseUrlResolver?.call() ?? storage.getCustomBaseUrl(),
      );

  String get currentFirebaseBaseUrl => AppConfig.resolveFirebaseApiBaseUrl(
        _baseUrlResolver?.call() ?? storage.getCustomBaseUrl(),
      );

  String resolveMediaUrl(String? rawUrl) {
    return AppConfig.resolveUrl(rawUrl, baseUrl: currentBaseUrl);
  }

  String get adminPanelUrl => AppConfig.adminPanelUrl(baseUrl: currentBaseUrl);

  String get openApiDocsUrl =>
      AppConfig.openApiDocsUrl(baseUrl: currentBaseUrl);

  String get firebaseSwaggerDocsUrl => AppConfig.firebaseSwaggerDocsUrl(
        baseUrl: _baseUrlResolver?.call() ?? storage.getCustomBaseUrl(),
      );

  /// Discovers the PC backend URL (Wi-Fi LAN IP or live Cloudflare tunnel)
  /// from Cloud Firestore on native builds when no manual URL override is set.
  Future<void> resolveRuntimeEndpointsIfNeeded({bool force = false}) async {
    if (kIsWeb ||
        AppConfig.hasBuildDefinedApiUrl ||
        (_hasInjectedHttpClient && _runtimeEndpointResolver == null)) {
      return;
    }
    final customUrl =
        (_baseUrlResolver?.call() ?? storage.getCustomBaseUrl())?.trim() ?? '';
    if (customUrl.isNotEmpty) {
      return;
    }
    if (_runtimeDiscoveryAttempted &&
        !force &&
        AppConfig.discoveredBaseUrl != null) {
      return;
    }
    if (!force && _inFlightDiscovery != null) {
      await _inFlightDiscovery;
      return;
    }
    if (force && _inFlightDiscovery != null) {
      await _inFlightDiscovery;
    }

    final future = _runRuntimeDiscovery(force: force);
    _inFlightDiscovery = future;
    try {
      await future;
    } finally {
      if (identical(_inFlightDiscovery, future)) {
        _inFlightDiscovery = null;
      }
    }
  }

  Future<void> _runRuntimeDiscovery({required bool force}) async {
    _runtimeDiscoveryAttempted = true;
    final resolver = _runtimeEndpointResolver ?? RuntimeEndpointResolver();
    final resolved = await resolver.resolve();
    if (resolved != null) {
      AppConfig.setDiscoveredEndpoints(
        baseUrl: resolved.backendUrl,
        firebaseBaseUrl: resolved.gatewayUrl,
      );
    } else if (force) {
      AppConfig.clearDiscoveredEndpoints();
    }
  }

  String webInvoiceUrl(String orderNumber) {
    return AppConfig.webInvoiceUrl(
      orderNumber,
      orderToken: storage.getOrderToken(orderNumber),
      baseUrl: currentBaseUrl,
    );
  }

  // ---------------------------------------------------------------------------
  // Store Bootstrap, Home & Catalog
  // ---------------------------------------------------------------------------

  Future<BootstrapResponse> getBootstrap() async {
    await resolveRuntimeEndpointsIfNeeded();
    try {
      final json = await _requestJson('GET', ApiEndpoints.bootstrap);
      final res = BootstrapResponse.fromJson(json);
      final cartToken = res.cart?.cartToken;
      if (cartToken != null && cartToken.isNotEmpty) {
        await storage.setCartToken(cartToken);
      }
      return res;
    } on ApiException {
      final gateway = _firebaseGateway;
      if (gateway != null) {
        final firebaseRes = await gateway.getBootstrap();
        if (firebaseRes != null) {
          return firebaseRes;
        }
      }
      rethrow;
    }
  }

  Future<HomeResponse> getHome() async {
    await resolveRuntimeEndpointsIfNeeded();
    final gateway = _firebaseGateway;
    if (gateway != null) {
      final firebaseRes = await gateway.getHome();
      if (firebaseRes != null) {
        return firebaseRes;
      }
    }
    final json = await _requestJson('GET', ApiEndpoints.home);
    return HomeResponse.fromJson(json);
  }

  Future<ProductsResponse> getProducts([
    ProductsQuery query = const ProductsQuery(),
  ]) async {
    await resolveRuntimeEndpointsIfNeeded();
    final gateway = _firebaseGateway;
    if (gateway != null) {
      final firebaseRes = await gateway.getProducts(query);
      if (firebaseRes != null) {
        return firebaseRes;
      }
    }
    final json = await _requestJson(
      'GET',
      ApiEndpoints.products,
      queryParameters: query.toQueryParameters(),
    );
    return ProductsResponse.fromJson(json);
  }

  Future<SearchSuggestResponse> searchSuggest(String query) async {
    await resolveRuntimeEndpointsIfNeeded();
    final gateway = _firebaseGateway;
    if (gateway != null) {
      final firebaseRes = await gateway.searchSuggest(query);
      if (firebaseRes != null) {
        return firebaseRes;
      }
    }
    final json = await _requestJson(
      'GET',
      ApiEndpoints.searchSuggest,
      queryParameters: <String, dynamic>{
        if (query.trim().isNotEmpty) 'q': query.trim(),
      },
    );
    return SearchSuggestResponse.fromJson(json);
  }

  Future<ProductDetailResponse> getProductDetail(String slug) async {
    await resolveRuntimeEndpointsIfNeeded();
    final gateway = _firebaseGateway;
    final isGuest = storage.getAuthToken() == null;
    if (isGuest && gateway != null) {
      final firebaseRes = await gateway.getProductDetail(slug);
      if (firebaseRes != null) {
        return firebaseRes;
      }
    }
    try {
      final json = await _requestJson(
        'GET',
        ApiEndpoints.productDetail(slug),
      );
      return ProductDetailResponse.fromJson(json);
    } on ApiException catch (e) {
      if (!isGuest &&
          gateway != null &&
          (e.isNetworkError || e.statusCode >= 500)) {
        final firebaseRes = await gateway.getProductDetail(slug);
        if (firebaseRes != null) {
          return firebaseRes;
        }
      }
      rethrow;
    }
  }

  Future<CreateReviewResponse> createReview(
    String slug,
    CreateReviewRequest request,
  ) async {
    final json = await _requestJson(
      'POST',
      ApiEndpoints.productReviews(slug),
      body: request.toJson(),
      triggerUnauthorizedCallback: true,
    );
    return CreateReviewResponse.fromJson(json);
  }

  // ---------------------------------------------------------------------------
  // Wishlist
  // ---------------------------------------------------------------------------

  Future<WishlistResponse> getWishlist() async {
    final json = await _requestJson(
      'GET',
      ApiEndpoints.wishlist,
      triggerUnauthorizedCallback: true,
    );
    return WishlistResponse.fromJson(json);
  }

  Future<ToggleWishlistResponse> toggleWishlist(int productId) async {
    final json = await _requestJson(
      'POST',
      ApiEndpoints.wishlistToggle,
      body: <String, dynamic>{'product_id': productId},
      triggerUnauthorizedCallback: true,
    );
    return ToggleWishlistResponse.fromJson(json);
  }

  // ---------------------------------------------------------------------------
  // Cart & Discounts
  // ---------------------------------------------------------------------------

  Future<CartPayloadDto> getCart({
    String? province,
    String? shippingMethod,
  }) async {
    final json = await _requestJson(
      'GET',
      ApiEndpoints.cart,
      queryParameters: <String, dynamic>{
        if (province != null && province.isNotEmpty) 'province': province,
        if (shippingMethod != null && shippingMethod.isNotEmpty)
          'shipping_method': shippingMethod,
      },
    );
    return _parseAndPersistCart(asMap(json['cart']));
  }

  Future<CartMutationResponse> addCartItem(AddCartItemRequest request) async {
    final json = await _requestJson(
      'POST',
      ApiEndpoints.cartItems,
      body: request.toJson(),
    );
    final cart = await _parseAndPersistCart(asMap(json['cart']));
    return CartMutationResponse(
      message: asString(json['message']),
      cart: cart,
    );
  }

  Future<CartMutationResponse> updateCartItem(
    int itemId,
    UpdateCartItemRequest request,
  ) async {
    final json = await _requestJson(
      'PATCH',
      ApiEndpoints.cartItem(itemId),
      body: request.toJson(),
    );
    final cart = await _parseAndPersistCart(asMap(json['cart']));
    return CartMutationResponse(
      message: asString(json['message']),
      cart: cart,
    );
  }

  Future<CartMutationResponse> removeCartItem(
    int itemId, {
    String? province,
    String? shippingMethod,
  }) async {
    final json = await _requestJson(
      'DELETE',
      ApiEndpoints.cartItem(itemId),
      queryParameters: <String, dynamic>{
        if (province != null && province.isNotEmpty) 'province': province,
        if (shippingMethod != null && shippingMethod.isNotEmpty)
          'shipping_method': shippingMethod,
      },
    );
    final cart = await _parseAndPersistCart(asMap(json['cart']));
    return CartMutationResponse(
      message: asString(json['message']),
      cart: cart,
    );
  }

  Future<CartMutationResponse> applyDiscount(
    ApplyDiscountRequest request,
  ) async {
    final json = await _requestJson(
      'POST',
      ApiEndpoints.cartDiscount,
      body: request.toJson(),
    );
    final cart = await _parseAndPersistCart(asMap(json['cart']));
    return CartMutationResponse(
      message: asString(json['message']),
      cart: cart,
    );
  }

  Future<CartMutationResponse> removeDiscount({
    String? province,
    String? shippingMethod,
  }) async {
    final json = await _requestJson(
      'DELETE',
      ApiEndpoints.cartDiscount,
      queryParameters: <String, dynamic>{
        if (province != null && province.isNotEmpty) 'province': province,
        if (shippingMethod != null && shippingMethod.isNotEmpty)
          'shipping_method': shippingMethod,
      },
    );
    final cart = await _parseAndPersistCart(asMap(json['cart']));
    return CartMutationResponse(
      message: asString(json['message']),
      cart: cart,
    );
  }

  // ---------------------------------------------------------------------------
  // Checkout, Bakong KHQR Payment & Tax Invoice
  // ---------------------------------------------------------------------------

  Future<CheckoutResponse> checkout(CheckoutRequest request) async {
    final json = await _requestJson(
      'POST',
      ApiEndpoints.checkout,
      body: request.toJson(),
    );
    final response = CheckoutResponse.fromJson(json);
    if (response.orderAccessToken.isNotEmpty) {
      await storage.saveOrderToken(
        response.order.number,
        response.orderAccessToken,
      );
    }
    return response;
  }

  Future<OrderPaymentResponse> getOrderPayment(
    String orderNumber, {
    String? orderToken,
  }) async {
    final json = await _requestJson(
      'GET',
      ApiEndpoints.orderPayment(orderNumber),
      orderTokenOverride: orderToken ?? storage.getOrderToken(orderNumber),
    );
    return OrderPaymentResponse.fromJson(json);
  }

  Future<PaymentStatusResponse> getPaymentStatus(
    int paymentId, {
    String? orderNumber,
    String? orderToken,
  }) async {
    final resolvedToken = orderToken ??
        (orderNumber != null ? storage.getOrderToken(orderNumber) : null);
    final json = await _requestJson(
      'GET',
      ApiEndpoints.paymentStatus(paymentId),
      orderTokenOverride: resolvedToken,
    );
    return PaymentStatusResponse.fromJson(json);
  }

  Future<RegenerateQrResponse> regenerateQr(
    String orderNumber, {
    String? orderToken,
  }) async {
    final json = await _requestJson(
      'POST',
      ApiEndpoints.orderRegenerateQr(orderNumber),
      orderTokenOverride: orderToken ?? storage.getOrderToken(orderNumber),
    );
    return RegenerateQrResponse.fromJson(json);
  }

  Future<SimulatePayResponse> simulatePay(
    int paymentId, {
    String? orderNumber,
    String? orderToken,
  }) async {
    final resolvedToken = orderToken ??
        (orderNumber != null ? storage.getOrderToken(orderNumber) : null);
    final json = await _requestJson(
      'POST',
      ApiEndpoints.paymentSimulatePay(paymentId),
      orderTokenOverride: resolvedToken,
    );
    return SimulatePayResponse.fromJson(json);
  }

  Future<TaxInvoiceDto> getOrderInvoice(
    String orderNumber, {
    String? orderToken,
  }) async {
    final json = await _requestJson(
      'GET',
      ApiEndpoints.orderInvoice(orderNumber),
      orderTokenOverride: orderToken ?? storage.getOrderToken(orderNumber),
    );
    return TaxInvoiceDto.fromJson(asMap(json['invoice']));
  }

  // ---------------------------------------------------------------------------
  // Authentication
  // ---------------------------------------------------------------------------

  Future<AuthResponse> register(RegisterRequest request) async {
    final json = await _requestJson(
      'POST',
      ApiEndpoints.authRegister,
      body: request.toJson(),
    );
    final res = AuthResponse.fromJson(json);
    await _persistAuthResponse(res);
    return res;
  }

  Future<AuthResponse> login(LoginRequest request) async {
    final json = await _requestJson(
      'POST',
      ApiEndpoints.authLogin,
      body: request.toJson(),
    );
    final res = AuthResponse.fromJson(json);
    await _persistAuthResponse(res);
    return res;
  }

  Future<String> logout() async {
    try {
      final json = await _requestJson('POST', ApiEndpoints.authLogout);
      return asString(json['message']);
    } finally {
      await storage.clearAuth();
    }
  }

  Future<ForgotPasswordResponse> forgotPassword(String email) async {
    final json = await _requestJson(
      'POST',
      ApiEndpoints.authForgotPassword,
      body: <String, dynamic>{'email': email.trim()},
    );
    return ForgotPasswordResponse.fromJson(json);
  }

  Future<UserDto> me() async {
    final json = await _requestJson(
      'GET',
      ApiEndpoints.authMe,
      triggerUnauthorizedCallback: true,
    );
    final user = UserDto.fromJson(asMap(json['user']));
    await storage.setUserJson(user.toJson());
    return user;
  }

  Future<String> updatePassword(UpdatePasswordRequest request) async {
    final json = await _requestJson(
      'PUT',
      ApiEndpoints.authPassword,
      body: request.toJson(),
      triggerUnauthorizedCallback: true,
    );
    return asString(json['message']);
  }

  // ---------------------------------------------------------------------------
  // Customer Account Portal
  // ---------------------------------------------------------------------------

  Future<AccountProfileResponse> getProfile() async {
    final json = await _requestJson(
      'GET',
      ApiEndpoints.accountProfile,
      triggerUnauthorizedCallback: true,
    );
    return AccountProfileResponse.fromJson(json);
  }

  Future<UpdateProfileResponse> updateProfile(
    UpdateProfileRequest request,
  ) async {
    final json = await _requestJson(
      'PATCH',
      ApiEndpoints.accountProfile,
      body: request.toJson(),
      triggerUnauthorizedCallback: true,
    );
    final res = UpdateProfileResponse.fromJson(json);
    await storage.setUserJson(res.user.toJson());
    return res;
  }

  Future<AccountOrdersResponse> getOrders({
    int page = 1,
    int perPage = 10,
  }) async {
    final json = await _requestJson(
      'GET',
      ApiEndpoints.accountOrders,
      queryParameters: <String, dynamic>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      },
      triggerUnauthorizedCallback: true,
    );
    return AccountOrdersResponse.fromJson(json);
  }

  Future<OrderDetailDto> getOrderDetail(String orderNumber) async {
    final json = await _requestJson(
      'GET',
      ApiEndpoints.accountOrderDetail(orderNumber),
      triggerUnauthorizedCallback: true,
    );
    final token = asNullableString(json['order_access_token']);
    if (token != null && token.isNotEmpty) {
      await storage.saveOrderToken(orderNumber, token);
    }
    return OrderDetailDto.fromJson(asMap(json['order']));
  }

  Future<AccountAddressesResponse> getAddresses() async {
    final json = await _requestJson(
      'GET',
      ApiEndpoints.accountAddresses,
      triggerUnauthorizedCallback: true,
    );
    return AccountAddressesResponse.fromJson(json);
  }

  Future<AccountAddressMutationResponse> createAddress(
    UpsertAddressRequest request,
  ) async {
    final json = await _requestJson(
      'POST',
      ApiEndpoints.accountAddresses,
      body: request.toJson(),
      triggerUnauthorizedCallback: true,
    );
    return AccountAddressMutationResponse.fromJson(json);
  }

  Future<AccountAddressMutationResponse> updateAddress(
    int addressId,
    UpsertAddressRequest request,
  ) async {
    final json = await _requestJson(
      'PUT',
      ApiEndpoints.accountAddress(addressId),
      body: request.toJson(),
      triggerUnauthorizedCallback: true,
    );
    return AccountAddressMutationResponse.fromJson(json);
  }

  Future<String> deleteAddress(int addressId) async {
    final json = await _requestJson(
      'DELETE',
      ApiEndpoints.accountAddress(addressId),
      triggerUnauthorizedCallback: true,
    );
    return asString(json['message']);
  }

  // ---------------------------------------------------------------------------
  // Info Pages, Contact & Newsletter
  // ---------------------------------------------------------------------------

  Future<StructuredInfoPageDto> getPage(String slug) async {
    final json = await _requestJson('GET', ApiEndpoints.pageDetail(slug));
    return StructuredInfoPageDto.fromJson(json);
  }

  Future<ContactResponse> submitContact(ContactRequest request) async {
    final json = await _requestJson(
      'POST',
      ApiEndpoints.contact,
      body: request.toJson(),
    );
    return ContactResponse.fromJson(json);
  }

  Future<NewsletterResponse> subscribeNewsletter(String email) async {
    final json = await _requestJson(
      'POST',
      ApiEndpoints.newsletter,
      body: <String, dynamic>{'email': email.trim()},
    );
    return NewsletterResponse.fromJson(json);
  }

  // ---------------------------------------------------------------------------
  // Core Request & Error Handling
  // ---------------------------------------------------------------------------

  Future<CartPayloadDto> _parseAndPersistCart(
    Map<String, dynamic> rawCart,
  ) async {
    final cart = CartPayloadDto.fromJson(rawCart);
    if (cart.cartToken != null && cart.cartToken!.isNotEmpty) {
      await storage.setCartToken(cart.cartToken);
    }
    return cart;
  }

  Future<void> _persistAuthResponse(AuthResponse response) async {
    await storage.setAuthToken(response.token);
    await storage.setUserJson(response.user.toJson());
    if (response.cart.cartToken != null &&
        response.cart.cartToken!.isNotEmpty) {
      await storage.setCartToken(response.cart.cartToken);
    } else {
      await storage.setCartToken(null);
    }
  }

  Map<String, String> _buildHeaders({
    String? orderTokenOverride,
    bool hasBody = false,
  }) {
    final locale = _resolveLocale();
    final currency = _resolveCurrency();
    final authToken = storage.getAuthToken();
    final cartToken = storage.getCartToken();

    final headers = <String, String>{
      'Accept': 'application/json',
      'X-Locale': locale,
      'Accept-Language': locale,
      'X-Currency': currency,
      if (!kIsWeb) 'Bypass-Tunnel-Reminder': 'true',
    };

    if (hasBody) {
      headers['Content-Type'] = 'application/json';
    }
    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    if (cartToken != null && cartToken.isNotEmpty) {
      headers['X-Cart-Token'] = cartToken;
    }
    if (orderTokenOverride != null && orderTokenOverride.isNotEmpty) {
      headers['X-Order-Token'] = orderTokenOverride;
    }

    return headers;
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

  Future<Map<String, dynamic>> _requestJson(
    String method,
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? body,
    String? orderTokenOverride,
    bool triggerUnauthorizedCallback = false,
    bool allowDiscoveryRetry = true,
  }) async {
    await resolveRuntimeEndpointsIfNeeded();
    final attemptBaseUrl = currentBaseUrl;
    final uri = _buildUri(path, queryParameters);
    final headers = _buildHeaders(
      orderTokenOverride: orderTokenOverride,
      hasBody: body != null,
    );
    final encodedBody = body == null ? null : jsonEncode(body);

    late http.Response response;
    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _httpClient
              .get(uri, headers: headers)
              .timeout(defaultTimeout);
          break;
        case 'POST':
          response = await _httpClient
              .post(uri, headers: headers, body: encodedBody)
              .timeout(defaultTimeout);
          break;
        case 'PATCH':
          response = await _httpClient
              .patch(uri, headers: headers, body: encodedBody)
              .timeout(defaultTimeout);
          break;
        case 'PUT':
          response = await _httpClient
              .put(uri, headers: headers, body: encodedBody)
              .timeout(defaultTimeout);
          break;
        case 'DELETE':
          response = await _httpClient
              .delete(uri, headers: headers, body: encodedBody)
              .timeout(defaultTimeout);
          break;
        default:
          throw ApiException(
            statusCode: 0,
            code: 'UNSUPPORTED_METHOD',
            message: 'Unsupported HTTP method: $method',
          );
      }
    } on TimeoutException {
      if (allowDiscoveryRetry &&
          await _tryRediscoverEndpoint(previousBaseUrl: attemptBaseUrl)) {
        return _requestJson(
          method,
          path,
          queryParameters: queryParameters,
          body: body,
          orderTokenOverride: orderTokenOverride,
          triggerUnauthorizedCallback: triggerUnauthorizedCallback,
          allowDiscoveryRetry: false,
        );
      }
      throw const ApiException(
        statusCode: 0,
        code: 'NETWORK_TIMEOUT',
        message: 'Connection timed out. Please check your network and retry.',
      );
    } on http.ClientException catch (e) {
      if (allowDiscoveryRetry &&
          await _tryRediscoverEndpoint(previousBaseUrl: attemptBaseUrl)) {
        return _requestJson(
          method,
          path,
          queryParameters: queryParameters,
          body: body,
          orderTokenOverride: orderTokenOverride,
          triggerUnauthorizedCallback: triggerUnauthorizedCallback,
          allowDiscoveryRetry: false,
        );
      }
      throw ApiException(
        statusCode: 0,
        code: 'NETWORK_ERROR',
        message: e.message.isNotEmpty
            ? e.message
            : 'Unable to reach RESET Store server.',
      );
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        code: 'NETWORK_ERROR',
        message: e.toString(),
      );
    }

    Map<String, dynamic> decoded = <String, dynamic>{};
    if (response.body.trim().isNotEmpty) {
      try {
        final raw = jsonDecode(response.body);
        decoded = asMap(raw);
      } on FormatException {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          throw ApiException(
            statusCode: response.statusCode,
            code: 'INVALID_JSON',
            message: 'Unexpected server response format.',
          );
        }
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    if (response.statusCode == 401 && triggerUnauthorizedCallback) {
      await storage.clearAuth();
      _onUnauthorized?.call();
    }

    final parsedErrors = <String, List<String>>{};
    final rawErrors = decoded['errors'];
    if (rawErrors is Map) {
      rawErrors.forEach((key, value) {
        if (value is List) {
          parsedErrors[key.toString()] = value
              .map((item) => item.toString())
              .toList();
        } else if (value != null) {
          parsedErrors[key.toString()] = <String>[value.toString()];
        }
      });
    }

    final fallbackMessage = switch (response.statusCode) {
      401 => 'Authentication required. Please sign in.',
      403 => 'You are not authorized to access this resource.',
      404 => 'The requested resource was not found.',
      422 => 'Please check the highlighted fields and try again.',
      429 => 'Too many requests. Please wait a moment and try again.',
      _ => 'Server error (${response.statusCode}). Please try again.',
    };

    throw ApiException(
      statusCode: response.statusCode,
      code: asNullableString(decoded['code']),
      message: asString(decoded['message'], fallback: fallbackMessage),
      errors: parsedErrors,
    );
  }

  Future<bool> _tryRediscoverEndpoint({required String previousBaseUrl}) async {
    await resolveRuntimeEndpointsIfNeeded(force: true);
    return currentBaseUrl != previousBaseUrl &&
        AppConfig.discoveredBaseUrl != null;
  }
}
