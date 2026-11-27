import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exceptions.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../providers/app_navigation_provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/common_states.dart';
import '../../widgets/product_card.dart';
import '../../widgets/reset_scaffold.dart';
import '../auth/login_screen.dart';
import '../product/product_detail_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<AuthProvider>().isAuthenticated) {
        context.read<WishlistProvider>().loadWishlist();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final settings = context.watch<AppSettingsProvider>();
    final strings = settings.strings;
    final auth = context.watch<AuthProvider>();
    final wishlist = context.watch<WishlistProvider>();
    final width = MediaQuery.sizeOf(context).width;
    final cols = AppBreakpoints.isDesktop(width)
        ? 4
        : (AppBreakpoints.isTablet(width) ? 3 : 2);
    final sidePadding = math.max(
      16.0,
      (width - AppSpacing.maxContentWidth) / 2,
    );

    return ResetScaffold(
      showBackButton: true,
      title: strings.get('account_wishlist'),
      body: CustomScrollView(
        slivers: <Widget>[
          SliverPadding(
            padding: EdgeInsets.fromLTRB(sidePadding, 24, sidePadding, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    strings.get('account_wishlist'),
                    style: AppTheme.displayStyle(
                      locale: settings.locale,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.get('account_wishlist_desc'),
                    style: AppTheme.bodyStyle(
                      locale: settings.locale,
                      fontSize: 13.5,
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!auth.isAuthenticated)
                    ResetEmptyState(
                      icon: Icons.favorite_border,
                      title: strings.get('nav_login'),
                      subtitle: strings.get('wishlist_signin_prompt'),
                      ctaLabel: strings.get('nav_login'),
                      onCtaPressed: () async {
                        final ok = await Navigator.of(context).push<bool>(
                          MaterialPageRoute<bool>(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                        if (ok == true && context.mounted) {
                          context.read<WishlistProvider>().loadWishlist();
                        }
                      },
                    )
                  else if (wishlist.isLoading && wishlist.items.isEmpty)
                    ProductGridSkeleton(count: cols, crossAxisCount: cols)
                  else if (wishlist.errorMessage != null)
                    ResetErrorBanner(
                      message: wishlist.errorMessage!,
                      onRetry: () => wishlist.loadWishlist(),
                    )
                  else if (wishlist.items.isEmpty)
                    ResetEmptyState(
                      icon: Icons.favorite_border,
                      title: strings.get('account_no_wishlist'),
                      subtitle: strings.get('account_wishlist_desc'),
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
          if (auth.isAuthenticated &&
              wishlist.errorMessage == null &&
              wishlist.items.isNotEmpty)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(sidePadding, 0, sidePadding, 24),
              sliver: SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 22,
                  childAspectRatio: cols == 2 ? 0.47 : 0.52,
                ),
                itemCount: wishlist.items.length,
                itemBuilder: (context, index) {
                  final item = wishlist.items[index];
                  return RepaintBoundary(
                    key: ValueKey<int>(item.id),
                    child: ProductCard(
                      product: item,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ProductDetailScreen(slug: item.slug),
                          ),
                        );
                      },
                      onWishlistTap: () async {
                        try {
                          await wishlist.toggle(item.id);
                        } on ApiException catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.message)),
                            );
                          }
                        }
                      },
                    ),
                  );
                },
              ),
            )
          else
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
