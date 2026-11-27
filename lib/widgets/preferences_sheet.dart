import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/app_tokens.dart';
import '../providers/app_settings_provider.dart';
import '../providers/bootstrap_provider.dart';
import '../providers/cart_provider.dart';
import '../screens/pages/contact_screen.dart';
import '../screens/pages/info_page_screen.dart';

class PreferencesSheet extends StatefulWidget {
  const PreferencesSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const PreferencesSheet(),
    );
  }

  @override
  State<PreferencesSheet> createState() => _PreferencesSheetState();
}

class _PreferencesSheetState extends State<PreferencesSheet> {
  Future<void> _refreshStoreContext() async {
    final bootstrap = context.read<BootstrapProvider>();
    final cart = context.read<CartProvider>();
    await Future.wait(<Future<void>>[
      bootstrap.loadBootstrap(silent: true),
      cart.refreshCart(silent: true),
    ]);
  }

  void _openInfoSlug(String slug) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InfoPageScreen(slug: slug),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final settings = context.watch<AppSettingsProvider>();
    final strings = settings.strings;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.borderSubtle,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              strings.get('preferences_title'),
              style: AppTheme.displayStyle(
                locale: settings.locale,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _SettingRow(
              label: strings.get('language_switch'),
              child: _SegmentedControl(
                values: const <String>['en', 'km'],
                labels: const <String>['EN', 'ខ្មែរ'],
                selected: settings.locale,
                onSelect: (val) async {
                  await settings.setLocale(val);
                  await _refreshStoreContext();
                },
              ),
            ),
            const SizedBox(height: 12),
            _SettingRow(
              label: strings.get('currency_switch'),
              child: _SegmentedControl(
                values: const <String>['KHR', 'USD'],
                labels: const <String>['៛ KHR', '\$ USD'],
                selected: settings.currency,
                onSelect: (val) async {
                  await settings.setCurrency(val);
                  await _refreshStoreContext();
                },
              ),
            ),
            const SizedBox(height: 12),
            _SettingRow(
              label: strings.get('theme_switch'),
              child: _SegmentedControl(
                values: const <String>['light', 'dark'],
                labels: <String>[
                  strings.get('theme_light'),
                  strings.get('theme_dark'),
                ],
                selected: settings.isDarkMode ? 'dark' : 'light',
                onSelect: (val) => settings.setThemeMode(
                  val == 'dark' ? ThemeMode.dark : ThemeMode.light,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Divider(color: palette.borderSubtle),
            const SizedBox(height: 14),
            Text(
              strings.get('footer_help').toUpperCase(),
              style: AppTheme.displayStyle(
                locale: settings.locale,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: palette.textTertiary,
                letterSpacing: settings.isKm ? 0 : 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _InfoChip(
                  label: strings.get('footer_about'),
                  onTap: () => _openInfoSlug('about'),
                ),
                _InfoChip(
                  label: strings.get('footer_faq'),
                  onTap: () => _openInfoSlug('faq'),
                ),
                _InfoChip(
                  label: strings.get('footer_shipping'),
                  onTap: () => _openInfoSlug('shipping'),
                ),
                _InfoChip(
                  label: strings.get('footer_size_guide'),
                  onTap: () => _openInfoSlug('size-guide'),
                ),
                _InfoChip(
                  label: strings.get('footer_privacy'),
                  onTap: () => _openInfoSlug('privacy'),
                ),
                _InfoChip(
                  label: strings.get('footer_terms'),
                  onTap: () => _openInfoSlug('terms'),
                ),
                _InfoChip(
                  label: strings.get('nav_contact'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ContactScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final locale = context.watch<AppSettingsProvider>().locale;
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: AppTheme.bodyStyle(
              locale: locale,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: palette.textPrimary,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({
    required this.values,
    required this.labels,
    required this.selected,
    required this.onSelect,
  });

  final List<String> values;
  final List<String> labels;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: palette.surfaceBone,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(values.length, (i) {
          final active = values[i] == selected;
          return InkWell(
            onTap: () => onSelect(values[i]),
            borderRadius: BorderRadius.circular(AppRadii.xs),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: active ? palette.buttonPrimaryBg : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadii.xs),
              ),
              child: Text(
                labels[i],
                style: values[i] == 'km'
                    ? AppTheme.bodyStyle(
                        locale: 'km',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: active
                            ? palette.buttonPrimaryFg
                            : palette.textPrimary,
                        height: 1.25,
                      )
                    : AppTheme.monoStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: active
                            ? palette.buttonPrimaryFg
                            : palette.textPrimary,
                      ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final locale = context.watch<AppSettingsProvider>().locale;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: palette.elevatedSurface,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(color: palette.borderSubtle),
        ),
        child: Text(
          label,
          style: AppTheme.bodyStyle(
            locale: locale,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: palette.textPrimary,
          ),
        ),
      ),
    );
  }
}
