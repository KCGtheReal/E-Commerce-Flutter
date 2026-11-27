import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exceptions.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../models/auth_account_models.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_states.dart';
import '../../widgets/reset_logo.dart';
import '../../widgets/reset_scaffold.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _submitting = false;
  String? _generalError;
  Map<String, List<String>> _fieldErrors = const <String, List<String>>{};

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _submitting = true;
      _generalError = null;
      _fieldErrors = const <String, List<String>>{};
    });

    try {
      await context.read<AuthProvider>().register(
            RegisterRequest(
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              phone: _phoneController.text.trim(),
              password: _passwordController.text,
              passwordConfirmation: _confirmController.text,
            ),
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
        _generalError = e.errors.isEmpty ? e.message : null;
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
      title: strings.get('nav_register'),
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
                      strings.get('nav_register'),
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
                      strings.get('auth_register_subtitle'),
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyStyle(
                        locale: settings.locale,
                        fontSize: 13,
                        color: palette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_generalError != null) ...<Widget>[
                      ResetErrorBanner(message: _generalError!),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: strings.get('checkout_full_name'),
                        errorText: _fieldError('name'),
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
                        labelText: strings.get('checkout_email'),
                        errorText: _fieldError('email'),
                      ),
                      validator: (val) => (val == null || !val.contains('@'))
                          ? strings.get('error_invalid_email')
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: strings.get('checkout_phone'),
                        hintText: '012 345 678',
                        errorText: _fieldError('phone'),
                      ),
                      validator: (val) => (val == null || val.trim().length < 8)
                          ? strings.get('error_required')
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
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
                      validator: (val) => (val == null || val.length < 8)
                          ? strings.get('error_required')
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: strings.get('confirm_password'),
                      ),
                      validator: (val) {
                        if (val != _passwordController.text) {
                          return 'Passwords do not match.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(strings.get('nav_register')),
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
