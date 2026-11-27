import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/cart_models.dart';
import '../../models/order_payment_models.dart';
import '../../providers/app_navigation_provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bootstrap_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/common_states.dart';
import '../../widgets/reset_scaffold.dart';
import '../auth/login_screen.dart';
import '../payment/khqr_payment_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _districtController = TextEditingController();
  final _communeController = TextEditingController();
  final _streetController = TextEditingController();
  final _notesController = TextEditingController();
  final _promoController = TextEditingController();

  bool _isSubmitting = false;
  bool _prefilled = false;
  String? _generalError;
  String? _promoError;
  String? _expressResetBanner;
  Map<String, List<String>> _fieldErrors = const <String, List<String>>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefillUserAndCart();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _districtController.dispose();
    _communeController.dispose();
    _streetController.dispose();
    _notesController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _prefillUserAndCart() async {
    if (_prefilled) {
      return;
    }
    _prefilled = true;

    final auth = context.read<AuthProvider>();
    final cartProvider = context.read<CartProvider>();
    await cartProvider.refreshCart(silent: true);

    if (!mounted) {
      return;
    }

    if (auth.isAuthenticated) {
      final user = auth.user!;
      _nameController.text = user.name;
      _emailController.text = user.email;
      _phoneController.text = user.phone ?? '';
      try {
        final profile = await context.read<ApiClient>().getProfile();
        if (!mounted) {
          return;
        }
        final addr = profile.defaultShippingAddress;
        if (addr != null) {
          if (addr.fullName.trim().isNotEmpty) {
            _nameController.text = addr.fullName;
          }
          if (addr.phone.trim().isNotEmpty) {
            _phoneController.text = addr.phone;
          }
          _districtController.text = addr.district ?? '';
          _communeController.text = addr.commune ?? '';
          _streetController.text = addr.streetAddress;
          await cartProvider.setShippingContext(
            province: addr.province,
            shippingMethod: addr.province == 'Phnom Penh'
                ? cartProvider.selectedShippingMethod
                : 'standard',
          );
        }
      } catch (_) {
        // Fallback silently to basic user fields
      }
    }
  }

  Future<void> _onProvinceChanged(String nextProvince) async {
    final strings = context.read<AppSettingsProvider>().strings;
    final didReset = await context.read<CartProvider>().setShippingContext(
          province: nextProvince,
        );
    if (!mounted) {
      return;
    }
    setState(() {
      _expressResetBanner =
          didReset ? strings.get('express_reset_notice') : null;
    });
  }

  Future<void> _onShippingMethodChanged(String method) async {
    final cartProvider = context.read<CartProvider>();
    await cartProvider.setShippingContext(
      province: cartProvider.selectedProvince,
      shippingMethod: method,
    );
    if (mounted) {
      setState(() => _expressResetBanner = null);
    }
  }

  Future<void> _pickProvinceModal(List<String> provinces) async {
    final strings = context.read<AppSettingsProvider>().strings;
    final selected = await showDialog<String>(
      context: context,
      builder: (_) => _ProvincePickerDialog(
        provinces: provinces,
        selectedProvince: context.read<CartProvider>().selectedProvince,
        title: strings.get('checkout_select_province'),
      ),
    );
    if (selected != null) {
      await _onProvinceChanged(selected);
    }
  }

  Future<void> _applyPromo() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) {
      return;
    }
    setState(() => _promoError = null);
    try {
      final msg = await context.read<CartProvider>().applyDiscount(code);
      if (mounted) {
        _promoController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _promoError = e.fieldError('code') ?? e.message);
      }
    }
  }

  Future<void> _submitCheckout() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final cartProvider = context.read<CartProvider>();
    final selectedProvince = cartProvider.selectedProvince;
    final shippingMethod = selectedProvince == 'Phnom Penh'
        ? cartProvider.selectedShippingMethod
        : 'standard';

    setState(() {
      _isSubmitting = true;
      _generalError = null;
      _fieldErrors = const <String, List<String>>{};
    });

    try {
      final res = await context.read<ApiClient>().checkout(
            CheckoutRequest(
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              phone: _phoneController.text.trim(),
              province: selectedProvince,
              district: _districtController.text.trim(),
              commune: _communeController.text.trim(),
              streetAddress: _streetController.text.trim(),
              shippingMethod: shippingMethod,
              notes: _notesController.text.trim(),
            ),
          );
      if (!mounted) {
        return;
      }
      cartProvider.clearAfterCheckout();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => KhqrPaymentScreen(
            orderNumber: res.order.number,
            initialOrder: res.order,
            initialPayment: res.payment,
            orderToken: res.orderAccessToken,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _fieldErrors = e.errors;
        _generalError = e.message;
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String? _fieldError(String key) {
    final list = _fieldErrors[key];
    return (list != null && list.isNotEmpty) ? list.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final settings = context.watch<AppSettingsProvider>();
    final strings = settings.strings;
    final auth = context.watch<AuthProvider>();
    final bootstrap = context.watch<BootstrapProvider>();
    final cartProvider = context.watch<CartProvider>();
    final cart = cartProvider.cart;
    final width = MediaQuery.sizeOf(context).width;
    final isWide = AppBreakpoints.isDesktop(width);

    if (cart == null || cart.items.isEmpty) {
      return ResetScaffold(
        showBackButton: true,
        title: strings.get('checkout_title'),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: ResetEmptyState(
            icon: Icons.shopping_bag_outlined,
            title: strings.get('cart_empty'),
            subtitle: strings.get('cart_empty_subtext'),
            ctaLabel: strings.get('cart_empty_cta'),
            onCtaPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
              context.read<AppNavigationProvider>().openShop();
            },
          ),
        ),
      );
    }

    final expressFeeLabel = CurrencyFormatter.formatCents(
      bootstrap.settings?.expressShippingFeeKhr ??
          CurrencyFormatter.expressShippingFeeKhr,
      currency: settings.currency,
      exchangeRate: bootstrap.exchangeRate,
    );
    final standardFeeLabel = CurrencyFormatter.formatCents(
      0,
      currency: settings.currency,
      exchangeRate: bootstrap.exchangeRate,
    );

    final formSection = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Auth Status Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.surfaceBone,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(color: palette.borderSubtle),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  auth.isAuthenticated
                      ? Icons.verified_user_outlined
                      : Icons.person_outline,
                  size: 18,
                  color: AppColors.terracotta,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    auth.isAuthenticated
                        ? strings.get('checkout_signed_in_as', <String, String>{
                            'email': auth.user!.email,
                          })
                        : strings.get('checkout_guest_or_login'),
                    style: AppTheme.bodyStyle(
                      locale: settings.locale,
                      fontSize: 12.5,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
                if (!auth.isAuthenticated)
                  TextButton(
                    onPressed: () async {
                      final ok = await Navigator.of(context).push<bool>(
                        MaterialPageRoute<bool>(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                      if (ok == true) {
                        _prefilled = false;
                        _prefillUserAndCart();
                      }
                    },
                    child: Text(strings.get('nav_login')),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          if (_generalError != null) ...<Widget>[
            ResetErrorBanner(message: _generalError!),
            const SizedBox(height: 16),
          ],

          // Contact Information
          _SectionCard(
            title: strings.get('checkout_contact_info'),
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: strings.get('checkout_full_name'),
                  errorText: _fieldError('name'),
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? strings.get('error_required')
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: strings.get('checkout_email'),
                  errorText: _fieldError('email'),
                ),
                validator: (val) => (val == null || !val.contains('@'))
                    ? strings.get('error_invalid_email')
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: strings.get('checkout_phone'),
                  hintText: '012 345 678',
                  errorText: _fieldError('phone'),
                ),
                validator: (val) => (val == null || val.trim().length < 8)
                    ? strings.get('error_required')
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Shipping Address
          _SectionCard(
            title: strings.get('checkout_shipping_address'),
            children: <Widget>[
              InkWell(
                onTap: () => _pickProvinceModal(bootstrap.provinces),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: strings.get('checkout_province'),
                    errorText: _fieldError('province'),
                    suffixIcon: const Icon(Icons.keyboard_arrow_down),
                  ),
                  child: Text(
                    cartProvider.selectedProvince,
                    style: AppTheme.bodyStyle(
                      locale: settings.locale,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _districtController,
                      decoration: InputDecoration(
                        labelText: strings.get('checkout_district'),
                        errorText: _fieldError('district'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _communeController,
                      decoration: InputDecoration(
                        labelText: strings.get('checkout_commune'),
                        errorText: _fieldError('commune'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _streetController,
                decoration: InputDecoration(
                  labelText: strings.get('checkout_street_address'),
                  errorText: _fieldError('street_address'),
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? strings.get('error_required')
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: strings.get('checkout_notes'),
                  errorText: _fieldError('notes'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Delivery Method (Express STRICTLY Phnom Penh only!)
          _SectionCard(
            title: strings.get('checkout_delivery_method'),
            children: <Widget>[
              if (_expressResetBanner != null) ...<Widget>[
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: SemanticStatusColors.fromKey(
                      'warning',
                      Theme.of(context).brightness,
                    ).background,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(
                      color: SemanticStatusColors.fromKey(
                        'warning',
                        Theme.of(context).brightness,
                      ).border,
                    ),
                  ),
                  child: Text(
                    _expressResetBanner!,
                    style: AppTheme.bodyStyle(
                      locale: settings.locale,
                      fontSize: 12,
                      color: SemanticStatusColors.fromKey(
                        'warning',
                        Theme.of(context).brightness,
                      ).foreground,
                    ),
                  ),
                ),
              ],
              _DeliveryOptionTile(
                title: strings.get('checkout_standard_delivery'),
                subtitle: strings.get('standard_delivery_desc'),
                priceLabel: standardFeeLabel,
                selected: cartProvider.selectedShippingMethod == 'standard',
                onTap: () => _onShippingMethodChanged('standard'),
              ),
              if (cartProvider.canUseExpressShipping) ...<Widget>[
                const SizedBox(height: 10),
                _DeliveryOptionTile(
                  title: strings.get('checkout_express_delivery'),
                  subtitle: strings.get('express_delivery_desc'),
                  priceLabel: expressFeeLabel,
                  selected: cartProvider.selectedShippingMethod == 'express',
                  onTap: () => _onShippingMethodChanged('express'),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    final summarySection = _OrderSummaryCard(
      cart: cart,
      promoController: _promoController,
      promoError: _promoError,
      isMutating: cartProvider.isMutating,
      isSubmitting: _isSubmitting,
      onApplyPromo: _applyPromo,
      onRemovePromo: () => cartProvider.removeDiscount(),
      onPlaceOrder: _submitCheckout,
    );

    return ResetScaffold(
      showBackButton: true,
      title: strings.get('checkout_title'),
      onRefreshContext: () => cartProvider.refreshCart(silent: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxContentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  strings.get('checkout_title'),
                  style: AppTheme.displayStyle(
                    locale: settings.locale,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(flex: 7, child: formSection),
                      const SizedBox(width: 28),
                      Expanded(flex: 5, child: summarySection),
                    ],
                  )
                else ...<Widget>[
                  formSection,
                  const SizedBox(height: 20),
                  summarySection,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final locale = context.watch<AppSettingsProvider>().locale;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.cardSurface,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: AppTheme.displayStyle(
              locale: locale,
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _DeliveryOptionTile extends StatelessWidget {
  const _DeliveryOptionTile({
    required this.title,
    required this.subtitle,
    required this.priceLabel,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String priceLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final locale = context.watch<AppSettingsProvider>().locale;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.elevatedSurface,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(
            color: selected ? AppColors.terracotta : palette.borderSubtle,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: selected ? AppColors.terracotta : palette.textTertiary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: AppTheme.bodyStyle(
                      locale: locale,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTheme.bodyStyle(
                      locale: locale,
                      fontSize: 12,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              priceLabel,
              style: AppTheme.monoStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({
    required this.cart,
    required this.promoController,
    required this.promoError,
    required this.isMutating,
    required this.isSubmitting,
    required this.onApplyPromo,
    required this.onRemovePromo,
    required this.onPlaceOrder,
  });

  final CartPayloadDto cart;
  final TextEditingController promoController;
  final String? promoError;
  final bool isMutating;
  final bool isSubmitting;
  final VoidCallback onApplyPromo;
  final VoidCallback onRemovePromo;
  final VoidCallback onPlaceOrder;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final settings = context.watch<AppSettingsProvider>();
    final strings = settings.strings;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surfaceBone,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            strings.get('checkout_order_summary'),
            style: AppTheme.displayStyle(
              locale: settings.locale,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          ...cart.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${item.quantity}× ${item.productName} (${item.variantLabel})',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodyStyle(
                        locale: settings.locale,
                        fontSize: 12.5,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.formattedSubtotal,
                    style: AppTheme.monoStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }),
          Divider(color: palette.borderSubtle),
          const SizedBox(height: 12),

          if (cart.discountCode != null && cart.discountCode!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                    onPressed: isMutating ? null : onRemovePromo,
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
                    controller: promoController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: strings.get('cart_promo_placeholder'),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: isMutating ? null : onApplyPromo,
                  child: Text(strings.get('cart_promo_apply')),
                ),
              ],
            ),
          if (promoError != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              promoError!,
              style: AppTheme.bodyStyle(
                locale: settings.locale,
                fontSize: 12,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],

          const SizedBox(height: 14),
          _SummaryLine(
            label: strings.get('cart_subtotal'),
            value: cart.formattedSubtotal,
          ),
          if (cart.discountCents > 0) ...<Widget>[
            const SizedBox(height: 6),
            _SummaryLine(
              label: strings.get('cart_discount'),
              value: '-${cart.formattedDiscount}',
              color: AppColors.terracotta,
            ),
          ],
          const SizedBox(height: 6),
          _SummaryLine(
            label: strings.get('shipping_fee'),
            value: cart.formattedShipping,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: palette.borderSubtle),
          ),
          _SummaryLine(
            label: strings.get('cart_total'),
            value: cart.formattedTotal,
            bold: true,
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              CurrencyFormatter.formatEquivalent(
                cart.totalCents,
                primaryCurrency: cart.currency,
                exchangeRate: cart.exchangeRate,
              ),
              style: AppTheme.monoStyle(
                fontSize: 11.5,
                color: palette.textTertiary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: palette.elevatedSurface,
              borderRadius: BorderRadius.circular(AppRadii.xs),
              border: Border.all(color: palette.borderSubtle),
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: AppColors.terracotta,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    strings.get('checkout_stock_reserved_note'),
                    style: AppTheme.bodyStyle(
                      locale: settings.locale,
                      fontSize: 11.5,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: isSubmitting ? null : onPlaceOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.khqrRed,
              foregroundColor: AppColors.pureWhite,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.pureWhite,
                    ),
                  )
                : Text(strings.get('checkout_place_order')),
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
    this.color,
    this.bold = false,
  });

  final String label;
  final String value;
  final Color? color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final locale = context.watch<AppSettingsProvider>().locale;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          label,
          style: bold
              ? AppTheme.displayStyle(
                  locale: locale,
                  fontSize: 15,
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
            fontSize: bold ? 16 : 13,
            fontWeight: FontWeight.w700,
            color: color ?? palette.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ProvincePickerDialog extends StatefulWidget {
  const _ProvincePickerDialog({
    required this.provinces,
    required this.selectedProvince,
    required this.title,
  });

  final List<String> provinces;
  final String selectedProvince;
  final String title;

  @override
  State<_ProvincePickerDialog> createState() => _ProvincePickerDialogState();
}

class _ProvincePickerDialogState extends State<_ProvincePickerDialog> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.provinces
        .where((p) => p.toLowerCase().contains(_filter.toLowerCase()))
        .toList();

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 380,
        height: 400,
        child: Column(
          children: <Widget>[
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, size: 18),
                hintText: 'Phnom Penh, Siem Reap...',
                isDense: true,
              ),
              onChanged: (val) => setState(() => _filter = val.trim()),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final province = filtered[index];
                  final selected = province == widget.selectedProvince;
                  return ListTile(
                    dense: true,
                    title: Text(province),
                    trailing: selected
                        ? const Icon(
                            Icons.check,
                            size: 18,
                            color: AppColors.terracotta,
                          )
                        : null,
                    onTap: () => Navigator.of(context).pop(province),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
