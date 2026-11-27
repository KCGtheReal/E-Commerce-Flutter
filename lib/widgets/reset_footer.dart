import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api/api_client.dart';
import '../core/api/api_exceptions.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_tokens.dart';
import '../providers/app_navigation_provider.dart';
import '../providers/app_settings_provider.dart';
import '../providers/bootstrap_provider.dart';
import '../screens/pages/contact_screen.dart';
import '../screens/pages/info_page_screen.dart';
import 'reset_logo.dart';

class ResetFooter extends StatefulWidget {
  const ResetFooter({super.key});

  @override
  State<ResetFooter> createState() => _ResetFooterState();
}

class _ResetFooterState extends State<ResetFooter> {
  final TextEditingController _emailController = TextEditingController();
  bool _submitting = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitNewsletter() async {
    final strings = context.read<AppSettingsProvider>().strings;
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() {
        _errorMessage = strings.get('error_invalid_email');
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final res = await context.read<ApiClient>().subscribeNewsletter(email);
      if (!mounted) {
        return;
      }
      setState(() {
        _successMessage = res.message.isNotEmpty
            ? res.message
            : strings.get('newsletter_success');
        _emailController.clear();
      });
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = e.fieldError('email') ?? e.message;
      });
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _openShopCategory(String? slug) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    context.read<AppNavigationProvider>().openShop(categorySlug: slug);
  }

  void _openInfoPage(String slug) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => InfoPageScreen(slug: slug)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    final strings = settings.strings;
    final categories = context.watch<BootstrapProvider>().categories;
    final apiClient = context.read<ApiClient>();
    final width = MediaQuery.sizeOf(context).width;
    final isWide = !AppBreakpoints.isMobile(width);

    final bottomSafePadding = isWide ? 0.0 : MediaQuery.paddingOf(context).bottom;

    return Container(
      width: double.infinity,
      color: AppColors.onyxBlack,
      padding: EdgeInsets.fromLTRB(
        isWide ? 32 : 18,
        isWide ? 48 : 36,
        isWide ? 32 : 18,
        (isWide ? 48 : 36) + bottomSafePadding,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSpacing.maxContentWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(flex: 3, child: _BrandAndNewsletterColumn()),
                    const SizedBox(width: 40),
                    Expanded(
                      flex: 2,
                      child: _ShopLinksColumn(
                        categories: categories
                            .map((c) => MapEntry(c.slug, c.name))
                            .toList(),
                        onTapCategory: _openShopCategory,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 2,
                      child: _HelpLinksColumn(
                        onOpenPage: _openInfoPage,
                        onOpenContact: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ContactScreen(),
                            ),
                          );
                        },
                        onOpenAdmin: () {
                          launchUrl(
                            Uri.parse(apiClient.adminPanelUrl),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                      ),
                    ),
                  ],
                )
              else ...<Widget>[
                _BrandAndNewsletterColumn(),
                const SizedBox(height: 28),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: _ShopLinksColumn(
                        categories: categories
                            .map((c) => MapEntry(c.slug, c.name))
                            .toList(),
                        onTapCategory: _openShopCategory,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _HelpLinksColumn(
                        onOpenPage: _openInfoPage,
                        onOpenContact: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ContactScreen(),
                            ),
                          );
                        },
                        onOpenAdmin: () {
                          launchUrl(
                            Uri.parse(apiClient.adminPanelUrl),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 36),
              Container(
                padding: const EdgeInsets.only(top: 20),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.darkBorder),
                  ),
                ),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(
                      '© ${DateTime.now().year} RESET Store. ${strings.get('footer_rights')}',
                      style: AppTheme.bodyStyle(
                        locale: settings.locale,
                        fontSize: 12,
                        color: AppColors.neutralMuted,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.softCharcoal,
                        borderRadius: BorderRadius.circular(AppRadii.xs),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.khqrRed,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              'KHQR',
                              style: AppTheme.monoStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.pureWhite,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            strings.get('footer_powered_by'),
                            style: AppTheme.bodyStyle(
                              locale: settings.locale,
                              fontSize: 11.5,
                              color: AppColors.boneWhite,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ignore: non_constant_identifier_names
  Widget _BrandAndNewsletterColumn() {
    final settings = context.watch<AppSettingsProvider>();
    final strings = settings.strings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const ResetWordmark(fontSize: 24, color: AppColors.boneWhite),
        const SizedBox(height: 10),
        Text(
          strings.get('footer_brand_desc'),
          style: AppTheme.bodyStyle(
            locale: settings.locale,
            fontSize: 13,
            color: AppColors.neutralMuted,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          strings.get('newsletter_title').toUpperCase(),
          style: AppTheme.displayStyle(
            locale: settings.locale,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.boneWhite,
            letterSpacing: settings.isKm ? 0 : 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          strings.get('newsletter_subtitle'),
          style: AppTheme.bodyStyle(
            locale: settings.locale,
            fontSize: 12,
            color: AppColors.neutralMuted,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: AppTheme.bodyStyle(
                  locale: settings.locale,
                  fontSize: 13,
                  color: AppColors.boneWhite,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.softCharcoal,
                  hintText: strings.get('newsletter_placeholder'),
                  hintStyle: AppTheme.bodyStyle(
                    locale: settings.locale,
                    fontSize: 12.5,
                    color: AppColors.neutralGray,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.xs),
                    borderSide: const BorderSide(color: AppColors.darkBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.xs),
                    borderSide: const BorderSide(color: AppColors.terracotta),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _submitting ? null : _submitNewsletter,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.terracotta,
                foregroundColor: AppColors.pureWhite,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.pureWhite,
                      ),
                    )
                  : Text(strings.get('newsletter_submit')),
            ),
          ],
        ),
        if (_errorMessage != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: AppTheme.bodyStyle(
              locale: settings.locale,
              fontSize: 12,
              color: const Color(0xFFF87171),
            ),
          ),
        ],
        if (_successMessage != null) ...<Widget>[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0x2915803D),
              borderRadius: BorderRadius.circular(AppRadii.xs),
              border: Border.all(color: const Color(0x4D4ADE80)),
            ),
            child: Text(
              _successMessage!,
              style: AppTheme.bodyStyle(
                locale: settings.locale,
                fontSize: 12,
                color: const Color(0xFF4ADE80),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ShopLinksColumn extends StatelessWidget {
  const _ShopLinksColumn({
    required this.categories,
    required this.onTapCategory,
  });

  final List<MapEntry<String, String>> categories;
  final ValueChanged<String?> onTapCategory;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    final strings = settings.strings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          strings.get('footer_shop').toUpperCase(),
          style: AppTheme.displayStyle(
            locale: settings.locale,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.boneWhite,
            letterSpacing: settings.isKm ? 0 : 1.1,
          ),
        ),
        const SizedBox(height: 12),
        _FooterLink(
          label: strings.get('nav_shop_all'),
          onTap: () => onTapCategory(null),
        ),
        ...categories.map((entry) {
          return _FooterLink(
            label: entry.value,
            onTap: () => onTapCategory(entry.key),
          );
        }),
      ],
    );
  }
}

