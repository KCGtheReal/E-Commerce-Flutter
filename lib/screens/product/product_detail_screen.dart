import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../models/catalog_models.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/cart_drawer.dart';
import '../../widgets/common_states.dart';
import '../../widgets/image_zoom_modal.dart';
import '../../widgets/product_card.dart';
import '../../widgets/reset_footer.dart';
import '../../widgets/reset_scaffold.dart';
import '../../widgets/size_guide_modal.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  ProductDetailResponse? _detail;
  bool _isLoading = true;
  bool _isAdding = false;
  String? _errorMessage;
  String? _loadedContextKey;

  int _selectedImageIndex = 0;
  String? _selectedColor;
  String? _selectedSize;
  int _quantity = 1;
  final Set<String> _expandedTabs = <String>{'description'};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = context.watch<AppSettingsProvider>();
    final key = '${settings.locale}|${settings.currency}|${widget.slug}';
    if (_loadedContextKey != key) {
      _loadedContextKey = key;
      _loadProduct();
    }
  }

  Future<void> _loadProduct() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final res = await context.read<ApiClient>().getProductDetail(widget.slug);
      if (!mounted) {
        return;
      }
      final product = res.product;
      context.read<WishlistProvider>().markWishlisted(product.id, res.inWishlist);

      // Default to first in-stock variant if available
      ProductVariantDto? defaultVariant;
      for (final v in product.variants) {
        if (v.availableStock > 0) {
          defaultVariant = v;
          break;
        }
      }
      defaultVariant ??=
          product.variants.isNotEmpty ? product.variants.first : null;

      setState(() {
        _detail = res;
        _selectedColor ??= defaultVariant?.color ??
            (product.availableColors.isNotEmpty
                ? product.availableColors.first.name
                : null);
        _selectedSize ??= defaultVariant?.size ??
            (product.availableSizes.isNotEmpty
                ? product.availableSizes.first
                : null);
        _clampQuantity();
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    }
  }

  ProductVariantDto? get _activeVariant {
    final product = _detail?.product;
    if (product == null || product.variants.isEmpty) {
      return null;
    }
    for (final v in product.variants) {
      if (v.color == _selectedColor && v.size == _selectedSize) {
        return v;
      }
    }
    for (final v in product.variants) {
      if (v.color == _selectedColor) {
        return v;
      }
    }
    return product.variants.first;
  }

  bool _isSizeAvailableForColor(String size) {
    final product = _detail?.product;
    if (product == null) {
      return false;
    }
    for (final v in product.variants) {
      if (v.size == size &&
          (_selectedColor == null || v.color == _selectedColor)) {
        if (v.availableStock > 0) {
          return true;
        }
      }
    }
    return false;
  }

  void _clampQuantity() {
    final stock = _activeVariant?.availableStock ?? 0;
    final maxAllowed = stock <= 0 ? 1 : stock.clamp(1, 20);
    if (_quantity > maxAllowed) {
      _quantity = maxAllowed;
    }
    if (_quantity < 1) {
      _quantity = 1;
    }
  }

  Future<void> _addToCart() async {
    final variant = _activeVariant;
    if (variant == null || variant.availableStock <= 0) {
      return;
    }
    setState(() => _isAdding = true);
    try {
      final msg = await context.read<CartProvider>().addItem(
            productVariantId: variant.id,
            quantity: _quantity,
          );
      if (!mounted) {
        return;
      }
      if (msg != null && msg.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            action: SnackBarAction(
              label: context.read<AppSettingsProvider>().strings.get('nav_cart'),
              textColor: AppColors.terracotta,
              onPressed: () => CartDrawer.show(context),
            ),
          ),
        );
      }
      CartDrawer.show(context);
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.firstErrorMessage)),
      );
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  Future<void> _toggleWishlist() async {
    final product = _detail?.product;
    if (product == null) {
      return;
    }
    final strings = context.read<AppSettingsProvider>().strings;
    final auth = context.read<AuthProvider>();

    if (!auth.isAuthenticated) {
      final signedIn = await showSignInPromptDialog(
        context,
        message: strings.get('wishlist_signin_prompt'),
      );
      if (!signedIn || !mounted) {
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
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Future<void> _openWriteReview() async {
    final product = _detail?.product;
    if (product == null) {
      return;
    }
    final strings = context.read<AppSettingsProvider>().strings;
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      final signedIn = await showSignInPromptDialog(
        context,
        message: strings.get('review_signin_prompt'),
      );
      if (!signedIn || !mounted) {
        return;
      }
    }

    final submitted = await showDialog<bool>(
      context: context,
      builder: (_) => _WriteReviewDialog(slug: product.slug),
    );
    if (submitted == true && mounted) {
      await _loadProduct();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final settings = context.watch<AppSettingsProvider>();
    final strings = settings.strings;
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = AppBreakpoints.isDesktop(width);
    final detail = _detail;
    final product = detail?.product;
    final activeVariant = _activeVariant;
    final isWishlisted = context.select<WishlistProvider, bool>(
      (w) => product != null && w.isWishlisted(product.id),
    );

    return ResetScaffold(
      showBackButton: true,
      title: product?.name,
      onRefreshContext: _loadProduct,
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSpacing.maxContentWidth,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 24 : 16,
                    vertical: 24,
                  ),
                  child: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 80),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : _errorMessage != null
                          ? ResetErrorBanner(
                              message: _errorMessage!,
                              onRetry: _loadProduct,
                            )
                          : detail == null || product == null
                              ? const SizedBox.shrink()
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    if (isDesktop)
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Expanded(
                                            flex: 7,
                                            child: _buildGallery(
                                              context,
                                              product,
                                            ),
                                          ),
                                          const SizedBox(width: 36),
                                          Expanded(
                                            flex: 5,
                                            child: _buildPurchasePanel(
                                              context,
                                              product,
                                              activeVariant,
                                              isWishlisted,
                                            ),
                                          ),
                                        ],
                                      )
                                    else ...<Widget>[
                                      _buildGallery(context, product),
                                      const SizedBox(height: 22),
                                      _buildPurchasePanel(
                                        context,
                                        product,
                                        activeVariant,
                                        isWishlisted,
                                      ),
                                    ],

                                    const SizedBox(height: 32),

                                    // 5 Expandable Detail Tabs
                                    ...product.detailTabs.map((tab) {
                                      final expanded =
                                          _expandedTabs.contains(tab.key);
                                      return Container(
                                        decoration: BoxDecoration(
                                          border: Border(
                                            top: BorderSide(
                                              color: palette.borderSubtle,
                                            ),
                                          ),
                                        ),
                                        child: ExpansionTile(
                                          initiallyExpanded: expanded,
                                          onExpansionChanged: (val) {
                                            setState(() {
                                              if (val) {
                                                _expandedTabs.add(tab.key);
                                              } else {
                                                _expandedTabs.remove(tab.key);
                                              }
                                            });
                                          },
                                          tilePadding:
                                              const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          title: Text(
                                            tab.title,
                                            style: AppTheme.displayStyle(
                                              locale: settings.locale,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: palette.textPrimary,
                                            ),
                                          ),
                                          children: <Widget>[
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 16,
                                                ),
                                                child: Text(
                                                  tab.content,
                                                  style: AppTheme.bodyStyle(
                                                    locale: settings.locale,
                                                    fontSize: 13.5,
                                                    color:
                                                        palette.textSecondary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                    Divider(color: palette.borderSubtle),
                                    const SizedBox(height: 36),

                                    // Customer Reviews Section
                                    _buildReviewsSection(context, product),

                                    if (detail.relatedProducts.isNotEmpty) ...<Widget>[
                                      const SizedBox(height: 40),
                                      Text(
                                        strings.get('related_products'),
                                        style: AppTheme.displayStyle(
                                          locale: settings.locale,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: palette.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      GridView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: isDesktop ? 4 : 2,
                                          crossAxisSpacing: 14,
                                          mainAxisSpacing: 20,
                                          childAspectRatio: isDesktop ? 0.52 : 0.47,
                                        ),
                                        itemCount: detail.relatedProducts.length,
                                        itemBuilder: (context, index) {
                                          final related =
                                              detail.relatedProducts[index];
                                          return RepaintBoundary(
                                            key: ValueKey<int>(related.id),
                                            child: ProductCard(
                                              product: related,
                                              onTap: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute<void>(
                                                    builder: (_) =>
                                                        ProductDetailScreen(
                                                      slug: related.slug,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                ),
              ),
            ),
            const ResetFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildGallery(BuildContext context, ProductDetailDto product) {
    final palette = context.palette;
    final strings = context.watch<AppSettingsProvider>().strings;
    final images = product.images.isNotEmpty
        ? product.images
        : <ProductImageDto>[
            ProductImageDto(
              id: 0,
              imageUrl: product.primaryImageUrl,
              altText: product.name,
              isPrimary: true,
              sortOrder: 0,
            ),
          ];

    return Column(
      children: <Widget>[
        AspectRatio(
          aspectRatio: 4 / 5,
          child: Container(
            decoration: BoxDecoration(
              color: palette.elevatedSurface,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(color: palette.borderSubtle),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: <Widget>[
                PageView.builder(
                  itemCount: images.length,
                  onPageChanged: (index) {
                    setState(() => _selectedImageIndex = index);
                  },
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => ImageZoomModal.show(
                        context,
                        images: images,
                        initialIndex: _selectedImageIndex,
                      ),
                      child: ResetNetworkImage(
                        imageUrl: images[index].imageUrl,
                        fit: BoxFit.cover,
                        cacheWidth: 1000,
                      ),
                    );
                  },
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: InkWell(
                    onTap: () => ImageZoomModal.show(
                      context,
                      images: images,
                      initialIndex: _selectedImageIndex,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.onyxBlack.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(AppRadii.xs),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(
                            Icons.zoom_in,
                            size: 14,
                            color: AppColors.pureWhite,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            strings.get('click_to_zoom'),
                            style: AppTheme.monoStyle(
                              fontSize: 10.5,
                              color: AppColors.pureWhite,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (images.length > 1) ...<Widget>[
          const SizedBox(height: 10),
          SizedBox(
            height: 68,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final active = index == _selectedImageIndex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedImageIndex = index),
                  child: Container(
                    width: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadii.xs),
                      border: Border.all(
                        color: active
                            ? AppColors.terracotta
                            : palette.borderSubtle,
                        width: active ? 2 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ResetNetworkImage(
                      imageUrl: images[index].imageUrl,
                      fit: BoxFit.cover,
                      cacheWidth: 160,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPurchasePanel(
    BuildContext context,
    ProductDetailDto product,
    ProductVariantDto? variant,
    bool isWishlisted,
  ) {
    final palette = context.palette;
    final settings = context.watch<AppSettingsProvider>();
    final strings = settings.strings;
    final stock = variant?.availableStock ?? 0;
    final isInStock = stock > 0;
    final priceText = variant?.formattedPrice ?? product.formattedPrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '${product.category?.name.toUpperCase() ?? ''} • SKU: ${variant?.sku ?? product.skuPrefix}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.monoStyle(
            fontSize: 11,
            color: palette.textTertiary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          product.name,
          style: AppTheme.displayStyle(
            locale: settings.locale,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
        if (product.tagline != null && product.tagline!.isNotEmpty) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            product.tagline!,
            style: AppTheme.bodyStyle(
              locale: settings.locale,
              fontSize: 14,
              color: palette.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            const Icon(Icons.star, size: 16, color: AppColors.terracotta),
            const SizedBox(width: 4),
            Text(
              '${product.averageRating.toStringAsFixed(1)} (${product.reviewCount})',
              style: AppTheme.monoStyle(
                fontSize: 12,
                color: palette.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Text(
              priceText,
              style: AppTheme.monoStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
            if (product.formattedCompareAtPrice != null) ...<Widget>[
              const SizedBox(width: 10),
              Text(
                product.formattedCompareAtPrice!,
                style: AppTheme.monoStyle(
                  fontSize: 14,
                  color: palette.textTertiary,
                ).copyWith(decoration: TextDecoration.lineThrough),
              ),
            ],
          ],
        ),
        const SizedBox(height: 18),

        // Color Selector
        if (product.availableColors.isNotEmpty) ...<Widget>[
          Text(
            '${strings.get('select_color')}: ${_selectedColor ?? ''}',
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
            children: product.availableColors.map((swatch) {
              final active = swatch.name == _selectedColor;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedColor = swatch.name;
                    _clampQuantity();
                  });
                },
                borderRadius: BorderRadius.circular(AppRadii.sm),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: palette.elevatedSurface,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(
                      color: active
                          ? palette.borderStrong
                          : palette.borderSubtle,
                      width: active ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: parseHexColor(swatch.code),
                          shape: BoxShape.circle,
                          border: Border.all(color: palette.borderSubtle),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        swatch.name,
                        style: AppTheme.bodyStyle(
                          locale: settings.locale,
                          fontSize: 12.5,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500,
                          color: palette.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Size Selector + Size Guide
        if (product.availableSizes.isNotEmpty) ...<Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                strings.get('select_size'),
                style: AppTheme.displayStyle(
                  locale: settings.locale,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: () => SizeGuideModal.show(context),
                icon: const Icon(Icons.straighten, size: 16),
                label: Text(strings.get('size_guide')),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: product.availableSizes.map((size) {
              final active = size == _selectedSize;
              final available = _isSizeAvailableForColor(size);
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedSize = size;
                    _clampQuantity();
                  });
                },
                borderRadius: BorderRadius.circular(AppRadii.xs),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 54, minHeight: 38),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
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
                    textAlign: TextAlign.center,
                    style: AppTheme.monoStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: active
                          ? palette.buttonPrimaryFg
                          : (available
                              ? palette.textPrimary
                              : palette.textTertiary),
                    ).copyWith(
                      decoration: available
                          ? null
                          : TextDecoration.lineThrough,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Live Stock Indicator
        SemanticStatusBadge(
          label: isInStock
              ? '${strings.get('in_stock')} ($stock ${strings.get('stock_left')})'
              : strings.get('out_of_stock'),
          colorKey: isInStock ? 'success' : 'danger',
        ),
        const SizedBox(height: 16),

        // Quantity Stepper + Add to Cart + Wishlist Heart
        Row(
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                color: palette.elevatedSurface,
                borderRadius: BorderRadius.circular(AppRadii.xs),
                border: Border.all(color: palette.borderSubtle),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    onPressed: _quantity > 1
                        ? () => setState(() => _quantity--)
                        : null,
                    icon: const Icon(Icons.remove, size: 16),
                  ),
                  Text(
                    '$_quantity',
                    style: AppTheme.monoStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: isInStock && _quantity < stock && _quantity < 20
                        ? () => setState(() => _quantity++)
                        : null,
                    icon: const Icon(Icons.add, size: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: isInStock && !_isAdding ? _addToCart : null,
                child: _isAdding
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text(strings.get('adding_to_cart')),
                        ],
                      )
                    : Text(
                        isInStock
                            ? strings.get('add_to_cart')
                            : strings.get('out_of_stock'),
                      ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 46,
              width: 46,
              child: OutlinedButton(
                onPressed: _toggleWishlist,
                style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                child: Icon(
                  isWishlisted ? Icons.favorite : Icons.favorite_border,
                  color: isWishlisted
                      ? AppColors.terracotta
                      : palette.textPrimary,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Bakong Notice Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: palette.surfaceBone,
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(color: palette.borderSubtle),
          ),
          child: Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.khqrRed,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  'KHQR',
                  style: AppTheme.monoStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.pureWhite,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  strings.get('product_bakong_notice'),
                  style: AppTheme.bodyStyle(
                    locale: settings.locale,
                    fontSize: 12,
                    color: palette.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection(BuildContext context, ProductDetailDto product) {
    final palette = context.palette;
    final settings = context.watch<AppSettingsProvider>();
    final strings = settings.strings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  strings.get('customer_reviews'),
                  style: AppTheme.displayStyle(
                    locale: settings.locale,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.averageRating.toStringAsFixed(1)} / 5.0 • ${product.reviewCount}',
                  style: AppTheme.monoStyle(
                    fontSize: 12.5,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
            OutlinedButton.icon(
              onPressed: _openWriteReview,
              icon: const Icon(Icons.rate_review_outlined, size: 16),
              label: Text(strings.get('write_review')),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (product.reviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: palette.cardSurface,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(color: palette.borderSubtle),
            ),
            child: Text(
              strings.get('no_reviews_yet'),
              style: AppTheme.bodyStyle(
                locale: settings.locale,
                fontSize: 13,
                color: palette.textSecondary,
              ),
            ),
          )
        else
          ...product.reviews.map((review) {
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.cardSurface,
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(color: palette.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List<Widget>.generate(5, (idx) {
                          return Icon(
                            idx < review.rating ? Icons.star : Icons.star_border,
                            size: 15,
                            color: AppColors.terracotta,
                          );
                        }),
                      ),
                      Text(
                        review.authorName,
                        style: AppTheme.bodyStyle(
                          locale: settings.locale,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                      ),
                      if (review.isVerifiedPurchase)
                        SemanticStatusBadge(
                          label: strings.get('review_verified'),
                          colorKey: 'success',
                        ),
                      Text(
                        review.formattedDate,
                        style: AppTheme.monoStyle(
                          fontSize: 11,
                          color: palette.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  if (review.title != null &&
                      review.title!.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      review.title!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodyStyle(
                        locale: settings.locale,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    review.body,
                    style: AppTheme.bodyStyle(
                      locale: settings.locale,
                      fontSize: 13,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _WriteReviewDialog extends StatefulWidget {
  const _WriteReviewDialog({required this.slug});

  final String slug;

  @override
  State<_WriteReviewDialog> createState() => _WriteReviewDialogState();
}

class _WriteReviewDialogState extends State<_WriteReviewDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  int _rating = 5;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final res = await context.read<ApiClient>().createReview(
            widget.slug,
            CreateReviewRequest(
              rating: _rating,
              title: _titleController.text,
              body: _bodyController.text,
            ),
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message)),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.firstErrorMessage;
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppSettingsProvider>().strings;
    return AlertDialog(
      title: Text(strings.get('write_review')),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (_error != null) ...<Widget>[
                  ResetErrorBanner(message: _error!),
                  const SizedBox(height: 12),
                ],
                Text(strings.get('review_rating')),
                const SizedBox(height: 6),
                Row(
                  children: List<Widget>.generate(5, (i) {
                    final star = i + 1;
                    return IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      onPressed: () => setState(() => _rating = star),
                      icon: Icon(
                        star <= _rating ? Icons.star : Icons.star_border,
                        color: AppColors.terracotta,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: strings.get('review_title'),
                    hintText: strings.get('review_title_placeholder'),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bodyController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: strings.get('review_body'),
                    hintText: strings.get('review_body_placeholder'),
                    alignLabelWithHint: true,
                  ),
                  validator: (val) => (val == null || val.trim().length < 5)
                      ? strings.get('error_required')
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: Text(strings.get('cancel')),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(strings.get('review_submit')),
        ),
      ],
    );
  }
}
