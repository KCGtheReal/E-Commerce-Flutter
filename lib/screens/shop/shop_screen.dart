import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../models/catalog_models.dart';
import '../../models/common_models.dart';
import '../../providers/app_navigation_provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/common_states.dart';
import '../../widgets/product_card.dart';
import '../../widgets/reset_footer.dart';
import '../product/product_detail_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, this.isActive = true});

  final bool isActive;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  ProductsQuery _query = const ProductsQuery();
  final List<ProductCardDto> _products = <ProductCardDto>[];
  ShopFacetsDto? _facets;
  PaginationMeta? _meta;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _needsReload = false;
  String? _errorMessage;

  int _lastShopRequestVersion = -1;
  int _requestSequence = 0;
  String? _loadedContextKey;
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _syncContextIfNeeded(int shopRequestVersion, String contextKey) {
    final versionChanged = shopRequestVersion != _lastShopRequestVersion;
    final contextChanged = _loadedContextKey != contextKey;

    if (!versionChanged && !contextChanged) {
      return;
    }

    _lastShopRequestVersion = shopRequestVersion;
    _loadedContextKey = contextKey;

    final hasPendingNav = versionChanged && shopRequestVersion > 0;
    if (!widget.isActive && !hasPendingNav) {
      _needsReload = true;
      return;
    }

    _needsReload = false;
    Future.microtask(() {
      if (!mounted) {
        return;
      }
      if (hasPendingNav) {
        final nav = context.read<AppNavigationProvider>();
        _searchDebounce?.cancel();
        _query = ProductsQuery(
          category: nav.pendingCategorySlug,
          q: nav.pendingSearchQuery,
          sort: nav.pendingSort ?? 'featured',
        );
        _searchController.text = nav.pendingSearchQuery ?? '';
        _minPriceController.clear();
        _maxPriceController.clear();
        nav.clearPendingShopFilters();
      }
      _loadProducts(reset: true);
    });
  }

  @override
  void didUpdateWidget(covariant ShopScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive && _needsReload) {
      _needsReload = false;
      _loadProducts(reset: true);
    }
  }

  Future<void> _loadProducts({bool reset = true}) async {
    final seq = ++_requestSequence;
    if (reset) {
      if (!_isLoading || _errorMessage != null) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }
    } else {
      setState(() {
        _isLoadingMore = true;
        _errorMessage = null;
      });
    }

    try {
      final res = await context.read<ApiClient>().getProducts(_query);
      if (!mounted || seq != _requestSequence) {
        return;
      }
      setState(() {
        if (reset) {
          _products.clear();
        }
        _products.addAll(res.data);
        _facets = res.facets;
        _meta = res.meta;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } on ApiException catch (e) {
      if (!mounted || seq != _requestSequence) {
        return;
      }
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _applyQuery(ProductsQuery nextQuery) {
    setState(() {
      _query = nextQuery.copyWith(page: 1);
    });
    _loadProducts(reset: true);
  }

  void _clearAllFilters() {
    _searchDebounce?.cancel();
    _searchController.clear();
    _minPriceController.clear();
    _maxPriceController.clear();
    _applyQuery(ProductsQuery(sort: _query.sort));
  }

  void _onSearchChanged(String val) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(AppMotion.searchDebounce, () {
      _applyQuery(_query.copyWith(q: val.trim(), clearQ: val.trim().isEmpty));
    });
  }

  Future<void> _toggleWishlist(ProductCardDto product) async {
    final strings = context.read<AppSettingsProvider>().strings;
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      final ok = await showSignInPromptDialog(
        context,
        message: strings.get('wishlist_signin_prompt'),
      );
      if (!ok || !mounted) {
        return;
      }
    }
    try {
      final res = await context.read<WishlistProvider>().toggle(product.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message)),
        );
      }
    } on ApiException catch (e) {
      if (e.isUnauthenticated && mounted) {
        await showSignInPromptDialog(
          context,
          message: strings.get('wishlist_signin_prompt'),
        );
      }
    }
  }

  void _openFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.88,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _FilterPanelContent(
                query: _query,
                facets: _facets,
                minPriceController: _minPriceController,
                maxPriceController: _maxPriceController,
                onApply: (nextQuery) {
                  Navigator.of(sheetContext).pop();
                  _applyQuery(nextQuery);
                },
                onClear: () {
                  Navigator.of(sheetContext).pop();
                  _clearAllFilters();
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final shopRequestVersion = context.select<AppNavigationProvider, int>(
      (nav) => nav.shopRequestVersion,
    );
    final contextKey = context.select<AppSettingsProvider, String>(
      (s) => '${s.locale}|${s.currency}',
    );
    _syncContextIfNeeded(shopRequestVersion, contextKey);

    final palette = context.palette;
    final settings = context.watch<AppSettingsProvider>();
    final strings = settings.strings;
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = AppBreakpoints.isDesktop(width);
    final isMobile = AppBreakpoints.isMobile(width);
    final cols = isDesktop ? 3 : (AppBreakpoints.isTablet(width) ? 3 : 2);
    final activeFiltersCount = _facets?.activeFilterCount ?? 0;
    final sidePadding = math.max(
      isMobile ? 16.0 : 24.0,
      (width - AppSpacing.maxContentWidth) / 2,
    );

    final catalogResultsSlivers = _buildProductsSlivers(
      context,
      cols,
      isMobile,
    );

    return RefreshIndicator(
      onRefresh: () => _loadProducts(reset: true),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverPadding(
            padding: EdgeInsets.fromLTRB(sidePadding, 24, sidePadding, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Catalog Header
                  Text(
                    strings.get('catalog_title'),
                    style: AppTheme.displayStyle(
                      locale: settings.locale,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_meta?.total ?? _products.length} ${strings.get('products_found')}',
                    style: AppTheme.bodyStyle(
                      locale: settings.locale,
                      fontSize: 13,
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search + Sort + Mobile Filter Trigger Row
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      SizedBox(
                        width: isMobile ? double.infinity : 280,
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search, size: 18),
                            hintText: strings.get('search_placeholder'),
                            isDense: true,
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () {
                                      _searchDebounce?.cancel();
                                      _searchController.clear();
                                      _applyQuery(
                                        _query.copyWith(clearQ: true),
                                      );
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                      if (!isDesktop)
                        OutlinedButton.icon(
                          onPressed: _openFilterSheet,
                          icon: const Icon(Icons.tune, size: 16),
                          label: Text(
                            activeFiltersCount > 0
                                ? '${strings.get('filter_title')} ($activeFiltersCount)'
                                : strings.get('filter_title'),
                          ),
                        ),
                      SizedBox(
                        width: isMobile ? 190 : 210,
                        child: DropdownButtonFormField<String>(
                          initialValue: _query.sort,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: strings.get('sort_by'),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          items: <DropdownMenuItem<String>>[
                            DropdownMenuItem(
                              value: 'featured',
                              child: Text(strings.get('sort_featured')),
                            ),
                            DropdownMenuItem(
                              value: 'newest',
                              child: Text(strings.get('sort_newest')),
                            ),
                            DropdownMenuItem(
                              value: 'price_low',
                              child: Text(strings.get('sort_price_low')),
                            ),
                            DropdownMenuItem(
                              value: 'price_high',
                              child: Text(strings.get('sort_price_high')),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              _applyQuery(_query.copyWith(sort: val));
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  // Active Filter Chips
                  if (activeFiltersCount > 0) ...<Widget>[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        if (_query.q != null && _query.q!.isNotEmpty)
                          Chip(
                            label: Text('"${_query.q}"'),
                            onDeleted: () {
                              _searchDebounce?.cancel();
                              _searchController.clear();
                              _applyQuery(_query.copyWith(clearQ: true));
                            },
                          ),
                        if (_query.category != null)
                          Chip(
                            label: Text(_query.category!),
                            onDeleted: () => _applyQuery(
                              _query.copyWith(clearCategory: true),
                            ),
                          ),
                        ..._query.sizes.map((size) {
                          return Chip(
                            label: Text(size),
                            onDeleted: () {
                              final next = List<String>.from(_query.sizes)
                                ..remove(size);
                              _applyQuery(_query.copyWith(sizes: next));
                            },
                          );
                        }),
                        if (_query.color != null)
                          Chip(
                            label: Text(_query.color!),
                            onDeleted: () => _applyQuery(
                              _query.copyWith(clearColor: true),
                            ),
                          ),
                        if (_query.minPrice != null ||
                            _query.maxPrice != null)
                          Chip(
                            label: Text(
                              '${_query.minPrice ?? 0}–${_query.maxPrice ?? '∞'} ${settings.currency}',
                            ),
                            onDeleted: () {
                              _minPriceController.clear();
                              _maxPriceController.clear();
                              _applyQuery(
                                _query.copyWith(
                                  clearMinPrice: true,
                                  clearMaxPrice: true,
                                ),
                              );
                            },
                          ),
                        if (_query.inStock)
                          Chip(
                            label: Text(strings.get('filter_in_stock')),
                            onDeleted: () => _applyQuery(
                              _query.copyWith(inStock: false),
                            ),
                          ),
                        TextButton(
                          onPressed: _clearAllFilters,
                          child: Text(strings.get('filter_clear')),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (isDesktop)
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: sidePadding),
              sliver: SliverCrossAxisGroup(
                slivers: <Widget>[
                  SliverConstrainedCrossAxis(
                    maxExtent: AppSpacing.filterSidebarWidth,
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: palette.cardSurface,
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                          border: Border.all(color: palette.borderSubtle),
                        ),
                        child: _FilterPanelContent(
                          query: _query,
                          facets: _facets,
                          minPriceController: _minPriceController,
                          maxPriceController: _maxPriceController,
                          onApply: _applyQuery,
                          onClear: _clearAllFilters,
                        ),
                      ),
                    ),
                  ),
                  const SliverConstrainedCrossAxis(
                    maxExtent: 28,
                    sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
                  ),
                  SliverCrossAxisExpanded(
                    flex: 1,
                    sliver: SliverMainAxisGroup(slivers: catalogResultsSlivers),
                  ),
                ],
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: sidePadding),
              sliver: SliverMainAxisGroup(slivers: catalogResultsSlivers),
            ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 24),
              child: ResetFooter(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildProductsSlivers(
    BuildContext context,
    int cols,
    bool isMobile,
  ) {
    final settings = context.watch<AppSettingsProvider>();
    final strings = settings.strings;

    if (_isLoading && _products.isEmpty) {
      return <Widget>[
        SliverToBoxAdapter(
          child: ProductGridSkeleton(count: cols * 2, crossAxisCount: cols),
        ),
      ];
    }

    if (_errorMessage != null && _products.isEmpty) {
      return <Widget>[
        SliverToBoxAdapter(
          child: ResetErrorBanner(
            message: _errorMessage!,
            onRetry: () => _loadProducts(reset: true),
          ),
        ),
      ];
    }

    if (_products.isEmpty) {
      return <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: ResetEmptyState(
              icon: Icons.filter_alt_off_outlined,
              title: strings.get('no_products_found'),
              subtitle: strings.get('no_products_found_hint'),
              ctaLabel: strings.get('filter_clear'),
              onCtaPressed: _clearAllFilters,
            ),
          ),
        ),
      ];
    }

    return <Widget>[
      SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: isMobile ? 12 : 20,
          mainAxisSpacing: 24,
          childAspectRatio: isMobile ? 0.47 : 0.52,
        ),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final item = _products[index];
          return RepaintBoundary(
            key: ValueKey<int>(item.id),
            child: ProductCard(
              product: item,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ProductDetailScreen(slug: item.slug),
                  ),
                );
              },
              onWishlistTap: () => _toggleWishlist(item),
            ),
          );
        },
      ),
      if (_meta != null)
        SliverToBoxAdapter(
          child: Column(
            children: <Widget>[
              const SizedBox(height: 28),
              if (_meta!.hasMorePages)
                OutlinedButton(
                  onPressed: _isLoadingMore
                      ? null
                      : () {
                          setState(() {
                            _query = _query.copyWith(
                              page: _meta!.currentPage + 1,
                            );
                          });
                          _loadProducts(reset: false);
                        },
                  child: _isLoadingMore
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(strings.get('load_more')),
                ),
              const SizedBox(height: 8),
              Text(
                strings.get('page_of', <String, String>{
                  'page': '${_meta!.currentPage}',
                  'last': '${_meta!.lastPage}',
                }),
                style: AppTheme.monoStyle(
                  fontSize: 11.5,
                  color: context.palette.textTertiary,
                ),
              ),
            ],
          ),
        ),
    ];
  }
}

