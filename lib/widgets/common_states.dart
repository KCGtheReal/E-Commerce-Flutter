import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api/api_client.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_tokens.dart';
import '../providers/app_settings_provider.dart';
import '../screens/auth/login_screen.dart';

Color parseHexColor(String hex, {Color fallback = AppColors.onyxBlack}) {
  final cleaned = hex.trim().replaceAll('#', '');
  if (cleaned.length == 6) {
    final parsed = int.tryParse('FF$cleaned', radix: 16);
    if (parsed != null) {
      return Color(parsed);
    }
  } else if (cleaned.length == 8) {
    final parsed = int.tryParse(cleaned, radix: 16);
    if (parsed != null) {
      return Color(parsed);
    }
  }
  return fallback;
}

class ResetNetworkImage extends StatelessWidget {
  const ResetNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.cacheWidth,
    this.cacheHeight,
    this.borderRadius = BorderRadius.zero,
    this.colorFilter,
  });

  final String? imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final int? cacheWidth;
  final int? cacheHeight;
  final BorderRadius borderRadius;
  final ColorFilter? colorFilter;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final raw = imageUrl?.trim() ?? '';
    String resolvedUrl = raw;
    if (raw.isNotEmpty &&
        !raw.startsWith('http://') &&
        !raw.startsWith('https://')) {
      try {
        resolvedUrl = context.read<ApiClient>().resolveMediaUrl(raw);
      } catch (_) {
        resolvedUrl = raw;
      }
    }

    Widget fallbackWidget() {
      return Container(
        width: width,
        height: height,
        color: palette.surfaceBone,
        child: Center(
          child: Icon(
            Icons.checkroom_outlined,
            size: 28,
            color: palette.textTertiary,
          ),
        ),
      );
    }

    if (resolvedUrl.isEmpty) {
      return ClipRRect(borderRadius: borderRadius, child: fallbackWidget());
    }

    Widget img = Image.network(
      resolvedUrl,
      width: width,
      height: height,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      fit: fit,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return Container(
          width: width,
          height: height,
          color: palette.skeletonBase,
        );
      },
      errorBuilder: (context, error, stackTrace) => fallbackWidget(),
    );

    if (colorFilter != null) {
      img = ColorFiltered(colorFilter: colorFilter!, child: img);
    }

    return ClipRRect(borderRadius: borderRadius, child: img);
  }
}

class ResetErrorBanner extends StatelessWidget {
  const ResetErrorBanner({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final strings = context.watch<AppSettingsProvider>().strings;
    final statusColors = SemanticStatusColors.fromKey(
      'danger',
      Theme.of(context).brightness,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColors.background,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: statusColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.error_outline, color: statusColors.foreground, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTheme.bodyStyle(
                locale: strings.locale,
                fontSize: 13,
                color: palette.textPrimary,
              ),
            ),
          ),
          if (onRetry != null) ...<Widget>[
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: const Size(0, 36),
              ),
              child: Text(strings.get('retry')),
            ),
          ],
        ],
      ),
    );
  }
}

class ResetEmptyState extends StatelessWidget {
  const ResetEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.ctaLabel,
    this.onCtaPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? ctaLabel;
  final VoidCallback? onCtaPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final locale = context.watch<AppSettingsProvider>().locale;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: palette.cardSurface,
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(color: palette.borderSubtle),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: palette.surfaceBone,
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.borderSubtle),
                ),
                child: Icon(icon, size: 26, color: palette.textSecondary),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTheme.displayStyle(
                  locale: locale,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTheme.bodyStyle(
                  locale: locale,
                  fontSize: 13,
                  color: palette.textSecondary,
                ),
              ),
              if (ctaLabel != null && onCtaPressed != null) ...<Widget>[
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: onCtaPressed,
                  child: Text(ctaLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SemanticStatusBadge extends StatelessWidget {
  const SemanticStatusBadge({
    super.key,
    required this.label,
    required this.colorKey,
    this.showDot = true,
  });

  final String label;
  final String colorKey;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final statusColors = SemanticStatusColors.fromKey(
      colorKey,
      Theme.of(context).brightness,
    );
    final locale = context.watch<AppSettingsProvider>().locale;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusColors.background,
        borderRadius: BorderRadius.circular(AppRadii.xs),
        border: Border.all(color: statusColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (showDot) ...<Widget>[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: statusColors.dot,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTheme.displayStyle(
              locale: locale,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: statusColors.foreground,
              letterSpacing: locale == 'km' ? 0 : 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class ProductGridSkeleton extends StatelessWidget {
  const ProductGridSkeleton({
    super.key,
    this.count = 4,
    this.crossAxisCount = 2,
  });

  final int count;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 14,
        mainAxisSpacing: 18,
        childAspectRatio: crossAxisCount == 2 ? 0.47 : 0.52,
      ),
      itemCount: count,
      itemBuilder: (context, index) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: palette.skeletonBase,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(color: palette.borderSubtle),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 10,
              width: 64,
              color: palette.skeletonBase,
            ),
            const SizedBox(height: 6),
            Container(
              height: 14,
              width: double.infinity,
              color: palette.skeletonBase,
            ),
            const SizedBox(height: 6),
            Container(
              height: 12,
              width: 90,
              color: palette.skeletonBase,
            ),
          ],
        );
      },
    );
  }
}

Future<bool> showSignInPromptDialog(
  BuildContext context, {
  required String message,
}) async {
  final settings = context.read<AppSettingsProvider>();
  final strings = settings.strings;

  final shouldSignIn = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(strings.get('nav_login')),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.get('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.get('nav_login')),
          ),
        ],
      );
    },
  );

  if (shouldSignIn == true && context.mounted) {
    final signedIn = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const LoginScreen()),
    );
    return signedIn == true;
  }
  return false;
}
