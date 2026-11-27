import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_navigation_provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../widgets/reset_scaffold.dart';
import '../account/account_hub_screen.dart';
import '../cart/cart_screen.dart';
import '../home/home_screen.dart';
import '../shop/shop_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final Set<int> _mountedTabs = <int>{0};

  @override
  Widget build(BuildContext context) {
    final tabIndex = context.select<AppNavigationProvider, int>(
      (nav) => nav.tabIndex,
    );
    _mountedTabs.add(tabIndex);
    final strings = context.watch<AppSettingsProvider>().strings;

    final tabTitle = switch (tabIndex) {
      1 => strings.get('nav_shop'),
      2 => strings.get('cart_title'),
      3 => strings.get('nav_account'),
      _ => null,
    };

    return ResetScaffold(
      showBottomNav: true,
      title: tabTitle,
      body: IndexedStack(
        index: tabIndex,
        children: <Widget>[
          HomeScreen(isActive: tabIndex == 0),
          _mountedTabs.contains(1)
              ? ShopScreen(isActive: tabIndex == 1)
              : const SizedBox.shrink(),
          _mountedTabs.contains(2)
              ? const CartScreen()
              : const SizedBox.shrink(),
          _mountedTabs.contains(3)
              ? const AccountHubScreen()
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}
