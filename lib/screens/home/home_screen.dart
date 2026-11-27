import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../models/catalog_models.dart';
import '../../providers/app_navigation_provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bootstrap_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/common_states.dart';
import '../../widgets/product_card.dart';
import '../../widgets/reset_footer.dart';
import '../pages/info_page_screen.dart';
import '../product/product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.isActive = true});

  final bool isActive;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _heroImageUrl =
      'https://images.unsplash.com/photo-1509967419530-da38b4704bc6?auto=format&fit=crop&w=1800&q=85';
  static const String _storyImageUrl =
      'https://images.unsplash.com/photo-1551028719-00167b16eac5?auto=format&fit=crop&w=1200&q=80';

  HomeResponse? _home;
  bool _isLoading = true;
  bool _needsReload = false;
  String? _errorMessage;
  String? _loadedContextKey;

  void _syncContextIfNeeded(String key) {
    if (_loadedContextKey == key) {
      return;
    }
    _loadedContextKey = key;
    if (widget.isActive) {
      _needsReload = false;
      Future.microtask(() {
        if (mounted) {
          _loadHome();
        }
      });
    } else {
      _needsReload = true;
    }
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive && _needsReload) {
      _needsReload = false;
      _loadHome();
    }
  }

  Future<void> _loadHome() async {
    if (!_isLoading || _errorMessage != null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final res = await context.read<ApiClient>().getHome();
      if (!mounted) {
        return;
      }
      setState(() {
        _home = res;
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

  Future<void> _onToggleWishlist(ProductCardDto product) async {
    final strings = context.read<AppSettingsProvider>().strings;
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      final ok = await showSignInPromptDialog(
        context,
        message: strings.get('wishlist_signin_prompt'),
      );
      if (!ok || !mounted) {
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

  void _openProduct(String slug) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailScreen(slug: slug),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contextKey = context.select<AppSettingsProvider, String>(
      (s) => '${s.locale}|${s.currency}',
    );
    _syncContextIfNeeded(contextKey);

    final palette = context.palette;
    final settings = context.watch<AppSettingsProvider>();
    final strings = settings.strings;
    final bootstrap = context.watch<BootstrapProvider>();
    final nav = context.read<AppNavigationProvider>();
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = AppBreakpoints.isMobile(width);
    final cols = AppBreakpoints.isDesktop(width)
        ? 4
        : (AppBreakpoints.isTablet(width) ? 3 : 2);
    final horizontalPad = isMobile ? 16.0 : 28.0;

    final home = _home;
    final isAllEmpty = home != null &&
        home.categories.isEmpty &&
        home.newArrivals.isEmpty &&
        home.bestSellers.isEmpty;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait(<Future<void>>[
          bootstrap.loadBootstrap(silent: true),
          _loadHome(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // 1. Editorial Hero Banner
            _HeroSection(
              heroImageUrl: _heroImageUrl,
              isMobile: isMobile,
              onExplore: () => nav.openShop(),
              onStory: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const InfoPageScreen(slug: 'about'),
                  ),
                );
              },
            ),

            // 2. 3-Item Trust Strip
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPad,
                vertical: 18,
              ),
              decoration: BoxDecoration(
                color: palette.surfaceBone,
                border: Border.symmetric(
                  horizontal: BorderSide(color: palette.borderSubtle),
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSpacing.maxContentWidth,
                  ),
                  child: isMobile
                      ? Column(
                          children: <Widget>[
                            _TrustItem(
                              icon: Icons.verified_outlined,
                              label: strings.get('trust_bakong_certified'),
                            ),
                            const SizedBox(height: 10),
                            _TrustItem(
                              icon: Icons.local_shipping_outlined,
                              label: strings.get(
                                'free_delivery_feature',
                                <String, String>{
                                  'amount':
                                      bootstrap.formattedFreeShippingThreshold,
                                },
                              ),
                            ),
                            const SizedBox(height: 10),
                            _TrustItem(
                              icon: Icons.workspace_premium_outlined,
                              label: strings.get('trust_organic_cotton'),
                            ),
                          ],
                        )
                      : Row(
                          children: <Widget>[
                            Expanded(
                              child: _TrustItem(
                                icon: Icons.verified_outlined,
                                label: strings.get('trust_bakong_certified'),
                              ),
                            ),
                            Expanded(
                              child: _TrustItem(
                                icon: Icons.local_shipping_outlined,
                                label: strings.get(
                                  'free_delivery_feature',
                                  <String, String>{
                                    'amount': bootstrap
                                        .formattedFreeShippingThreshold,
                                  },
                                ),
                              ),
                            ),
                            Expanded(
                              child: _TrustItem(
                                icon: Icons.workspace_premium_outlined,
                                label: strings.get('trust_organic_cotton'),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),

            if (_errorMessage != null)
              Padding(
                padding: EdgeInsets.all(horizontalPad),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSpacing.maxContentWidth,
                    ),
                    child: ResetErrorBanner(
                      message: _errorMessage!,
                      onRetry: _loadHome,
                    ),
                  ),
                ),
              )
            else if (_isLoading && home == null)
              Padding(
                padding: EdgeInsets.all(horizontalPad),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSpacing.maxContentWidth,
                    ),
                    child: ProductGridSkeleton(count: cols, crossAxisCount: cols),
                  ),
                ),
              )
            else if (isAllEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 48,
                ),
                child: ResetEmptyState(
                  icon: Icons.checkroom_outlined,
                  title: strings.get('home_empty_title'),
                  subtitle: strings.get('home_empty_hint'),
                  ctaLabel: strings.get('nav_shop'),
                  onCtaPressed: () => nav.openShop(),
                ),
              )
            else if (home != null) ...<Widget>[
              // 3. Featured Collections
              if (home.categories.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPad,
                    vertical: 40,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppSpacing.maxContentWidth,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _SectionHeader(
                            overline: strings.get('section_categories'),
                            title: strings.get('featured_collections'),
                            actionLabel: strings.get('view_all'),
                            onAction: () => nav.openShop(),
                          ),
                          const SizedBox(height: 20),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isMobile ? 2 : 4,
                              crossAxisSpacing: isMobile ? 12 : 20,
                              mainAxisSpacing: isMobile ? 12 : 20,
                              childAspectRatio: 0.8,
                            ),
                            itemCount: home.categories.length,
                            itemBuilder: (context, index) {
                              final cat = home.categories[index];
                              return _CategoryCard(
                                category: cat,
                                onTap: () =>
                                    nav.openShop(categorySlug: cat.slug),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 4. New Arrivals Showcase
              if (home.newArrivals.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPad,
                    vertical: 44,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceBone,
                    border: Border.symmetric(
                      horizontal: BorderSide(color: palette.borderSubtle),
                    ),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppSpacing.maxContentWidth,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _SectionHeader(
                            overline: strings.get('section_just_dropped'),
                            title: strings.get('new_arrivals'),
                            subtitle: strings.get('new_arrivals_desc'),
                            actionLabel: strings.get('view_all'),
                            onAction: () => nav.openShop(sort: 'newest'),
                          ),
                          const SizedBox(height: 22),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              crossAxisSpacing: isMobile ? 12 : 20,
                              mainAxisSpacing: 22,
                              childAspectRatio: isMobile ? 0.47 : 0.52,
                            ),
                            itemCount: home.newArrivals.length,
                            itemBuilder: (context, index) {
                              final item = home.newArrivals[index];
                              return RepaintBoundary(
                                key: ValueKey<int>(item.id),
                                child: ProductCard(
                                  product: item,
                                  onTap: () => _openProduct(item.slug),
                                  onWishlistTap: () => _onToggleWishlist(item),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 5. Brand Editorial Story Block
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPad,
                  vertical: 48,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSpacing.maxContentWidth,
                    ),
                    child: _BrandStorySection(
                      imageUrl: _storyImageUrl,
                      isWide: !isMobile,
                      onLearnMore: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const InfoPageScreen(slug: 'about'),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // 6. Best Sellers Showcase
              if (home.bestSellers.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPad,
                    vertical: 44,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceBone,
                    border: Border(
                      top: BorderSide(color: palette.borderSubtle),
                    ),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppSpacing.maxContentWidth,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _SectionHeader(
                            overline: strings.get('section_essentials'),
                            title: strings.get('best_sellers'),
                            subtitle: strings.get('best_sellers_desc'),
                            actionLabel: strings.get('view_all'),
                            onAction: () => nav.openShop(),
                          ),
                          const SizedBox(height: 22),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              crossAxisSpacing: isMobile ? 12 : 20,
                              mainAxisSpacing: 22,
                              childAspectRatio: isMobile ? 0.47 : 0.52,
                            ),
                            itemCount: home.bestSellers.length,
                            itemBuilder: (context, index) {
                              final item = home.bestSellers[index];
                              return RepaintBoundary(
                                key: ValueKey<int>(item.id),
                                child: ProductCard(
                                  product: item,
                                  onTap: () => _openProduct(item.slug),
                                  onWishlistTap: () => _onToggleWishlist(item),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],

            // 7. Editorial Footer + Newsletter
            const ResetFooter(),
          ],
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.heroImageUrl,
    required this.isMobile,
    required this.onExplore,
    required this.onStory,
  });

  final String heroImageUrl;
  final bool isMobile;
  final VoidCallback onExplore;
  final VoidCallback onStory;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    final strings = settings.strings;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: isMobile ? 440 : 540),
      color: AppColors.onyxBlack,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Opacity(
              opacity: 0.36,
              child: ResetNetworkImage(
                imageUrl: heroImageUrl,
                fit: BoxFit.cover,
                cacheWidth: 1400,
                colorFilter: const ColorFilter.mode(
                  Colors.grey,
                  BlendMode.saturation,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: <Color>[
                    AppColors.onyxBlack,
                    AppColors.onyxBlack.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.maxContentWidth,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 18 : 32,
                  vertical: isMobile ? 48 : 80,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 660),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.terracotta,
                            borderRadius: BorderRadius.circular(AppRadii.xs),
                          ),
                          child: Text(
                            strings.get('badge_capsule'),
                            style: AppTheme.displayStyle(
                              locale: settings.locale,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.pureWhite,
                              letterSpacing: settings.isKm ? 0 : 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          settings.isKm
                              ? strings.get('hero_title')
                              : strings.get('hero_title').toUpperCase(),
                          style: AppTheme.displayStyle(
                            locale: settings.locale,
                            fontSize: isMobile ? 30 : 48,
                            fontWeight: FontWeight.w800,
                            color: AppColors.pureWhite,
                            letterSpacing: settings.isKm ? 0 : -1.0,
                            height: settings.isKm ? 1.35 : 1.08,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          strings.get('hero_subtitle'),
                          style: AppTheme.bodyStyle(
                            locale: settings.locale,
                            fontSize: isMobile ? 14 : 16,
                            color: AppColors.boneWhite.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: <Widget>[
                            ElevatedButton.icon(
                              onPressed: onExplore,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.pureWhite,
                                foregroundColor: AppColors.onyxBlack,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 16,
                                ),
                              ),
                              icon: const Icon(Icons.arrow_forward, size: 16),
                              label: Text(strings.get('hero_cta_shop')),
                            ),
                            OutlinedButton(
                              onPressed: onStory,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: AppColors.pureWhite,
                                side: BorderSide(
                                  color: AppColors.pureWhite.withValues(
                                    alpha: 0.45,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 16,
                                ),
                              ),
                              child: Text(strings.get('hero_cta_story')),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final settings = context.watch<AppSettingsProvider>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(icon, size: 18, color: AppColors.terracotta),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.displayStyle(
              locale: settings.locale,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
              letterSpacing: settings.isKm ? 0 : 0.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.overline,
    required this.title,
    this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String overline;
  final String title;
  final String? subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final settings = context.watch<AppSettingsProvider>();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                overline.toUpperCase(),
                style: AppTheme.displayStyle(
                  locale: settings.locale,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.terracotta,
                  letterSpacing: settings.isKm ? 0 : 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                settings.isKm ? title : title.toUpperCase(),
                style: AppTheme.displayStyle(
                  locale: settings.locale,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                ),
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: AppTheme.bodyStyle(
                    locale: settings.locale,
                    fontSize: 12.5,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        TextButton(
          onPressed: onAction,
          child: Text('$actionLabel →'),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final CategoryDto category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    return Material(
      color: AppColors.onyxBlack,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ResetNetworkImage(
              imageUrl: category.imageUrl,
              fit: BoxFit.cover,
              cacheWidth: 700,
              colorFilter: const ColorFilter.mode(
                Colors.grey,
                BlendMode.saturation,
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: <Color>[
                    AppColors.onyxBlack.withValues(alpha: 0.85),
                    AppColors.onyxBlack.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    settings.isKm
                        ? category.name
                        : category.name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.displayStyle(
                      locale: settings.locale,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.pureWhite,
                    ),
                  ),
                  if (category.description != null &&
                      category.description!.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      category.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodyStyle(
                        locale: settings.locale,
                        fontSize: 11.5,
                        color: AppColors.boneWhite.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandStorySection extends StatelessWidget {
  const _BrandStorySection({
    required this.imageUrl,
    required this.isWide,
    required this.onLearnMore,
  });

  final String imageUrl;
  final bool isWide;
  final VoidCallback onLearnMore;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final settings = context.watch<AppSettingsProvider>();
    final strings = settings.strings;

    final imageBox = AspectRatio(
      aspectRatio: 4 / 5,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(color: palette.borderSubtle),
        ),
        clipBehavior: Clip.antiAlias,
        child: ResetNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          cacheWidth: 1000,
        ),
      ),
    );

    final copyBox = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          strings.get('section_philosophy').toUpperCase(),
          style: AppTheme.displayStyle(
            locale: settings.locale,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.terracotta,
            letterSpacing: settings.isKm ? 0 : 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          settings.isKm
              ? strings.get('brand_story_title')
              : strings.get('brand_story_title').toUpperCase(),
          style: AppTheme.displayStyle(
            locale: settings.locale,
            fontSize: isWide ? 34 : 26,
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          strings.get('brand_story_text'),
          style: AppTheme.bodyStyle(
            locale: settings.locale,
            fontSize: 14.5,
            color: palette.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.only(left: 14, top: 4, bottom: 4),
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: AppColors.terracotta, width: 2.5),
            ),
          ),
          child: Text(
            strings.get('craft_quote'),
            style: AppTheme.bodyStyle(
              locale: settings.locale,
              fontSize: 13.5,
              color: palette.textPrimary,
            ).copyWith(fontStyle: FontStyle.italic),
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: onLearnMore,
          child: Text(strings.get('learn_our_craft')),
        ),
      ],
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(flex: 5, child: imageBox),
          const SizedBox(width: 40),
          Expanded(flex: 7, child: copyBox),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        imageBox,
        const SizedBox(height: 22),
        copyBox,
      ],
    );
  }
}
