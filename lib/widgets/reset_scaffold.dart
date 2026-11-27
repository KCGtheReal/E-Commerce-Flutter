import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/app_tokens.dart';
import '../providers/app_navigation_provider.dart';
import '../providers/app_settings_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/bootstrap_provider.dart';
import '../providers/cart_provider.dart';
import '../screens/account/wishlist_screen.dart';
import '../screens/pages/info_page_screen.dart';
import 'announcement_bar.dart';
import 'cart_drawer.dart';
import 'preferences_sheet.dart';
import 'reset_logo.dart';
import 'search_modal.dart';

class ResetScaffold extends StatelessWidget {
  const ResetScaffold({
    super.key,
    required this.body,
    this.showBackButton = false,
    this.showBottomNav = false,
    this.title,
    this.onRefreshContext,
  });

  final Widget body;
  final bool showBackButton;
  final bool showBottomNav;
  final String? title;
  final VoidCallback? onRefreshContext;

  void _triggerContextRefresh(BuildContext context) {
    context.read<BootstrapProvider>().loadBootstrap(silent: true);
    context.read<CartProvider>().refreshCart(silent: true);
    onRefreshContext?.call();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = AppBreakpoints.isMobile(width);
    final cartCount = context.watch<CartProvider>().itemCount;
    final nav = context.watch<AppNavigationProvider>();
    final auth = context.watch<AuthProvider>();
    final overlayStyle = AppTheme.systemOverlayStyle(
      brightness: Theme.of(context).brightness,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: palette.scaffoldBackground,
        extendBody: isMobile && showBottomNav,
        body: Column(
        children: <Widget>[
          AnnouncementBar(
            onSettingsChanged: () => _triggerContextRefresh(context),
          ),
          // Responsive Header Bar
          Container(
            height: isMobile ? 56 : 70,
            decoration: BoxDecoration(
              color: palette.scaffoldBackground,
              border: Border(bottom: BorderSide(color: palette.borderSubtle)),
            ),
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSpacing.maxContentWidth,
                ),
                child: isMobile
                    ? _MobileHeader(
                        showBackButton: showBackButton,
                        title: title,
                        cartCount: cartCount,
                        onOpenCart: () {
                          if (showBottomNav) {
                            nav.selectTab(2);
                          } else {
                            CartDrawer.show(context);
                          }
                        },
                      )
                    : _DesktopHeader(
                        showBackButton: showBackButton,
                        cartCount: cartCount,
                        isAuthenticated: auth.isAuthenticated,
                        onOpenShop: (slug) {
                          Navigator.of(context).popUntil(
                            (route) => route.isFirst,
                          );
                          nav.openShop(categorySlug: slug);
                        },
                        onGoHome: () {
                          Navigator.of(context).popUntil(
                            (route) => route.isFirst,
                          );
                          nav.selectTab(0);
                        },
                        onOpenAccount: () {
                          Navigator.of(context).popUntil(
                            (route) => route.isFirst,
                          );
                          nav.selectTab(3);
                        },
                        onOpenAbout: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const InfoPageScreen(slug: 'about'),
                            ),
                          );
                        },
                        onOpenWishlist: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const WishlistScreen(),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: isMobile && showBottomNav
          ? _AppleFloatingNavBar(
              tabIndex: nav.tabIndex,
              cartCount: cartCount,
              onSelectTab: nav.selectTab,
              onOpenSearch: () => SearchModal.show(context),
            )
          : null,
      ),
    );
  }
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader({
    required this.showBackButton,
    this.title,
    required this.cartCount,
    required this.onOpenCart,
  });

  final bool showBackButton;
  final String? title;
  final int cartCount;
  final VoidCallback onOpenCart;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final settings = context.watch<AppSettingsProvider>();

    return Row(
      children: <Widget>[
        if (showBackButton)
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back),
          )
        else
          const SizedBox(width: 8),
        if (title != null && title!.isNotEmpty)
          Expanded(
            child: Text(
              title!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.displayStyle(
                locale: settings.locale,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
          )
        else ...<Widget>[
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    context.read<AppNavigationProvider>().selectTab(0);
                  },
                  child: const ResetWordmark(fontSize: 20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
        InkWell(
          onTap: () => PreferencesSheet.show(context),
          borderRadius: BorderRadius.circular(AppRadii.sm),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: palette.surfaceBone,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(color: palette.borderSubtle),
            ),
            child: Text(
              '${settings.isKm ? 'ខ្មែរ' : 'EN'} · ${settings.currency == 'USD' ? '\$' : '៛'}',
              style: AppTheme.monoStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Stack(
          alignment: Alignment.center,
          children: <Widget>[
            IconButton(
              onPressed: onOpenCart,
              icon: const Icon(Icons.shopping_bag_outlined, size: 21),
            ),
            if (cartCount > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.terracotta,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    '$cartCount',
                    style: AppTheme.monoStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.pureWhite,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader({
    required this.showBackButton,
    required this.cartCount,
    required this.isAuthenticated,
    required this.onOpenShop,
    required this.onGoHome,
    required this.onOpenAccount,
    required this.onOpenAbout,
    required this.onOpenWishlist,
  });

  final bool showBackButton;
  final int cartCount;
  final bool isAuthenticated;
  final ValueChanged<String?> onOpenShop;
  final VoidCallback onGoHome;
  final VoidCallback onOpenAccount;
  final VoidCallback onOpenAbout;
  final VoidCallback onOpenWishlist;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final settings = context.watch<AppSettingsProvider>();
    final strings = settings.strings;
    final categories = context.watch<BootstrapProvider>().categories;
    final width = MediaQuery.sizeOf(context).width;
    final showCategoryLinks = width >= 980;

    return Row(
      children: <Widget>[
        if (showBackButton) ...<Widget>[
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(width: 4),
        ],
        InkWell(
          onTap: onGoHome,
          child: const ResetWordmark(fontSize: 22),
        ),
        const SizedBox(width: 24),
        if (showCategoryLinks) ...<Widget>[
          _NavTextBtn(
            label: strings.get('nav_shop_all'),
            onTap: () => onOpenShop(null),
          ),
          ...categories.take(4).map((cat) {
            return _NavTextBtn(
              label: cat.name,
              onTap: () => onOpenShop(cat.slug),
            );
          }),
          _NavTextBtn(
            label: strings.get('nav_about'),
            onTap: onOpenAbout,
          ),
        ] else
          _NavTextBtn(
            label: strings.get('nav_shop'),
            onTap: () => onOpenShop(null),
          ),
        const Spacer(),
        // Search Pill
        InkWell(
          onTap: () => SearchModal.show(context),
          borderRadius: BorderRadius.circular(AppRadii.sm),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: palette.surfaceBone,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(color: palette.borderSubtle),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.search, size: 16, color: palette.textSecondary),
                const SizedBox(width: 8),
                Text(
                  strings.get('search_button'),
                  style: AppTheme.bodyStyle(
                    locale: settings.locale,
                    fontSize: 12.5,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        IconButton(
          tooltip: strings.get('nav_wishlist'),
          onPressed: onOpenWishlist,
          icon: const Icon(Icons.favorite_border, size: 20),
        ),
        IconButton(
          tooltip: strings.get('nav_account'),
          onPressed: onOpenAccount,
          icon: Icon(
            isAuthenticated ? Icons.person : Icons.person_outline,
            size: 21,
          ),
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: () => CartDrawer.show(context),
          borderRadius: BorderRadius.circular(AppRadii.xs),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: palette.buttonPrimaryBg,
              borderRadius: BorderRadius.circular(AppRadii.xs),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 16,
                  color: palette.buttonPrimaryFg,
                ),
                const SizedBox(width: 6),
                Text(
                  '${strings.get('nav_cart')} ($cartCount)',
                  style: AppTheme.displayStyle(
                    locale: settings.locale,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: palette.buttonPrimaryFg,
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

class _NavTextBtn extends StatelessWidget {
  const _NavTextBtn({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final locale = context.watch<AppSettingsProvider>().locale;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.xs),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(
          locale == 'km' ? label : label.toUpperCase(),
          style: AppTheme.displayStyle(
            locale: locale,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
            letterSpacing: locale == 'km' ? 0 : 0.9,
          ),
        ),
      ),
    );
  }
}

class _AppleFloatingNavBar extends StatelessWidget {
  const _AppleFloatingNavBar({
    required this.tabIndex,
    required this.cartCount,
    required this.onSelectTab,
    required this.onOpenSearch,
  });

  final int tabIndex;
  final int cartCount;
  final ValueChanged<int> onSelectTab;
  final VoidCallback onOpenSearch;

  static BoxDecoration _floatingSurfaceDecoration({
    required Color color,
    required Color borderColor,
    required bool isDark,
    required BoxShape shape,
    BorderRadius? borderRadius,
  }) {
    final shadows = isDark
        ? <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.24),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ]
        : <BoxShadow>[
            BoxShadow(
              color: AppColors.onyxBlack.withValues(alpha: 0.08),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppColors.onyxBlack.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ];

    return BoxDecoration(
      color: color,
      shape: shape,
      borderRadius: shape == BoxShape.circle ? null : borderRadius,
      border: Border.all(color: borderColor),
      boxShadow: shadows,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strings = context.watch<AppSettingsProvider>().strings;

    // Solid opaque elevated architectural surfaces (intentionally no liquid glass).
    final surfaceColor = palette.elevatedSurface;
    final borderColor =
        isDark ? const Color(0xFF2E2E2E) : palette.borderSubtle;
    final activeCapsuleColor =
        isDark ? const Color(0xFF2B2B2B) : const Color(0xFFF2EFE9);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final clampedIndex = tabIndex.clamp(0, 3);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
        child: Row(
          children: <Widget>[
            Expanded(
              child: DecoratedBox(
                key: const ValueKey<String>('apple-floating-nav-pill'),
                decoration: _floatingSurfaceDecoration(
                  color: surfaceColor,
                  borderColor: borderColor,
                  isDark: isDark,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: SizedBox(
                  height: 62,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final slotWidth = constraints.maxWidth / 4;
                        final visualSlot =
                            isRtl ? (3 - clampedIndex) : clampedIndex;
                        return Stack(
                          children: <Widget>[
                            AnimatedPositioned(
                              duration: AppMotion.stateTransition,
                              curve: AppMotion.curve,
                              left: visualSlot * slotWidth,
                              top: 0,
                              bottom: 0,
                              width: slotWidth,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: activeCapsuleColor,
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.pill,
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              children: <Widget>[
                                _BottomNavItem(
                                  icon: Icons.home_outlined,
                                  activeIcon: Icons.home_rounded,
                                  label: strings.get('nav_home'),
                                  selected: clampedIndex == 0,
                                  pillSurfaceColor: surfaceColor,
                                  activeCapsuleColor: activeCapsuleColor,
                                  onTap: () => onSelectTab(0),
                                ),
                                _BottomNavItem(
                                  icon: Icons.grid_view_outlined,
                                  activeIcon: Icons.grid_view_rounded,
                                  label: strings.get('nav_shop'),
                                  selected: clampedIndex == 1,
                                  pillSurfaceColor: surfaceColor,
                                  activeCapsuleColor: activeCapsuleColor,
                                  onTap: () => onSelectTab(1),
                                ),
                                _BottomNavItem(
                                  icon: Icons.shopping_bag_outlined,
                                  activeIcon: Icons.shopping_bag_rounded,
                                  label: strings.get('nav_cart'),
                                  selected: clampedIndex == 2,
                                  badgeCount: cartCount,
                                  pillSurfaceColor: surfaceColor,
                                  activeCapsuleColor: activeCapsuleColor,
                                  onTap: () => onSelectTab(2),
                                ),
                                _BottomNavItem(
                                  icon: Icons.person_outline,
                                  activeIcon: Icons.person_rounded,
                                  label: strings.get('nav_account'),
                                  selected: clampedIndex == 3,
                                  pillSurfaceColor: surfaceColor,
                                  activeCapsuleColor: activeCapsuleColor,
                                  onTap: () => onSelectTab(3),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            DecoratedBox(
              key: const ValueKey<String>('apple-floating-search-button'),
              decoration: _floatingSurfaceDecoration(
                color: surfaceColor,
                borderColor: borderColor,
                isDark: isDark,
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 62,
                height: 62,
                child: Semantics(
                  button: true,
                  label: strings.get('nav_search'),
                  child: Tooltip(
                    message: strings.get('nav_search'),
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onOpenSearch,
                        child: Center(
                          child: Icon(
                            Icons.search_rounded,
                            size: 24,
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.pillSurfaceColor,
    required this.activeCapsuleColor,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final Color pillSurfaceColor;
  final Color activeCapsuleColor;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final locale = context.watch<AppSettingsProvider>().locale;
    final color = selected ? AppColors.terracotta : palette.textSecondary;

    return Expanded(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              AnimatedScale(
                scale: selected ? 1.0 : 0.94,
                duration: AppMotion.microTap,
                curve: AppMotion.curve,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Icon(selected ? activeIcon : icon, size: 21, color: color),
                    if (badgeCount > 0)
                      Positioned(
                        top: -4,
                        right: -9,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.terracotta,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                            border: Border.all(
                              color: selected
                                  ? activeCapsuleColor
                                  : pillSurfaceColor,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              badgeCount > 99 ? '99+' : '$badgeCount',
                              style: AppTheme.monoStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.pureWhite,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    style: AppTheme.bodyStyle(
                      locale: locale,
                      fontSize: 10.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: color,
                      height: 1.25,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
