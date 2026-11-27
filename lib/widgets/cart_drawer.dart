import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api/api_exceptions.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_tokens.dart';
import '../models/cart_models.dart';
import '../providers/app_navigation_provider.dart';
import '../providers/app_settings_provider.dart';
import '../providers/cart_provider.dart';
import '../screens/checkout/checkout_screen.dart';
import '../screens/product/product_detail_screen.dart';
import 'common_states.dart';

class CartDrawer {
  CartDrawer._();

  static Future<void> show(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (AppBreakpoints.isMobile(width)) {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) {
          return FractionallySizedBox(
            heightFactor: 0.9,
            child: CartContentView(
              inDrawerOrSheet: true,
              onClose: () => Navigator.of(sheetContext).pop(),
              onProceedToCheckout: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CheckoutScreen(),
                  ),
                );
              },
              onContinueShopping: () {
                Navigator.of(sheetContext).pop();
                context.read<AppNavigationProvider>().openShop();
              },
            ),
          );
        },
      );
    }

    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cart Drawer',
      barrierColor: Colors.black54,
      transitionDuration: AppMotion.sheetAndDrawer,
      pageBuilder: (dialogContext, _, __) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: dialogContext.palette.scaffoldBackground,
            child: SizedBox(
              width: AppSpacing.cartDrawerWidth,
              height: double.infinity,
              child: CartContentView(
                inDrawerOrSheet: true,
                onClose: () => Navigator.of(dialogContext).pop(),
                onProceedToCheckout: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CheckoutScreen(),
                    ),
                  );
                },
                onContinueShopping: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  context.read<AppNavigationProvider>().openShop();
                },
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        final offset = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: AppMotion.curve));
        return SlideTransition(position: offset, child: child);
      },
    );
  }
}

class CartContentView extends StatefulWidget {
  const CartContentView({
    super.key,
    this.inDrawerOrSheet = false,
    this.onClose,
    required this.onProceedToCheckout,
    required this.onContinueShopping,
  });

  final bool inDrawerOrSheet;
  final VoidCallback? onClose;
  final VoidCallback onProceedToCheckout;
  final VoidCallback onContinueShopping;

  @override
  State<CartContentView> createState() => _CartContentViewState();
}

