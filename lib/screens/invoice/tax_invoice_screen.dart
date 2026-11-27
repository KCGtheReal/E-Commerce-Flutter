import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/web_print.dart';
import '../../models/order_payment_models.dart';
import '../../providers/app_settings_provider.dart';
import '../../widgets/common_states.dart';
import '../../widgets/reset_scaffold.dart';

class TaxInvoiceScreen extends StatefulWidget {
  const TaxInvoiceScreen({
    super.key,
    required this.orderNumber,
    this.orderToken,
  });

  final String orderNumber;
  final String? orderToken;

  @override
  State<TaxInvoiceScreen> createState() => _TaxInvoiceScreenState();
}

class _TaxInvoiceScreenState extends State<TaxInvoiceScreen> {
  TaxInvoiceDto? _invoice;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final invoice = await context.read<ApiClient>().getOrderInvoice(
            widget.orderNumber,
            orderToken: widget.orderToken,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _invoice = invoice;
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

  Future<void> _handlePrintOrOpenWeb(TaxInvoiceDto invoice) async {
    final printed = triggerBrowserPrint();
    if (!printed && mounted) {
      final url = context.read<ApiClient>().webInvoiceUrl(invoice.order.number);
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _copySummary(TaxInvoiceDto invoice) async {
    final strings = context.read<AppSettingsProvider>().strings;
    final order = invoice.order;
    final buffer = StringBuffer()
      ..writeln('${invoice.storeInfo.name} — TAX INVOICE')
      ..writeln('Invoice: ${invoice.invoiceNumber} | Order: #${order.number}')
      ..writeln('Date: ${invoice.issuedDate} | Status: ${order.statusLabel}')
      ..writeln('Customer: ${order.shippingAddress.displayName}')
      ..writeln('Total: ${order.formattedTotal} (${order.formattedEquivalentUsd})')
      ..writeln(
        invoice.payment != null
            ? 'Bakong MD5: ${invoice.payment!.md5}'
            : '',
      );
    await Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.get('invoice_copied'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    final strings = settings.strings;
    final invoice = _invoice;

    return ResetScaffold(
      showBackButton: true,
      title: '${strings.get('invoice_tax_invoice')} #${widget.orderNumber}',
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 80),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _errorMessage != null
                    ? ResetErrorBanner(
                        message: _errorMessage!,
                        onRetry: _loadInvoice,
                      )
                    : invoice == null
                        ? const SizedBox.shrink()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              // Top Action Controls
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                alignment: WrapAlignment.end,
                                children: <Widget>[
                                  OutlinedButton.icon(
                                    onPressed: () => _copySummary(invoice),
                                    icon: const Icon(Icons.copy, size: 16),
                                    label: Text(
                                      strings.get('invoice_copy_summary'),
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      final url = context
                                          .read<ApiClient>()
                                          .webInvoiceUrl(invoice.order.number);
                                      launchUrl(
                                        Uri.parse(url),
                                        mode: LaunchMode.externalApplication,
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.open_in_new,
                                      size: 16,
                                    ),
                                    label: Text(
                                      strings.get('invoice_open_web'),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        _handlePrintOrOpenWeb(invoice),
                                    icon: const Icon(Icons.print, size: 16),
                                    label: Text(strings.get('invoice_print')),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Monochrome Printable Paper Card
                              _InvoicePaperDocument(invoice: invoice),
                            ],
                          ),
          ),
        ),
      ),
    );
  }
}

class _InvoicePaperDocument extends StatelessWidget {
  const _InvoicePaperDocument({required this.invoice});

  final TaxInvoiceDto invoice;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    final strings = settings.strings;
    final order = invoice.order;
    final payment = invoice.payment;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(AppRadii.xs),
        border: Border.all(color: AppColors.onyxBlack, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'RESET',
                      style: AppTheme.displayStyle(
                        locale: 'en',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onyxBlack,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      invoice.storeInfo.tagline,
                      style: AppTheme.bodyStyle(
                        locale: settings.locale,
                        fontSize: 12,
                        color: AppColors.neutralGray,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      invoice.storeInfo.name,
                      style: AppTheme.bodyStyle(
                        locale: settings.locale,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onyxBlack,
                      ),
                    ),
                    Text(
                      invoice.storeInfo.address,
                      style: AppTheme.bodyStyle(
                        locale: settings.locale,
                        fontSize: 12,
                        color: AppColors.neutralSecondary,
                      ),
                    ),
                    Text(
                      '${invoice.storeInfo.phone} • ${invoice.storeInfo.email}',
                      style: AppTheme.bodyStyle(
                        locale: settings.locale,
                        fontSize: 12,
                        color: AppColors.neutralSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    color: AppColors.onyxBlack,
                    child: Text(
                      strings.get('invoice_tax_invoice'),
                      style: AppTheme.displayStyle(
                        locale: settings.locale,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.pureWhite,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '#${order.number}',
                    style: AppTheme.monoStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onyxBlack,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${strings.get('invoice_number')}: ${invoice.invoiceNumber}',
                    style: AppTheme.monoStyle(
                      fontSize: 11,
                      color: AppColors.neutralSecondary,
                    ),
                  ),
                  Text(
                    '${strings.get('invoice_date')}: ${invoice.issuedDate}',
                    style: AppTheme.bodyStyle(
                      locale: settings.locale,
                      fontSize: 12,
                      color: AppColors.neutralSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.statusLabel.toUpperCase(),
                    style: AppTheme.displayStyle(
                      locale: settings.locale,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF15803D),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 2, color: AppColors.onyxBlack),
          const SizedBox(height: 18),

          // Bill To / Ship To
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      strings.get('invoice_customer_billed_to').toUpperCase(),
                      style: AppTheme.displayStyle(
                        locale: settings.locale,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.neutralGray,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.shippingAddress.displayName,
                      style: AppTheme.bodyStyle(
                        locale: settings.locale,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onyxBlack,
                      ),
                    ),
                    Text(
                      order.email,
                      style: AppTheme.bodyStyle(
                        locale: settings.locale,
                        fontSize: 12,
                        color: AppColors.neutralSecondary,
                      ),
                    ),
                    Text(
                      order.phone,
                      style: AppTheme.bodyStyle(
                        locale: settings.locale,
                        fontSize: 12,
                        color: AppColors.neutralSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      strings.get('invoice_shipping_destination').toUpperCase(),
                      style: AppTheme.displayStyle(
                        locale: settings.locale,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.neutralGray,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.shippingAddress.streetAddress,
                      style: AppTheme.bodyStyle(
                        locale: settings.locale,
                        fontSize: 12.5,
                        color: AppColors.onyxBlack,
                      ),
                    ),
                    if (order.shippingAddress.displayRegion.isNotEmpty)
                      Text(
                        order.shippingAddress.displayRegion,
                        style: AppTheme.bodyStyle(
                          locale: settings.locale,
                          fontSize: 12,
                          color: AppColors.neutralSecondary,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '${strings.get('invoice_method')}: ${order.shippingMethod.toUpperCase()}',
                      style: AppTheme.monoStyle(
                        fontSize: 11,
                        color: AppColors.neutralSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Itemized Table
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.onyxBlack, width: 1.5),
                bottom: BorderSide(color: AppColors.onyxBlack, width: 1.5),
              ),
            ),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        flex: 5,
                        child: Text(
                          strings.get('invoice_item_desc').toUpperCase(),
                          style: AppTheme.displayStyle(
                            locale: settings.locale,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onyxBlack,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          strings.get('invoice_qty').toUpperCase(),
                          textAlign: TextAlign.center,
                          style: AppTheme.displayStyle(
                            locale: settings.locale,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onyxBlack,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          strings.get('invoice_unit_price').toUpperCase(),
                          textAlign: TextAlign.right,
                          style: AppTheme.displayStyle(
                            locale: settings.locale,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onyxBlack,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          strings.get('invoice_amount').toUpperCase(),
                          textAlign: TextAlign.right,
                          style: AppTheme.displayStyle(
                            locale: settings.locale,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onyxBlack,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.onyxBlack),
                ...order.items.map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE5E5E5)),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                item.productName,
                                style: AppTheme.bodyStyle(
                                  locale: settings.locale,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onyxBlack,
                                ),
                              ),
                              Text(
                                '${item.variantLabel} • ${item.sku}',
                                style: AppTheme.monoStyle(
                                  fontSize: 10.5,
                                  color: AppColors.neutralGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '${item.quantity}',
                            textAlign: TextAlign.center,
                            style: AppTheme.monoStyle(
                              fontSize: 12,
                              color: AppColors.onyxBlack,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            item.formattedPrice,
                            textAlign: TextAlign.right,
                            style: AppTheme.monoStyle(
                              fontSize: 11.5,
                              color: AppColors.neutralSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            item.formattedSubtotal,
                            textAlign: TextAlign.right,
                            style: AppTheme.monoStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onyxBlack,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Totals
          Align(
            alignment: Alignment.centerRight,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Column(
                children: <Widget>[
                  _PaperTotalRow(
                    label: strings.get('cart_subtotal'),
                    value: order.formattedSubtotal,
                  ),
                  if (order.discountCents > 0) ...<Widget>[
                    const SizedBox(height: 6),
                    _PaperTotalRow(
                      label:
                          '${strings.get('cart_discount')} (${order.discountCode ?? ''})',
                      value: '-${order.formattedDiscount}',
                      color: AppColors.khqrRed,
                    ),
                  ],
                  const SizedBox(height: 6),
                  _PaperTotalRow(
                    label: strings.get('shipping_fee'),
                    value: order.formattedShipping,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: AppColors.onyxBlack),
                  ),
                  _PaperTotalRow(
                    label: strings.get('total_amount'),
                    value: order.formattedTotal,
                    bold: true,
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${order.formattedEquivalentKhr} / ${order.formattedEquivalentUsd}',
                      style: AppTheme.monoStyle(
                        fontSize: 11,
                        color: AppColors.neutralGray,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (payment != null) ...<Widget>[
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.boneWhite,
                borderRadius: BorderRadius.circular(AppRadii.xs),
                border: Border.all(color: AppColors.warmBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    strings.get('invoice_settlement_title').toUpperCase(),
                    style: AppTheme.displayStyle(
                      locale: settings.locale,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onyxBlack,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${strings.get('invoice_payment_id')}: #${payment.id}   •   ${strings.get('invoice_settled_account')}: ${payment.accountId}',
                    style: AppTheme.monoStyle(
                      fontSize: 11,
                      color: AppColors.neutralSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${strings.get('invoice_md5_hash')}: ${payment.md5}',
                    style: AppTheme.monoStyle(
                      fontSize: 11,
                      color: AppColors.neutralSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.get('invoice_certified_settlement'),
                    style: AppTheme.bodyStyle(
                      locale: settings.locale,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF15803D),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),
          Center(
            child: Text(
              strings.get('invoice_thank_you'),
              textAlign: TextAlign.center,
              style: AppTheme.bodyStyle(
                locale: settings.locale,
                fontSize: 12,
                color: AppColors.neutralGray,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaperTotalRow extends StatelessWidget {
  const _PaperTotalRow({
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            fontSize: bold ? 13 : 12,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            color: color ?? AppColors.onyxBlack,
          ),
        ),
        Text(
          value,
          style: AppTheme.monoStyle(
            fontSize: bold ? 14 : 12,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: color ?? AppColors.onyxBlack,
          ),
        ),
      ],
    );
  }
}
