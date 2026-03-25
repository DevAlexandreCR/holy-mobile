import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_design_tokens.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';
import 'package:holyverso/data/devotionals/devotionals_repository.dart';
import 'package:holyverso/domain/devotionals/devotional.dart';
import 'package:holyverso/domain/devotionals/devotional_status.dart';
import 'package:holyverso/presentation/state/devotionals/devotionals_feed_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotionals_feed_state.dart';
import 'package:holyverso/presentation/state/devotionals/devotionals_list_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotionals_list_state.dart';
import 'package:share_plus/share_plus.dart';
import 'package:visibility_detector/visibility_detector.dart';

class DevotionalsListScreen extends ConsumerStatefulWidget {
  const DevotionalsListScreen({super.key});

  @override
  ConsumerState<DevotionalsListScreen> createState() =>
      _DevotionalsListScreenState();
}

class _DevotionalsListScreenState extends ConsumerState<DevotionalsListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openEditor([String? devotionalId]) async {
    if (devotionalId == null) {
      await context.push('/devotionals/create');
    } else {
      await context.push('/devotionals/$devotionalId/edit');
    }

    if (!mounted) return;
    unawaited(ref.read(devotionalsFeedControllerProvider.notifier).refresh());
    unawaited(ref.read(devotionalsListControllerProvider.notifier).refresh());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.midnightFaith,
      appBar: AppBar(
        title: Text(
          l10n.devotionalsTitle,
          style: AppTextStyles.headline3.copyWith(
            color: AppColors.pureWhite,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.holyGold,
          labelColor: AppColors.holyGold,
          unselectedLabelColor: AppColors.softMist,
          tabs: [
            Tab(text: l10n.devotionalsPublic),
            Tab(text: l10n.devotionalsMine),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openEditor,
        backgroundColor: AppColors.holyGold,
        foregroundColor: AppColors.midnightFaith,
        child: const Icon(Icons.edit),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _PublicFeedTab(),
          _MyDevotionalsTab(onOpenEditor: _openEditor),
        ],
      ),
    );
  }
}

class _PublicFeedTab extends ConsumerStatefulWidget {
  const _PublicFeedTab();

  @override
  ConsumerState<_PublicFeedTab> createState() => _PublicFeedTabState();
}

class _PublicFeedTabState extends ConsumerState<_PublicFeedTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final feedState = ref.read(devotionalsFeedControllerProvider);
      if (feedState.items.isEmpty &&
          feedState.status == DevotionalsFeedStatus.idle) {
        ref.read(devotionalsFeedControllerProvider.notifier).loadInitial();
      }
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(devotionalsFeedControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _share(Devotional devotional) async {
    final shareText = [
      devotional.title.trim(),
      if (devotional.previewText.isNotEmpty) devotional.previewText,
      'https://holyverso.com/devotionals/${devotional.id}',
    ].join('\n\n');

    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null
        ? (box.localToGlobal(Offset.zero) & box.size)
        : const Rect.fromLTWH(0, 0, 1, 1);

    Share.share(
      shareText,
      subject: context.l10n.shareDevotional,
      sharePositionOrigin: origin,
    );

    await ref
        .read(devotionalsFeedControllerProvider.notifier)
        .registerShare(devotional);
  }

  Future<void> _openDetail(Devotional devotional) async {
    await ref
        .read(devotionalsFeedControllerProvider.notifier)
        .registerOpen(devotional);
    if (!mounted) return;
    final updated = await context.push<Devotional>(
      '/devotionals/${devotional.id}',
    );
    if (updated != null && mounted) {
      ref
          .read(devotionalsFeedControllerProvider.notifier)
          .syncUpdatedDevotional(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(devotionalsFeedControllerProvider);
    final l10n = context.l10n;

    if (state.status == DevotionalsFeedStatus.loading && state.items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.holyGold),
      );
    }

    if (state.status == DevotionalsFeedStatus.error && state.items.isEmpty) {
      return _ErrorState(
        message: state.errorMessage ?? l10n.genericError,
        onRetry: () => ref
            .read(devotionalsFeedControllerProvider.notifier)
            .loadInitial(forceRefresh: true),
      );
    }

    if (state.items.isEmpty) {
      return _EmptyState(
        title: l10n.devotionalsFeedEmptyTitle,
        subtitle: l10n.devotionalsFeedEmptySubtitle,
      );
    }

    final showErrorBanner =
        state.errorMessage != null && state.items.isNotEmpty;

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(devotionalsFeedControllerProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        itemCount:
            state.items.length +
            (state.isFetchingMore ? 1 : 0) +
            (showErrorBanner ? 1 : 0),
        itemBuilder: (context, index) {
          if (showErrorBanner && index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _ErrorBanner(message: state.errorMessage!),
            );
          }

          final listIndex = showErrorBanner ? index - 1 : index;

          if (listIndex >= state.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.holyGold),
              ),
            );
          }

          final devotional = state.items[listIndex];
          return _FeedImpressionTracker(
            devotional: devotional,
            onQualified: () => ref
                .read(devotionalsFeedControllerProvider.notifier)
                .registerImpression(devotional),
            child: _PublicDevotionalCard(
              devotional: devotional,
              onOpen: () => _openDetail(devotional),
              onLike: () => ref
                  .read(devotionalsFeedControllerProvider.notifier)
                  .toggleLike(devotional.id),
              onSave: () => ref
                  .read(devotionalsFeedControllerProvider.notifier)
                  .toggleSave(devotional.id),
              onShare: () => _share(devotional),
            ),
          );
        },
      ),
    );
  }
}

