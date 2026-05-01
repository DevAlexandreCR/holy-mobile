import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:holyverso/core/errors/app_error_mapper.dart';
import 'package:holyverso/core/errors/devotional_publish_error_resolver.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_design_tokens.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';
import 'package:holyverso/data/devotionals/devotionals_repository.dart';
import 'package:holyverso/domain/devotionals/devotional.dart';
import 'package:holyverso/domain/devotionals/devotional_daily_featured.dart';
import 'package:holyverso/domain/devotionals/devotional_feed_mode.dart';
import 'package:holyverso/domain/devotionals/devotional_feed_header.dart';
import 'package:holyverso/domain/devotionals/devotional_publication_state.dart';
import 'package:holyverso/domain/devotionals/devotional_status.dart';
import 'package:holyverso/domain/devotionals/devotional_verse_reference.dart';
import 'package:holyverso/presentation/screens/devotionals/devotional_editor_screen.dart';
import 'package:holyverso/presentation/screens/devotionals/devotional_feed_reader_args.dart';
import 'package:holyverso/presentation/state/auth/auth_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotionals_feed_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotionals_feed_state.dart';
import 'package:holyverso/presentation/state/devotionals/devotionals_list_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotionals_list_state.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_review_queue_controller.dart';
import 'package:holyverso/presentation/widgets/common/holy_child_app_bar.dart';
import 'package:holyverso/presentation/widgets/devotionals/devotional_feed_context_copy.dart';
import 'package:holyverso/presentation/widgets/devotionals/devotional_reference_preview.dart';
import 'package:holyverso/presentation/widgets/notifications/notification_inbox_bell_button.dart';
import 'package:share_plus/share_plus.dart';
import 'package:visibility_detector/visibility_detector.dart';

class DevotionalsListScreen extends ConsumerStatefulWidget {
  const DevotionalsListScreen({
    super.key,
    this.initialTab = DevotionalsTopTab.forYou,
  });

  final DevotionalsTopTab initialTab;

  @override
  ConsumerState<DevotionalsListScreen> createState() =>
      _DevotionalsListScreenState();
}

enum DevotionalsTopTab {
  forYou('for_you'),
  following('following'),
  mine('mine'),
  review('review');

  const DevotionalsTopTab(this.queryValue);

  final String queryValue;

  static DevotionalsTopTab fromQueryValue(String? value) {
    return switch (value) {
      'following' => DevotionalsTopTab.following,
      'mine' => DevotionalsTopTab.mine,
      'review' => DevotionalsTopTab.review,
      _ => DevotionalsTopTab.forYou,
    };
  }
}

const double _publicFeedMediaSectionHeight = 164;
const double _publicFeedMediaOverlayTop = 4;
const double _publicFeedMediaOverlayTopWithBadge = 46;

String _formatStreakLabel(int currentStreak) {
  final daysLabel = currentStreak == 1 ? 'día' : 'días';
  return 'Racha: $currentStreak $daysLabel';
}

