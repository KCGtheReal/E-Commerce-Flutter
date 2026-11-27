import 'package:flutter/foundation.dart';

class AppNavigationProvider extends ChangeNotifier {
  int _tabIndex = 0; // 0: Home, 1: Shop, 2: Bag, 3: Account
  String? _pendingCategorySlug;
  String? _pendingSearchQuery;
  String? _pendingSort;
  int _shopRequestVersion = 0;

  int get tabIndex => _tabIndex;
  String? get pendingCategorySlug => _pendingCategorySlug;
  String? get pendingSearchQuery => _pendingSearchQuery;
  String? get pendingSort => _pendingSort;
  int get shopRequestVersion => _shopRequestVersion;

  void selectTab(int index) {
    if (index < 0 || index > 3) {
      return;
    }
    _tabIndex = index;
    notifyListeners();
  }

  void openShop({
    String? categorySlug,
    String? searchQuery,
    String? sort,
  }) {
    _pendingCategorySlug = categorySlug;
    _pendingSearchQuery = searchQuery;
    _pendingSort = sort;
    _shopRequestVersion++;
    _tabIndex = 1;
    notifyListeners();
  }

  void clearPendingShopFilters() {
    _pendingCategorySlug = null;
    _pendingSearchQuery = null;
    _pendingSort = null;
  }
}
