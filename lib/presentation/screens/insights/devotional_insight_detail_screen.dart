import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/core/errors/app_error_mapper.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_design_tokens.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';
import 'package:holyverso/data/insights/insights_repository.dart';
import 'package:holyverso/domain/insights/creator_devotional_insight.dart';
import 'package:holyverso/presentation/widgets/common/holy_child_app_bar.dart';

class DevotionalInsightDetailScreen extends ConsumerStatefulWidget {
  const DevotionalInsightDetailScreen({super.key, required this.devotionalId});

  final String devotionalId;

  @override
  ConsumerState<DevotionalInsightDetailScreen> createState() =>
      _DevotionalInsightDetailScreenState();
}

class _DevotionalInsightDetailScreenState
    extends ConsumerState<DevotionalInsightDetailScreen> {
  CreatorDevotionalInsight? _insight;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final insight = await ref
          .read(insightsRepositoryProvider)
          .fetchDevotionalInsightDetail(widget.devotionalId);
      if (!mounted) return;
      setState(() {
        _insight = insight;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AppErrorMapper.toMessage(
          error,
          l10n: context.l10n,
          fallbackMessage: 'No se pudo cargar este insight',
        );
        _isLoading = false;
      });
    }
  }

  String _percent(double value) => '${(value * 100).toStringAsFixed(1)}%';

  @override
  Widget build(BuildContext context) {
    final insight = _insight;

    return Scaffold(
      backgroundColor: AppColors.midnightFaith,
      appBar: const HolyChildAppBar(title: 'Insight del devocional'),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.holyGold),
              )
            : _errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    _errorMessage!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.pureWhite,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : insight == null
            ? const SizedBox.shrink()
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Text(
                    insight.title,
                    style: AppTextStyles.headline2.copyWith(
                      color: AppColors.pureWhite,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      _DetailMetric(label: 'Impresiones', value: '${insight.impressions}'),
                      _DetailMetric(label: 'Únicos', value: '${insight.uniqueImpressions}'),
                      _DetailMetric(label: 'Aperturas', value: '${insight.opens}'),
                      _DetailMetric(label: 'Lecturas completas', value: '${insight.readCompletes}'),
                      _DetailMetric(label: 'Tasa completa', value: _percent(insight.readCompleteRate)),
                      _DetailMetric(label: 'Me gusta', value: '${insight.likes}'),
                      _DetailMetric(label: 'Comentarios', value: '${insight.comments}'),
                      _DetailMetric(label: 'Guardados', value: '${insight.saves}'),
                      _DetailMetric(label: 'Compartidos', value: '${insight.shares}'),
                      _DetailMetric(label: 'Reportes', value: '${insight.reports}'),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

class _DetailMetric extends StatelessWidget {
  const _DetailMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.of(context).size.width - AppSpacing.lg * 3) / 2,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.pureWhite.withValues(alpha: 0.05),
        borderRadius: AppBorderRadius.card,
        border: Border.all(color: AppColors.pureWhite.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTextStyles.headline3.copyWith(
              color: AppColors.holyGold,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.softMist,
            ),
          ),
        ],
      ),
    );
  }
}
