import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../models/order_payment_models.dart';
import '../../providers/app_settings_provider.dart';
import '../../widgets/common_states.dart';
import '../../widgets/reset_scaffold.dart';
import '../invoice/tax_invoice_screen.dart';
import '../payment/khqr_payment_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderNumber});

  final String orderNumber;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  OrderDetailDto? _order;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final order = await context.read<ApiClient>().getOrderDetail(
            widget.orderNumber,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _order = order;
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

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final settings = context.watch<AppSettingsProvider>();
    final strings = settings.strings;
    final order = _order;

    return ResetScaffold(
      showBackButton: true,
      title: '#${widget.orderNumber}',
      onRefreshContext: _loadOrder,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 80),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _errorMessage != null
                    ? ResetErrorBanner(
                        message: _errorMessage!,
                        onRetry: _loadOrder,
                      )
                    : order == null
                        ? const SizedBox.shrink()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              // Header Card
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: palette.cardSurface,
                                  borderRadius:
                                      BorderRadius.circular(AppRadii.sm),
                                  border: Border.all(
                                    color: palette.borderSubtle,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 8,
                                      alignment:
                                          WrapAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: <Widget>[
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              '#${order.number}',
                                              style: AppTheme.monoStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                color: palette.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              order.formattedCreatedAt,
                                              style: AppTheme.bodyStyle(
                                                locale: settings.locale,
                                                fontSize: 12.5,
                                                color: palette.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SemanticStatusBadge(
                                          label: order.statusLabel,
                                          colorKey: order.statusColor,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: <Widget>[
                                        if (order.canPayNow)
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.of(context)
                                                  .push(
                                                    MaterialPageRoute<void>(
                                                      builder: (_) =>
                                                          KhqrPaymentScreen(
                                                        orderNumber:
                                                            order.number,
                                                      ),
                                                    ),
                                                  )
                                                  .then((_) => _loadOrder());
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.terracotta,
                                              foregroundColor:
                                                  AppColors.pureWhite,
                                            ),
                                            icon: const Icon(
                                              Icons.qr_code_2,
                                              size: 18,
                                            ),
                                            label: Text(
                                              strings.get('account_pay_now'),
                                            ),
                                          ),
                                        OutlinedButton.icon(
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute<void>(
                                                builder: (_) =>
                                                    TaxInvoiceScreen(
                                                  orderNumber: order.number,
                                                ),
                                              ),
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.receipt_long_outlined,
                                            size: 18,
                                          ),
                                          label: Text(
                                            strings.get('invoice_download'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Fulfillment Timeline Card
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: palette.cardSurface,
                                  borderRadius:
                                      BorderRadius.circular(AppRadii.sm),
                                  border: Border.all(
                                    color: palette.borderSubtle,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      strings.get('fulfillment_status'),
                                      style: AppTheme.displayStyle(
                                        locale: settings.locale,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: palette.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    if (order.isTerminalNegative)
                                      SemanticStatusBadge(
                                        label: order.statusLabel,
                                        colorKey: order.statusColor,
                                      )
                                    else
                                      Column(
                                        children: order.statusTimeline
                                            .asMap()
                                            .entries
                                            .map((entry) {
                                          final idx = entry.key;
                                          final step = entry.value;
                                          final isLast = idx ==
                                              order.statusTimeline.length - 1;
                                          return _TimelineStepRow(
                                            step: step,
                                            isLast: isLast,
                                          );
                                        }).toList(),
                                      ),
                                  ],
                                ),
                              ),

                              // Shipping & Tracking Card
                              if (order.trackingNumber != null ||
                                  order.shippingCarrier != null) ...<Widget>[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: palette.cardSurface,
                                    borderRadius:
                                        BorderRadius.circular(AppRadii.sm),
                                    border: Border.all(
                                      color: palette.borderSubtle,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        strings.get(
                                          'shipping_and_tracking_info',
                                        ),
                                        style: AppTheme.displayStyle(
                                          locale: settings.locale,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: palette.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      if (order.shippingCarrier != null)
                                        Text(
                                          '${strings.get('order_carrier')}: ${order.shippingCarrier}',
                                          style: AppTheme.bodyStyle(
                                            locale: settings.locale,
                                            fontSize: 13.5,
                                            color: palette.textPrimary,
                                          ),
                                        ),
                                      if (order.trackingNumber != null)
                                        Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: Text(
                                                '${strings.get('order_tracking_number')}: ${order.trackingNumber}',
                                                style: AppTheme.monoStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: palette.textPrimary,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () async {
                                                await Clipboard.setData(
                                                  ClipboardData(
                                                    text:
                                                        order.trackingNumber!,
                                                  ),
                                                );
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        order.trackingNumber!,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                              icon: const Icon(
                                                Icons.copy,
                                                size: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 16),

                              // Address & Items Card
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: palette.cardSurface,
                                  borderRadius:
                                      BorderRadius.circular(AppRadii.sm),
                                  border: Border.all(
                                    color: palette.borderSubtle,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      strings.get(
                                        'invoice_shipping_destination',
                                      ),
                                      style: AppTheme.displayStyle(
                                        locale: settings.locale,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: palette.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${order.shippingAddress.displayName} • ${order.phone}',
                                      style: AppTheme.bodyStyle(
                                        locale: settings.locale,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: palette.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '${order.shippingAddress.streetAddress}, ${order.shippingAddress.displayRegion}',
                                      style: AppTheme.bodyStyle(
                                        locale: settings.locale,
                                        fontSize: 12.5,
                                        color: palette.textSecondary,
                                      ),
                                    ),
                                    if (order.customerNotes != null &&
                                        order.customerNotes!
                                            .isNotEmpty) ...<Widget>[
                                      const SizedBox(height: 8),
                                      Text(
                                        '${strings.get('order_notes')}: ${order.customerNotes}',
                                        style: AppTheme.bodyStyle(
                                          locale: settings.locale,
                                          fontSize: 12,
                                          color: palette.textSecondary,
                                        ),
                                      ),
                                    ],
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      child: Divider(
                                        color: palette.borderSubtle,
                                      ),
                                    ),
                                    ...order.items.map((item) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: Row(
                                          children: <Widget>[
                                            Container(
                                              width: 52,
                                              height: 64,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  AppRadii.xs,
                                                ),
                                                border: Border.all(
                                                  color: palette.borderSubtle,
                                                ),
                                              ),
                                              clipBehavior: Clip.antiAlias,
                                              child: ResetNetworkImage(
                                                imageUrl: item.imageUrl,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Text(
                                                    item.productName,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: AppTheme.bodyStyle(
                                                      locale: settings.locale,
                                                      fontSize: 13.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          palette.textPrimary,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${item.variantLabel} × ${item.quantity}',
                                                    style: AppTheme.monoStyle(
                                                      fontSize: 11.5,
                                                      color:
                                                          palette.textSecondary,
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
                                    Divider(color: palette.borderSubtle),
                                    const SizedBox(height: 10),
                                    _DetailPriceRow(
                                      label: strings.get('cart_subtotal'),
                                      value: order.formattedSubtotal,
                                    ),
                                    if (order.discountCents > 0) ...<Widget>[
                                      const SizedBox(height: 4),
                                      _DetailPriceRow(
                                        label: strings.get('cart_discount'),
                                        value: '-${order.formattedDiscount}',
                                        color: AppColors.terracotta,
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    _DetailPriceRow(
                                      label: strings.get('shipping_fee'),
                                      value: order.formattedShipping,
                                    ),
                                    const SizedBox(height: 8),
                                    _DetailPriceRow(
                                      label: strings.get('total_amount'),
                                      value: order.formattedTotal,
                                      bold: true,
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        '${order.formattedEquivalentKhr} ≈ ${order.formattedEquivalentUsd}',
                                        style: AppTheme.monoStyle(
                                          fontSize: 11,
                                          color: palette.textTertiary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
          ),
        ),
      ),
    );
  }
}

class _TimelineStepRow extends StatelessWidget {
  const _TimelineStepRow({required this.step, required this.isLast});

  final OrderStatusStepDto step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final locale = context.watch<AppSettingsProvider>().locale;
    final success = SemanticStatusColors.fromKey(
      'success',
      Theme.of(context).brightness,
    );

    final circleColor = step.completed
        ? success.dot
        : (step.active ? AppColors.terracotta : palette.borderSubtle);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Column(
          children: <Widget>[
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: step.completed || step.active
                    ? circleColor
                    : palette.elevatedSurface,
                shape: BoxShape.circle,
                border: Border.all(color: circleColor, width: 1.5),
              ),
              child: step.completed
                  ? const Icon(Icons.check, size: 13, color: AppColors.pureWhite)
                  : (step.active
                      ? const Icon(
                          Icons.circle,
                          size: 8,
                          color: AppColors.pureWhite,
                        )
                      : null),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                color: step.completed ? success.dot : palette.borderSubtle,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Text(
                    step.label,
                    style: AppTheme.bodyStyle(
                      locale: locale,
                      fontSize: 13.5,
                      fontWeight: (step.completed || step.active)
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: (step.completed || step.active)
                          ? palette.textPrimary
                          : palette.textTertiary,
                    ),
                  ),
                ),
                if (step.timestamp != null)
                  Text(
                    step.timestamp!,
                    style: AppTheme.monoStyle(
                      fontSize: 11,
                      color: palette.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailPriceRow extends StatelessWidget {
  const _DetailPriceRow({
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
