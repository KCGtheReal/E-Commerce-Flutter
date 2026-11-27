import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/app_tokens.dart';
import '../models/bootstrap_page_models.dart';
import '../providers/app_settings_provider.dart';
import '../providers/bootstrap_provider.dart';

class SizeGuideModal extends StatelessWidget {
  const SizeGuideModal({super.key, this.sizeGuideData});

  final SizeGuideDataDto? sizeGuideData;

  static Future<void> show(BuildContext context, {SizeGuideDataDto? data}) {
    return showDialog<void>(
      context: context,
      builder: (_) => SizeGuideModal(sizeGuideData: data),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final settings = context.watch<AppSettingsProvider>();
    final strings = settings.strings;
    final data = sizeGuideData ??
        context.watch<BootstrapProvider>().sizeGuide ??
        _fallbackSizeGuide(settings.locale);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: palette.borderSubtle)),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.straighten,
                    size: 18,
                    color: AppColors.terracotta,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          data.title,
                          style: AppTheme.displayStyle(
                            locale: settings.locale,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          data.subtitle,
                          style: AppTheme.bodyStyle(
                            locale: settings.locale,
                            fontSize: 12,
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: SizeGuideContent(data: data),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(strings.get('cancel')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SizeGuideContent extends StatelessWidget {
  const SizeGuideContent({super.key, required this.data});

  final SizeGuideDataDto data;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final locale = context.watch<AppSettingsProvider>().locale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (data.fitNoteBody.isNotEmpty) ...<Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.surfaceBone,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(color: palette.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (data.fitNoteTitle.isNotEmpty)
                  Text(
                    data.fitNoteTitle,
                    style: AppTheme.displayStyle(
                      locale: locale,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                if (data.fitNoteTitle.isNotEmpty) const SizedBox(height: 4),
                Text(
                  data.fitNoteBody,
                  style: AppTheme.bodyStyle(
                    locale: locale,
                    fontSize: 12.5,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
        ...data.tables.map((table) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  table.title,
                  style: AppTheme.displayStyle(
                    locale: locale,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(color: palette.borderSubtle),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStatePropertyAll(
                        palette.surfaceBone,
                      ),
                      columnSpacing: 24,
                      horizontalMargin: 16,
                      columns: <DataColumn>[
                        DataColumn(label: Text(table.columns.size)),
                        DataColumn(label: Text(table.columns.chest)),
                        DataColumn(label: Text(table.columns.length)),
                        DataColumn(label: Text(table.columns.shoulder)),
                        DataColumn(label: Text(table.columns.sleeve)),
                      ],
                      rows: table.rows.map((row) {
                        return DataRow(
                          cells: <DataCell>[
                            DataCell(
                              Text(
                                row.size,
                                style: AppTheme.displayStyle(
                                  locale: 'en',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: palette.textPrimary,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${row.chestCm} cm',
                                style: AppTheme.monoStyle(
                                  fontSize: 12.5,
                                  color: palette.textPrimary,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${row.lengthCm} cm',
                                style: AppTheme.monoStyle(
                                  fontSize: 12.5,
                                  color: palette.textPrimary,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${row.shoulderCm} cm',
                                style: AppTheme.monoStyle(
                                  fontSize: 12.5,
                                  color: palette.textPrimary,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${row.sleeveCm} cm',
                                style: AppTheme.monoStyle(
                                  fontSize: 12.5,
                                  color: palette.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        if (data.tip.isNotEmpty) ...<Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: AppColors.terracotta, width: 3),
              ),
              color: palette.surfaceBone,
            ),
            child: Text(
              data.tip,
              style: AppTheme.bodyStyle(
                locale: locale,
                fontSize: 12.5,
                color: palette.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],
        if (data.howToMeasure.isNotEmpty) ...<Widget>[
          Text(
            data.howToMeasureTitle,
            style: AppTheme.displayStyle(
              locale: locale,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...data.howToMeasure.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 7, right: 10),
                    decoration: const BoxDecoration(
                      color: AppColors.terracotta,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: AppTheme.bodyStyle(
                          locale: locale,
                          fontSize: 12.5,
                          color: palette.textSecondary,
                        ),
                        children: <InlineSpan>[
                          TextSpan(
                            text: '${item.label}: ',
                            style: AppTheme.bodyStyle(
                              locale: locale,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: palette.textPrimary,
                            ),
                          ),
                          TextSpan(text: item.description),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}

SizeGuideDataDto _fallbackSizeGuide(String locale) {
  return SizeGuideDataDto(
    title: locale == 'km' ? 'រង្វាស់ទំហំសម្លៀកបំពាក់' : 'Garment Measurements',
    subtitle: locale == 'km'
        ? 'រង្វាស់ទាំងអស់ត្រូវបានវាស់លើសម្លៀកបំពាក់រាបស្មើ គិតជាសង់ទីម៉ែត្រ (cm)។'
        : 'All measurements are taken flat across the garment in centimeters (cm).',
    fitNoteTitle: 'RESET Boxy Streetwear Fit',
    fitNoteBody:
        'Our tees and hoodies are engineered with dropped shoulders and generous boxy drape.',
    tip: 'For a more fitted look, we recommend sizing down one full size.',
    tables: const <SizeGuideTableDto>[
      SizeGuideTableDto(
        id: 'tees',
        title: 'Heavyweight T-Shirts & Tops (S–XL)',
        columns: SizeGuideColumnsDto(
          size: 'Size',
          chest: 'Chest',
          length: 'Length',
          shoulder: 'Shoulder',
          sleeve: 'Sleeve',
        ),
        rows: <SizeGuideRowDto>[
          SizeGuideRowDto(
            size: 'S',
            chestCm: 56,
            lengthCm: 68,
            shoulderCm: 52,
            sleeveCm: 21,
          ),
          SizeGuideRowDto(
            size: 'M',
            chestCm: 59,
            lengthCm: 71,
            shoulderCm: 55,
            sleeveCm: 22,
          ),
          SizeGuideRowDto(
            size: 'L',
            chestCm: 62,
            lengthCm: 74,
            shoulderCm: 58,
            sleeveCm: 23,
          ),
          SizeGuideRowDto(
            size: 'XL',
            chestCm: 65,
            lengthCm: 77,
            shoulderCm: 61,
            sleeveCm: 24,
          ),
        ],
      ),
      SizeGuideTableDto(
        id: 'hoodies',
        title: 'French Terry Hoodies & Crewnecks (S–XL)',
        columns: SizeGuideColumnsDto(
          size: 'Size',
          chest: 'Chest',
          length: 'Length',
          shoulder: 'Shoulder',
          sleeve: 'Sleeve',
        ),
        rows: <SizeGuideRowDto>[
          SizeGuideRowDto(
            size: 'S',
            chestCm: 60,
            lengthCm: 67,
            shoulderCm: 58,
            sleeveCm: 59,
          ),
          SizeGuideRowDto(
            size: 'M',
            chestCm: 63,
            lengthCm: 70,
            shoulderCm: 61,
            sleeveCm: 61,
          ),
          SizeGuideRowDto(
            size: 'L',
            chestCm: 66,
            lengthCm: 73,
            shoulderCm: 64,
            sleeveCm: 63,
          ),
          SizeGuideRowDto(
            size: 'XL',
            chestCm: 69,
            lengthCm: 76,
            shoulderCm: 67,
            sleeveCm: 65,
          ),
        ],
      ),
    ],
    howToMeasureTitle: 'How to Measure',
    howToMeasure: const <SizeGuideMeasureInstructionDto>[
      SizeGuideMeasureInstructionDto(
        key: 'chest',
        label: 'Chest',
        description: 'Measured flat across the garment 2cm below the armhole.',
      ),
      SizeGuideMeasureInstructionDto(
        key: 'length',
        label: 'Length',
        description:
            'Measured from the highest point of the shoulder seam to the bottom hem.',
      ),
      SizeGuideMeasureInstructionDto(
        key: 'shoulder',
        label: 'Shoulder',
        description: 'Measured straight across from shoulder seam to seam.',
      ),
      SizeGuideMeasureInstructionDto(
        key: 'sleeve',
        label: 'Sleeve',
        description: 'Measured from the shoulder seam to the end of the cuff.',
      ),
    ],
  );
}
