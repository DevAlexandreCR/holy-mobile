import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:holyverso/core/errors/app_error_mapper.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_design_tokens.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';
import 'package:holyverso/data/insights/insights_repository.dart';
import 'package:holyverso/domain/insights/creator_devotional_insight.dart';
import 'package:holyverso/domain/insights/creator_insights_overview.dart';
import 'package:holyverso/presentation/widgets/common/holy_child_app_bar.dart';

class CreatorInsightsScreen extends ConsumerStatefulWidget {
  const CreatorInsightsScreen({super.key});

  @override
  ConsumerState<CreatorInsightsScreen> createState() =>
      _CreatorInsightsScreenState();
}

class _CreatorInsightsScreenState extends ConsumerState<CreatorInsightsScreen> {
  final ScrollController _scrollController = ScrollController();
  CreatorInsightsOverview? _overview;
  List<CreatorDevotionalInsight> _items = const [];
  String? _nextCursor;
  bool _hasMore = true;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_load());
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      unawaited(_loadMore());
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(insightsRepositoryProvider);
      final overview = await repository.fetchOverview();
      final devotionals = await repository.fetchDevotionalInsights();

      if (!mounted) return;
      setState(() {
        _overview = overview;
        _items = devotionals.items;
        _nextCursor = devotionals.nextCursor;
        _hasMore = devotionals.hasMore;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AppErrorMapper.toMessage(
          error,
          l10n: context.l10n,
          fallbackMessage: 'No se pudieron cargar los insights',
        );
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    final cursor = _nextCursor;
    if (cursor == null || _isLoadingMore) return;

    setState(() => _isLoadingMore = true);
    try {
      final result = await ref
          .read(insightsRepositoryProvider)
          .fetchDevotionalInsights(cursor: cursor);
      if (!mounted) return;
      setState(() {
        _items = [..._items, ...result.items];
        _nextCursor = result.nextCursor;
        _hasMore = result.hasMore;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _refresh() => _load();

  String _formatWindow(CreatorInsightsOverview overview) {
    final start = overview.windowStart;
    final end = overview.windowEnd;
    if (start == null || end == null) {
      return 'Últimos 30 días';
    }

    String format(DateTime value) =>
        '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}';

    return '${format(start)} - ${format(end)}';
  }

  String _percent(double value) => '${(value * 100).toStringAsFixed(1)}%';

  @override
  Widget build(BuildContext context) {
    final overview = _overview;

    return Scaffold(
      backgroundColor: AppColors.midnightFaith,
      appBar: const HolyChildAppBar(title: 'Insights'),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.holyGold),
              )
            : _errorMessage != null
            ? _InsightsError(
                message: _errorMessage!,
                onRetry: _load,
              )
            : RefreshIndicator(
                onRefresh: _refresh,
                color: AppColors.holyGold,
                backgroundColor: AppColors.midnightFaith,
                child: ListView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    if (overview != null) ...[
                      Text(
                        'Resumen del creador',
                        style: AppTextStyles.headline2.copyWith(
                          color: AppColors.pureWhite,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _formatWindow(overview),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.softMist,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.md,
                        children: [
                          _MetricCard(
                            label: 'Publicados',
                            value: overview.publishedDevotionalsLast30d.toString(),
                          ),
                          _MetricCard(
                            label: 'Impresiones',
                            value: overview.totalImpressionsLast30d.toString(),
                          ),
                          _MetricCard(
                            label: 'Únicos',
                            value:
                                overview.totalUniqueImpressionsLast30d.toString(),
                          ),
                          _MetricCard(
                            label: 'Aperturas',
                            value: overview.totalOpensLast30d.toString(),
                          ),
                          _MetricCard(
                            label: 'Lecturas completas',
                            value:
                                overview.totalReadsCompletedLast30d.toString(),
                          ),
                          _MetricCard(
                            label: 'Tasa completa',
                            value: _percent(overview.readCompleteRateLast30d),
                          ),
                          _MetricCard(
                            label: 'Guardados',
                            value: overview.totalSavesLast30d.toString(),
                          ),
                          _MetricCard(
                            label: 'Compartidos',
                            value: overview.totalSharesLast30d.toString(),
                          ),
                          _MetricCard(
                            label: 'Nuevos seguidores',
                            value: overview.newFollowersLast30d.toString(),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                    Text(
                      'Por devocional',
                      style: AppTextStyles.headline3.copyWith(
                        color: AppColors.pureWhite,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ..._items.map(
                      (item) => _InsightListCard(
                        insight: item,
                        onTap: () => context.push('/profile/insights/devotionals/${item.id}'),
                      ),
                    ),
                    if (_isLoadingMore)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.holyGold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

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
            style: AppTextStyles.headline2.copyWith(
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

class _InsightListCard extends StatelessWidget {
  const _InsightListCard({required this.insight, required this.onTap});

  final CreatorDevotionalInsight insight;
  final VoidCallback onTap;

  String _percent(double value) => '${(value * 100).toStringAsFixed(1)}%';

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppBorderRadius.card,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
              insight.title,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.pureWhite,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _Chip(label: 'Imp. ${insight.impressions}'),
                _Chip(label: 'Únicos ${insight.uniqueImpressions}'),
                _Chip(label: 'Aperturas ${insight.opens}'),
                _Chip(label: 'Lectura ${_percent(insight.readCompleteRate)}'),
                _Chip(label: 'Guardados ${insight.saves}'),
                _Chip(label: 'Compartidos ${insight.shares}'),
                _Chip(label: 'Reportes ${insight.reports}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.holyGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.holyGold,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InsightsError extends StatelessWidget {
  const _InsightsError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.pureWhite,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
