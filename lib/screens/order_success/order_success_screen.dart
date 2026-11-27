import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../models/order_payment_models.dart';
import '../../providers/app_navigation_provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_states.dart';
import '../../widgets/reset_scaffold.dart';
import '../account/order_detail_screen.dart';
import '../invoice/tax_invoice_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({
    super.key,
    required this.order,
    this.orderToken,
  });

  final OrderDetailDto order;
  final String? orderToken;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final settings = context.watch<AppSettingsProvider>();
    final strings = settings.strings;
    final auth = context.watch<AuthProvider>();
    final successColors = SemanticStatusColors.fromKey(
      'success',
      Theme.of(context).brightness,
    );

    return ResetScaffold(
      showBackButton: true,
      title: strings.get('success_order_number'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: palette.cardSurface,
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(color: palette.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: successColors.background,
                        shape: BoxShape.circle,
                        border: Border.all(color: successColors.border),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 34,
                        color: successColors.foreground,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    strings.get('success_title'),
                    textAlign: TextAlign.center,
                    style: AppTheme.displayStyle(
                      locale: settings.locale,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.get('success_subtitle'),
                    textAlign: TextAlign.center,
                    style: AppTheme.bodyStyle(
                      locale: settings.locale,
                      fontSize: 13.5,
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Order Number + Method Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: palette.surfaceBone,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      border: Border.all(color: palette.borderSubtle),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              strings.get('success_order_number').toUpperCase(),
                              style: AppTheme.displayStyle(
                                locale: settings.locale,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: palette.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '#${order.number}',
                              style: AppTheme.monoStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: palette.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        SemanticStatusBadge(
                          label: strings.get('bakong_payment_badge'),
                          colorKey: 'success',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Destination
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: palette.elevatedSurface,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      border: Border.all(color: palette.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          strings
                              .get('invoice_shipping_destination')
                              .toUpperCase(),
                          style: AppTheme.displayStyle(
                            locale: settings.locale,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: palette.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${order.shippingAddress.displayName} • ${order.phone}',
                          style: AppTheme.bodyStyle(
                            locale: settings.locale,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${order.shippingAddress.streetAddress}, ${order.shippingAddress.displayRegion}',
                          style: AppTheme.bodyStyle(
                            locale: settings.locale,
                            fontSize: 12.5,
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Items List
                  ...order.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  '${item.quantity}× ${item.productName}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTheme.bodyStyle(
                                    locale: settings.locale,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: palette.textPrimary,
                                  ),
                                ),
                                Text(
                                  item.variantLabel,
                                  style: AppTheme.monoStyle(
                                    fontSize: 11,
                                    color: palette.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.formattedSubtotal,
                            style: AppTheme.monoStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: palette.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: palette.borderSubtle),
                  ),
                  _SummaryRow(
                    label: strings.get('cart_subtotal'),
                    value: order.formattedSubtotal,
                  ),
                  if (order.discountCents > 0) ...<Widget>[
                    const SizedBox(height: 4),
                    _SummaryRow(
                      label: strings.get('cart_discount'),
                      value: '-${order.formattedDiscount}',
                      color: AppColors.terracotta,
                    ),
                  ],
                  const SizedBox(height: 4),
                  _SummaryRow(
                    label: strings.get('shipping_fee'),
                    value: order.formattedShipping,
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: strings.get('total_amount'),
                    value: order.formattedTotal,
                    bold: true,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${order.formattedEquivalentKhr} ≈ ${order.formattedEquivalentUsd}',
                      style: AppTheme.monoStyle(
                        fontSize: 11.5,
                        color: palette.textTertiary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => TaxInvoiceScreen(
                            orderNumber: order.number,
                            orderToken: orderToken,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.receipt_long_outlined, size: 18),
                    label: Text(strings.get('invoice_download')),
                  ),
                  if (auth.isAuthenticated) ...<Widget>[
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => OrderDetailScreen(
                              orderNumber: order.number,
                            ),
                          ),
                        );
                      },
                      child: Text(strings.get('success_view_order')),
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      context.read<AppNavigationProvider>().openShop();
                    },
                    child: Text(strings.get('success_continue_shopping')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
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
            fontSize: bold ? 15 : 13,
            fontWeight: FontWeight.w700,
            color: color ?? palette.textPrimary,
          ),
        ),
      ],
    );
  }
}
