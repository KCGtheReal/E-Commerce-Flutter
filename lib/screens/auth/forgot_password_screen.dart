import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exceptions.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_states.dart';
import '../../widgets/reset_scaffold.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _submitting = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _submitting = true;
      _errorMessage = null;
      _successMessage = null;
    });
    try {
      final res = await context.read<AuthProvider>().forgotPassword(
            _emailController.text.trim(),
          );
      if (!mounted) {
        return;
      }
      setState(() => _successMessage = res.message);
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

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final settings = context.watch<AppSettingsProvider>();
    final strings = settings.strings;

    return ResetScaffold(
      showBackButton: true,
      title: strings.get('auth_forgot_password'),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              padding: const EdgeInsets.all(24),
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
                      strings.get('auth_forgot_password'),
                      style: AppTheme.displayStyle(
                        locale: settings.locale,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.get('auth_forgot_subtitle'),
                      style: AppTheme.bodyStyle(
                        locale: settings.locale,
                        fontSize: 13,
                        color: palette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (_errorMessage != null) ...<Widget>[
                      ResetErrorBanner(message: _errorMessage!),
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
                            fontSize: 13,
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
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: strings.get('checkout_email'),
                      ),
                      validator: (val) => (val == null || !val.contains('@'))
                          ? strings.get('error_invalid_email')
                          : null,
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
                          : Text(strings.get('auth_send_reset_link')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
