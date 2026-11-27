import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exceptions.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../models/auth_account_models.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_states.dart';
import '../../widgets/reset_scaffold.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileKey = GlobalKey<FormState>();
  final _passwordKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _savingProfile = false;
  bool _savingPassword = false;
  String? _profileError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!(_profileKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _savingProfile = true;
      _profileError = null;
    });
    try {
      final res = await context.read<AuthProvider>().updateProfile(
            name: _nameController.text,
            phone: _phoneController.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message)),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _profileError = e.firstErrorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _savingProfile = false);
      }
    }
  }

  Future<void> _savePassword() async {
    if (!(_passwordKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _savingPassword = true;
      _passwordError = null;
    });
    try {
      final msg = await context.read<AuthProvider>().updatePassword(
            UpdatePasswordRequest(
              currentPassword: _currentPassController.text,
              password: _newPassController.text,
              passwordConfirmation: _confirmPassController.text,
            ),
          );
      if (mounted) {
        _currentPassController.clear();
        _newPassController.clear();
        _confirmPassController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _passwordError = e.firstErrorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _savingPassword = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final settings = context.watch<AppSettingsProvider>();
    final strings = settings.strings;
    final user = context.watch<AuthProvider>().user;

    return ResetScaffold(
      showBackButton: true,
      title: strings.get('account_profile'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: palette.cardSurface,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(color: palette.borderSubtle),
                  ),
                  child: Form(
                    key: _profileKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          strings.get('account_profile'),
                          style: AppTheme.displayStyle(
                            locale: settings.locale,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (_profileError != null) ...<Widget>[
                          ResetErrorBanner(message: _profileError!),
                          const SizedBox(height: 12),
                        ],
                        TextFormField(
                          initialValue: user?.email ?? '',
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: strings.get('checkout_email'),
                            helperText: strings.get(
                              'account_email_permanent_note',
                            ),
                            suffixIcon: const Icon(Icons.lock_outline, size: 18),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: strings.get('checkout_full_name'),
                          ),
                          validator: (val) =>
                              (val == null || val.trim().isEmpty)
                                  ? strings.get('error_required')
                                  : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: strings.get('checkout_phone'),
                          ),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton(
                          onPressed: _savingProfile ? null : _saveProfile,
                          child: _savingProfile
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(strings.get('account_save_changes')),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: palette.cardSurface,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(color: palette.borderSubtle),
                  ),
                  child: Form(
                    key: _passwordKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          strings.get('update_password'),
                          style: AppTheme.displayStyle(
                            locale: settings.locale,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (_passwordError != null) ...<Widget>[
                          ResetErrorBanner(message: _passwordError!),
                          const SizedBox(height: 12),
                        ],
                        TextFormField(
                          controller: _currentPassController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: strings.get('current_password'),
                          ),
                          validator: (val) => (val == null || val.isEmpty)
                              ? strings.get('error_required')
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _newPassController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: strings.get('new_password'),
                          ),
                          validator: (val) => (val == null || val.length < 8)
                              ? strings.get('error_required')
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmPassController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: strings.get('confirm_password'),
                          ),
                          validator: (val) => val != _newPassController.text
                              ? 'Passwords do not match.'
                              : null,
                        ),
                        const SizedBox(height: 18),
                        OutlinedButton(
                          onPressed: _savingPassword ? null : _savePassword,
                          child: _savingPassword
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(strings.get('update_password')),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