class _MyDevotionalsTab extends ConsumerStatefulWidget {
  const _MyDevotionalsTab({required this.onOpenEditor});

  final Future<void> Function([String? devotionalId]) onOpenEditor;

  @override
  ConsumerState<_MyDevotionalsTab> createState() => _MyDevotionalsTabState();
}

class _MyDevotionalsTabState extends ConsumerState<_MyDevotionalsTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(devotionalsListControllerProvider.notifier).loadInitial();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(devotionalsListControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _publish(Devotional devotional) async {
    await ref
        .read(devotionalsRepositoryProvider)
        .publishDevotional(devotional.id);
    if (!mounted) return;
    await ref.read(devotionalsListControllerProvider.notifier).refresh();
    await ref.read(devotionalsFeedControllerProvider.notifier).refresh();
  }

  Future<void> _archive(Devotional devotional) async {
    await ref
        .read(devotionalsRepositoryProvider)
        .archiveDevotional(devotional.id);
    if (!mounted) return;
    await ref.read(devotionalsListControllerProvider.notifier).refresh();
    await ref.read(devotionalsFeedControllerProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(devotionalsListControllerProvider);
    final l10n = context.l10n;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: _StatusSelector(
            current: state.statusFilter,
            onSelected: (status) => ref
                .read(devotionalsListControllerProvider.notifier)
                .setStatusFilter(status),
          ),
        ),
        Expanded(
          child: switch (state.status) {
            DevotionalsListStatus.loading when state.items.isEmpty =>
              const Center(
                child: CircularProgressIndicator(color: AppColors.holyGold),
              ),
            DevotionalsListStatus.error when state.items.isEmpty => _ErrorState(
              message: state.errorMessage ?? l10n.genericError,
              onRetry: () => ref
                  .read(devotionalsListControllerProvider.notifier)
                  .loadInitial(forceRefresh: true),
            ),
            _ =>
              state.items.isEmpty
                  ? _EmptyState(
                      title: l10n.devotionalsMyEmptyTitle,
                      subtitle: l10n.devotionalsMyEmptySubtitle,
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref
                          .read(devotionalsListControllerProvider.notifier)
                          .refresh(),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.sm,
                          AppSpacing.lg,
                          AppSpacing.xl,
                        ),
                        itemCount:
                            state.items.length + (state.isFetchingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= state.items.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.holyGold,
                                ),
                              ),
                            );
                          }

                          final devotional = state.items[index];
                          return _OwnerDevotionalCard(
                            devotional: devotional,
                            onEdit: () => widget.onOpenEditor(devotional.id),
                            onPublish:
                                devotional.status == DevotionalStatus.draft
                                ? () => _publish(devotional)
                                : null,
                            onArchive:
                                devotional.status != DevotionalStatus.archived
                                ? () => _archive(devotional)
                                : null,
                            onOpen: () =>
                                context.push('/devotionals/${devotional.id}'),
                          );
                        },
                      ),
                    ),
          },
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.14),
        borderRadius: AppBorderRadius.card,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.pureWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedImpressionTracker extends StatefulWidget {
  const _FeedImpressionTracker({
    required this.devotional,
    required this.onQualified,
    required this.child,
  });

  final Devotional devotional;
  final VoidCallback onQualified;
  final Widget child;

  @override
  State<_FeedImpressionTracker> createState() => _FeedImpressionTrackerState();
}

