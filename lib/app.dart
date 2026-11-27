import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api/api_client.dart';
import 'core/storage/app_storage.dart';
import 'core/theme/app_theme.dart';
import 'providers/app_navigation_provider.dart';
import 'providers/app_settings_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/bootstrap_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/wishlist_provider.dart';
import 'screens/shell/main_shell.dart';

class ResetStoreApp extends StatelessWidget {
  const ResetStoreApp({
    super.key,
    required this.storage,
    required this.apiClient,
    this.autoInitialize = true,
  });

  final AppStorage storage;
  final ApiClient apiClient;
  final bool autoInitialize;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppStorage>.value(value: storage),
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider<AppNavigationProvider>(
          create: (_) => AppNavigationProvider(),
        ),
        ChangeNotifierProvider<AppSettingsProvider>(
          create: (_) => AppSettingsProvider(storage),
        ),
        ChangeNotifierProvider<BootstrapProvider>(
          create: (_) => BootstrapProvider(apiClient),
        ),
        ChangeNotifierProvider<CartProvider>(
          create: (_) => CartProvider(apiClient),
        ),
        ChangeNotifierProvider<WishlistProvider>(
          create: (_) => WishlistProvider(apiClient),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (ctx) {
            final auth = AuthProvider(
              apiClient: apiClient,
              storage: storage,
              cartProvider: ctx.read<CartProvider>(),
              wishlistProvider: ctx.read<WishlistProvider>(),
            );
            final settings = ctx.read<AppSettingsProvider>();
            apiClient.attachContext(
              localeResolver: () => settings.locale,
              currencyResolver: () => settings.currency,
              baseUrlResolver: () => settings.customBaseUrl,
              onUnauthorized: () => auth.handleUnauthorized(),
            );
            return auth;
          },
        ),
      ],
      child: _ResetMaterialApp(autoInitialize: autoInitialize),
    );
  }
}

class _ResetMaterialApp extends StatefulWidget {
  const _ResetMaterialApp({required this.autoInitialize});

  final bool autoInitialize;

  @override
  State<_ResetMaterialApp> createState() => _ResetMaterialAppState();
}

class _ResetMaterialAppState extends State<_ResetMaterialApp> {
  @override
  void initState() {
    super.initState();
    if (widget.autoInitialize) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _initializeApp());
    }
  }

  Future<void> _initializeApp() async {
    final bootstrap = context.read<BootstrapProvider>();
    final auth = context.read<AuthProvider>();
    final cart = context.read<CartProvider>();

    final res = await bootstrap.loadBootstrap();
    if (!mounted) {
      return;
    }
    final postBootstrapTasks = <Future<void>>[];
    if (res != null) {
      auth.hydrateFromBootstrap(res.user);
      if (res.cart != null) {
        cart.hydrateFromPayload(res.cart);
      } else {
        postBootstrapTasks.add(cart.refreshCart(silent: true));
      }
      postBootstrapTasks.add(auth.init(skipUserRefresh: res.user != null));
    } else {
      postBootstrapTasks.add(auth.init());
    }

    if (postBootstrapTasks.isNotEmpty) {
      await Future.wait(postBootstrapTasks);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();

    return MaterialApp(
      title: 'RESET',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: AppTheme.build(
        brightness: Brightness.light,
        locale: settings.locale,
      ),
      darkTheme: AppTheme.build(
        brightness: Brightness.dark,
        locale: settings.locale,
      ),
      home: const MainShell(),
    );
  }
}
