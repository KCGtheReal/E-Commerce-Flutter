import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../models/bootstrap_page_models.dart';
import '../../providers/app_settings_provider.dart';
import '../../widgets/common_states.dart';
import '../../widgets/reset_footer.dart';
import '../../widgets/reset_scaffold.dart';
import '../../widgets/size_guide_modal.dart';

class InfoPageScreen extends StatefulWidget {
  const InfoPageScreen({super.key, required this.slug});

  final String slug;

  @override
  State<InfoPageScreen> createState() => _InfoPageScreenState();
}

class _InfoPageScreenState extends State<InfoPageScreen> {
  StructuredInfoPageDto? _page;
  bool _isLoading = true;
  String? _errorMessage;
  String? _loadedLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = context.watch<AppSettingsProvider>().locale;
    if (_loadedLocale != locale) {
      _loadedLocale = locale;
      _loadPage();
    }
  }

  Future<void> _loadPage() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final page = await context.read<ApiClient>().getPage(widget.slug);
      if (!mounted) {
        return;
      }
      setState(() {
        _page = page;
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

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final settings = context.watch<AppSettingsProvider>();
    final page = _page;

    return ResetScaffold(
      showBackButton: true,
      title: page?.title,
      onRefreshContext: _loadPage,
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 28,
                  ),
                  child: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 64),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : _errorMessage != null
                          ? ResetErrorBanner(
                              message: _errorMessage!,
                              onRetry: _loadPage,
                            )
                          : page == null
                              ? const SizedBox.shrink()
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    if (page.badge != null &&
                                        page.badge!.isNotEmpty) ...<Widget>[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.terracotta,
                                          borderRadius: BorderRadius.circular(
                                            AppRadii.xs,
                                          ),
                                        ),
                                        child: Text(
                                          page.badge!.toUpperCase(),
                                          style: AppTheme.displayStyle(
                                            locale: settings.locale,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.pureWhite,
                                            letterSpacing:
                                                settings.isKm ? 0 : 1.1,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    Text(
                                      page.title,
                                      style: AppTheme.displayStyle(
                                        locale: settings.locale,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: palette.textPrimary,
                                      ),
                                    ),
                                    if (page.subtitle != null &&
                                        page.subtitle!.isNotEmpty) ...<Widget>[
                                      const SizedBox(height: 8),
                                      Text(
                                        page.subtitle!,
                                        style: AppTheme.bodyStyle(
                                          locale: settings.locale,
                                          fontSize: 15,
                                          color: palette.textSecondary,
                                        ),
                                      ),
                                    ],
                                    if (page.updatedAt != null &&
                                        page.updatedAt!.isNotEmpty) ...<Widget>[
                                      const SizedBox(height: 8),
                                      Text(
                                        page.updatedAt!,
                                        style: AppTheme.monoStyle(
                                          fontSize: 11.5,
                                          color: palette.textTertiary,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 24),
                                    Divider(color: palette.borderSubtle),
                                    const SizedBox(height: 24),

                                    if (page.sizeGuide != null) ...<Widget>[
                                      SizeGuideContent(data: page.sizeGuide!),
                                      const SizedBox(height: 24),
                                    ],

                                    ...page.tables.map((table) {
                                      return _StructuredTableCard(table: table);
                                    }),

                                    ...page.sections.map((section) {
                                      return _StructuredSectionCard(
                                        section: section,
                                      );
                                    }),
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

class _StructuredTableCard extends StatelessWidget {
  const _StructuredTableCard({required this.table});

  final StructuredPageTableDto table;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final locale = context.watch<AppSettingsProvider>().locale;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            table.title,
            style: AppTheme.displayStyle(
              locale: locale,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: palette.cardSurface,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(color: palette.borderSubtle),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStatePropertyAll(palette.surfaceBone),
                columns: table.headers
                    .map((h) => DataColumn(label: Text(h)))
                    .toList(),
                rows: table.rows.map((row) {
                  return DataRow(
                    cells: row
                        .map(
                          (cell) => DataCell(
                            Text(
                              cell,
                              style: AppTheme.bodyStyle(
                                locale: locale,
                                fontSize: 13,
                                color: palette.textPrimary,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StructuredSectionCard extends StatelessWidget {
  const _StructuredSectionCard({required this.section});

  final StructuredPageSectionDto section;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final locale = context.watch<AppSettingsProvider>().locale;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.cardSurface,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (section.eyebrow != null &&
              section.eyebrow!.isNotEmpty) ...<Widget>[
            Text(
              section.eyebrow!.toUpperCase(),
              style: AppTheme.displayStyle(
                locale: locale,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.terracotta,
                letterSpacing: locale == 'km' ? 0 : 1.0,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            section.title,
            style: AppTheme.displayStyle(
              locale: locale,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          if (section.paragraphs.isNotEmpty) const SizedBox(height: 10),
          ...section.paragraphs.map((p) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                p,
                style: AppTheme.bodyStyle(
                  locale: locale,
                  fontSize: 14,
                  color: palette.textSecondary,
                ),
              ),
            );
          }),
          if (section.bullets.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            ...section.bullets.map((bullet) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 8, right: 10),
                      decoration: const BoxDecoration(
                        color: AppColors.terracotta,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        bullet,
                        style: AppTheme.bodyStyle(
                          locale: locale,
                          fontSize: 13.5,
                          color: palette.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          if (section.items.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            ...section.items.map((item) {
              if (item.question != null && item.answer != null) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: palette.elevatedSurface,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(color: palette.borderSubtle),
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    title: Text(
                      item.question!,
                      style: AppTheme.bodyStyle(
                        locale: locale,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                    children: <Widget>[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          item.answer!,
                          style: AppTheme.bodyStyle(
                            locale: locale,
                            fontSize: 13,
                            color: palette.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (item.title != null || item.label != null)
                      Text(
                        item.title ?? item.label ?? '',
                        style: AppTheme.bodyStyle(
                          locale: locale,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                      ),
                    if (item.description != null)
                      Text(
                        item.description!,
                        style: AppTheme.bodyStyle(
                          locale: locale,
                          fontSize: 13,
                          color: palette.textSecondary,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