class _DevotionalsListScreenState extends ConsumerState<DevotionalsListScreen> {
  late DevotionalsTopTab _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  @override
  void didUpdateWidget(covariant DevotionalsListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _selectedTab = widget.initialTab;
    }
  }

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
    final tabs = <(DevotionalsTopTab, _TopLevelTabData)>[
      (
        DevotionalsTopTab.forYou,
        _TopLevelTabData(
          key: const Key('devotionals-tab-for-you'),
          label: l10n.devotionalsForYou,
        ),
      ),
      (
        DevotionalsTopTab.following,
        _TopLevelTabData(
          key: const Key('devotionals-tab-following'),
          label: l10n.devotionalsFollowing,
        ),
      ),
      (
        DevotionalsTopTab.mine,
        _TopLevelTabData(
          key: const Key('devotionals-tab-mine'),
          label: l10n.devotionalsMine,
        ),
      ),
      if (canModerate)
        (
          DevotionalsTopTab.review,
          const _TopLevelTabData(
            key: Key('devotionals-tab-review'),
            label: 'En revisión',
          ),
        ),
    ];
    final selectedTab = tabs.any((entry) => entry.$1 == _selectedTab)
        ? _selectedTab
        : tabs.first.$1;
    final selectedIndex = tabs.indexWhere((entry) => entry.$1 == selectedTab);

    return Scaffold(
      backgroundColor: AppColors.midnightFaithDark,
      appBar: HolyChildAppBar(
        title: l10n.navDevotionalsLabel,
        showBackButton: false,
        actions: const [NotificationInboxBellButton()],
        bottom: _DevotionalsTopTabsBar(
          selectedIndex: selectedIndex,
          onSelected: (index) {
            final nextTab = tabs[index].$1;
            if (selectedTab == nextTab) return;
            setState(() {
              _selectedTab = nextTab;
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
            index: selectedIndex,
            children: tabs.map((entry) {
              switch (entry.$1) {
                case DevotionalsTopTab.forYou:
                  return _PublicFeedModeView(
                    mode: DevotionalFeedMode.forYou,
                    provider: forYouFeedControllerProvider,
                  );
                case DevotionalsTopTab.following:
                  return _PublicFeedModeView(
                    mode: DevotionalFeedMode.following,
                    provider: followingFeedControllerProvider,
                  );
                case DevotionalsTopTab.mine:
                  return _MyDevotionalsTab(onOpenEditor: _openEditor);
                case DevotionalsTopTab.review:
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
  ProviderSubscription<bool?>? _completedHeaderListener;
  bool _completedBadgeDismissed = false;
  bool? _previousHeaderCompletedToday;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(widget.provider.notifier).loadInitial();
    });
    _bindCompletedHeaderListener();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant _PublicFeedModeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.provider != widget.provider) {
      _completedHeaderListener?.close();
      _previousHeaderCompletedToday = null;
      _bindCompletedHeaderListener();
    }
  }

  @override
  void dispose() {
    _completedHeaderListener?.close();
    _scrollController.dispose();
    super.dispose();
  }

  void _bindCompletedHeaderListener() {
    _completedHeaderListener = ref.listenManual<bool?>(
      widget.provider.select((state) => state.feedHeader?.completedToday),
      (_, next) {
        final wasCompleted = _previousHeaderCompletedToday == true;
        final isCompleted = next == true;
        if (!wasCompleted &&
            isCompleted &&
            _completedBadgeDismissed &&
            mounted) {
          setState(() {
            _completedBadgeDismissed = false;
          });
        }
        _previousHeaderCompletedToday = next;
      },
      fireImmediately: true,
    );
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
      devotional.primaryHook,
      if (devotional.feedPreview.isNotEmpty) devotional.feedPreview,
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

  Future<void> _toggleSave(Devotional devotional) async {
    final willSave = !devotional.saved;
    final success = await ref
        .read(widget.provider.notifier)
        .toggleSave(devotional.id);

    if (!mounted || !success || !willSave) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(context.l10n.devotionalFeedSavedToast),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _heroTagFor(Devotional devotional) {
    return 'public-feed-${widget.mode.name}-${devotional.id}';
  }

  Future<void> _openDetail(Devotional devotional, {String? heroTag}) async {
    await ref.read(widget.provider.notifier).registerOpen(devotional);
    if (!mounted) return;
    final query = devotional.deliveryToken != null
        ? '?delivery_token=${Uri.encodeComponent(devotional.deliveryToken!)}'
        : '';
    final updated = await context.push<Devotional>(
      '/devotionals/${devotional.id}$query',
      extra: DevotionalFeedReaderArgs(
        feedMode: widget.mode,
        initialDevotionalId: devotional.id,
        initialDeliveryToken: devotional.deliveryToken,
        heroTag: heroTag,
      ),
    );
    if (mounted && widget.mode == DevotionalFeedMode.forYou) {
      await ref.read(widget.provider.notifier).refreshHeader();
    }
    if (updated != null && mounted) {
      ref.read(widget.provider.notifier).syncUpdatedDevotional(updated);
    }
  }

  Future<void> _handleHeaderCta(
    DevotionalFeedHeader header,
    List<Devotional> items,
  ) async {
    final devotionalId =
        header.primaryCtaDevotionalId ?? header.dailyFeatured?.id;

    if (header.primaryCtaType == 'BROWSE_FEED' && devotionalId == null) {
      if (items.isEmpty) {
        await ref.read(widget.provider.notifier).refresh();
      }
      return;
    }

    if (devotionalId != null && devotionalId.isNotEmpty) {
      final matchedDevotional = items.where((item) => item.id == devotionalId);
      if (matchedDevotional.isNotEmpty) {
        await _openDetail(matchedDevotional.first);
        return;
      }

      final updated = await context.push<Devotional>(
        '/devotionals/$devotionalId',
      );
      if (updated != null && mounted) {
        ref.read(widget.provider.notifier).syncUpdatedDevotional(updated);
      }
      if (mounted) {
        await ref.read(widget.provider.notifier).refreshHeader();
      }
      return;
    }

    if (items.isNotEmpty) {
      await _openDetail(items.first);
      return;
    }

    await ref.read(widget.provider.notifier).refresh();
  }

  Future<void> _openAuthor(Devotional devotional) async {
    if (!mounted) return;
    await context.push('/users/${devotional.author.id}');
  }

  Future<void> _openReferencePreview(DevotionalVerseReference reference) {
    return showDevotionalReferencePreview(context, reference: reference);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(widget.provider);
    final l10n = context.l10n;
    final header = widget.mode == DevotionalFeedMode.forYou
        ? state.feedHeader
        : null;
    final showsInlineHeader = header != null && !header.completedToday;
    final completedHeader = header != null && header.completedToday;

    if (state.status == DevotionalsFeedStatus.loading &&
        state.items.isEmpty &&
        header == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.holyGold),
      );
    }

    if (state.status == DevotionalsFeedStatus.error &&
        state.items.isEmpty &&
        header == null) {
      return _ErrorState(
        message: state.errorMessage ?? l10n.genericError,
        onRetry: () =>
            ref.read(widget.provider.notifier).loadInitial(forceRefresh: true),
      );
    }

    if (state.items.isEmpty) {
      final emptyContent = switch (state.status) {
        DevotionalsFeedStatus.loading => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.holyGold),
          ),
        ),
        DevotionalsFeedStatus.error => _ErrorState(
          message: state.errorMessage ?? l10n.genericError,
          onRetry: () => ref
              .read(widget.provider.notifier)
              .loadInitial(forceRefresh: true),
        ),
        _ => _EmptyState(
          title: widget.mode == DevotionalFeedMode.following
              ? l10n.devotionalsFollowingEmptyTitle
              : l10n.devotionalsFeedEmptyTitle,
          subtitle: widget.mode == DevotionalFeedMode.following
              ? l10n.devotionalsFollowingEmptySubtitle
              : l10n.devotionalsFeedEmptySubtitle,
        ),
      };

      return RefreshIndicator(
        onRefresh: () => ref.read(widget.provider.notifier).refresh(),
        child: Stack(
          children: [
            ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                12,
                AppSpacing.sm,
                12,
                AppSpacing.xxl,
              ),
              children: [
                if (showsInlineHeader) ...[
                  _FeedRitualHeader(
                    header: header,
                    onPrimaryCta: () => _handleHeaderCta(header, state.items),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                emptyContent,
              ],
            ),
            if (completedHeader)
              PositionedDirectional(
                top: AppSpacing.sm,
                end: 12,
                child: _CompletedStreakBadge(
                  key: const Key('completed-streak-badge'),
                  header: header,
                  visible: !_completedBadgeDismissed,
                  onDismiss: () {
                    setState(() {
                      _completedBadgeDismissed = true;
                    });
                  },
                ),
              ),
          ],
        ),
      );
    }

    final showErrorBanner =
        state.errorMessage != null && state.items.isNotEmpty;
    final leadingItemsCount =
        (showsInlineHeader ? 1 : 0) + (showErrorBanner ? 1 : 0);

    return RefreshIndicator(
      onRefresh: () => ref.read(widget.provider.notifier).refresh(),
      child: Stack(
        children: [
          ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              12,
              AppSpacing.sm,
              12,
              AppSpacing.xxl,
            ),
            itemCount:
                (showsInlineHeader ? 1 : 0) +
                state.items.length +
                (state.isFetchingMore ? 1 : 0) +
                (showErrorBanner ? 1 : 0),
            itemBuilder: (context, index) {
              if (showsInlineHeader && index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _FeedRitualHeader(
                    header: header,
                    onPrimaryCta: () => _handleHeaderCta(header, state.items),
                  ),
                );
              }

              if (showErrorBanner && index == (showsInlineHeader ? 1 : 0)) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _ErrorBanner(message: state.errorMessage!),
                );
              }

              final listIndex = index - leadingItemsCount;
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
                child: _FeedCardEntrance(
                  index: listIndex,
                  child: _PublicDevotionalCard(
                    devotional: devotional,
                    isSaving: state.savingDevotionalId == devotional.id,
                    heroTag: _heroTagFor(devotional),
                    onOpen: () => _openDetail(
                      devotional,
                      heroTag: _heroTagFor(devotional),
                    ),
                    onOpenAuthor: () => _openAuthor(devotional),
                    onOpenReference: _openReferencePreview,
                    onSave: () => _toggleSave(devotional),
                    onShare: () => _share(devotional),
                  ),
                ),
              );
            },
          ),
          if (completedHeader)
            PositionedDirectional(
              top: AppSpacing.sm,
              end: 12,
              child: _CompletedStreakBadge(
                key: const Key('completed-streak-badge'),
                header: header,
                visible: !_completedBadgeDismissed,
                onDismiss: () {
                  setState(() {
                    _completedBadgeDismissed = true;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _FeedRitualHeader extends StatelessWidget {
  const _FeedRitualHeader({required this.header, required this.onPrimaryCta});

  final DevotionalFeedHeader header;
  final VoidCallback onPrimaryCta;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final statusLabel = header.completedToday
        ? l10n.devotionalFeedCompletedToday
        : l10n.devotionalFeedPendingToday;
    final statusIcon = header.completedToday
        ? Icons.check_circle_rounded
        : Icons.schedule_rounded;
    final statusColor = header.completedToday
        ? AppColors.holyGold
        : AppColors.morningLight;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppBorderRadius.card,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.midnightFaithDark.withValues(alpha: 0.96),
            const Color(0xFF243553),
            const Color(0xFF304868),
          ],
        ),
        border: Border.all(color: AppColors.holyGold.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.holyGold.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: AppColors.holyGold,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.devotionalFeedRitualTitle,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.softMist.withValues(alpha: 0.82),
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _formatStreakLabel(header.currentStreak),
                        style: AppTextStyles.headline3.copyWith(
                          color: AppColors.pureWhite,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppBorderRadius.full),
                border: Border.all(color: statusColor.withValues(alpha: 0.24)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 16, color: statusColor),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    statusLabel,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              header.completedToday
                  ? l10n.devotionalFeedCompletedMessage
                  : l10n.devotionalFeedPendingMessage,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.softMist.withValues(alpha: 0.9),
                height: 1.45,
              ),
            ),
            if (header.dailyFeatured != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _DailyFeaturedDevotionalCard(
                devotional: header.dailyFeatured!,
                ctaLabel: header.primaryCtaLabel,
                onPrimaryCta: onPrimaryCta,
                completedToday: header.completedToday,
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onPrimaryCta,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: header.completedToday
                        ? AppColors.pureWhite.withValues(alpha: 0.1)
                        : AppColors.holyGold,
                    foregroundColor: header.completedToday
                        ? AppColors.pureWhite
                        : AppColors.midnightFaithDark,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppBorderRadius.button,
                      side: header.completedToday
                          ? BorderSide(
                              color: AppColors.pureWhite.withValues(
                                alpha: 0.18,
                              ),
                            )
                          : BorderSide.none,
                    ),
                  ),
                  child: Text(
                    header.primaryCtaLabel,
                    style: AppTextStyles.button.copyWith(
                      color: header.completedToday
                          ? AppColors.pureWhite
                          : AppColors.midnightFaithDark,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompletedStreakBadge extends StatefulWidget {
  const _CompletedStreakBadge({
    super.key,
    required this.header,
    required this.visible,
    required this.onDismiss,
  });

  final DevotionalFeedHeader header;
  final bool visible;
  final VoidCallback onDismiss;

  @override
  State<_CompletedStreakBadge> createState() => _CompletedStreakBadgeState();
}

class _CompletedStreakBadgeState extends State<_CompletedStreakBadge> {
  bool _entered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _entered = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final badgeLabel =
        '${l10n.devotionalFeedCompletedToday}. ${_formatStreakLabel(widget.header.currentStreak)}.';
    final isVisible = widget.visible && _entered;
    final dismissLabel = l10n.devotionalFeedHideCompletedBadge;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: IgnorePointer(
        ignoring: !widget.visible,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          scale: isVisible ? 1 : 0.96,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            opacity: isVisible ? 1 : 0,
            child: Semantics(
              container: true,
              explicitChildNodes: true,
              label: badgeLabel,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppBorderRadius.full),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF243553).withValues(alpha: 0.96),
                      const Color(0xFF304868).withValues(alpha: 0.94),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.holyGold.withValues(alpha: 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.sm,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        fit: FlexFit.loose,
                        child: ExcludeSemantics(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.holyGold.withValues(
                                    alpha: 0.14,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppBorderRadius.full,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.local_fire_department_rounded,
                                  color: AppColors.holyGold,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatStreakLabel(
                                        widget.header.currentStreak,
                                      ),
                                      style: AppTextStyles.labelLarge.copyWith(
                                        color: AppColors.pureWhite,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      l10n.devotionalFeedCompletedToday,
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.softMist.withValues(
                                          alpha: 0.84,
                                        ),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Tooltip(
                        message: dismissLabel,
                        child: Semantics(
                          button: true,
                          label: dismissLabel,
                          onTap: widget.onDismiss,
                          child: ExcludeSemantics(
                            child: InkResponse(
                              key: const Key('completed-streak-badge-close'),
                              radius: 18,
                              onTap: widget.onDismiss,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.pureWhite.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppBorderRadius.full,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: AppColors.softMist,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyFeaturedDevotionalCard extends StatelessWidget {
  const _DailyFeaturedDevotionalCard({
    required this.devotional,
    required this.ctaLabel,
    required this.onPrimaryCta,
    required this.completedToday,
  });

  final DevotionalDailyFeatured devotional;
  final String ctaLabel;
  final VoidCallback onPrimaryCta;
  final bool completedToday;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasImage =
        devotional.previewImageUrl != null &&
        devotional.previewImageUrl!.trim().isNotEmpty;

    return Container(
      key: Key('daily-featured-card-${devotional.id}'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.pureWhite.withValues(alpha: 0.08),
        borderRadius: AppBorderRadius.card,
        border: Border.all(color: AppColors.pureWhite.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.devotionalFeedDailyFeaturedLabel,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.holyGold,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (hasImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  key: Key('daily-featured-image-${devotional.id}'),
                  imageUrl: devotional.previewImageUrl!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(
            devotional.title,
            style: AppTextStyles.headline3.copyWith(
              color: AppColors.pureWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 16,
                color: AppColors.holyGold,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${devotional.estimatedReadTime} ${l10n.devotionalMinutesShort}',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.softMist.withValues(alpha: 0.88),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.devotionalFeedReadTimeLabel,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.softMist.withValues(alpha: 0.66),
                ),
              ),
            ],
          ),
          if (devotional.previewText.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              devotional.previewText.trim(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.softMist.withValues(alpha: 0.92),
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPrimaryCta,
              style: ElevatedButton.styleFrom(
                backgroundColor: completedToday
                    ? AppColors.pureWhite.withValues(alpha: 0.1)
                    : AppColors.holyGold,
                foregroundColor: completedToday
                    ? AppColors.pureWhite
                    : AppColors.midnightFaithDark,
                elevation: 0,
                minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: AppBorderRadius.button,
                  side: completedToday
                      ? BorderSide(
                          color: AppColors.pureWhite.withValues(alpha: 0.18),
                        )
                      : BorderSide.none,
                ),
              ),
              child: Text(
                ctaLabel,
                style: AppTextStyles.button.copyWith(
                  color: completedToday
                      ? AppColors.pureWhite
                      : AppColors.midnightFaithDark,
                ),
              ),
            ),
          ),
        ],
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
            _resolveOwnerActionErrorMessage(
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
        'USER_BLOCKED_DEVOTIONAL_PUBLISH':
            'Tu cuenta está bloqueada y no puede publicar devocionales.',
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

  Future<void> _openReferencePreview(DevotionalVerseReference reference) {
    return showDevotionalReferencePreview(context, reference: reference);
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
                            onOpenReference: _openReferencePreview,
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

  Future<void> _openReferencePreview(DevotionalVerseReference reference) {
    return showDevotionalReferencePreview(context, reference: reference);
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
                      onOpenReference: _openReferencePreview,
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
    required this.isSaving,
    required this.heroTag,
    required this.onOpen,
    required this.onOpenAuthor,
    required this.onOpenReference,
    required this.onSave,
    required this.onShare,
  });

  final Devotional devotional;
  final bool isSaving;
  final String heroTag;
  final VoidCallback onOpen;
  final VoidCallback onOpenAuthor;
  final ValueChanged<DevotionalVerseReference> onOpenReference;
  final VoidCallback onSave;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final previewReferences = devotionalPreviewReferences(devotional);
    final secondaryTitleVisible = _shouldShowSecondaryTitle(devotional);
    final previewText = devotional.feedPreview;
    final hasImage =
        (devotional.previewImageUrl ?? devotional.coverImageUrl)?.isNotEmpty ==
        true;
    final feedInterpretation =
        devotionalFeedInterpretationLabel(
          context.l10n,
          devotional.feedContextReason,
        ) ??
        context.l10n.devotionalFeedOpenCta;
    final stateMarker = _feedStateMarkerLabel(context, devotional);
    final inlineStateMarker = hasImage ? null : stateMarker;
    final showEngagementStats =
        devotional.likesCount > 0 ||
        devotional.commentsCount > 0 ||
        devotional.viewCount > 0;
    final saveButton = _FeedActionIconButton(
      key: Key('public-devotional-save-${devotional.id}'),
      label: devotional.saved
          ? context.l10n.savedAction
          : context.l10n.saveAction,
      icon: devotional.saved
          ? Icons.bookmark_rounded
          : Icons.bookmark_border_rounded,
      color: devotional.saved
          ? AppColors.holyGold
          : AppColors.pureWhite.withValues(alpha: 0.9),
      isSaved: devotional.saved,
      isLoading: isSaving,
      onPressed: isSaving ? null : onSave,
    );
    final shareButton = _FeedActionIconButton(
      key: Key('public-devotional-share-${devotional.id}'),
      label: context.l10n.shareAction,
      onPressed: onShare,
      icon: Icons.share_outlined,
      color: AppColors.pureWhite.withValues(alpha: 0.9),
    );
    final inlineStats = _PublicFeedStats(
      likesCount: devotional.likesCount,
      commentsCount: devotional.commentsCount,
      viewsCount: devotional.viewCount,
    );
    final overlayStats = _PublicFeedStats(
      key: Key('public-devotional-overlay-stats-${devotional.id}'),
      likesCount: devotional.likesCount,
      commentsCount: devotional.commentsCount,
      viewsCount: devotional.viewCount,
      singleLine: true,
    );

    return Hero(
      tag: heroTag,
      child: Material(
        color: Colors.transparent,
        child: _DevotionalSurfaceCard(
          featured:
              devotional.publicationState ==
              DevotionalPublicationState.featured,
          child: _FeedOpenSurface(
            onTap: onOpen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                    hasImage ? 0 : AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        devotional.primaryHook,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.headline2.copyWith(
                          color: AppColors.pureWhite,
                          fontWeight: FontWeight.w700,
                          height: 1.22,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _PublicAuthorContext(
                        authorName: devotional.author.name,
                        handle: devotional.author.handle,
                        avatarUrl: devotional.author.avatarUrl,
                        following: devotional.author.following,
                        referenceLinks: previewReferences.isEmpty
                            ? null
                            : DevotionalReferenceLinks(
                                references: previewReferences,
                                onTap: onOpenReference,
                                compact: true,
                              ),
                        onTap: onOpenAuthor,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (secondaryTitleVisible) ...[
                        Text(
                          devotional.title.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.pureWhite.withValues(alpha: 0.72),
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      if (previewText.isNotEmpty) ...[
                        Text(
                          previewText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.softMist.withValues(alpha: 0.82),
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _PublicFeedInterpretation(label: feedInterpretation),
                          if (inlineStateMarker != null)
                            _PublicFeedStateMarker(
                              label: inlineStateMarker.label,
                              highlighted: inlineStateMarker.highlighted,
                              icon: inlineStateMarker.icon,
                            ),
                        ],
                      ),
                      if (!hasImage) ...[
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            if (showEngagementStats)
                              Expanded(child: inlineStats)
                            else
                              const Spacer(),
                            saveButton,
                            const SizedBox(width: AppSpacing.sm),
                            shareButton,
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (hasImage) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _FeedImageStrip(
                    key: Key('public-devotional-image-${devotional.id}'),
                    imageUrl:
                        devotional.previewImageUrl ?? devotional.coverImageUrl,
                    focusY: devotional.coverImageFocusY,
                    stateMarker: stateMarker,
                    overlayBar: Row(
                      key: Key(
                        'public-devotional-overlay-bar-${devotional.id}',
                      ),
                      children: [
                        if (showEngagementStats)
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: overlayStats,
                            ),
                          )
                        else
                          const Spacer(),
                        const SizedBox(width: AppSpacing.md),
                        Row(
                          key: Key(
                            'public-devotional-overlay-actions-${devotional.id}',
                          ),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            saveButton,
                            const SizedBox(width: AppSpacing.sm),
                            shareButton,
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedStateMarkerData {
  const _FeedStateMarkerData({
    required this.label,
    required this.highlighted,
    required this.icon,
  });

  final String label;
  final bool highlighted;
  final IconData icon;
}

class _PublicFeedInterpretation extends StatelessWidget {
  const _PublicFeedInterpretation({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label ->',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.labelSmall.copyWith(
        color: AppColors.holyGold.withValues(alpha: 0.82),
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _PublicFeedStateMarker extends StatelessWidget {
  const _PublicFeedStateMarker({
    required this.label,
    required this.highlighted,
    required this.icon,
  });

  final String label;
  final bool highlighted;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final accent = highlighted ? AppColors.holyGold : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: accent.withValues(alpha: 0.82)),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: accent.withValues(alpha: 0.82),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageFeedStateBadge extends StatelessWidget {
  const _ImageFeedStateBadge({
    required this.label,
    required this.highlighted,
    required this.icon,
  });

  final String label;
  final bool highlighted;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final accent = highlighted ? AppColors.holyGold : AppColors.warning;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.midnightFaithDark.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowDark.withValues(alpha: 0.18),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: accent.withValues(alpha: 0.92)),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: accent.withValues(alpha: 0.94),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublicFeedStats extends StatelessWidget {
  const _PublicFeedStats({
    super.key,
    required this.likesCount,
    required this.commentsCount,
    required this.viewsCount,
    this.singleLine = false,
  });

  final int likesCount;
  final int commentsCount;
  final int viewsCount;
  final bool singleLine;

  @override
  Widget build(BuildContext context) {
    final stats = <Widget>[
      if (likesCount > 0)
        _PublicFeedStat(
          key: const Key('public-devotional-likes'),
          icon: Icons.favorite_border,
          value: likesCount,
          semanticsLabel: context.l10n.likesLabel,
        ),
      if (commentsCount > 0)
        _PublicFeedStat(
          key: const Key('public-devotional-comments'),
          icon: Icons.chat_bubble_outline,
          value: commentsCount,
          semanticsLabel: context.l10n.commentsLabel,
        ),
      if (viewsCount > 0)
        _PublicFeedStat(
          key: const Key('public-devotional-views'),
          icon: Icons.remove_red_eye_outlined,
          value: viewsCount,
          semanticsLabel: context.l10n.viewsLabel,
        ),
    ];

    if (stats.isEmpty) {
      return const SizedBox.shrink();
    }

    if (singleLine) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            stats[i],
          ],
        ],
      );
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: stats,
    );
  }
}

class _PublicFeedStat extends StatelessWidget {
  const _PublicFeedStat({
    super.key,
    required this.icon,
    required this.value,
    required this.semanticsLabel,
  });

  final IconData icon;
  final int value;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      value: value.toString(),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: AppColors.softMist.withValues(alpha: 0.64),
            ),
            const SizedBox(width: 4),
            Text(
              value.toString(),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.softMist.withValues(alpha: 0.66),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
    required this.onOpenReference,
    this.pendingAction,
    this.onPublish,
    this.onArchive,
  });

  final Devotional devotional;
  final VoidCallback onEdit;
  final VoidCallback onInsights;
  final VoidCallback? onOpen;
  final ValueChanged<DevotionalVerseReference> onOpenReference;
  final _OwnerDevotionalAction? pendingAction;
  final VoidCallback? onPublish;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isBusy = pendingAction != null;
    final previewReferences = devotionalPreviewReferences(devotional);

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
                if (previewReferences.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  DevotionalReferenceLinks(
                    references: previewReferences,
                    onTap: onOpenReference,
                    compact: true,
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
  const _ReviewDevotionalCard({
    required this.devotional,
    required this.onOpenReference,
    required this.onOpen,
  });

  final Devotional devotional;
  final ValueChanged<DevotionalVerseReference> onOpenReference;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final previewReferences = devotionalPreviewReferences(devotional);

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
                if (previewReferences.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  DevotionalReferenceLinks(
                    references: previewReferences,
                    onTap: onOpenReference,
                    compact: true,
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
                    if (devotional.authorBlockRecommendation?.authorIsBlocked ==
                        true)
                      const _StatusPill(
                        label: 'Autor bloqueado',
                        isWarning: true,
                      )
                    else if (devotional
                            .authorBlockRecommendation
                            ?.shouldSuggestBlocking ==
                        true)
                      const _StatusPill(
                        label: 'Sugerir bloqueo',
                        isWarning: true,
                      ),
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

    return Wrap(
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

class _FeedCardEntrance extends StatefulWidget {
  const _FeedCardEntrance({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_FeedCardEntrance> createState() => _FeedCardEntranceState();
}

class _FeedCardEntranceState extends State<_FeedCardEntrance> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    final delayMs = ((widget.index * 32).clamp(0, 180) as num).toInt();
    Future<void>.delayed(Duration(milliseconds: delayMs), () {
      if (!mounted) return;
      setState(() {
        _visible = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      offset: _visible ? Offset.zero : const Offset(0, 0.03),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        scale: _visible ? 1 : 0.98,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          opacity: _visible ? 1 : 0,
          child: widget.child,
        ),
      ),
    );
  }
}

class _DevotionalSurfaceCard extends StatelessWidget {
  const _DevotionalSurfaceCard({required this.child, this.featured = false});

  final Widget child;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.midnightFaith.withValues(alpha: 0.92),
        borderRadius: AppBorderRadius.card,
        boxShadow: [
          ...AppShadows.cardShadow,
          if (featured)
            BoxShadow(
              color: AppColors.holyGold.withValues(alpha: 0.12),
              blurRadius: 24,
              spreadRadius: 0,
            ),
        ],
        border: Border.all(
          color: featured
              ? AppColors.holyGold.withValues(alpha: 0.24)
              : AppColors.pureWhite.withValues(alpha: 0.08),
        ),
      ),
      child: child,
    );
  }
}

class _FeedOpenSurface extends StatefulWidget {
  const _FeedOpenSurface({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_FeedOpenSurface> createState() => _FeedOpenSurfaceState();
}

class _FeedOpenSurfaceState extends State<_FeedOpenSurface> {
  bool _pressed = false;
  bool _opening = false;

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() {
      _pressed = value;
    });
  }

  Future<void> _handleTap() async {
    if (_opening) return;
    _opening = true;
    _setPressed(true);
    await Future<void>.delayed(const Duration(milliseconds: 70));
    if (mounted) {
      widget.onTap();
    }
    _setPressed(false);
    _opening = false;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      scale: _pressed ? 0.98 : 1,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        opacity: _pressed ? 0.94 : 1,
        child: Material(
          color: Colors.transparent,
          borderRadius: AppBorderRadius.card,
          child: InkWell(
            borderRadius: AppBorderRadius.card,
            splashColor: AppColors.holyGold.withValues(alpha: 0.06),
            highlightColor: Colors.transparent,
            onTapDown: (_) => _setPressed(true),
            onTapCancel: () => _setPressed(false),
            onTapUp: (_) => _setPressed(false),
            onTap: _handleTap,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _FeedImageStrip extends StatelessWidget {
  const _FeedImageStrip({
    super.key,
    required this.imageUrl,
    required this.focusY,
    this.stateMarker,
    this.overlayBar,
  });

  final String? imageUrl;
  final double focusY;
  final _FeedStateMarkerData? stateMarker;
  final Widget? overlayBar;

  @override
  Widget build(BuildContext context) {
    final effectiveUrl = imageUrl;
    if (effectiveUrl == null || effectiveUrl.isEmpty) {
      return const SizedBox.shrink();
    }
    final overlayTop = stateMarker == null
        ? _publicFeedMediaOverlayTop
        : _publicFeedMediaOverlayTopWithBadge;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AppBorderRadius.lg),
      ),
      child: SizedBox(
        height: _publicFeedMediaSectionHeight,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: effectiveUrl,
              fit: BoxFit.cover,
              alignment: Alignment(0, focusY),
              errorWidget: (context, url, error) => Container(
                color: AppColors.midnightFaithDark,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.softMist,
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.18, 0.42, 0.72, 1],
                  colors: [
                    AppColors.midnightFaith.withValues(alpha: 0.95),
                    AppColors.midnightFaith.withValues(alpha: 0.82),
                    AppColors.midnightFaithDark.withValues(alpha: 0.58),
                    AppColors.midnightFaithDark.withValues(alpha: 0.2),
                    AppColors.midnightFaithDark.withValues(alpha: 0.06),
                  ],
                ),
              ),
            ),
            if (overlayBar != null)
              Positioned(
                top: overlayTop,
                left: 12,
                right: 12,
                child: overlayBar!,
              ),
            if (stateMarker != null)
              Positioned(
                top: 12,
                left: 12,
                child: _ImageFeedStateBadge(
                  label: stateMarker!.label,
                  highlighted: stateMarker!.highlighted,
                  icon: stateMarker!.icon,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FeedActionIconButton extends StatelessWidget {
  const _FeedActionIconButton({
    super.key,
    required this.onPressed,
    required this.label,
    required this.icon,
    required this.color,
    this.isSaved = false,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color color;
  final bool isSaved;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      selected: isSaved,
      child: Tooltip(
        message: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(AppBorderRadius.full),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: ExcludeSemantics(
                child: isLoading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      )
                    : Icon(icon, color: color, size: 24),
              ),
            ),
          ),
        ),
      ),
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

class _PublicAuthorContext extends StatelessWidget {
  const _PublicAuthorContext({
    required this.authorName,
    required this.handle,
    required this.avatarUrl,
    required this.following,
    this.referenceLinks,
    this.onTap,
  });

  final String authorName;
  final String? handle;
  final String? avatarUrl;
  final bool following;
  final Widget? referenceLinks;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: 15,
      backgroundColor: AppColors.holyGold.withValues(alpha: 0.14),
      backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
          ? CachedNetworkImageProvider(avatarUrl!)
          : null,
      child: avatarUrl == null || avatarUrl!.isEmpty
          ? Text(
              authorName.isNotEmpty ? authorName.characters.first : '?',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.holyGold,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    );

    final authorLine = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: authorName,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.pureWhite.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          if (handle != null && handle!.isNotEmpty)
            TextSpan(
              text: ' · @$handle',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.softMist.withValues(alpha: 0.72),
                fontWeight: FontWeight.w500,
              ),
            ),
          if (following)
            TextSpan(
              text: ' · ${context.l10n.devotionalFeedFollowingInline}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.softMist.withValues(alpha: 0.72),
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        avatar,
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              authorLine,
              if (referenceLinks != null) ...[
                const SizedBox(height: 4),
                referenceLinks!,
              ],
            ],
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

_FeedStateMarkerData? _feedStateMarkerLabel(
  BuildContext context,
  Devotional devotional,
) {
  if (devotional.publicationState == DevotionalPublicationState.trending) {
    return _FeedStateMarkerData(
      label: context.l10n.devotionalFeedBadgeTrending,
      highlighted: false,
      icon: Icons.local_fire_department_rounded,
    );
  }

  if (devotional.publicationState == DevotionalPublicationState.featured ||
      devotional.feedContextReason == 'FEATURED') {
    return _FeedStateMarkerData(
      label: context.l10n.devotionalFeedBadgeRecommended,
      highlighted: true,
      icon: Icons.star_rounded,
    );
  }

  return null;
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

bool _shouldShowSecondaryTitle(Devotional devotional) {
  final title = devotional.title.trim();
  if (title.isEmpty) return false;
  return !_textsNearDuplicate(title, devotional.primaryHook);
}

bool _textsNearDuplicate(String left, String right) {
  final normalizedLeft = _normalizeForComparison(left);
  final normalizedRight = _normalizeForComparison(right);

  if (normalizedLeft.isEmpty || normalizedRight.isEmpty) {
    return false;
  }

  if (normalizedLeft == normalizedRight ||
      normalizedLeft.contains(normalizedRight) ||
      normalizedRight.contains(normalizedLeft)) {
    return true;
  }

  final leftTokens = normalizedLeft
      .split(' ')
      .where((token) => token.isNotEmpty);
  final rightTokens = normalizedRight
      .split(' ')
      .where((token) => token.isNotEmpty)
      .toSet();

  if (rightTokens.isEmpty) return false;

  var overlap = 0;
  var leftCount = 0;
  for (final token in leftTokens) {
    leftCount += 1;
    if (rightTokens.contains(token)) {
      overlap += 1;
    }
  }

  if (leftCount == 0) return false;
  return overlap /
          (leftCount > rightTokens.length ? leftCount : rightTokens.length) >=
      0.8;
}

String _normalizeForComparison(String value) {
  const accents = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'Á': 'a',
    'É': 'e',
    'Í': 'i',
    'Ó': 'o',
    'Ú': 'u',
    'ñ': 'n',
    'Ñ': 'n',
  };

  final buffer = StringBuffer();
  for (final char in value.characters) {
    buffer.write(accents[char] ?? char.toLowerCase());
  }

  return buffer
      .toString()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _resolveOwnerActionErrorMessage(
  Object error, {
  required AppLocalizations l10n,
  required String fallbackMessage,
  required Map<String, String> businessCodeMessages,
}) {
  return resolveDevotionalPublishErrorMessage(
    error,
    l10n: l10n,
    fallbackMessage: fallbackMessage,
    businessCodeMessages: businessCodeMessages,
  );
}
