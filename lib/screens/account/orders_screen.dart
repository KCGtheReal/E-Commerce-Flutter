import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../models/common_models.dart';
import '../../models/order_payment_models.dart';
import '../../providers/app_navigation_provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../widgets/common_states.dart';
import '../../widgets/reset_scaffold.dart';
import '../payment/khqr_payment_screen.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final List<OrderSummaryDto> _orders = <OrderSummaryDto>[];
  PaginationMeta? _meta;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrders(page: 1, reset: true);
  }

  Future<void> _loadOrders({required int page, bool reset = false}) async {
    setState(() {
      if (reset) {
        _isLoading = true;
      } else {
        _isLoadingMore = true;
      }
      _errorMessage = null;
    });
    try {
      final res = await context.read<ApiClient>().getOrders(page: page);
      if (!mounted) {
        return;
      }
      setState(() {
        if (reset) {
          _orders.clear();
        }
        _orders.addAll(res.data);
        _meta = res.meta;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final settings = context.watch<AppSettingsProvider>();
    final strings = settings.strings;

    return ResetScaffold(
      showBackButton: true,
      title: strings.get('account_orders'),
      onRefreshContext: () => _loadOrders(page: 1, reset: true),
      body: RefreshIndicator(
        onRefresh: () => _loadOrders(page: 1, reset: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 840),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          strings.get('account_orders'),
                          style: AppTheme.displayStyle(
                            locale: settings.locale,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          strings.get('account_orders_desc'),
                          style: AppTheme.bodyStyle(
                            locale: settings.locale,
                            fontSize: 13.5,
                            color: palette.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 64),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_errorMessage != null)
                          ResetErrorBanner(
                            message: _errorMessage!,
                            onRetry: () => _loadOrders(page: 1, reset: true),
                          )
                        else if (_orders.isEmpty)
                          ResetEmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: strings.get('account_no_orders'),
                            subtitle: strings.get('account_orders_desc'),
                            ctaLabel: strings.get('cart_empty_cta'),
                            onCtaPressed: () {
                              Navigator.of(context)
                                  .popUntil((route) => route.isFirst);
                              context.read<AppNavigationProvider>().openShop();
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (!_isLoading && _errorMessage == null && _orders.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.builder(
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 840),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: palette.cardSurface,
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                            border: Border.all(color: palette.borderSubtle),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      '#${order.number}',
                                      style: AppTheme.monoStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: palette.textPrimary,
                                      ),
                                    ),
                                  ),
                                  SemanticStatusBadge(
                                    label: order.statusLabel,
                                    colorKey: order.statusColor,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${order.formattedCreatedAt} • ${order.itemsCount} ${order.itemsCount == 1 ? strings.get('item_singular') : strings.get('items_count')}',
                                style: AppTheme.bodyStyle(
                                  locale: settings.locale,
                                  fontSize: 12,
                                  color: palette.textSecondary,
                                ),
                              ),
                              if (order.previewItemNames.isNotEmpty) ...<Widget>[
                                const SizedBox(height: 6),
                                Text(
                                  order.previewItemNames.join(', '),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTheme.bodyStyle(
                                    locale: settings.locale,
                                    fontSize: 13,
                                    color: palette.textPrimary,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Divider(color: palette.borderSubtle),
                              const SizedBox(height: 10),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          order.formattedTotal,
                                          style: AppTheme.monoStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: palette.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          '${order.formattedEquivalentKhr} / ${order.formattedEquivalentUsd}',
                                          style: AppTheme.monoStyle(
                                            fontSize: 10.5,
                                            color: palette.textTertiary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (order.canPayNow) ...<Widget>[
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context)
                                            .push(
                                              MaterialPageRoute<void>(
                                                builder: (_) =>
                                                    KhqrPaymentScreen(
                                                  orderNumber: order.number,
                                                ),
                                              ),
                                            )
                                            .then(
                                              (_) => _loadOrders(
                                                page: 1,
                                                reset: true,
                                              ),
                                            );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.terracotta,
                                        foregroundColor: AppColors.pureWhite,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                      ),
                                      child: Text(
                                        strings.get('account_pay_now'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  OutlinedButton(
                                    onPressed: () {
                                      Navigator.of(context)
                                          .push(
                                            MaterialPageRoute<void>(
                                              builder: (_) => OrderDetailScreen(
                                                orderNumber: order.number,
                                              ),
                                            ),
                                          )
                                          .then(
                                            (_) => _loadOrders(
                                              page: 1,
                                              reset: true,
                                            ),
                                          );
                                    },
                                    child: Text(strings.get('account_details')),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (!_isLoading &&
                _errorMessage == null &&
                _meta != null &&
                _meta!.hasMorePages)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: OutlinedButton(
                      onPressed: _isLoadingMore
                          ? null
                          : () => _loadOrders(
                                page: _meta!.currentPage + 1,
                              ),
                      child: _isLoadingMore
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(strings.get('load_more')),
                    ),
                  ),
                ),
              )
            else
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}