class _FilterPanelContent extends StatefulWidget {
  const _FilterPanelContent({
    required this.query,
    required this.facets,
    required this.minPriceController,
    required this.maxPriceController,
    required this.onApply,
    required this.onClear,
  });

  final ProductsQuery query;
  final ShopFacetsDto? facets;
  final TextEditingController minPriceController;
  final TextEditingController maxPriceController;
  final ValueChanged<ProductsQuery> onApply;
  final VoidCallback onClear;

  @override
  State<_FilterPanelContent> createState() => _FilterPanelContentState();
}

class _FilterPanelContentState extends State<_FilterPanelContent> {
  late ProductsQuery _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.query;
  }

  @override
  void didUpdateWidget(covariant _FilterPanelContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _draft = widget.query;
    }
  }

  void _selectPricePreset(double? min, double? max) {
    widget.minPriceController.text = min == null ? '' : '${min.round()}';
    widget.maxPriceController.text = max == null ? '' : '${max.round()}';
    setState(() {
      _draft = _draft.copyWith(
        minPrice: min,
        clearMinPrice: min == null,
        maxPrice: max,
        clearMaxPrice: max == null,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final settings = context.watch<AppSettingsProvider>();
    final strings = settings.strings;
    final facets = widget.facets;
    final isUsd = settings.currency == 'USD';
    final symbol = isUsd ? '\$' : '៛';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              strings.get('filter_title').toUpperCase(),
              style: AppTheme.displayStyle(
                locale: settings.locale,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: palette.textPrimary,
              ),
            ),
            TextButton(
              onPressed: widget.onClear,
              child: Text(strings.get('filter_clear')),
            ),
          ],
        ),
        Divider(color: palette.borderSubtle),
        const SizedBox(height: 12),

        // Categories
        if (facets != null && facets.categories.isNotEmpty) ...<Widget>[
          Text(
            strings.get('filter_category'),
            style: AppTheme.displayStyle(
              locale: settings.locale,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          _CategoryRadioRow(
            label: '${strings.get('filter_all')} (${facets.allProductsCount})',
            selected: _draft.category == null,
            onTap: () => setState(() {
              _draft = _draft.copyWith(clearCategory: true);
            }),
          ),
          ...facets.categories.map((cat) {
            return _CategoryRadioRow(
              label: '${cat.name} (${cat.productsCount})',
              selected: _draft.category == cat.slug,
              onTap: () => setState(() {
                _draft = _draft.copyWith(category: cat.slug);
              }),
            );
          }),
          const SizedBox(height: 14),
        ],

        // Sizes
        if (facets != null && facets.availableSizes.isNotEmpty) ...<Widget>[
          Text(
            strings.get('filter_size'),
            style: AppTheme.displayStyle(
              locale: settings.locale,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: facets.availableSizes.map((size) {
              final active = _draft.sizes.contains(size);
              return InkWell(
                onTap: () {
                  final next = List<String>.from(_draft.sizes);
                  if (active) {
                    next.remove(size);
                  } else {
                    next.add(size);
                  }
                  setState(() => _draft = _draft.copyWith(sizes: next));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? palette.buttonPrimaryBg
                        : palette.elevatedSurface,
                    borderRadius: BorderRadius.circular(AppRadii.xs),
                    border: Border.all(
                      color: active
                          ? palette.buttonPrimaryBg
                          : palette.borderSubtle,
                    ),
                  ),
                  child: Text(
                    size,
                    style: AppTheme.monoStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: active
                          ? palette.buttonPrimaryFg
                          : palette.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Colors
        if (facets != null && facets.availableColors.isNotEmpty) ...<Widget>[
          Text(
            strings.get('filter_color'),
            style: AppTheme.displayStyle(
              locale: settings.locale,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: facets.availableColors.map((c) {
              final active = _draft.color == c.color;
              return Tooltip(
                message: c.color,
                child: InkWell(
                  onTap: () => setState(() {
                    _draft = active
                        ? _draft.copyWith(clearColor: true)
                        : _draft.copyWith(color: c.color);
                  }),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 28,
                    height: 28,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: active
                            ? AppColors.terracotta
                            : palette.borderSubtle,
                        width: active ? 2 : 1,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: parseHexColor(c.colorCode),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Currency-Aware Price Range
        Text(
          '${strings.get('filter_price')} ($symbol)',
          style: AppTheme.displayStyle(
            locale: settings.locale,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: isUsd
              ? <Widget>[
                  ActionChip(
                    label: const Text('< \$25'),
                    onPressed: () => _selectPricePreset(null, 25),
                  ),
                  ActionChip(
                    label: const Text('\$25–\$50'),
                    onPressed: () => _selectPricePreset(25, 50),
                  ),
                  ActionChip(
                    label: const Text('> \$50'),
                    onPressed: () => _selectPricePreset(50, null),
                  ),
                ]
              : <Widget>[
                  ActionChip(
                    label: const Text('< 100K ៛'),
                    onPressed: () => _selectPricePreset(null, 100000),
                  ),
                  ActionChip(
                    label: const Text('100K–200K ៛'),
                    onPressed: () => _selectPricePreset(100000, 200000),
                  ),
                  ActionChip(
                    label: const Text('> 200K ៛'),
                    onPressed: () => _selectPricePreset(200000, null),
                  ),
                ],
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: widget.minPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: strings.get('filter_min'),
                  prefixText: '$symbol ',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: widget.maxPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: strings.get('filter_max'),
                  prefixText: '$symbol ',
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // In Stock Switch
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            strings.get('filter_in_stock'),
            style: AppTheme.bodyStyle(
              locale: settings.locale,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: palette.textPrimary,
            ),
          ),
          value: _draft.inStock,
          onChanged: (val) => setState(() {
            _draft = _draft.copyWith(inStock: val);
          }),
        ),
        const SizedBox(height: 14),

        ElevatedButton(
          onPressed: () {
            final parsedMin = double.tryParse(
              widget.minPriceController.text.trim(),
            );
            final parsedMax = double.tryParse(
              widget.maxPriceController.text.trim(),
            );
            widget.onApply(
              _draft.copyWith(
                minPrice: parsedMin,
                clearMinPrice: parsedMin == null,
                maxPrice: parsedMax,
                clearMaxPrice: parsedMax == null,
              ),
            );
          },
          child: Text(strings.get('filter_apply')),
        ),
      ],
    );
  }
}

class _CategoryRadioRow extends StatelessWidget {
  const _CategoryRadioRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final locale = context.watch<AppSettingsProvider>().locale;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: <Widget>[
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 16,
              color: selected ? AppColors.terracotta : palette.textTertiary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodyStyle(
                  locale: locale,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: palette.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
