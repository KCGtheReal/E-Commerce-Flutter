import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../models/auth_account_models.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/bootstrap_provider.dart';
import '../../widgets/common_states.dart';
import '../../widgets/reset_scaffold.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  List<AddressDto> _addresses = const <AddressDto>[];
  List<String> _provinces = BootstrapProvider.defaultCambodiaProvinces;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final res = await context.read<ApiClient>().getAddresses();
      if (!mounted) {
        return;
      }
      setState(() {
        _addresses = res.addresses;
        if (res.provinces.isNotEmpty) {
          _provinces = res.provinces;
        }
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _openAddressForm({AddressDto? existing}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _AddressFormDialog(
        existing: existing,
        provinces: _provinces,
      ),
    );
    if (saved == true) {
      await _loadAddresses();
    }
  }

  Future<void> _deleteAddress(AddressDto address) async {
    final strings = context.read<AppSettingsProvider>().strings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.get('account_delete_address')),
        content: Text(strings.get('confirm_delete_address')),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.get('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.get('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    try {
      final msg = await context.read<ApiClient>().deleteAddress(address.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        await _loadAddresses();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Future<void> _setDefault(AddressDto address) async {
    try {
      await context.read<ApiClient>().updateAddress(
            address.id,
            UpsertAddressRequest(
              firstName: address.firstName,
              lastName: address.lastName,
              phone: address.phone,
              province: address.province,
              district: address.district,
              commune: address.commune,
              streetAddress: address.streetAddress,
              isDefault: true,
            ),
          );
      await _loadAddresses();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
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
      title: strings.get('account_addresses'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            strings.get('account_addresses'),
                            style: AppTheme.displayStyle(
                              locale: settings.locale,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: palette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            strings.get('account_addresses_desc'),
                            style: AppTheme.bodyStyle(
                              locale: settings.locale,
                              fontSize: 13,
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => _openAddressForm(),
                      child: Text(strings.get('account_add_address')),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 64),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_errorMessage != null)
                  ResetErrorBanner(
                    message: _errorMessage!,
                    onRetry: _loadAddresses,
                  )
                else if (_addresses.isEmpty)
                  ResetEmptyState(
                    icon: Icons.location_on_outlined,
                    title: strings.get('account_no_addresses'),
                    subtitle: strings.get('account_addresses_desc'),
                    ctaLabel: strings.get('account_add_address'),
                    onCtaPressed: () => _openAddressForm(),
                  )
                else
                  ..._addresses.map((addr) {
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: palette.cardSurface,
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        border: Border.all(
                          color: addr.isDefault
                              ? AppColors.terracotta
                              : palette.borderSubtle,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  '${addr.fullName} • ${addr.phone}',
                                  style: AppTheme.bodyStyle(
                                    locale: settings.locale,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: palette.textPrimary,
                                  ),
                                ),
                              ),
                              if (addr.isDefault)
                                SemanticStatusBadge(
                                  label: strings.get('account_default_badge'),
                                  colorKey: 'primary',
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            addr.formattedAddress,
                            style: AppTheme.bodyStyle(
                              locale: settings.locale,
                              fontSize: 13,
                              color: palette.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              OutlinedButton(
                                onPressed: () =>
                                    _openAddressForm(existing: addr),
                                child: Text(strings.get('account_edit_address')),
                              ),
                              if (!addr.isDefault)
                                OutlinedButton(
                                  onPressed: () => _setDefault(addr),
                                  child: Text(
                                    strings.get('account_set_as_default'),
                                  ),
                                ),
                              TextButton(
                                onPressed: () => _deleteAddress(addr),
                                style: TextButton.styleFrom(
                                  foregroundColor:
                                      Theme.of(context).colorScheme.error,
                                ),
                                child: Text(
                                  strings.get('account_delete_address'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddressFormDialog extends StatefulWidget {
  const _AddressFormDialog({this.existing, required this.provinces});

  final AddressDto? existing;
  final List<String> provinces;

  @override
  State<_AddressFormDialog> createState() => _AddressFormDialogState();
}

class _AddressFormDialogState extends State<_AddressFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _districtController;
  late final TextEditingController _communeController;
  late final TextEditingController _streetController;
  late String _province;
  late bool _isDefault;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.fullName ?? '');
    _phoneController = TextEditingController(text: e?.phone ?? '');
    _districtController = TextEditingController(text: e?.district ?? '');
    _communeController = TextEditingController(text: e?.commune ?? '');
    _streetController = TextEditingController(text: e?.streetAddress ?? '');
    _province = e != null && widget.provinces.contains(e.province)
        ? e.province
        : widget.provinces.first;
    _isDefault = e?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _districtController.dispose();
    _communeController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    final req = UpsertAddressRequest(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      province: _province,
      district: _districtController.text.trim(),
      commune: _communeController.text.trim(),
      streetAddress: _streetController.text.trim(),
      isDefault: _isDefault,
    );

    try {
      final api = context.read<ApiClient>();
      if (widget.existing == null) {
        await api.createAddress(req);
      } else {
        await api.updateAddress(widget.existing!.id, req);
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.firstErrorMessage;
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppSettingsProvider>().strings;
    return AlertDialog(
      title: Text(
        widget.existing == null
            ? strings.get('account_add_new_address')
            : strings.get('account_edit_address'),
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (_error != null) ...<Widget>[
                  ResetErrorBanner(message: _error!),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: strings.get('checkout_full_name'),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? strings.get('error_required')
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: strings.get('checkout_phone'),
                  ),
                  validator: (val) => (val == null || val.trim().length < 8)
                      ? strings.get('error_required')
                      : null,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _province,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: strings.get('checkout_province'),
                  ),
                  items: widget.provinces
                      .map(
                        (p) => DropdownMenuItem<String>(value: p, child: Text(p)),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _province = val);
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _districtController,
                  decoration: InputDecoration(
                    labelText: strings.get('checkout_district'),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _communeController,
                  decoration: InputDecoration(
                    labelText: strings.get('checkout_commune'),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _streetController,
                  decoration: InputDecoration(
                    labelText: strings.get('checkout_street_address'),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? strings.get('error_required')
                      : null,
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isDefault,
                  onChanged: (val) => setState(() => _isDefault = val ?? false),
                  title: Text(strings.get('account_set_as_default')),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: Text(strings.get('cancel')),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(strings.get('account_save_address')),
        ),
      ],
    );
  }
}
