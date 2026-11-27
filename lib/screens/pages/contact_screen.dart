import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../models/bootstrap_page_models.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bootstrap_provider.dart';
import '../../widgets/common_states.dart';
import '../../widgets/reset_footer.dart';
import '../../widgets/reset_scaffold.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  bool _submitting = false;
  Map<String, List<String>> _fieldErrors = const <String, List<String>>{};
  String? _generalError;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _submitting = true;
      _fieldErrors = const <String, List<String>>{};
      _generalError = null;
      _successMessage = null;
    });

    try {
      final res = await context.read<ApiClient>().submitContact(
            ContactRequest(
              name: _nameController.text,
              email: _emailController.text,
              subject: _subjectController.text,
              message: _messageController.text,
            ),
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _successMessage = res.message;
        _subjectController.clear();
        _messageController.clear();
      });
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _fieldErrors = e.errors;
        _generalError = e.errors.isEmpty ? e.message : null;
      });
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  String? _serverError(String field) {
    final list = _fieldErrors[field];
    return (list != null && list.isNotEmpty) ? list.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final settings = context.watch<AppSettingsProvider>();
    final strings = settings.strings;
    final storeSettings = context.watch<BootstrapProvider>().settings;
    final width = MediaQuery.sizeOf(context).width;
    final isWide = !AppBreakpoints.isMobile(width);

    final studioCard = Container(
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
            strings.get('contact_studio_title').toUpperCase(),
            style: AppTheme.displayStyle(
              locale: settings.locale,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.terracotta,
              letterSpacing: settings.isKm ? 0 : 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            storeSettings?.storeName ?? 'RESET Studio Phnom Penh',
            style: AppTheme.displayStyle(
              locale: settings.locale,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _InfoTile(
            icon: Icons.location_on_outlined,
            text: storeSettings?.storeAddress ??
                'Street 178, Daun Penh, Phnom Penh, Cambodia',
          ),
          const _InfoTile(
            icon: Icons.schedule_outlined,
            text: 'Mon – Sun: 10:00 AM – 8:00 PM',
          ),
          const SizedBox(height: 16),
          Divider(color: palette.borderSubtle),
          const SizedBox(height: 16),
          Text(
            strings.get('contact_channels_title').toUpperCase(),
            style: AppTheme.displayStyle(
              locale: settings.locale,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: palette.textTertiary,
              letterSpacing: settings.isKm ? 0 : 1.0,
            ),
          ),
          const SizedBox(height: 10),
          _InfoTile(
            icon: Icons.email_outlined,
            text: storeSettings?.storeEmail ?? 'support@reset.store',
            onTap: () => launchUrl(
              Uri.parse(
                'mailto:${storeSettings?.storeEmail ?? 'support@reset.store'}',
              ),
            ),
          ),
          _InfoTile(
            icon: Icons.phone_outlined,
            text: storeSettings?.storePhone ?? '+855 23 999 123',
            onTap: () => launchUrl(
              Uri.parse(
                'tel:${(storeSettings?.storePhone ?? '+85523999123').replaceAll(' ', '')}',
              ),
            ),
          ),
          _InfoTile(
            icon: Icons.send_outlined,
            text: 'Telegram: @reset_store_kh',
            onTap: () => launchUrl(
              Uri.parse('https://t.me/reset_store_kh'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.surfaceBone,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(color: palette.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  strings.get('contact_fastest_title'),
                  style: AppTheme.displayStyle(
                    locale: settings.locale,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  strings.get('contact_fastest_desc'),
                  style: AppTheme.bodyStyle(
                    locale: settings.locale,
                    fontSize: 12.5,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final formCard = Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: palette.cardSurface,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              strings.get('contact_send_message'),
              style: AppTheme.displayStyle(
                locale: settings.locale,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            if (_generalError != null) ...<Widget>[
              ResetErrorBanner(message: _generalError!),
              const SizedBox(height: 14),
            ],
            if (_successMessage != null) ...<Widget>[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: SemanticStatusColors.fromKey(
                    'success',
                    Theme.of(context).brightness,
                  ).background,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(
                    color: SemanticStatusColors.fromKey(
                      'success',
                      Theme.of(context).brightness,
                    ).border,
                  ),
                ),
                child: Text(
                  _successMessage!,
                  style: AppTheme.bodyStyle(
                    locale: settings.locale,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: SemanticStatusColors.fromKey(
                      'success',
                      Theme.of(context).brightness,
                    ).foreground,
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: strings.get('contact_name'),
                errorText: _serverError('name'),
              ),
              validator: (val) => (val == null || val.trim().isEmpty)
                  ? strings.get('error_required')
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: strings.get('contact_email'),
                errorText: _serverError('email'),
              ),
              validator: (val) {
                if (val == null || !val.contains('@')) {
                  return strings.get('error_invalid_email');
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: strings.get('contact_subject'),
                errorText: _serverError('subject'),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _messageController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: strings.get('contact_message'),
                hintText: strings.get('contact_message_placeholder'),
                alignLabelWithHint: true,
                errorText: _serverError('message'),
              ),
              validator: (val) {
                if (val == null || val.trim().length < 10) {
                  return strings.get('error_required');
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(strings.get('contact_submit')),
            ),
          ],
        ),
      ),
    );

    return ResetScaffold(
      showBackButton: true,
      title: strings.get('nav_contact'),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSpacing.maxContentWidth,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 28,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        strings.get('nav_contact'),
                        style: AppTheme.displayStyle(
                          locale: settings.locale,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        strings.get('contact_subtitle'),
                        style: AppTheme.bodyStyle(
                          locale: settings.locale,
                          fontSize: 14,
                          color: palette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(flex: 5, child: studioCard),
                            const SizedBox(width: 24),
                            Expanded(flex: 7, child: formCard),
                          ],
                        )
                      else ...<Widget>[
                        studioCard,
                        const SizedBox(height: 20),
                        formCard,
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const ResetFooter(),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.text,
    this.onTap,
  });

  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final locale = context.watch<AppSettingsProvider>().locale;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 17, color: AppColors.terracotta),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: AppTheme.bodyStyle(
                  locale: locale,
                  fontSize: 13.5,
                  color: onTap != null
                      ? palette.textPrimary
                      : palette.textSecondary,
                ).copyWith(
                  decoration: onTap != null ? TextDecoration.underline : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
