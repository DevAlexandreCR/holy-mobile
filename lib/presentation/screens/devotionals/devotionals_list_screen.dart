import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:holyverso/core/errors/app_error_mapper.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_design_tokens.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';
import 'package:holyverso/data/devotionals/devotionals_repository.dart';
import 'package:holyverso/domain/devotionals/devotional.dart';
import 'package:holyverso/domain/devotionals/devotional_feed_mode.dart';
import 'package:holyverso/domain/devotionals/devotional_status.dart';
import 'package:holyverso/domain/devotionals/devotional_verse_reference.dart';
import 'package:holyverso/presentation/screens/devotionals/devotional_editor_screen.dart';
import 'package:holyverso/presentation/state/auth/auth_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotionals_feed_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotionals_feed_state.dart';
import 'package:holyverso/presentation/state/devotionals/devotionals_list_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotionals_list_state.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_review_queue_controller.dart';
import 'package:holyverso/presentation/widgets/common/holy_child_app_bar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:visibility_detector/visibility_detector.dart';

class DevotionalsListScreen extends ConsumerStatefulWidget {
  const DevotionalsListScreen({super.key});

  @override
  ConsumerState<DevotionalsListScreen> createState() =>
      _DevotionalsListScreenState();
}

enum _DevotionalsTopTab { forYou, following, mine, review }

class _DevotionalsListScreenState extends ConsumerState<DevotionalsListScreen> {
  int _selectedTabIndex = 0;