class _CartContentViewState extends State<CartContentView> {
  final TextEditingController _promoController = TextEditingController();
  String? _promoError;
  String? _actionError;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _updateQuantity(CartItemDto item, int nextQty) async {
    setState(() => _actionError = null);
    try {
      await context.read<CartProvider>().updateQuantity(
            itemId: item.id,
            quantity: nextQty,
          );
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _actionError = e.firstErrorMessage);
      }
    }
  }

  Future<void> _removeItem(CartItemDto item) async {
    setState(() => _actionError = null);
    try {
      await context.read<CartProvider>().removeItem(item.id);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _actionError = e.message);
      }
    }
  }

  Future<void> _applyPromo() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) {
      return;
    }
    setState(() {
      _promoError = null;
      _actionError = null;
    });
    try {
      final msg = await context.read<CartProvider>().applyDiscount(code);
      if (!mounted) {
        return;
      }
      _promoController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _promoError = e.fieldError('code') ?? e.message);
      }
    }
  }

  Future<void> _removePromo() async {
    setState(() {
      _promoError = null;
      _actionError = null;
    });
    try {
      await context.read<CartProvider>().removeDiscount();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _promoError = e.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final settings = context.watch<AppSettingsProvider>();
    final strings = settings.strings;
    final cartProvider = context.watch<CartProvider>();
    final cart = cartProvider.cart;

    return Container(
      decoration: widget.inDrawerOrSheet
          ? BoxDecoration(
              border: Border(left: BorderSide(color: palette.borderSubtle)),
            )
          : null,
      child: Column(
        children: <Widget>[
          // Header
          if (widget.inDrawerOrSheet)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: palette.borderSubtle)),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${strings.get('cart_drawer_title')} (${cartProvider.itemCount})',
                      style: AppTheme.displayStyle(
                        locale: settings.locale,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  if (widget.onClose != null)
                    IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
            ),

          if (cartProvider.isLoading && cart == null)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (cart == null || cart.items.isEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ResetEmptyState(
                  icon: Icons.shopping_bag_outlined,
                  title: strings.get('cart_empty'),
                  subtitle: strings.get('cart_empty_subtext'),
                  ctaLabel: strings.get('cart_empty_cta'),
                  onCtaPressed: widget.onContinueShopping,
                ),
              ),
            )
          else ...<Widget>[
            // Free Shipping Progress Banner
            _FreeShippingBanner(cart: cart),

            if (_actionError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: ResetErrorBanner(message: _actionError!),
              ),

            // Cart Items List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: cart.items.length,
                separatorBuilder: (_, __) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: palette.borderSubtle),
                ),
                itemBuilder: (context, index) {
                  final item = cart.items[index];
                  return _CartItemRow(
                    item: item,
                    disabled: cartProvider.isMutating,
                    onTapProduct: () {
                      widget.onClose?.call();
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ProductDetailScreen(
                            slug: item.productSlug,
                          ),
                        ),
                      );
                    },
                    onDecrement: () => _updateQuantity(
                      item,
                      item.quantity <= 1 ? 0 : item.quantity - 1,
                    ),
                    onIncrement: item.quantity < item.maxStock &&
                            item.quantity < 20
                        ? () => _updateQuantity(item, item.quantity + 1)
                        : null,
                    onRemove: () => _removeItem(item),
                  );
                },
              ),
            ),

            // Promo & Totals Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.surfaceBone,
                border: Border(top: BorderSide(color: palette.borderSubtle)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Promo Code Section
                    if (cart.discountCode != null &&
                        cart.discountCode!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: SemanticStatusColors.fromKey(
                            'success',
                            Theme.of(context).brightness,
                          ).background,
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                          border: Border.all(
                            color: SemanticStatusColors.fromKey(
                              'success',
                              Theme.of(context).brightness,
                            ).border,
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.local_offer_outlined,
                              size: 16,
                              color: SemanticStatusColors.fromKey(
                                'success',
                                Theme.of(context).brightness,
                              ).foreground,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${cart.discountCode} (${cart.discount?.formattedValue ?? cart.formattedDiscount})',
                                style: AppTheme.monoStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: SemanticStatusColors.fromKey(
                                    'success',
                                    Theme.of(context).brightness,
                                  ).foreground,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: cartProvider.isMutating
                                  ? null
                                  : _removePromo,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                minimumSize: const Size(0, 30),
                              ),
                              child: Text(strings.get('cart_promo_remove')),
                            ),
                          ],
                        ),
                      )
                    else
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              controller: _promoController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                hintText: strings.get('cart_promo_placeholder'),
                                isDense: true,
                              ),
                              onSubmitted: (_) => _applyPromo(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed:
                                cartProvider.isMutating ? null : _applyPromo,
                            child: Text(strings.get('cart_promo_apply')),
                          ),
                        ],
                      ),
                    if (_promoError != null) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        _promoError!,
                        style: AppTheme.bodyStyle(
                          locale: settings.locale,
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _TotalRow(
                      label: strings.get('cart_subtotal'),
                      value: cart.formattedSubtotal,
                    ),
                    if (cart.discountCents > 0) ...<Widget>[
                      const SizedBox(height: 6),
                      _TotalRow(
                        label: strings.get('cart_discount'),
                        value: '-${cart.formattedDiscount}',
                        valueColor: AppColors.terracotta,
                      ),
                    ],
                    const SizedBox(height: 6),
                    _TotalRow(
                      label: strings.get('cart_shipping'),
                      value: cart.formattedShipping,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Divider(color: palette.borderSubtle),
                    ),
                    _TotalRow(
                      label: strings.get('cart_total'),
                      value: cart.formattedTotal,
                      isGrandTotal: true,
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: cartProvider.isMutating
                          ? null
                          : widget.onProceedToCheckout,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(strings.get('cart_checkout')),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 16),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.get('cart_security_badge'),
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyStyle(
                        locale: settings.locale,
                        fontSize: 11,
                        color: palette.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FreeShippingBanner extends StatelessWidget {
  const _FreeShippingBanner({required this.cart});

  final CartPayloadDto cart;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final settings = context.watch<AppSettingsProvider>();
    final strings = settings.strings;
    final progress =
        (cart.freeShippingProgressPercent / 100.0).clamp(0.0, 1.0);
    final successColors = SemanticStatusColors.fromKey(
      'success',
      Theme.of(context).brightness,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: palette.surfaceBone,
        border: Border(bottom: BorderSide(color: palette.borderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                cart.freeShippingQualified
                    ? Icons.verified_outlined
                    : Icons.local_shipping_outlined,
                size: 16,
                color: cart.freeShippingQualified
                    ? successColors.foreground
                    : AppColors.terracotta,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cart.freeShippingQualified
                      ? strings.get('cart_free_shipping_unlocked')
                      : strings.get('cart_free_shipping_hint', <String, String>{
                          'amount': cart.freeShippingRemainingFormatted,
                        }),
                  style: AppTheme.bodyStyle(
                    locale: settings.locale,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cart.freeShippingQualified
                        ? successColors.foreground
                        : palette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: LinearProgressIndicator(
              value: cart.freeShippingQualified ? 1.0 : progress,
              minHeight: 6,
              backgroundColor: palette.borderSubtle,
              valueColor: AlwaysStoppedAnimation<Color>(
                cart.freeShippingQualified
                    ? successColors.dot
                    : AppColors.terracotta,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemRow extends StatelessWidget {
  const _CartItemRow({
    required this.item,
    required this.disabled,
    required this.onTapProduct,
    required this.onDecrement,
    required this.onIncrement,
    required this.onRemove,
  });

  final CartItemDto item;
  final bool disabled;
  final VoidCallback onTapProduct;
  final VoidCallback onDecrement;
  final VoidCallback? onIncrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final locale = context.watch<AppSettingsProvider>().locale;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        GestureDetector(
          onTap: onTapProduct,
          child: Container(
            width: 76,
            height: 94,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(color: palette.borderSubtle),
            ),
            clipBehavior: Clip.antiAlias,
            child: ResetNetworkImage(
              imageUrl: item.imageUrl,
              fit: BoxFit.cover,
              cacheWidth: 200,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: GestureDetector(
                      onTap: onTapProduct,
                      child: Text(
                        item.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.bodyStyle(
                          locale: locale,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                          height: locale == 'km' ? 1.45 : 1.25,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    onPressed: disabled ? null : onRemove,
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: palette.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${item.variantLabel} • ${item.sku}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.monoStyle(
                  fontSize: 11,
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        _StepperBtn(
                          icon: Icons.remove,
                          onTap: disabled ? null : onDecrement,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            '${item.quantity}',
                            style: AppTheme.monoStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: palette.textPrimary,
                            ),
                          ),
                        ),
                        _StepperBtn(
                          icon: Icons.add,
                          onTap: disabled ? null : onIncrement,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    item.formattedSubtotal,
                    style: AppTheme.monoStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepperBtn extends StatelessWidget {
  const _StepperBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 14,
          color: onTap == null ? palette.textTertiary : palette.textPrimary,
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isGrandTotal = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool isGrandTotal;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final locale = context.watch<AppSettingsProvider>().locale;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          label,
          style: isGrandTotal
              ? AppTheme.displayStyle(
                  locale: locale,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                )
              : AppTheme.bodyStyle(
                  locale: locale,
                  fontSize: 13,
                  color: palette.textSecondary,
                ),
        ),
        Text(
          value,
          style: AppTheme.monoStyle(
            fontSize: isGrandTotal ? 16 : 13,
            fontWeight: FontWeight.w700,
            color: valueColor ?? palette.textPrimary,
          ),
        ),
      ],
    );
  }
}
