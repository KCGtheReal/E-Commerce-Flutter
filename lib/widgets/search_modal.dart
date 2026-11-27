import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api/api_client.dart';
import '../core/api/api_exceptions.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_tokens.dart';
import '../models/catalog_models.dart';
import '../providers/app_navigation_provider.dart';
import '../providers/app_settings_provider.dart';
import '../screens/product/product_detail_screen.dart';
import 'common_states.dart';

class SearchModal extends StatefulWidget {
  const SearchModal({super.key});

  static Future<void> show(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (AppBreakpoints.isMobile(width)) {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => const FractionallySizedBox(
          heightFactor: 0.92,
          child: SearchModal(),
        ),
      );
    }

    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 672, maxHeight: 620),
          child: const SearchModal(),
        ),
      ),
    );
  }

  @override
  State<SearchModal> createState() => _SearchModalState();
}

class _SearchModalState extends State<SearchModal> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  int _requestSequence = 0;

  SearchSuggestResponse? _result;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSuggestions('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(AppMotion.searchDebounce, () {
      _fetchSuggestions(value);
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    final seq = ++_requestSequence;
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final res = await context.read<ApiClient>().searchSuggest(query);
      if (!mounted || seq != _requestSequence) {
        return;
      }
      setState(() {
        _result = res;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted || seq != _requestSequence) {
        return;
      }
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    }
  }

  void _navigateToShop({String? query, String? categorySlug}) {
    final nav = context.read<AppNavigationProvider>();
    Navigator.of(context).pop();
    Navigator.of(context).popUntil((route) => route.isFirst);
    nav.openShop(searchQuery: query, categorySlug: categorySlug);
  }

  void _navigateToProduct(String slug) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailScreen(slug: slug),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final settings = context.watch<AppSettingsProvider>();
    final strings = settings.strings;
    final query = _controller.text.trim();
    final res = _result;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Search Input Bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: palette.borderSubtle)),
          ),
          child: Row(
            children: <Widget>[
              Icon(Icons.search, size: 20, color: palette.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  onChanged: _onQueryChanged,
                  onSubmitted: (val) {
                    _debounce?.cancel();
                    if (val.trim().isNotEmpty) {
                      _navigateToShop(query: val.trim());
                    }
                  },
                  decoration: InputDecoration(
                    hintText: strings.get('search_placeholder'),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (_controller.text.isNotEmpty)
                IconButton(
                  onPressed: () {
                    _debounce?.cancel();
                    _controller.clear();
                    _fetchSuggestions('');
                  },
                  icon: const Icon(Icons.clear, size: 18),
                ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(strings.get('cancel')),
              ),
            ],
          ),
        ),

        // Body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildBody(context, query, res),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    String query,
    SearchSuggestResponse? res,
  ) {
    final palette = context.palette;
    final settings = context.watch<AppSettingsProvider>();
    final strings = settings.strings;

    if (_errorMessage != null) {
      return ResetErrorBanner(
        message: _errorMessage!,
        onRetry: () => _fetchSuggestions(query),
      );
    }

    if (res == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // State 1: Empty Query -> Popular searches + Categories
    if (query.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (res.popularSearches.isNotEmpty) ...<Widget>[
            Text(
              strings.get('search_popular').toUpperCase(),
              style: AppTheme.displayStyle(
                locale: settings.locale,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: palette.textTertiary,
                letterSpacing: settings.isKm ? 0 : 1.0,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: res.popularSearches.map((term) {
                return ActionChip(
                  avatar: const Icon(Icons.trending_up, size: 14),
                  label: Text(term),
                  onPressed: () {
                    _debounce?.cancel();
                    _controller.text = term;
                    _fetchSuggestions(term);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 22),
          ],
          if (res.categories.isNotEmpty) ...<Widget>[
            Text(
              strings.get('search_categories').toUpperCase(),
              style: AppTheme.displayStyle(
                locale: settings.locale,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: palette.textTertiary,
                letterSpacing: settings.isKm ? 0 : 1.0,
              ),
            ),
            const SizedBox(height: 10),
            ...res.categories.map((cat) {
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: Text(cat.name),
                trailing: const Icon(Icons.arrow_forward, size: 16),
                onTap: () => _navigateToShop(categorySlug: cat.slug),
              );
            }),
          ],
        ],
      );
    }

    // State 3: No results
    if (!_isLoading && res.products.isEmpty && res.categories.isEmpty) {
      return Column(
        children: <Widget>[
          const SizedBox(height: 20),
          ResetEmptyState(
            icon: Icons.search_off_outlined,
            title: strings.get('search_no_results', <String, String>{
              'query': query,
            }),
            subtitle: strings.get('search_try_fallback'),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: const <String>['Tee', 'Hoodie', 'Pants'].map((term) {
              return ActionChip(
                label: Text(term),
                onPressed: () {
                  _debounce?.cancel();
                  _controller.text = term;
                  _fetchSuggestions(term);
                },
              );
            }).toList(),
          ),
        ],
      );
    }

    // State 2: Results found
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (res.categories.isNotEmpty) ...<Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: res.categories.map((cat) {
              return ActionChip(
                avatar: const Icon(Icons.category_outlined, size: 14),
                label: Text(cat.name),
                onPressed: () => _navigateToShop(categorySlug: cat.slug),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
        ],
        ...res.products.map((item) {
          return InkWell(
            onTap: () => _navigateToProduct(item.slug),
            borderRadius: BorderRadius.circular(AppRadii.sm),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: palette.borderSubtle),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 52,
                    height: 62,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadii.xs),
                      border: Border.all(color: palette.borderSubtle),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ResetNetworkImage(
                      imageUrl: item.imageUrl,
                      fit: BoxFit.cover,
                      cacheWidth: 160,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (item.category != null)
                          Text(
                            item.category!.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.displayStyle(
                              locale: settings.locale,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: palette.textTertiary,
                            ),
                          ),
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.bodyStyle(
                            locale: settings.locale,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.isInStock
                              ? strings.get('in_stock')
                              : strings.get('out_of_stock'),
                          style: AppTheme.bodyStyle(
                            locale: settings.locale,
                            fontSize: 11,
                            color: item.isInStock
                                ? SemanticStatusColors.fromKey(
                                    'success',
                                    Theme.of(context).brightness,
                                  ).foreground
                                : palette.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        item.price,
                        style: AppTheme.monoStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                      ),
                      if (item.compareAtPrice != null)
                        Text(
                          item.compareAtPrice!,
                          style: AppTheme.monoStyle(
                            fontSize: 11,
                            color: palette.textTertiary,
                          ).copyWith(decoration: TextDecoration.lineThrough),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        if (res.total > 0) ...<Widget>[
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _navigateToShop(query: query),
            child: Text(
              strings.get('search_view_all', <String, String>{
                'total': '${res.total}',
              }),
            ),
          ),
        ],
      ],
    );
  }
}