class _HelpLinksColumn extends StatelessWidget {
  const _HelpLinksColumn({
    required this.onOpenPage,
    required this.onOpenContact,
    required this.onOpenAdmin,
  });

  final ValueChanged<String> onOpenPage;
  final VoidCallback onOpenContact;
  final VoidCallback onOpenAdmin;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    final strings = settings.strings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          strings.get('footer_help').toUpperCase(),
          style: AppTheme.displayStyle(
            locale: settings.locale,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.boneWhite,
            letterSpacing: settings.isKm ? 0 : 1.1,
          ),
        ),
        const SizedBox(height: 12),
        _FooterLink(
          label: strings.get('footer_about'),
          onTap: () => onOpenPage('about'),
        ),
        _FooterLink(
          label: strings.get('footer_faq'),
          onTap: () => onOpenPage('faq'),
        ),
        _FooterLink(
          label: strings.get('footer_shipping'),
          onTap: () => onOpenPage('shipping'),
        ),
        _FooterLink(
          label: strings.get('footer_size_guide'),
          onTap: () => onOpenPage('size-guide'),
        ),
        _FooterLink(
          label: strings.get('footer_privacy'),
          onTap: () => onOpenPage('privacy'),
        ),
        _FooterLink(
          label: strings.get('footer_terms'),
          onTap: () => onOpenPage('terms'),
        ),
        _FooterLink(
          label: strings.get('nav_contact'),
          onTap: onOpenContact,
        ),
        _FooterLink(
          label: strings.get('admin_panel'),
          onTap: onOpenAdmin,
        ),
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<AppSettingsProvider>().locale;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Text(
          label,
          style: AppTheme.bodyStyle(
            locale: locale,
            fontSize: 13,
            color: AppColors.neutralMuted,
          ),
        ),
      ),
    );
  }
}
