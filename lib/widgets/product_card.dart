import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/app_tokens.dart';
import '../core/utils/currency_formatter.dart';
import '../models/catalog_models.dart';
import '../providers/app_settings_provider.dart';
import '../providers/bootstrap_provider.dart';
import '../providers/wishlist_provider.dart';
import 'common_states.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onWishlistTap,
    this.showWishlistButton = true,
  });

  final ProductCardDto product;
  final VoidCallback onTap;
  final VoidCallback? onWishlistTap;
  final bool showWishlistButton;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final settings = context.watch<AppSettingsProvider>();
    final strings = settings.strings;
    final exchangeRate = context.select<BootstrapProvider, int>(
      (b) => b.exchangeRate,
    );
    final isWishlisted = context.select<WishlistProvider, bool>(
      (w) => w.isWishlisted(product.id),
    );

    final displayPrice = product.formattedPrice.isNotEmpty
        ? product.formattedPrice
        : CurrencyFormatter.formatCents(
            product.basePriceCents,
            currency: settings.currency,
            exchangeRate: exchangeRate,
          );

    final displayCompareAt = product.formattedCompareAtPrice ??
        (product.compareAtPriceCents != null
            ? CurrencyFormatter.formatCents(
                product.compareAtPriceCents!,
                currency: settings.currency,
                exchangeRate: exchangeRate,
              )
            : null);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // 3:4 Image Frame
            AspectRatio(
              aspectRatio: 3 / 4,
              child: Container(
                decoration: BoxDecoration(
                  color: palette.elevatedSurface,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(color: palette.borderSubtle),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    ResetNetworkImage(
                      imageUrl: product.primaryImageUrl,
                      fit: BoxFit.cover,
                      cacheWidth: 600,
                    ),
                    // Top-left status badges
                    Positioned(
                      top: 8,
                      left: 8,
                      right: showWishlistButton ? 40 : 8,
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: <Widget>[
                          if (product.isOnSale)
                            _CardBadge(
                              label: strings.get('badge_sale'),
                              backgroundColor: AppColors.terracotta,
                              foregroundColor: AppColors.pureWhite,
                            ),
                          if (product.isBestSeller && !product.isOnSale)
                            _CardBadge(
                              label: strings.get('badge_bestseller'),
                              backgroundColor: AppColors.onyxBlack,
                              foregroundColor: AppColors.pureWhite,
                            ),
                        ],
                      ),
                    ),
                    if (showWishlistButton && onWishlistTap != null)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Material(
                          color: palette.elevatedSurface.withValues(alpha: 0.9),
                          shape: CircleBorder(
                            side: BorderSide(color: palette.borderSubtle),
                          ),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: onWishlistTap,
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                isWishlisted
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 16,
                                color: isWishlisted
                                    ? AppColors.terracotta
                                    : palette.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (!product.isInStock)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: _CardBadge(
                          label: strings.get('out_of_stock'),
                          backgroundColor: AppColors.onyxBlack.withValues(
                            alpha: 0.85,
                          ),
                          foregroundColor: AppColors.pureWhite,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Category overline & Price row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (product.category != null) ...<Widget>[
                        Text(
                          product.category!.name.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.displayStyle(
                            locale: settings.locale,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: palette.textTertiary,
                            letterSpacing: settings.isKm ? 0 : 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                        style: AppTheme.bodyStyle(
                          locale: settings.locale,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: palette.textPrimary,
                          height: settings.isKm ? 1.5 : 1.25,
                        ),
                      ),
                      if (product.tagline != null &&
                          product.tagline!.trim().isNotEmpty) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(
                          product.tagline!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.bodyStyle(
                            locale: settings.locale,
                            fontSize: 11.5,
                            color: palette.textSecondary,
                            height: settings.isKm ? 1.5 : 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      displayPrice,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.monoStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                    if (displayCompareAt != null)
                      Text(
                        displayCompareAt,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.monoStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: palette.textTertiary,
                        ).copyWith(decoration: TextDecoration.lineThrough),
                      ),
                  ],
                ),
              ],
            ),
            if (product.colors.isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  ...product.colors.take(4).map((swatch) {
                    return Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: parseHexColor(swatch.code),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: palette.borderSubtle,
                          width: 1,
                        ),
                      ),
                    );
                  }),
                  if (product.colors.length > 4)
                    Text(
                      '+${product.colors.length - 4}',
                      style: AppTheme.monoStyle(
                        fontSize: 10,
                        color: palette.textTertiary,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CardBadge extends StatelessWidget {
  const _CardBadge({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadii.xs),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTheme.displayStyle(
          locale: 'en',
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: foregroundColor,
          letterSpacing: 0.8,
          height: 1.1,
        ),
      ),
    );
  }
}
