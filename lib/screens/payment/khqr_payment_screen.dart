import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/web_print.dart';
import '../../models/order_payment_models.dart';
import '../../providers/app_settings_provider.dart';
import '../../widgets/common_states.dart';
import '../../widgets/reset_scaffold.dart';
import '../order_success/order_success_screen.dart';

class KhqrPaymentScreen extends StatefulWidget {
  const KhqrPaymentScreen({
    super.key,
    required this.orderNumber,
    this.initialOrder,
    this.initialPayment,
    this.orderToken,
  });

  final String orderNumber;
  final OrderDetailDto? initialOrder;
  final PaymentDto? initialPayment;
  final String? orderToken;

  @override
  State<KhqrPaymentScreen> createState() => _KhqrPaymentScreenState();
}

class _KhqrPaymentScreenState extends State<KhqrPaymentScreen>
    with WidgetsBindingObserver {
  PaymentDto? _payment;
  bool _isLoading = false;
  bool _isActionLoading = false;
  bool _isPolling = false;
  bool _isRedirecting = false;
  String? _errorMessage;

  Timer? _countdownTimer;
  Timer? _pollTimer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _payment = widget.initialPayment;
    if (_payment != null) {
      _remainingSeconds = _payment!.timeRemainingSeconds.clamp(0, 86400);
      _startTimersIfPending();
    } else {
      _loadPayment();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTimers();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_payment == null || !_payment!.isPending || _isRedirecting) {
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _stopTimers();
    } else if (state == AppLifecycleState.resumed) {
      _startTimersIfPending();
      _pollPaymentStatus();
    }
  }

  void _stopTimers() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _startTimersIfPending() {
    _stopTimers();
    final payment = _payment;
    if (payment == null || !payment.isPending) {
      return;
    }

    _countdownTimer = Timer.periodic(AppMotion.khqrCountdownTick, (_) {
      if (!mounted) {
        return;
      }
      if (_remainingSeconds <= 1) {
        setState(() => _remainingSeconds = 0);
        _stopTimers();
        _pollPaymentStatus(markExpiredIfStillPending: true);
      } else {
        setState(() => _remainingSeconds -= 1);
      }
    });

    _pollTimer = Timer.periodic(AppMotion.khqrPollInterval, (_) {
      _pollPaymentStatus();
    });
  }

  Future<void> _loadPayment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final res = await context.read<ApiClient>().getOrderPayment(
            widget.orderNumber,
            orderToken: widget.orderToken,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _payment = res.payment;
        _remainingSeconds = res.payment.timeRemainingSeconds.clamp(0, 86400);
        _isLoading = false;
      });
      if (res.payment.isPaid) {
        _handlePaidTransition(res.order);
      } else {
        _startTimersIfPending();
      }
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

  Future<void> _pollPaymentStatus({
    bool markExpiredIfStillPending = false,
  }) async {
    final payment = _payment;
    if (payment == null || _isRedirecting) {
      return;
    }
    if (_isPolling && !markExpiredIfStillPending) {
      return;
    }

    _isPolling = true;
    try {
      final statusRes = await context.read<ApiClient>().getPaymentStatus(
            payment.id,
            orderNumber: widget.orderNumber,
            orderToken: widget.orderToken,
          );
      if (!mounted) {
        return;
      }

      if (statusRes.status == 'paid') {
        _stopTimers();
        final latest = await context.read<ApiClient>().getOrderPayment(
              widget.orderNumber,
              orderToken: widget.orderToken,
            );
        if (!mounted) {
          return;
        }
        setState(() {
          _payment = latest.payment;
        });
        _handlePaidTransition(latest.order);
        return;
      }

      if (statusRes.status == 'expired' ||
          (markExpiredIfStillPending && statusRes.timeRemainingSeconds <= 0)) {
        _stopTimers();
        setState(() {
          _remainingSeconds = 0;
          _payment = PaymentDto(
            id: payment.id,
            orderId: payment.orderId,
            orderNumber: payment.orderNumber,
            provider: payment.provider,
            md5: payment.md5,
            qrString: payment.qrString,
            accountId: payment.accountId,
            merchantName: payment.merchantName,
            amount: payment.amount,
            currency: payment.currency,
            formattedAmount: payment.formattedAmount,
            khrAmount: payment.khrAmount,
            formattedKhrAmount: payment.formattedKhrAmount,
            usdAmount: payment.usdAmount,
            formattedUsdAmount: payment.formattedUsdAmount,
            exchangeRate: payment.exchangeRate,
            status: 'expired',
            statusLabel: 'Expired',
            expiresAt: payment.expiresAt,
            timeRemainingSeconds: 0,
            paidAt: payment.paidAt,
            bakongMock: payment.bakongMock,
            deeplinkUrl: payment.deeplinkUrl,
          );
        });
        return;
      }

      setState(() {
        _remainingSeconds = statusRes.timeRemainingSeconds.clamp(0, 86400);
      });
    } catch (_) {
      // Resilience guard: ignore transient offline/network drops during polling
    } finally {
      _isPolling = false;
    }
  }

  Future<void> _handlePaidTransition(OrderDetailDto paidOrder) async {
    if (_isRedirecting) {
      return;
    }
    _stopTimers();
    setState(() => _isRedirecting = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => OrderSuccessScreen(
          order: paidOrder,
          orderToken: widget.orderToken,
        ),
      ),
    );
  }

  Future<void> _simulatePay() async {
    final payment = _payment;
    if (payment == null || _isActionLoading) {
      return;
    }
    setState(() {
      _isActionLoading = true;
      _errorMessage = null;
    });
    try {
      final res = await context.read<ApiClient>().simulatePay(
            payment.id,
            orderNumber: widget.orderNumber,
            orderToken: widget.orderToken,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _payment = res.payment;
      });
      await _handlePaidTransition(res.order);
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _regenerateQr() async {
    if (_isActionLoading) {
      return;
    }
    setState(() {
      _isActionLoading = true;
      _errorMessage = null;
    });
    try {
      final res = await context.read<ApiClient>().regenerateQr(
            widget.orderNumber,
            orderToken: widget.orderToken,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _payment = res.payment;
        _remainingSeconds = res.payment.timeRemainingSeconds.clamp(0, 86400);
      });
      _startTimersIfPending();
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _openBankingApp(PaymentDto payment) async {
    final strings = context.read<AppSettingsProvider>().strings;
    final uri = Uri.tryParse(payment.deeplinkUrl);
    var launched = false;
    if (uri != null) {
      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        launched = false;
      }
    }
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.get('payment_no_banking_app'))),
      );
    }
  }

  Future<void> _copyQr(PaymentDto payment) async {
    final strings = context.read<AppSettingsProvider>().strings;
    await Clipboard.setData(ClipboardData(text: payment.qrString));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.get('payment_copied_qr'))),
      );
    }
  }

  Future<void> _saveQrPng(PaymentDto payment) async {
    final strings = context.read<AppSettingsProvider>().strings;
    try {
      final painter = QrPainter(
        data: payment.qrString,
        version: QrVersions.auto,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: AppColors.onyxBlack,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: AppColors.onyxBlack,
        ),
      );
      final byteData = await painter.toImageData(720);
      if (byteData != null) {
        final downloaded = await triggerWebBytesDownload(
          byteData.buffer.asUint8List(),
          'RESET-KHQR-${payment.orderNumber}.png',
        );
        if (downloaded && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(strings.get('payment_qr_saved'))),
          );
          return;
        }
      }
    } catch (_) {
      // Fallback to clipboard below
    }

    await Clipboard.setData(ClipboardData(text: payment.qrString));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.get('payment_qr_copied_fallback'))),
      );
    }
  }

  String _formatCountdown(int seconds) {
    final safe = seconds < 0 ? 0 : seconds;
    final mins = (safe ~/ 60).toString().padLeft(2, '0');
    final secs = (safe % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final settings = context.watch<AppSettingsProvider>();
    final strings = settings.strings;
    final payment = _payment;

    return ResetScaffold(
      showBackButton: true,
      title: strings.get('bakong_payment_badge'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: _isLoading && payment == null
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 80),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _errorMessage != null && payment == null
                    ? ResetErrorBanner(
                        message: _errorMessage!,
                        onRetry: _loadPayment,
                      )
                    : payment == null
                        ? const SizedBox.shrink()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Text(
                                strings.get('payment_title'),
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
                                strings.get('payment_subtitle'),
                                textAlign: TextAlign.center,
                                style: AppTheme.bodyStyle(
                                  locale: settings.locale,
                                  fontSize: 12.5,
                                  color: palette.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 18),

                              if (_errorMessage != null) ...<Widget>[
                                ResetErrorBanner(message: _errorMessage!),
                                const SizedBox(height: 14),
                              ],

                              // KHQR Card
                              Container(
                                decoration: BoxDecoration(
                                  color: palette.cardSurface,
                                  borderRadius:
                                      BorderRadius.circular(AppRadii.sm),
                                  border: Border.all(
                                    color: palette.borderSubtle,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  children: <Widget>[
                                    // KHQR Red Branded Header
                                    Container(
                                      width: double.infinity,
                                      color: AppColors.khqrRed,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 14,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          Row(
                                            children: <Widget>[
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 3,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.pureWhite,
                                                  borderRadius:
                                                      BorderRadius.circular(2),
                                                ),
                                                child: Text(
                                                  'KHQR',
                                                  style: AppTheme.displayStyle(
                                                    locale: 'en',
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.khqrRed,
                                                    letterSpacing: 1,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'NBC BAKONG',
                                                style: AppTheme.monoStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.pureWhite,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            '#${payment.orderNumber}',
                                            style: AppTheme.monoStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.pureWhite,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        children: <Widget>[
                                          Text(
                                            strings
                                                .get('merchant_name')
                                                .toUpperCase(),
                                            style: AppTheme.displayStyle(
                                              locale: settings.locale,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: palette.textTertiary,
                                              letterSpacing:
                                                  settings.isKm ? 0 : 1.0,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            payment.merchantName,
                                            style: AppTheme.displayStyle(
                                              locale: 'en',
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: palette.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 14),

                                          // Dual Currency Well
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: palette.surfaceBone,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                AppRadii.sm,
                                              ),
                                              border: Border.all(
                                                color: palette.borderSubtle,
                                              ),
                                            ),
                                            child: Column(
                                              children: <Widget>[
                                                Text(
                                                  payment.currency == 'USD'
                                                      ? '${payment.formattedUsdAmount} USD'
                                                      : '${payment.formattedKhrAmount} KHR',
                                                  style: AppTheme.monoStyle(
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.w700,
                                                    color: palette.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  payment.currency == 'USD'
                                                      ? '≈ ${payment.formattedKhrAmount} KHR (${payment.exchangeRate} ៛/\$)'
                                                      : '≈ ${payment.formattedUsdAmount} USD (${payment.exchangeRate} ៛/\$)',
                                                  style: AppTheme.monoStyle(
                                                    fontSize: 12,
                                                    color:
                                                        palette.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 18),

                                          // Native QR Matrix Box (Always White Canvas!)
                                          _QrCanvasWithOverlays(
                                            payment: payment,
                                            isRedirecting: _isRedirecting,
                                            isRegenerating: _isActionLoading,
                                            onRegenerate: _regenerateQr,
                                          ),
                                          const SizedBox(height: 16),

                                          // Polling & Countdown Strip
                                          if (payment.isPending &&
                                              !_isRedirecting) ...<Widget>[
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: <Widget>[
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: AppColors.terracotta,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Flexible(
                                                  child: Text(
                                                    strings.get(
                                                      'payment_status_waiting',
                                                    ),
                                                    style: AppTheme.bodyStyle(
                                                      locale: settings.locale,
                                                      fontSize: 12.5,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          palette.textPrimary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              '${strings.get('payment_expires_in')} ${_formatCountdown(_remainingSeconds)}',
                                              style: AppTheme.monoStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                color: _remainingSeconds <= 60
                                                    ? AppColors.khqrRed
                                                    : palette.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Action Stack
                              if (payment.isPending && !_isRedirecting) ...<Widget>[
                                ElevatedButton.icon(
                                  onPressed: () => _openBankingApp(payment),
                                  icon: const Icon(
                                    Icons.account_balance_wallet_outlined,
                                    size: 18,
                                  ),
                                  label: Text(
                                    strings.get('payment_open_banking'),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _copyQr(payment),
                                        icon: const Icon(Icons.copy, size: 16),
                                        label: Text(
                                          strings.get('payment_copy_qr'),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _saveQrPng(payment),
                                        icon: const Icon(
                                          Icons.download_outlined,
                                          size: 16,
                                        ),
                                        label: Text(
                                          strings.get('payment_download_qr'),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              // Conditional Dev / Test Mode Mock Pay Panel (STRICT: ONLY when bakong_mock == true)
                              if (payment.bakongMock &&
                                  payment.isPending &&
                                  !_isRedirecting) ...<Widget>[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: SemanticStatusColors.fromKey(
                                      'warning',
                                      Theme.of(context).brightness,
                                    ).background,
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.sm,
                                    ),
                                    border: Border.all(
                                      color: SemanticStatusColors.fromKey(
                                        'warning',
                                        Theme.of(context).brightness,
                                      ).border,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: <Widget>[
                                      Row(
                                        children: <Widget>[
                                          Icon(
                                            Icons.bolt,
                                            size: 18,
                                            color: SemanticStatusColors.fromKey(
                                              'warning',
                                              Theme.of(context).brightness,
                                            ).foreground,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              strings.get(
                                                'payment_dev_mode_title',
                                              ),
                                              style: AppTheme.monoStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color:
                                                    SemanticStatusColors.fromKey(
                                                  'warning',
                                                  Theme.of(context).brightness,
                                                ).foreground,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        strings.get('payment_dev_mode_desc'),
                                        style: AppTheme.bodyStyle(
                                          locale: settings.locale,
                                          fontSize: 12,
                                          color: palette.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      ElevatedButton.icon(
                                        onPressed: _isActionLoading
                                            ? null
                                            : _simulatePay,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.terracotta,
                                          foregroundColor: AppColors.pureWhite,
                                        ),
                                        icon: _isActionLoading
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: AppColors.pureWhite,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.flash_on,
                                                size: 16,
                                              ),
                                        label: Text(
                                          strings.get('payment_simulate_pay'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 18),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: palette.surfaceBone,
                                  borderRadius:
                                      BorderRadius.circular(AppRadii.sm),
                                  border: Border.all(
                                    color: palette.borderSubtle,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        const Icon(
                                          Icons.verified_user_outlined,
                                          size: 16,
                                          color: AppColors.terracotta,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            strings.get(
                                              'payment_security_note',
                                            ),
                                            style: AppTheme.bodyStyle(
                                              locale: settings.locale,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: palette.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      strings.get('payment_supported_banks'),
                                      style: AppTheme.bodyStyle(
                                        locale: settings.locale,
                                        fontSize: 11.5,
                                        color: palette.textSecondary,
                                      ),
                                    ),
                                  ],
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

class _QrCanvasWithOverlays extends StatelessWidget {
  const _QrCanvasWithOverlays({
    required this.payment,
    required this.isRedirecting,
    required this.isRegenerating,
    required this.onRegenerate,
  });

  final PaymentDto payment;
  final bool isRedirecting;
  final bool isRegenerating;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    final strings = settings.strings;
    final showPaid = payment.isPaid || isRedirecting;
    final showExpired = payment.isExpired && !showPaid;

    return Container(
      width: 248,
      height: 248,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: AppColors.warmBorder, width: 1.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          QrImageView(
            data: payment.qrString.isNotEmpty
                ? payment.qrString
                : 'RESET-KHQR-${payment.orderNumber}',
            version: QrVersions.auto,
            backgroundColor: AppColors.pureWhite,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: AppColors.onyxBlack,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: AppColors.onyxBlack,
            ),
          ),
          if (showPaid)
            Positioned.fill(
              child: Container(
                color: AppColors.pureWhite.withValues(alpha: 0.94),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      width: 54,
                      height: 54,
                      decoration: const BoxDecoration(
                        color: Color(0xFFECFDF5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 32,
                        color: Color(0xFF15803D),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      strings.get('payment_status_paid'),
                      textAlign: TextAlign.center,
                      style: AppTheme.displayStyle(
                        locale: settings.locale,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (showExpired)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.xs),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Container(
                    color: AppColors.onyxBlack.withValues(alpha: 0.78),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Icon(
                          Icons.timer_off_outlined,
                          size: 30,
                          color: Color(0xFFF87171),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          strings.get('payment_status_expired'),
                          textAlign: TextAlign.center,
                          style: AppTheme.displayStyle(
                            locale: settings.locale,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.pureWhite,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: isRegenerating ? null : onRegenerate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.terracotta,
                            foregroundColor: AppColors.pureWhite,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                          child: isRegenerating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.pureWhite,
                                  ),
                                )
                              : Text(
                                  strings.get('payment_regenerate_qr'),
                                  textAlign: TextAlign.center,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
