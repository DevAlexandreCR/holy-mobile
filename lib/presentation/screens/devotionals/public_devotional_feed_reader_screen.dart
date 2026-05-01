import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/core/services/app_runtime_storage.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_design_tokens.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';
import 'package:holyverso/data/devotionals/devotionals_repository.dart';
import 'package:holyverso/domain/devotionals/devotional.dart';
import 'package:holyverso/domain/devotionals/devotional_comment.dart';
import 'package:holyverso/domain/devotionals/devotional_feed_mode.dart';
import 'package:holyverso/presentation/screens/devotionals/devotional_feed_reader_args.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_comments_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_comments_state.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_feed_reader_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_feed_reader_state.dart';
import 'package:holyverso/presentation/state/devotionals/devotionals_feed_controller.dart';
import 'package:holyverso/presentation/widgets/devotionals/devotional_content_view.dart';
import 'package:holyverso/presentation/widgets/devotionals/devotional_feed_context_copy.dart';
import 'package:share_plus/share_plus.dart';

const SystemUiOverlayStyle _readerOverlayStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarColor: AppColors.midnightFaith,
  systemNavigationBarIconBrightness: Brightness.light,
);

enum _ReaderMenuAction { report }

class PublicDevotionalFeedReaderScreen extends ConsumerStatefulWidget {
  const PublicDevotionalFeedReaderScreen({
    super.key,
    required this.devotionalId,
    required this.readerArgs,
  });

  final String devotionalId;
  final DevotionalFeedReaderArgs readerArgs;

  @override
  ConsumerState<PublicDevotionalFeedReaderScreen> createState() =>
      _PublicDevotionalFeedReaderScreenState();
}

