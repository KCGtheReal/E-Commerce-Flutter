import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/api/api_exceptions.dart';
import '../models/catalog_models.dart';

class WishlistProvider extends ChangeNotifier {
  WishlistProvider(this._apiClient);

  final ApiClient _apiClient;

  List<ProductCardDto> _items = const <ProductCardDto>[];
  Set<int> _wishlistedIds = <int>{};
  bool _isLoading = false;
  String? _errorMessage;

  List<ProductCardDto> get items => _items;
  Set<int> get wishlistedIds => _wishlistedIds;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool isWishlisted(int productId) => _wishlistedIds.contains(productId);

  void markWishlisted(int productId, bool value) {
    if (_wishlistedIds.contains(productId) == value) {
      return;
    }
    final next = Set<int>.from(_wishlistedIds);
    if (value) {
      next.add(productId);
    } else {
      next.remove(productId);
    }
    _wishlistedIds = next;
    notifyListeners();
  }

  Future<void> loadWishlist({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }
    try {
      final res = await _apiClient.getWishlist();
      _items = res.items;
      _wishlistedIds = res.items.map((e) => e.id).toSet();
      _errorMessage = null;
    } on ApiException catch (e) {
      if (e.isUnauthenticated) {
        clear();
        return;
      }
      _errorMessage = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ToggleWishlistResponse> toggle(int productId) async {
    final res = await _apiClient.toggleWishlist(productId);
    final nextIds = Set<int>.from(_wishlistedIds);
    if (res.added) {
      nextIds.add(productId);
    } else {
      nextIds.remove(productId);
      _items = _items.where((item) => item.id != productId).toList();
    }
    _wishlistedIds = nextIds;
    notifyListeners();
    // Sync full list in background if item was added
    if (res.added) {
      await loadWishlist(silent: true);
    }
    return res;
  }

  void clear() {
    _items = const <ProductCardDto>[];
    _wishlistedIds = <int>{};
    _errorMessage = null;
    notifyListeners();
  }
}
