import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/api/api_exceptions.dart';
import '../models/cart_models.dart';

class CartProvider extends ChangeNotifier {
  CartProvider(this._apiClient);

  final ApiClient _apiClient;

  CartPayloadDto? _cart;
  String _selectedProvince = 'Phnom Penh';
  String _selectedShippingMethod = 'standard';
  bool _isLoading = false;
  bool _isMutating = false;
  String? _errorMessage;

  CartPayloadDto? get cart => _cart;
  String get selectedProvince => _selectedProvince;
  String get selectedShippingMethod => _selectedShippingMethod;
  bool get canUseExpressShipping => _selectedProvince == 'Phnom Penh';
  bool get isLoading => _isLoading;
  bool get isMutating => _isMutating;
  String? get errorMessage => _errorMessage;

  int get itemCount => _cart?.itemCount ?? 0;
  bool get isEmpty => _cart == null || _cart!.items.isEmpty;

  void hydrateFromPayload(CartPayloadDto? payload) {
    if (payload == null) {
      return;
    }
    _cart = payload;
    _errorMessage = null;
    notifyListeners();
  }

  /// Updates selected province & shipping method, strictly enforcing that
  /// `express` is only valid when `province == 'Phnom Penh'`.
  /// Returns `true` if Express was automatically reset to Standard.
  Future<bool> setShippingContext({
    required String province,
    String? shippingMethod,
    bool refreshFromServer = true,
  }) async {
    var didResetExpress = false;
    _selectedProvince = province;

    var desiredMethod = shippingMethod ?? _selectedShippingMethod;
    if (province != 'Phnom Penh' && desiredMethod == 'express') {
      desiredMethod = 'standard';
      didResetExpress = true;
    }
    _selectedShippingMethod = desiredMethod;
    notifyListeners();

    if (refreshFromServer) {
      await refreshCart(silent: true);
    }
    return didResetExpress;
  }

  Future<void> refreshCart({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }
    try {
      final fetched = await _apiClient.getCart(
        province: _selectedProvince,
        shippingMethod: _selectedShippingMethod,
      );
      _cart = fetched;
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> addItem({
    required int productVariantId,
    int quantity = 1,
  }) async {
    _isMutating = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final res = await _apiClient.addCartItem(
        AddCartItemRequest(
          productVariantId: productVariantId,
          quantity: quantity,
          province: _selectedProvince,
          shippingMethod: _selectedShippingMethod,
        ),
      );
      _cart = res.cart;
      return res.message;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<String?> updateQuantity({
    required int itemId,
    required int quantity,
  }) async {
    _isMutating = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final res = await _apiClient.updateCartItem(
        itemId,
        UpdateCartItemRequest(
          quantity: quantity,
          province: _selectedProvince,
          shippingMethod: _selectedShippingMethod,
        ),
      );
      _cart = res.cart;
      return res.message;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<String?> removeItem(int itemId) async {
    _isMutating = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final res = await _apiClient.removeCartItem(
        itemId,
        province: _selectedProvince,
        shippingMethod: _selectedShippingMethod,
      );
      _cart = res.cart;
      return res.message;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<String> applyDiscount(String code) async {
    _isMutating = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final res = await _apiClient.applyDiscount(
        ApplyDiscountRequest(
          code: code,
          province: _selectedProvince,
          shippingMethod: _selectedShippingMethod,
        ),
      );
      _cart = res.cart;
      return res.message;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<String> removeDiscount() async {
    _isMutating = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final res = await _apiClient.removeDiscount(
        province: _selectedProvince,
        shippingMethod: _selectedShippingMethod,
      );
      _cart = res.cart;
      return res.message;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  void clearAfterCheckout() {
    if (_cart == null) {
      return;
    }
    _cart = CartPayloadDto(
      currency: _cart!.currency,
      exchangeRate: _cart!.exchangeRate,
      province: _selectedProvince,
      shippingMethod: 'standard',
      subtotalCents: 0,
      formattedSubtotal: _cart!.currency == 'USD' ? '\$0.00' : '0 ៛',
      discountCents: 0,
      formattedDiscount: _cart!.currency == 'USD' ? '\$0.00' : '0 ៛',
      shippingFeeCents: 0,
      formattedShipping: _cart!.currency == 'USD' ? '\$0.00' : '0 ៛',
      totalCents: 0,
      formattedTotal: _cart!.currency == 'USD' ? '\$0.00' : '0 ៛',
      convertedTotal: 0,
      freeShippingThresholdCents: _cart!.freeShippingThresholdCents,
      formattedFreeShippingThreshold: _cart!.formattedFreeShippingThreshold,
      freeShippingQualified: false,
      freeShippingRemainingCents: _cart!.freeShippingThresholdCents,
      freeShippingRemainingFormatted: _cart!.formattedFreeShippingThreshold,
      freeShippingProgressPercent: 0,
      cartToken: _cart!.cartToken,
      itemCount: 0,
      items: const <CartItemDto>[],
      discountCode: null,
      discount: null,
    );
    _selectedShippingMethod = 'standard';
    notifyListeners();
  }
}
