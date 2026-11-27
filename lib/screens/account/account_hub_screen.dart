import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/preferences_sheet.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../pages/contact_screen.dart';
import '../pages/info_page_screen.dart';
import 'addresses_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';
import 'wishlist_screen.dart';

class AccountHubScreen extends StatelessWidget {
  const AccountHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final settings = context.watch<AppSettingsProvider>();
    final strings = settings.strings;
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        24,
        16,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (!auth.isAuthenticated)
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: palette.cardSurface,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(color: palette.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        strings.get('guest_account_title'),
                        style: AppTheme.displayStyle(
                          locale: settings.locale,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        strings.get('guest_account_desc'),
                        style: AppTheme.bodyStyle(
                          locale: settings.locale,
                          fontSize: 13.5,
                          color: palette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                );
                              },
                              child: Text(strings.get('nav_login')),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                );
                              },
                              child: Text(strings.get('nav_register')),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else ...<Widget>[
                // Member Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: palette.cardSurface,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(color: palette.borderSubtle),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: palette.buttonPrimaryBg,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            user!.name.isNotEmpty
                                ? user.name.substring(0, 1).toUpperCase()
                                : 'R',
                            style: AppTheme.displayStyle(
                              locale: 'en',
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: palette.buttonPrimaryFg,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              user.name,
                              style: AppTheme.displayStyle(
                                locale: settings.locale,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: palette.textPrimary,
                              ),
                            ),
                            Text(
                              user.email,
                              style: AppTheme.monoStyle(
                                fontSize: 12,
                                color: palette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: auth.isLoading ? null : () => auth.logout(),
                        child: Text(strings.get('nav_logout')),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _AccountNavTile(
                  icon: Icons.receipt_long_outlined,
                  title: strings.get('account_orders'),
                  subtitle: strings.get('account_orders_desc'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const OrdersScreen(),
                      ),
                    );
                  },
                ),
                _AccountNavTile(
                  icon: Icons.location_on_outlined,
                  title: strings.get('account_addresses'),
                  subtitle: strings.get('account_addresses_desc'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AddressesScreen(),
                      ),
                    );
                  },
                ),
                _AccountNavTile(
                  icon: Icons.favorite_border,
                  title: strings.get('account_wishlist'),
                  subtitle: strings.get('account_wishlist_desc'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const WishlistScreen(),
                      ),
                    );
                  },
                ),
                _AccountNavTile(
                  icon: Icons.person_outline,
                  title: strings.get('account_profile'),
                  subtitle: strings.get('account_profile_desc'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ProfileScreen(),
                      ),
                    );
                  },
                ),
              ],

              const SizedBox(height: 20),
              Text(
                strings.get('preferences_title').toUpperCase(),
                style: AppTheme.displayStyle(
                  locale: settings.locale,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: palette.textTertiary,
                  letterSpacing: settings.isKm ? 0 : 1.0,
                ),
              ),
              const SizedBox(height: 10),
              _AccountNavTile(
                icon: Icons.tune,
                title: strings.get('preferences_title'),
                subtitle:
                    '${settings.isKm ? 'ខ្មែរ' : 'English'} · ${settings.currency} · ${settings.isDarkMode ? strings.get('theme_dark') : strings.get('theme_light')}',
                onTap: () => PreferencesSheet.show(context),
              ),
              _AccountNavTile(
                icon: Icons.info_outline,
                title: strings.get('footer_about'),
                subtitle: strings.get('brand_story_title'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const InfoPageScreen(slug: 'about'),
                    ),
                  );
                },
              ),
              _AccountNavTile(
                icon: Icons.help_outline,
                title: strings.get('footer_faq'),
                subtitle: strings.get('footer_shipping'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const InfoPageScreen(slug: 'faq'),
                    ),
                  );
                },
              ),
              _AccountNavTile(
                icon: Icons.straighten,
                title: strings.get('footer_size_guide'),
                subtitle: strings.get('size_guide_desc'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const InfoPageScreen(slug: 'size-guide'),
                    ),
                  );
                },
              ),
              _AccountNavTile(
                icon: Icons.support_agent_outlined,
                title: strings.get('nav_contact'),
                subtitle: strings.get('contact_subtitle'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ContactScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountNavTile extends StatelessWidget {
  const _AccountNavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final locale = context.watch<AppSettingsProvider>().locale;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: palette.cardSurface,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.terracotta),
        title: Text(
          title,
          style: AppTheme.bodyStyle(
            locale: locale,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.bodyStyle(
            locale: locale,
            fontSize: 12,
            color: palette.textSecondary,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }
}