class _FeedImpressionTrackerState extends State<_FeedImpressionTracker> {
  Timer? _timer;
  bool _reported = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (_reported) return;

    if (info.visibleFraction >= 0.5) {
      _timer ??= Timer(const Duration(milliseconds: 800), () {
        if (!mounted || _reported) return;
        _reported = true;
        widget.onQualified();
      });
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: ValueKey(
        'feed-${widget.devotional.deliveryToken ?? widget.devotional.id}',
      ),
      onVisibilityChanged: _onVisibilityChanged,
      child: widget.child,
    );
  }
}

class _PublicDevotionalCard extends StatelessWidget {
  const _PublicDevotionalCard({
    required this.devotional,
    required this.onOpen,
    required this.onLike,
    required this.onSave,
    required this.onShare,
  });

  final Devotional devotional;
  final VoidCallback onOpen;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.midnightFaith.withValues(alpha: 0.9),
        borderRadius: AppBorderRadius.card,
        border: Border.all(color: AppColors.pureWhite.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (devotional.previewImageUrl != null &&
              devotional.previewImageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppBorderRadius.lg),
              ),
              child: CachedNetworkImage(
                imageUrl: devotional.previewImageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                alignment: Alignment(0, devotional.coverImageFocusY),
                errorWidget: (context, url, error) => Container(
                  height: 180,
                  color: AppColors.midnightFaithDark,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.softMist,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  devotional.author.name,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.holyGold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  devotional.title,
                  style: AppTextStyles.headline3.copyWith(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  devotional.previewText,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.softMist,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _MetaChip(
                      icon: Icons.schedule_rounded,
                      label:
                          '${devotional.estimatedReadTime} ${context.l10n.devotionalMinutesShort}',
                    ),
                    _MetaChip(
                      icon: Icons.favorite_border,
                      label: devotional.likesCount.toString(),
                    ),
                    _MetaChip(
                      icon: Icons.chat_bubble_outline,
                      label: devotional.commentsCount.toString(),
                    ),
                    _MetaChip(
                      icon: Icons.share_outlined,
                      label: devotional.shareCount.toString(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onOpen,
                        child: Text(context.l10n.devotionalOpenDetail),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton(
                      onPressed: onLike,
                      icon: Icon(
                        devotional.liked
                            ? Icons.favorite
                            : Icons.favorite_border,
                      ),
                      color: devotional.liked
                          ? Colors.redAccent
                          : AppColors.holyGold,
                    ),
                    IconButton(
                      onPressed: onSave,
                      icon: Icon(
                        devotional.saved
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                      ),
                      color: AppColors.holyGold,
                    ),
                    IconButton(
                      onPressed: onShare,
                      icon: const Icon(Icons.share_outlined),
                      color: AppColors.holyGold,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerDevotionalCard extends StatelessWidget {
  const _OwnerDevotionalCard({
    required this.devotional,
    required this.onEdit,
    required this.onOpen,
    this.onPublish,
    this.onArchive,
  });

  final Devotional devotional;
  final VoidCallback onEdit;
  final VoidCallback onOpen;
  final VoidCallback? onPublish;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.midnightFaith.withValues(alpha: 0.9),
        borderRadius: AppBorderRadius.card,
        border: Border.all(color: AppColors.pureWhite.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (devotional.previewImageUrl != null &&
              devotional.previewImageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppBorderRadius.lg),
              ),
              child: CachedNetworkImage(
                imageUrl: devotional.previewImageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                alignment: Alignment(0, devotional.coverImageFocusY),
                errorWidget: (context, url, error) => Container(
                  height: 180,
                  color: AppColors.midnightFaithDark,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.softMist,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _StatusPill(label: _statusLabel(l10n, devotional.status)),
                    _StatusPill(
                      label: _moderationLabel(l10n, devotional),
                      isWarning: devotional.moderationReason != null,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  devotional.title,
                  style: AppTextStyles.headline3.copyWith(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  devotional.previewText,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.softMist,
                  ),
                ),
                if (devotional.moderationReason != null &&
                    devotional.moderationReason!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    devotional.moderationReason!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    OutlinedButton(
                      onPressed: onOpen,
                      child: Text(l10n.devotionalOpenDetail),
                    ),
                    if (devotional.status != DevotionalStatus.archived)
                      OutlinedButton(
                        onPressed: onEdit,
                        child: Text(l10n.editDevotional),
                      ),
                    if (onPublish != null)
                      ElevatedButton(
                        onPressed: onPublish,
                        child: Text(l10n.publish),
                      ),
                    if (onArchive != null)
                      TextButton(
                        onPressed: onArchive,
                        child: Text(l10n.devotionalArchiveAction),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n, DevotionalStatus status) {
    switch (status) {
      case DevotionalStatus.draft:
        return l10n.devotionalsDrafts;
      case DevotionalStatus.published:
        return l10n.devotionalsPublished;
      case DevotionalStatus.archived:
        return l10n.devotionalsArchived;
    }
  }

  String _moderationLabel(AppLocalizations l10n, Devotional devotional) {
    if (devotional.moderationStatus.name == 'underReview') {
      return l10n.devotionalModerationUnderReview;
    }
    if (devotional.moderationStatus.name == 'restricted') {
      return l10n.devotionalModerationRestricted;
    }
    return l10n.devotionalModerationClear;
  }
}

class _StatusSelector extends StatelessWidget {
  const _StatusSelector({required this.current, required this.onSelected});

  final DevotionalStatus current;
  final ValueChanged<DevotionalStatus> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.devotionalsStatusLabel,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.softMist),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _FilterChip(
              label: l10n.devotionalsDrafts,
              selected: current == DevotionalStatus.draft,
              onTap: () => onSelected(DevotionalStatus.draft),
            ),
            _FilterChip(
              label: l10n.devotionalsPublished,
              selected: current == DevotionalStatus.published,
              onTap: () => onSelected(DevotionalStatus.published),
            ),
            _FilterChip(
              label: l10n.devotionalsArchived,
              selected: current == DevotionalStatus.archived,
              onTap: () => onSelected(DevotionalStatus.archived),
            ),
          ],
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) => onTap(),
      selectedColor: AppColors.holyGold,
      backgroundColor: AppColors.inputBackground,
      labelStyle: AppTextStyles.labelSmall.copyWith(
        color: selected ? AppColors.midnightFaith : AppColors.softMist,
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.pureWhite.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.softMist),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.softMist),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, this.isWarning = false});

  final String label;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final color = isWarning ? AppColors.warning : AppColors.holyGold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: AppTextStyles.headline3.copyWith(
                color: AppColors.pureWhite,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.softMist,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

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
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.pureWhite,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(context.l10n.errorRetry),
            ),
          ],
        ),
      ),
    );
  }
}