  Future<void> _openEditor([String? devotionalId]) async {
    if (devotionalId == null) {
      await context.push('/devotionals/create');
    } else {
      await context.push('/devotionals/$devotionalId/edit');
    }

    if (!mounted) return;
    unawaited(ref.read(forYouFeedControllerProvider.notifier).refresh());
    unawaited(ref.read(followingFeedControllerProvider.notifier).refresh());
    unawaited(ref.read(devotionalsListControllerProvider.notifier).refresh());
    unawaited(
      ref.read(devotionalReviewQueueControllerProvider.notifier).refresh(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final role = ref.watch(
      authControllerProvider.select((state) => state.user?.role),
    );
    final canModerate = role?.canEditContent ?? false;
    final tabs = <(_DevotionalsTopTab, _TopLevelTabData)>[
      (
        _DevotionalsTopTab.forYou,
        _TopLevelTabData(
          key: const Key('devotionals-tab-for-you'),
          label: l10n.devotionalsForYou,
        ),
      ),
      (
        _DevotionalsTopTab.following,
        _TopLevelTabData(
          key: const Key('devotionals-tab-following'),
          label: l10n.devotionalsFollowing,
        ),
      ),
      (
        _DevotionalsTopTab.mine,
        _TopLevelTabData(
          key: const Key('devotionals-tab-mine'),
          label: l10n.devotionalsMine,
        ),
      ),
      if (canModerate)
        (
          _DevotionalsTopTab.review,
          const _TopLevelTabData(
            key: Key('devotionals-tab-review'),
            label: 'En revisión',
          ),
        ),
    ];

    if (_selectedTabIndex >= tabs.length) {
      _selectedTabIndex = tabs.length - 1;
    }

    return Scaffold(
      backgroundColor: AppColors.midnightFaithDark,
      appBar: HolyChildAppBar(
        title: l10n.navDevotionalsLabel,
        showBackButton: false,
        bottom: _DevotionalsTopTabsBar(
          selectedIndex: _selectedTabIndex,
          onSelected: (index) {
            if (_selectedTabIndex == index) return;
            setState(() {
              _selectedTabIndex = index;
            });
          },
          tabs: tabs.map((entry) => entry.$2).toList(),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        key: const Key('devotionals-create-fab'),
        onPressed: _openEditor,
        backgroundColor: AppColors.holyGold,
        foregroundColor: AppColors.midnightFaithDark,
        elevation: 0,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.midnightFaith, AppColors.midnightFaithDark],
          ),
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: IndexedStack(
            index: _selectedTabIndex,
            children: tabs.map((entry) {
              switch (entry.$1) {
                case _DevotionalsTopTab.forYou:
                  return _PublicFeedModeView(
                    mode: DevotionalFeedMode.forYou,
                    provider: forYouFeedControllerProvider,
                  );
                case _DevotionalsTopTab.following:
                  return _PublicFeedModeView(
                    mode: DevotionalFeedMode.following,
                    provider: followingFeedControllerProvider,
                  );
                case _DevotionalsTopTab.mine:
                  return _MyDevotionalsTab(onOpenEditor: _openEditor);
                case _DevotionalsTopTab.review:
                  return const _ReviewQueueTab();
              }
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _TopLevelTabData {
  const _TopLevelTabData({required this.key, required this.label});

  final Key key;
  final String label;
}

class _DevotionalsTopTabsBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _DevotionalsTopTabsBar({
    required this.selectedIndex,
    required this.onSelected,
    required this.tabs,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<_TopLevelTabData> tabs;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: preferredSize.height,
      child: Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          key: const Key('devotionals-top-tabs-scroll'),
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            0,
          ),
          child: Row(
            children: [
              for (final entry in tabs.asMap().entries) ...[
                _TopLevelTabButton(
                  key: entry.value.key,
                  label: entry.value.label,
                  selected: selectedIndex == entry.key,
                  onTap: () => onSelected(entry.key),
                ),
                if (entry.key != tabs.length - 1)
                  const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TopLevelTabButton extends StatelessWidget {
  const _TopLevelTabButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: selected
                      ? AppColors.holyGold
                      : AppColors.softMist.withValues(alpha: 0.72),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                height: 2,
                width: selected ? 44 : 24,
                decoration: BoxDecoration(
                  color: selected ? AppColors.holyGold : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppBorderRadius.full),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PublicFeedModeView extends ConsumerStatefulWidget {
  const _PublicFeedModeView({required this.mode, required this.provider});

  final DevotionalFeedMode mode;
  final NotifierProvider<BaseDevotionalsFeedController, DevotionalsFeedState>
  provider;

  @override
  ConsumerState<_PublicFeedModeView> createState() =>
      _PublicFeedModeViewState();
}

class _PublicFeedModeViewState extends ConsumerState<_PublicFeedModeView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(widget.provider.notifier).loadInitial();
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
      ref.read(widget.provider.notifier).loadMore();
    }
  }

  Future<void> _share(Devotional devotional) async {
    final result = await ref
        .read(devotionalsRepositoryProvider)
        .shareDevotional(
          devotional.id,
          deliveryToken: devotional.deliveryToken,
        );
    if (!mounted) return;

    final shareText = [
      devotional.title.trim(),
      if (devotional.previewText.isNotEmpty) devotional.previewText,
      result.shareUrl,
    ].join('\n\n');

    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null
        ? (box.localToGlobal(Offset.zero) & box.size)
        : const Rect.fromLTWH(0, 0, 1, 1);

    await Share.share(
      shareText,
      subject: context.l10n.shareDevotional,
      sharePositionOrigin: origin,
    );

    if (!mounted) return;
    await ref
        .read(widget.provider.notifier)
        .registerShare(devotional, shareCount: result.shareCount);
  }

  Future<void> _openDetail(Devotional devotional) async {
    await ref.read(widget.provider.notifier).registerOpen(devotional);
    if (!mounted) return;
    final query = devotional.deliveryToken != null
        ? '?delivery_token=${Uri.encodeComponent(devotional.deliveryToken!)}'
        : '';
    final updated = await context.push<Devotional>(
      '/devotionals/${devotional.id}$query',
    );
    if (updated != null && mounted) {
      ref.read(widget.provider.notifier).syncUpdatedDevotional(updated);
    }
  }

  Future<void> _openAuthor(Devotional devotional) async {
    if (!mounted) return;
    await context.push('/users/${devotional.author.id}');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(widget.provider);
    final l10n = context.l10n;

    if (state.status == DevotionalsFeedStatus.loading && state.items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.holyGold),
      );
    }

    if (state.status == DevotionalsFeedStatus.error && state.items.isEmpty) {
      return _ErrorState(
        message: state.errorMessage ?? l10n.genericError,
        onRetry: () =>
            ref.read(widget.provider.notifier).loadInitial(forceRefresh: true),
      );
    }

    if (state.items.isEmpty) {
      return _EmptyState(
        title: widget.mode == DevotionalFeedMode.following
            ? l10n.devotionalsFollowingEmptyTitle
            : l10n.devotionalsFeedEmptyTitle,
        subtitle: widget.mode == DevotionalFeedMode.following
            ? l10n.devotionalsFollowingEmptySubtitle
            : l10n.devotionalsFeedEmptySubtitle,
      );
    }

    final showErrorBanner =
        state.errorMessage != null && state.items.isNotEmpty;

    return RefreshIndicator(
      onRefresh: () => ref.read(widget.provider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxl,
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
                .read(widget.provider.notifier)
                .registerImpression(devotional),
            child: _PublicDevotionalCard(
              devotional: devotional,
              isLiking: state.likingDevotionalId == devotional.id,
              isSaving: state.savingDevotionalId == devotional.id,
              onOpen: () => _openDetail(devotional),
              onOpenAuthor: () => _openAuthor(devotional),
              onLike: () =>
                  ref.read(widget.provider.notifier).toggleLike(devotional.id),
              onSave: () =>
                  ref.read(widget.provider.notifier).toggleSave(devotional.id),
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
  final Map<String, _OwnerDevotionalAction> _pendingActions = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(devotionalsListControllerProvider);
      if (state.items.isEmpty && state.status == DevotionalsListStatus.idle) {
        ref.read(devotionalsListControllerProvider.notifier).loadInitial();
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
      ref.read(devotionalsListControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _runOwnerAction({
    required Devotional devotional,
    required _OwnerDevotionalAction action,
    required Future<void> Function() request,
    required String successMessage,
    required String fallbackMessage,
    Map<String, String> businessCodeMessages = const {},
  }) async {
    if (_pendingActions.containsKey(devotional.id)) return;

    setState(() {
      _pendingActions[devotional.id] = action;
    });

    try {
      await request();
      await Future.wait([
        ref.read(devotionalsListControllerProvider.notifier).refresh(),
        ref.read(devotionalReviewQueueControllerProvider.notifier).refresh(),
        ref.read(forYouFeedControllerProvider.notifier).refresh(),
        ref.read(followingFeedControllerProvider.notifier).refresh(),
      ]);

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            successMessage,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.midnightFaith,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: AppColors.holyGold,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            AppErrorMapper.toMessage(
              error,
              l10n: context.l10n,
              fallbackMessage: fallbackMessage,
              businessCodeMessages: businessCodeMessages,
            ),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _pendingActions.remove(devotional.id);
        });
      }
    }
  }

  Future<void> _publish(Devotional devotional) async {
    await _runOwnerAction(
      devotional: devotional,
      action: _OwnerDevotionalAction.publishing,
      request: () => ref
          .read(devotionalsRepositoryProvider)
          .publishDevotional(devotional.id),
      successMessage: context.l10n.devotionalPublishedMovedMessage,
      fallbackMessage: context.l10n.devotionalsSaveError,
      businessCodeMessages: {
        'DEVOTIONAL_PUBLISH_BLOCKED': context.l10n.devotionalPublishBlocked,
        'OPENAI_MODERATION_UNAVAILABLE':
            context.l10n.devotionalsModerationUnavailable,
      },
    );
  }

  Future<void> _archive(Devotional devotional) async {
    await _runOwnerAction(
      devotional: devotional,
      action: _OwnerDevotionalAction.archiving,
      request: () => ref
          .read(devotionalsRepositoryProvider)
          .archiveDevotional(devotional.id),
      successMessage: context.l10n.devotionalArchivedMovedMessage,
      fallbackMessage: context.l10n.devotionalsSaveError,
    );
  }

  Future<void> _openOwnerDevotional(Devotional devotional) async {
    if (devotional.isPubliclyVisible) {
      await context.push('/devotionals/${devotional.id}');
      return;
    }

    try {
      final fullDevotional = await ref
          .read(devotionalsRepositoryProvider)
          .getDevotional(devotional.id);
      if (!mounted) return;

      final payload = DevotionalPreviewPayload(
        title: fullDevotional.title,
        content: fullDevotional.content ?? const [],
        coverImageUrl: fullDevotional.coverImageUrl,
        coverImageFocusY: fullDevotional.coverImageFocusY,
        references: List<DevotionalVerseReference>.from(
          fullDevotional.verseReferences,
        ),
        authorName: fullDevotional.author.name,
      );

      await context.push('/devotionals/preview', extra: payload);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppErrorMapper.toMessage(
              error,
              l10n: context.l10n,
              fallbackMessage: context.l10n.devotionalsLoadError,
            ),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openInsightDetail(Devotional devotional) async {
    await context.push('/profile/insights/devotionals/${devotional.id}');
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
            AppSpacing.sm,
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
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          AppSpacing.xxl,
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
                          final pendingAction = _pendingActions[devotional.id];
                          return _OwnerDevotionalCard(
                            devotional: devotional,
                            pendingAction: pendingAction,
                            onEdit: () => widget.onOpenEditor(devotional.id),
                            onInsights: () => _openInsightDetail(devotional),
                            onPublish:
                                devotional.status == DevotionalStatus.draft &&
                                    pendingAction == null
                                ? () => _publish(devotional)
                                : null,
                            onArchive:
                                devotional.status !=
                                        DevotionalStatus.archived &&
                                    pendingAction == null
                                ? () => _archive(devotional)
                                : null,
                            onOpen: pendingAction == null
                                ? () => _openOwnerDevotional(devotional)
                                : null,
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

class _ReviewQueueTab extends ConsumerStatefulWidget {
  const _ReviewQueueTab();

  @override
  ConsumerState<_ReviewQueueTab> createState() => _ReviewQueueTabState();
}

class _ReviewQueueTabState extends ConsumerState<_ReviewQueueTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(devotionalReviewQueueControllerProvider);
      if (state.items.isEmpty && state.status == DevotionalsListStatus.idle) {
        ref
            .read(devotionalReviewQueueControllerProvider.notifier)
            .loadInitial();
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
      ref.read(devotionalReviewQueueControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _openReview(Devotional devotional) async {
    await context.push('/devotionals/${devotional.id}');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(devotionalReviewQueueControllerProvider);
    final l10n = context.l10n;

    return switch (state.status) {
      DevotionalsListStatus.loading when state.items.isEmpty => const Center(
        child: CircularProgressIndicator(color: AppColors.holyGold),
      ),
      DevotionalsListStatus.error when state.items.isEmpty => _ErrorState(
        message: state.errorMessage ?? l10n.genericError,
        onRetry: () => ref
            .read(devotionalReviewQueueControllerProvider.notifier)
            .loadInitial(forceRefresh: true),
      ),
      _ =>
        state.items.isEmpty
            ? const _EmptyState(
                title: 'No hay devocionales pendientes',
                subtitle:
                    'Cuando un devocional entre en revisión aparecerá en esta bandeja.',
              )
            : RefreshIndicator(
                onRefresh: () => ref
                    .read(devotionalReviewQueueControllerProvider.notifier)
                    .refresh(),
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  itemCount:
                      state.items.length + (state.isFetchingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= state.items.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.holyGold,
                          ),
                        ),
                      );
                    }

                    final devotional = state.items[index];
                    return _ReviewDevotionalCard(
                      devotional: devotional,
                      onOpen: () => _openReview(devotional),
                    );
                  },
                ),
              ),
    };
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
    required this.isLiking,
    required this.isSaving,
    required this.onOpen,
    required this.onOpenAuthor,
    required this.onLike,
    required this.onSave,
    required this.onShare,
  });

  final Devotional devotional;
  final bool isLiking;
  final bool isSaving;
  final VoidCallback onOpen;
  final VoidCallback onOpenAuthor;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final referenceLabel = _referenceLabel(devotional);

    return _DevotionalSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DevotionalCoverImage(
            imageUrl: devotional.previewImageUrl ?? devotional.coverImageUrl,
            focusY: devotional.coverImageFocusY,
            onTap: onOpen,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AuthorHeader(
                  authorName: devotional.author.name,
                  handle: devotional.author.handle,
                  avatarUrl: devotional.author.avatarUrl,
                  following: devotional.author.following,
                  onTap: onOpenAuthor,
                ),
                if (referenceLabel != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    referenceLabel,
                    style: AppTextStyles.referenceSmall.copyWith(
                      color: AppColors.holyGold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Text(
                  devotional.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headline2.copyWith(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                if (devotional.previewText.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    devotional.previewText,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.softMist.withValues(alpha: 0.84),
                      height: 1.55,
                    ),
                  ),
                ],
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
                      icon: Icons.favorite_rounded,
                      label: devotional.likesCount.toString(),
                    ),
                    _MetaChip(
                      icon: Icons.chat_bubble_outline_rounded,
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
                    Expanded(child: _ReadMoreAction(onTap: onOpen)),
                    const SizedBox(width: AppSpacing.sm),
                    _CardIconButton(
                      key: Key('public-devotional-like-${devotional.id}'),
                      onPressed: isLiking ? null : onLike,
                      icon: devotional.liked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      active: devotional.liked,
                      activeColor: Colors.redAccent,
                      tooltip: context.l10n.likesLabel,
                      isLoading: isLiking,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _CardIconButton(
                      key: Key('public-devotional-save-${devotional.id}'),
                      onPressed: isSaving ? null : onSave,
                      icon: devotional.saved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      active: devotional.saved,
                      tooltip: context.l10n.saveAction,
                      isLoading: isSaving,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _CardIconButton(
                      key: Key('public-devotional-share-${devotional.id}'),
                      onPressed: onShare,
                      icon: Icons.share_outlined,
                      tooltip: context.l10n.shareAction,
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
    required this.onInsights,
    required this.onOpen,
    this.pendingAction,
    this.onPublish,
    this.onArchive,
  });

  final Devotional devotional;
  final VoidCallback onEdit;
  final VoidCallback onInsights;
  final VoidCallback? onOpen;
  final _OwnerDevotionalAction? pendingAction;
  final VoidCallback? onPublish;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isBusy = pendingAction != null;
    final referenceLabel = _referenceLabel(devotional);

    return _DevotionalSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DevotionalCoverImage(
            imageUrl: devotional.previewImageUrl ?? devotional.coverImageUrl,
            focusY: devotional.coverImageFocusY,
            onTap: onOpen,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.devotionalsMine,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.holyGold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (referenceLabel != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    referenceLabel,
                    style: AppTextStyles.referenceSmall.copyWith(
                      color: AppColors.holyGold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Text(
                  devotional.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headline2.copyWith(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                if (devotional.previewText.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    devotional.previewText,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.softMist.withValues(alpha: 0.84),
                      height: 1.55,
                    ),
                  ),
                ],
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
                    _StatusPill(label: _statusLabel(l10n, devotional.status)),
                    _StatusPill(
                      label: _moderationLabel(l10n, devotional),
                      isWarning: devotional.moderationReason != null,
                    ),
                  ],
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
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _ReadMoreAction(
                      key: Key('owner-devotional-open-${devotional.id}'),
                      onTap: onOpen,
                    ),
                    _OwnerActionButton(
                      label: l10n.editDevotional,
                      onPressed: isBusy ? null : onEdit,
                    ),
                    _OwnerActionButton(
                      label: 'Insights',
                      onPressed: isBusy ? null : onInsights,
                    ),
                    if (onPublish != null)
                      _OwnerActionButton(
                        label:
                            pendingAction == _OwnerDevotionalAction.publishing
                            ? l10n.devotionalPublishingAction
                            : l10n.publish,
                        onPressed: onPublish,
                        filled: true,
                        isLoading:
                            pendingAction == _OwnerDevotionalAction.publishing,
                      ),
                    if (onArchive != null)
                      _OwnerActionButton(
                        label: pendingAction == _OwnerDevotionalAction.archiving
                            ? l10n.devotionalArchivingAction
                            : l10n.devotionalArchiveAction,
                        onPressed: onArchive,
                        isLoading:
                            pendingAction == _OwnerDevotionalAction.archiving,
                      ),
                  ],
                ),
                if (pendingAction != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _ActionFeedbackBanner(action: pendingAction!),
                ],
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

class _ReviewDevotionalCard extends StatelessWidget {
  const _ReviewDevotionalCard({required this.devotional, required this.onOpen});

  final Devotional devotional;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final referenceLabel = _referenceLabel(devotional);

    return _DevotionalSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DevotionalCoverImage(
            imageUrl: devotional.previewImageUrl ?? devotional.coverImageUrl,
            focusY: devotional.coverImageFocusY,
            onTap: onOpen,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AuthorHeader(
                  authorName: devotional.author.name,
                  handle: devotional.author.handle,
                  avatarUrl: devotional.author.avatarUrl,
                  following: false,
                  onTap: onOpen,
                ),
                if (referenceLabel != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    referenceLabel,
                    style: AppTextStyles.referenceSmall.copyWith(
                      color: AppColors.holyGold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Text(
                  devotional.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headline2.copyWith(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                if (devotional.moderationReason != null &&
                    devotional.moderationReason!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    devotional.moderationReason!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.softMist.withValues(alpha: 0.84),
                      height: 1.45,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    const _StatusPill(label: 'En revisión', isWarning: true),
                    _MetaChip(
                      icon: Icons.flag_outlined,
                      label: '${devotional.reportCount} reportes',
                    ),
                    if (devotional.openReportCount > 0)
                      _MetaChip(
                        icon: Icons.mark_email_unread_outlined,
                        label: '${devotional.openReportCount} abiertos',
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _ReadMoreAction(
                  key: Key('review-devotional-open-${devotional.id}'),
                  onTap: onOpen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _OwnerDevotionalAction { publishing, archiving }

class _ActionFeedbackBanner extends StatelessWidget {
  const _ActionFeedbackBanner({required this.action});

  final _OwnerDevotionalAction action;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final message = switch (action) {
      _OwnerDevotionalAction.publishing => l10n.devotionalPublishingFeedback,
      _OwnerDevotionalAction.archiving => l10n.devotionalArchivingFeedback,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.pureWhite.withValues(alpha: 0.06),
        borderRadius: AppBorderRadius.input,
        border: Border.all(color: AppColors.holyGold.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.holyGold),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.softMist,
              ),
            ),
          ),
        ],
      ),
    );
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
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.softMist.withValues(alpha: 0.82),
          ),
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
      side: BorderSide(
        color: selected
            ? Colors.transparent
            : AppColors.pureWhite.withValues(alpha: 0.08),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
      ),
      labelStyle: AppTextStyles.labelSmall.copyWith(
        color: selected ? AppColors.midnightFaith : AppColors.softMist,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _DevotionalSurfaceCard extends StatelessWidget {
  const _DevotionalSurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.midnightFaith.withValues(alpha: 0.92),
        borderRadius: AppBorderRadius.card,
        boxShadow: AppShadows.cardShadow,
        border: Border.all(color: AppColors.pureWhite.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }
}

class _DevotionalCoverImage extends StatelessWidget {
  const _DevotionalCoverImage({
    required this.imageUrl,
    required this.focusY,
    this.onTap,
  });

  final String? imageUrl;
  final double focusY;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveImageUrl = imageUrl;
    final image = effectiveImageUrl != null && effectiveImageUrl.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: effectiveImageUrl,
            fit: BoxFit.cover,
            alignment: Alignment(0, focusY),
            errorWidget: (context, url, error) => _fallback(),
          )
        : _fallback();

    final child = ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppBorderRadius.lg),
      ),
      child: AspectRatio(aspectRatio: 1.28, child: image),
    );

    if (onTap == null) return child;

    return InkWell(onTap: onTap, child: child);
  }

  Widget _fallback() {
    return Container(
      color: AppColors.midnightFaithDark,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.softMist,
      ),
    );
  }
}

class _AuthorHeader extends StatelessWidget {
  const _AuthorHeader({
    required this.authorName,
    required this.handle,
    required this.avatarUrl,
    required this.following,
    this.onTap,
  });

  final String authorName;
  final String? handle;
  final String? avatarUrl;
  final bool following;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.holyGold.withValues(alpha: 0.18),
      backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
          ? CachedNetworkImageProvider(avatarUrl!)
          : null,
      child: avatarUrl == null || avatarUrl!.isEmpty
          ? Text(
              authorName.isNotEmpty ? authorName.characters.first : '?',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.holyGold,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    );

    final content = Row(
      children: [
        avatar,
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                authorName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.pureWhite,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (handle != null && handle!.isNotEmpty)
                Text(
                  '@$handle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.softMist.withValues(alpha: 0.72),
                  ),
                ),
            ],
          ),
        ),
        if (following)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.holyGold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppBorderRadius.full),
              border: Border.all(
                color: AppColors.holyGold.withValues(alpha: 0.18),
              ),
            ),
            child: Text(
              context.l10n.devotionalsFollowingBadge.toUpperCase(),
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.holyGold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );

    if (onTap == null) return content;

    return InkWell(
      borderRadius: BorderRadius.circular(AppBorderRadius.md),
      onTap: onTap,
      child: content,
    );
  }
}

class _ReadMoreAction extends StatelessWidget {
  const _ReadMoreAction({super.key, required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppBorderRadius.full),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          '${context.l10n.devotionalOpenDetail} ->',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.holyGold,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CardIconButton extends StatelessWidget {
  const _CardIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    this.active = false,
    this.isLoading = false,
    this.activeColor = AppColors.holyGold,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String tooltip;
  final bool active;
  final bool isLoading;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = active ? activeColor : AppColors.pureWhite;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        onTap: onPressed,
        child: Ink(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: active
                ? activeColor.withValues(alpha: 0.14)
                : AppColors.pureWhite.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            border: Border.all(
              color: active
                  ? activeColor.withValues(alpha: 0.24)
                  : AppColors.pureWhite.withValues(alpha: 0.08),
            ),
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        foregroundColor,
                      ),
                    ),
                  )
                : Icon(icon, size: 20, color: foregroundColor),
          ),
        ),
      ),
    );
  }
}

class _OwnerActionButton extends StatelessWidget {
  const _OwnerActionButton({
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = filled
        ? AppColors.holyGold
        : AppColors.pureWhite.withValues(alpha: 0.04);
    final textColor = filled ? AppColors.midnightFaithDark : AppColors.holyGold;
    final borderColor = filled
        ? Colors.transparent
        : AppColors.holyGold.withValues(alpha: 0.24);

    return InkWell(
      borderRadius: BorderRadius.circular(AppBorderRadius.full),
      onTap: onPressed,
      child: Ink(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppBorderRadius.full),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading) ...[
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
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
        color: AppColors.pureWhite.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.softMist),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.softMist,
              fontWeight: FontWeight.w600,
            ),
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
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.18)),
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

String? _referenceLabel(Devotional devotional) {
  final primaryReferences = devotional.primaryReferences;
  if (primaryReferences.isNotEmpty) {
    return primaryReferences.first.referenceLabel;
  }
  if (devotional.verseReferences.isNotEmpty) {
    return devotional.verseReferences.first.referenceLabel;
  }
  return null;
}
