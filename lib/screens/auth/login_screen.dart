import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exceptions.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_states.dart';
import '../../widgets/reset_logo.dart';
import '../../widgets/reset_scaffold.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _submitting = false;
  String? _errorMessage;
  Map<String, List<String>> _fieldErrors = const <String, List<String>>{};

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _submitting = true;
      _errorMessage = null;
      _fieldErrors = const <String, List<String>>{};
    });

    try {
      await context.read<AuthProvider>().login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _fieldErrors = e.errors;
        _errorMessage = e.message;
      });
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  String? _fieldError(String key) {
    final list = _fieldErrors[key];
    return (list != null && list.isNotEmpty) ? list.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final settings = context.watch<AppSettingsProvider>();
    final strings = settings.strings;

    return ResetScaffold(
      showBackButton: true,
      title: strings.get('nav_login'),
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
                    const Center(child: ResetWordmark(fontSize: 24)),
                    const SizedBox(height: 12),
                    Text(
                      strings.get('nav_login'),
                      textAlign: TextAlign.center,
                      style: AppTheme.displayStyle(
                        locale: settings.locale,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      strings.get('auth_login_subtitle'),
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyStyle(
                        locale: settings.locale,
                        fontSize: 13,
                        color: palette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_errorMessage != null) ...<Widget>[
                      ResetErrorBanner(message: _errorMessage!),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const <String>[AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: strings.get('checkout_email'),
                        errorText: _fieldError('email'),
                      ),
                      validator: (val) => (val == null || !val.contains('@'))
                          ? strings.get('error_invalid_email')
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      autofillHints: const <String>[AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: strings.get('password'),
                        errorText: _fieldError('password'),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (val) => (val == null || val.isEmpty)
                          ? strings.get('error_required')
                          : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: Text(strings.get('auth_forgot_password')),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(strings.get('nav_login')),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      strings.get('auth_cart_merge_note'),
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyStyle(
                        locale: settings.locale,
                        fontSize: 11.5,
                        color: palette.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Divider(color: palette.borderSubtle),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          strings.get('auth_dont_have_account'),
                          style: AppTheme.bodyStyle(
                            locale: settings.locale,
                            fontSize: 13,
                            color: palette.textSecondary,
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final registered =
                                await Navigator.of(context).push<bool>(
                              MaterialPageRoute<bool>(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                            if (registered == true && context.mounted) {
                              Navigator.of(context).pop(true);
                            }
                          },
                          child: Text(strings.get('nav_register')),
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
    );
  }
}
