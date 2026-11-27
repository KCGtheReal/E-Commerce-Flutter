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
    final settings = context.watch<AppSettingsProvider>();
    final strings = settings.strings;
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
          ? Container(
              decoration: BoxDecoration(
                color: palette.scaffoldBackground,
                border: Border(top: BorderSide(color: palette.borderSubtle)),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 62,
                  child: Row(
                    children: <Widget>[
                      _BottomNavItem(
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home,
                        label: strings.get('nav_home'),
                        selected: nav.tabIndex == 0,
                        onTap: () => nav.selectTab(0),
                      ),
                      _BottomNavItem(
                        icon: Icons.grid_view_outlined,
                        activeIcon: Icons.grid_view_rounded,
                        label: strings.get('nav_shop'),
                        selected: nav.tabIndex == 1,
                        onTap: () => nav.selectTab(1),
                      ),
                      _BottomNavItem(
                        icon: Icons.search,
                        activeIcon: Icons.search,
                        label: strings.get('nav_search'),
                        selected: false,
                        onTap: () => SearchModal.show(context),
                      ),
                      _BottomNavItem(
                        icon: Icons.shopping_bag_outlined,
                        activeIcon: Icons.shopping_bag,
                        label: strings.get('nav_cart'),
                        selected: nav.tabIndex == 2,
                        badgeCount: cartCount,
                        onTap: () => nav.selectTab(2),
                      ),
                      _BottomNavItem(
                        icon: Icons.person_outline,
                        activeIcon: Icons.person,
                        label: strings.get('nav_account'),
                        selected: nav.tabIndex == 3,
                        onTap: () => nav.selectTab(3),
                      ),
                    ],
                  ),
                ),
              ),
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
          IconButton(
            tooltip: settings.strings.get('preferences_title'),
            onPressed: () => PreferencesSheet.show(context),
            icon: const Icon(Icons.menu),
          ),
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
          GestureDetector(
            onTap: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
              context.read<AppNavigationProvider>().selectTab(0);
            },
            child: const ResetWordmark(fontSize: 20),
          ),
          const Spacer(),
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
        IconButton(
          onPressed: () => SearchModal.show(context),
          icon: const Icon(Icons.search, size: 21),
        ),
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

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final locale = context.watch<AppSettingsProvider>().locale;
    final color = selected ? AppColors.terracotta : palette.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Icon(selected ? activeIcon : icon, size: 22, color: color),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.terracotta,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: AppTheme.monoStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.pureWhite,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyStyle(
                locale: locale,
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
