import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/app_tokens.dart';
import '../providers/app_settings_provider.dart';
import '../providers/bootstrap_provider.dart';

class AnnouncementBar extends StatelessWidget {
  const AnnouncementBar({
    super.key,
    required this.onSettingsChanged,
  });

  final VoidCallback onSettingsChanged;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final showDesktopControls = !AppBreakpoints.isMobile(width);
    final settings = context.watch<AppSettingsProvider>();
    final bootstrap = context.watch<BootstrapProvider>();
    final bannerText = bootstrap.announcementBanner(settings.locale);

    return Container(
      width: double.infinity,
      color: AppColors.onyxBlack,
      padding: EdgeInsets.symmetric(
        horizontal: showDesktopControls ? 20 : 12,
        vertical: 7,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                bannerText,
                textAlign:
                    showDesktopControls ? TextAlign.left : TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodyStyle(
                  locale: settings.locale,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.boneWhite,
                  height: settings.isKm ? 1.45 : 1.25,
                ),
              ),
            ),
            if (showDesktopControls) ...<Widget>[
              const SizedBox(width: 12),
              _MiniToggleButton(
                label: settings.isDarkMode ? 'DARK' : 'LIGHT',
                icon: settings.isDarkMode
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
                onTap: () => settings.toggleTheme(),
              ),
              const SizedBox(width: 6),
              _SegmentedPill(
                options: const <String>['KHR', 'USD'],
                labels: const <String>['៛ KHR', '\$ USD'],
                selected: settings.currency,
                onSelect: (val) async {
                  await settings.setCurrency(val);
                  onSettingsChanged();
                },
              ),
              const SizedBox(width: 6),
              _SegmentedPill(
                options: const <String>['en', 'km'],
                labels: const <String>['EN', 'ខ្មែរ'],
                selected: settings.locale,
                onSelect: (val) async {
                  await settings.setLocale(val);
                  onSettingsChanged();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniToggleButton extends StatelessWidget {
  const _MiniToggleButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.xs),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.softCharcoal,
          borderRadius: BorderRadius.circular(AppRadii.xs),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 12, color: AppColors.boneWhite),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTheme.monoStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.boneWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedPill extends StatelessWidget {
  const _SegmentedPill({
    required this.options,
    required this.labels,
    required this.selected,
    required this.onSelect,
  });

  final List<String> options;
  final List<String> labels;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.softCharcoal,
        borderRadius: BorderRadius.circular(AppRadii.xs),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(options.length, (i) {
          final isSelected = options[i] == selected;
          return InkWell(
            onTap: () => onSelect(options[i]),
            borderRadius: BorderRadius.circular(AppRadii.xs),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.terracotta : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadii.xs),
              ),
              child: Text(
                labels[i],
                style: options[i] == 'km'
                    ? AppTheme.bodyStyle(
                        locale: 'km',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.pureWhite,
                        height: 1.25,
                      )
                    : AppTheme.monoStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.pureWhite,
                      ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