class _PublicDevotionalFeedReaderScreenState
    extends ConsumerState<PublicDevotionalFeedReaderScreen> {
  late final PageController _pageController;
  final TextEditingController _commentController = TextEditingController();
  final Map<String, ScrollController> _scrollControllers =
      <String, ScrollController>{};
  bool _isAdvancing = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _configureReader();
    });
  }

  @override
  void didUpdateWidget(covariant PublicDevotionalFeedReaderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.devotionalId != widget.devotionalId ||
        oldWidget.readerArgs != widget.readerArgs) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _configureReader();
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _commentController.dispose();
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _configureReader() async {
    final deviceId = await ref
        .read(appRuntimeStorageProvider)
        .getOrCreateDeviceId();
    if (!mounted) {
      return;
    }

    await ref
        .read(devotionalFeedReaderControllerProvider.notifier)
        .configure(
          readerArgs: widget.readerArgs,
          devotionalId: widget.devotionalId,
          deliveryToken: widget.readerArgs.initialDeliveryToken,
          deviceId: deviceId,
        );

    if (!mounted) {
      return;
    }

    final readerState = ref.read(devotionalFeedReaderControllerProvider);
    if (_pageController.hasClients &&
        readerState.activeIndex != _pageController.page?.round()) {
      _pageController.jumpToPage(readerState.activeIndex);
    }
    await ref
        .read(devotionalCommentsControllerProvider.notifier)
        .load(widget.devotionalId);
  }

  ScrollController _scrollControllerFor(String devotionalId) {
    return _scrollControllers.putIfAbsent(devotionalId, ScrollController.new);
  }

  Future<void> _share(Devotional devotional) async {
    final feedSnapshot = ref
        .read(devotionalFeedReaderControllerProvider.notifier)
        .feedSnapshotFor(devotional.id);
    final result = await ref
        .read(devotionalsRepositoryProvider)
        .shareDevotional(
          devotional.id,
          deliveryToken:
              feedSnapshot?.deliveryToken ??
              (widget.readerArgs.initialDevotionalId == devotional.id
                  ? widget.readerArgs.initialDeliveryToken
                  : null),
        );

    if (!mounted) {
      return;
    }

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

    if (!mounted) {
      return;
    }

    await ref
        .read(devotionalFeedReaderControllerProvider.notifier)
        .registerShare(shareCount: result.shareCount);
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) {
      return;
    }

    final before = ref.read(devotionalCommentsControllerProvider).total;
    await ref
        .read(devotionalCommentsControllerProvider.notifier)
        .addComment(content);
    _commentController.clear();

    final after = ref.read(devotionalCommentsControllerProvider).total;
    if (after != before) {
      ref
          .read(devotionalFeedReaderControllerProvider.notifier)
          .syncCommentCount(after);
    }
  }

  Future<void> _openComments() async {
    final devotionalId = ref
        .read(devotionalFeedReaderControllerProvider)
        .activeDevotionalId;
    if (devotionalId == null) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentsBottomSheet(
        commentController: _commentController,
        onSubmitComment: _submitComment,
      ),
    );
  }

  Future<void> _openAuthor(Devotional devotional) async {
    await context.push('/users/${devotional.author.id}');
  }

  Future<void> _handlePageChanged(int index) async {
    await ref
        .read(devotionalFeedReaderControllerProvider.notifier)
        .activateIndex(index);
    final activeDevotionalId = ref
        .read(devotionalFeedReaderControllerProvider)
        .activeDevotionalId;
    if (activeDevotionalId == null || !mounted) {
      return;
    }
    _commentController.clear();
    await ref
        .read(devotionalCommentsControllerProvider.notifier)
        .load(activeDevotionalId);
  }

  Future<void> _advanceToNextIfPossible() async {
    if (_isAdvancing) {
      return;
    }

    _isAdvancing = true;
    try {
      final nextIndex = await ref
          .read(devotionalFeedReaderControllerProvider.notifier)
          .resolveNextIndex();
      if (!mounted || nextIndex == null) {
        return;
      }

      await _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    } finally {
      _isAdvancing = false;
    }
  }

  bool _onScrollNotification(
    String devotionalId,
    ScrollNotification notification,
  ) {
    final readerState = ref.read(devotionalFeedReaderControllerProvider);
    if (readerState.activeDevotionalId != devotionalId) {
      return false;
    }

    final maxExtent = notification.metrics.maxScrollExtent;
    if (maxExtent > 0) {
      final progress = notification.metrics.pixels / maxExtent;
      if (progress >= 0.75) {
        unawaited(
          ref
              .read(devotionalFeedReaderControllerProvider.notifier)
              .reportReadComplete(),
        );
      }
    }

    if (notification is OverscrollNotification &&
        notification.overscroll > 10 &&
        notification.metrics.pixels >= maxExtent) {
      unawaited(_advanceToNextIfPossible());
    }

    return false;
  }

  Future<void> _showReportSheet() async {
    final l10n = context.l10n;
    final detailController = TextEditingController();

    final reason = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.midnightFaith,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final options = [
          ('INAPPROPRIATE', l10n.devotionalReportInappropriate),
          ('OFFENSIVE', l10n.devotionalReportOffensive),
          ('SEXUAL', l10n.devotionalReportSexual),
          ('VIOLENCE', l10n.devotionalReportViolence),
          ('SPAM', l10n.devotionalReportSpam),
          ('INAPPROPRIATE_IMAGE', l10n.devotionalReportImage),
          ('MISLEADING', l10n.devotionalReportMisleading),
          ('OTHER', l10n.devotionalReportOther),
        ];
        final mediaQuery = MediaQuery.of(context);

        return SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: mediaQuery.size.height * 0.82,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                mediaQuery.viewInsets.bottom + AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.devotionalReportTitle,
                    style: AppTextStyles.headline3.copyWith(
                      color: AppColors.pureWhite,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...options.map(
                    (option) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        option.$2,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.pureWhite,
                        ),
                      ),
                      onTap: () => Navigator.of(context).pop(option.$1),
                    ),
                  ),
                  TextField(
                    controller: detailController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: l10n.devotionalReportDetailsHint,
                      filled: true,
                      fillColor: AppColors.inputBackground,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                        borderSide: BorderSide(
                          color: AppColors.inputBorder.withValues(alpha: 0.7),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                        borderSide: const BorderSide(
                          color: AppColors.holyGold,
                          width: 1.2,
                        ),
                      ),
                    ),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.pureWhite,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context).pop('WITH_DETAILS'),
                      child: Text(l10n.saveAction),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    detailController.dispose();

    if (!mounted || reason == null) {
      return;
    }

    final success = await ref
        .read(devotionalFeedReaderControllerProvider.notifier)
        .report(
          reason: reason == 'WITH_DETAILS' ? 'OTHER' : reason,
          details: detailController.text.trim(),
        );
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? context.l10n.devotionalReportSuccess
              : context.l10n.devotionalsSaveError,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final readerState = ref.watch(devotionalFeedReaderControllerProvider);
    final feedState = ref.watch(
      devotionalFeedProviderForMode(widget.readerArgs.feedMode),
    );

    ref.listen<String?>(
      devotionalFeedReaderControllerProvider.select(
        (state) => state.readCompleteJustSucceededId,
      ),
      (_, devotionalId) {
        if (devotionalId == null) {
          return;
        }
        ref
            .read(devotionalFeedReaderControllerProvider.notifier)
            .acknowledgeReadComplete();
        if (widget.readerArgs.feedMode == DevotionalFeedMode.forYou) {
          ref.read(forYouFeedControllerProvider.notifier).refreshHeader();
        }
      },
    );

    if (feedState.items.isEmpty &&
        readerState.status == DevotionalFeedReaderStatus.loading) {
      return const Scaffold(
        backgroundColor: AppColors.midnightFaith,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.holyGold),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _readerOverlayStyle,
      child: Scaffold(
        backgroundColor: AppColors.midnightFaith,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.pureWhite,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: _readerOverlayStyle,
          leading: const BackButton(),
          actions: [
            PopupMenuButton<_ReaderMenuAction>(
              icon: const Icon(Icons.more_horiz_rounded),
              color: AppColors.midnightFaithDark,
              surfaceTintColor: Colors.transparent,
              onSelected: (value) {
                if (value == _ReaderMenuAction.report) {
                  _showReportSheet();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<_ReaderMenuAction>(
                  value: _ReaderMenuAction.report,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.flag_outlined,
                        color: AppColors.pureWhite,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        context.l10n.devotionalReportAction,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.pureWhite,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          bottom: false,
          child: PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: _handlePageChanged,
            itemCount: feedState.items.length,
            itemBuilder: (context, index) {
              final feedItem = feedState.items[index];
              final fullDevotional =
                  readerState.devotionalFor(feedItem.id) ?? feedItem;
              final commentsState = ref.watch(
                devotionalCommentsControllerProvider,
              );
              final commentCount = commentsState.devotionalId == feedItem.id
                  ? commentsState.total
                  : fullDevotional.commentsCount;
              final page = _PublicReaderPage(
                key: Key('public-feed-reader-page-${feedItem.id}'),
                devotional: fullDevotional,
                commentCount: commentCount,
                scrollController: _scrollControllerFor(feedItem.id),
                isLoading:
                    readerState.activeDevotionalId == feedItem.id &&
                    readerState.status == DevotionalFeedReaderStatus.loading &&
                    readerState.devotionalFor(feedItem.id) == null,
                onRefresh: () => ref
                    .read(devotionalFeedReaderControllerProvider.notifier)
                    .reloadActive(),
                onScrollNotification: (notification) =>
                    _onScrollNotification(feedItem.id, notification),
                onToggleLike: () => ref
                    .read(devotionalFeedReaderControllerProvider.notifier)
                    .toggleLike(),
                onToggleSave: () => ref
                    .read(devotionalFeedReaderControllerProvider.notifier)
                    .toggleSave(),
                onOpenComments: _openComments,
                onShare: () => _share(fullDevotional),
                onOpenAuthor: () => _openAuthor(fullDevotional),
                isTogglingLike:
                    readerState.activeDevotionalId == feedItem.id &&
                    readerState.isTogglingLike,
                isTogglingSave:
                    readerState.activeDevotionalId == feedItem.id &&
                    readerState.isTogglingSave,
                heroTag:
                    widget.readerArgs.heroTag != null &&
                        widget.readerArgs.initialDevotionalId == feedItem.id &&
                        readerState.activeDevotionalId == feedItem.id
                    ? widget.readerArgs.heroTag
                    : null,
              );

              return page;
            },
          ),
        ),
      ),
    );
  }
}

class _PublicReaderPage extends StatelessWidget {
  const _PublicReaderPage({
    super.key,
    required this.devotional,
    required this.commentCount,
    required this.scrollController,
    required this.onRefresh,
    required this.onScrollNotification,
    required this.onToggleLike,
    required this.onToggleSave,
    required this.onOpenComments,
    required this.onShare,
    required this.onOpenAuthor,
    required this.isLoading,
    required this.isTogglingLike,
    required this.isTogglingSave,
    this.heroTag,
  });

  final Devotional devotional;
  final int commentCount;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final bool Function(ScrollNotification notification) onScrollNotification;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleSave;
  final VoidCallback onOpenComments;
  final VoidCallback onShare;
  final VoidCallback onOpenAuthor;
  final bool isLoading;
  final bool isTogglingLike;
  final bool isTogglingSave;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final referenceLabel = _referenceLabel(devotional);
    final continuityLabel = devotionalDetailContinuityLabel(
      context.l10n,
      devotional,
    );
    final hasCoverImage =
        devotional.coverImageUrl != null &&
        devotional.coverImageUrl!.isNotEmpty;
    final rail = _PublicReaderActionRail(
      devotional: devotional,
      commentCount: commentCount,
      isTogglingLike: isTogglingLike,
      isTogglingSave: isTogglingSave,
      onToggleLike: onToggleLike,
      onToggleSave: onToggleSave,
      onOpenComments: onOpenComments,
      onShare: onShare,
    );

    final body = Stack(
      children: [
        Positioned.fill(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: NotificationListener<ScrollNotification>(
              onNotification: onScrollNotification,
              child: SingleChildScrollView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.only(bottom: 168),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasCoverImage)
                      _PublicReaderHero(
                        imageUrl: devotional.coverImageUrl!,
                        focusY: devotional.coverImageFocusY,
                      )
                    else
                      const SizedBox(height: 124),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        92,
                        AppSpacing.xl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            devotional.title,
                            style: AppTextStyles.headline2.copyWith(
                              color: AppColors.pureWhite,
                              fontWeight: FontWeight.w800,
                              height: 1.16,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          InkWell(
                            onTap: onOpenAuthor,
                            borderRadius: BorderRadius.circular(
                              AppBorderRadius.md,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppColors.holyGold
                                      .withValues(alpha: 0.18),
                                  backgroundImage:
                                      devotional.author.avatarUrl != null &&
                                          devotional
                                              .author
                                              .avatarUrl!
                                              .isNotEmpty
                                      ? CachedNetworkImageProvider(
                                          devotional.author.avatarUrl!,
                                        )
                                      : null,
                                  child:
                                      devotional.author.avatarUrl == null ||
                                          devotional.author.avatarUrl!.isEmpty
                                      ? Text(
                                          devotional.author.name.isNotEmpty
                                              ? devotional
                                                    .author
                                                    .name
                                                    .characters
                                                    .first
                                                    .toUpperCase()
                                              : '?',
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(
                                                color: AppColors.holyGold,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        devotional.author.name,
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(
                                              color: AppColors.holyGold,
                                            ),
                                      ),
                                      if (devotional.author.handle != null &&
                                          devotional.author.handle!.isNotEmpty)
                                        Text(
                                          '@${devotional.author.handle}',
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                color: AppColors.softMist,
                                              ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (referenceLabel != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              referenceLabel,
                              style: AppTextStyles.reference.copyWith(
                                color: AppColors.holyGold.withValues(
                                  alpha: 0.92,
                                ),
                              ),
                            ),
                          ],
                          if (continuityLabel != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              continuityLabel,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.softMist.withValues(
                                  alpha: 0.9,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          if (isLoading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: AppSpacing.xxl,
                                ),
                                child: CircularProgressIndicator(
                                  color: AppColors.holyGold,
                                ),
                              ),
                            )
                          else if (devotional.content == null ||
                              devotional.content!.isEmpty)
                            Text(
                              context.l10n.devotionalsContentMissing,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.softMist,
                              ),
                            )
                          else
                            DevotionalContentView(
                              content: devotional.content!,
                              emphasizeLeadingParagraph: true,
                            ),
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            context.l10n.devotionalReflectionPrompt,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.softMist.withValues(alpha: 0.92),
                              fontWeight: FontWeight.w500,
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
        ),
        PositionedDirectional(end: AppSpacing.md, bottom: 112, child: rail),
      ],
    );

    if (heroTag == null) {
      return body;
    }

    return Hero(
      tag: heroTag!,
      child: Material(color: Colors.transparent, child: body),
    );
  }
}

class _PublicReaderHero extends StatelessWidget {
  const _PublicReaderHero({required this.imageUrl, required this.focusY});

  final String imageUrl;
  final double focusY;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: topInset + kToolbarHeight + 244,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            key: const Key('public-feed-reader-hero-image'),
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            alignment: Alignment(0, focusY),
            errorWidget: (context, url, error) =>
                Container(color: AppColors.midnightFaithDark),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, 0.32, 0.78, 1],
                colors: [
                  Colors.black.withValues(alpha: 0.48),
                  Colors.black.withValues(alpha: 0.18),
                  AppColors.midnightFaith.withValues(alpha: 0.9),
                  AppColors.midnightFaith,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicReaderActionRail extends StatelessWidget {
  const _PublicReaderActionRail({
    required this.devotional,
    required this.commentCount,
    required this.isTogglingLike,
    required this.isTogglingSave,
    required this.onToggleLike,
    required this.onToggleSave,
    required this.onOpenComments,
    required this.onShare,
  });

  final Devotional devotional;
  final int commentCount;
  final bool isTogglingLike;
  final bool isTogglingSave;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleSave;
  final VoidCallback onOpenComments;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('public-feed-reader-action-rail'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.midnightFaithDark.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
        border: Border.all(color: AppColors.pureWhite.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RailActionButton(
            key: const Key('public-feed-reader-save-button'),
            icon: devotional.saved
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            count: devotional.saveCount,
            active: devotional.saved,
            isLoading: isTogglingSave,
            onTap: onToggleSave,
          ),
          const SizedBox(height: AppSpacing.sm),
          _RailActionButton(
            key: const Key('public-feed-reader-like-button'),
            icon: devotional.liked
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            count: devotional.likesCount,
            active: devotional.liked,
            isLoading: isTogglingLike,
            onTap: onToggleLike,
          ),
          const SizedBox(height: AppSpacing.sm),
          _RailActionButton(
            key: const Key('public-feed-reader-comment-button'),
            icon: Icons.chat_bubble_outline_rounded,
            count: commentCount,
            onTap: onOpenComments,
          ),
          const SizedBox(height: AppSpacing.sm),
          _RailActionButton(
            key: const Key('public-feed-reader-share-button'),
            icon: Icons.share_outlined,
            count: devotional.shareCount,
            onTap: onShare,
          ),
        ],
      ),
    );
  }
}

class _RailActionButton extends StatelessWidget {
  const _RailActionButton({
    super.key,
    required this.icon,
    required this.count,
    required this.onTap,
    this.active = false,
    this.isLoading = false,
  });

  final IconData icon;
  final int count;
  final VoidCallback onTap;
  final bool active;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? AppColors.holyGold
        : AppColors.pureWhite.withValues(alpha: 0.9);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppBorderRadius.full),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          children: [
            if (isLoading)
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
            else
              Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              count.toString(),
              style: AppTextStyles.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentsBottomSheet extends ConsumerStatefulWidget {
  const _CommentsBottomSheet({
    required this.commentController,
    required this.onSubmitComment,
  });

  final TextEditingController commentController;
  final Future<void> Function() onSubmitComment;

  @override
  ConsumerState<_CommentsBottomSheet> createState() =>
      _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends ConsumerState<_CommentsBottomSheet> {
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }
    setState(() {
      _isSubmitting = true;
    });
    try {
      await widget.onSubmitComment();
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsState = ref.watch(devotionalCommentsControllerProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.42,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: DecoratedBox(
            key: const Key('public-feed-reader-comments-sheet'),
            decoration: const BoxDecoration(
              color: AppColors.midnightFaithDark,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppBorderRadius.xl),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(top: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.pureWhite.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppBorderRadius.full),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            commentsState.total > 0
                                ? '${context.l10n.commentsLabel} (${commentsState.total})'
                                : context.l10n.commentsLabel,
                            style: AppTextStyles.headline3.copyWith(
                              color: AppColors.pureWhite,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _CommentsList(
                      scrollController: scrollController,
                      commentsState: commentsState,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: widget.commentController,
                            minLines: 1,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: context.l10n.writeComment,
                              filled: true,
                              fillColor: AppColors.inputBackground,
                              hintStyle: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.inputPlaceholder.withValues(
                                  alpha: 0.82,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppBorderRadius.lg,
                                ),
                                borderSide: BorderSide(
                                  color: AppColors.inputBorder.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppBorderRadius.lg,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.holyGold,
                                  width: 1.2,
                                ),
                              ),
                            ),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.pureWhite,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Material(
                          color: AppColors.holyGold.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(
                            AppBorderRadius.full,
                          ),
                          child: IconButton(
                            onPressed: _isSubmitting ? null : _submit,
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.holyGold,
                                    ),
                                  )
                                : const Icon(
                                    Icons.send_rounded,
                                    color: AppColors.holyGold,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CommentsList extends ConsumerWidget {
  const _CommentsList({
    required this.scrollController,
    required this.commentsState,
  });

  final ScrollController scrollController;
  final DevotionalCommentsState commentsState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (commentsState.status == DevotionalCommentsStatus.loading &&
        commentsState.items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.holyGold),
      );
    }

    if (commentsState.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              context.l10n.devotionalCommentsEmptyTitle,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.pureWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.l10n.devotionalCommentsEmptySubtitle,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.softMist,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      itemCount: commentsState.items.length + 1,
      itemBuilder: (context, index) {
        if (index == commentsState.items.length) {
          if (commentsState.hasMore) {
            return Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Center(
                child: TextButton(
                  onPressed: commentsState.isFetchingMore
                      ? null
                      : () => ref
                            .read(devotionalCommentsControllerProvider.notifier)
                            .loadMore(),
                  child: commentsState.isFetchingMore
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.holyGold,
                          ),
                        )
                      : const Text('Cargar más comentarios'),
                ),
              ),
            );
          }
          return const SizedBox(height: AppSpacing.sm);
        }

        final comment = commentsState.items[index];
        return _CommentCard(comment: comment);
      },
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.comment});

  final DevotionalComment comment;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.pureWhite.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            comment.author.name,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.holyGold),
          ),
          const SizedBox(height: 4),
          Text(
            comment.content,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.pureWhite.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

String? _referenceLabel(Devotional devotional) {
  final primaryReferences = devotional.primaryReferences;
  if (primaryReferences.isNotEmpty) {
    return primaryReferences
        .map((reference) => reference.referenceLabel)
        .join(', ');
  }

  if (devotional.verseReferences.isNotEmpty) {
    return devotional.verseReferences.first.referenceLabel;
  }

  return null;
}
