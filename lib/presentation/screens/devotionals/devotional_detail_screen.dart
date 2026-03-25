import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_design_tokens.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';
import 'package:holyverso/domain/devotionals/devotional.dart';
import 'package:holyverso/domain/devotionals/devotional_comment.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_comments_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_comments_state.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_detail_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_detail_state.dart';
import 'package:holyverso/presentation/widgets/common/holy_child_app_bar.dart';
import 'package:holyverso/presentation/widgets/devotionals/devotional_content_view.dart';
import 'package:share_plus/share_plus.dart';

class DevotionalDetailScreen extends ConsumerStatefulWidget {
  const DevotionalDetailScreen({super.key, required this.devotionalId});

  final String devotionalId;

  @override
  ConsumerState<DevotionalDetailScreen> createState() =>
      _DevotionalDetailScreenState();
}

class _DevotionalDetailScreenState
    extends ConsumerState<DevotionalDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(devotionalDetailControllerProvider.notifier)
          .load(widget.devotionalId);
      ref
          .read(devotionalCommentsControllerProvider.notifier)
          .load(widget.devotionalId);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxExtent = _scrollController.position.maxScrollExtent;
    if (maxExtent <= 0) return;
    final progress = _scrollController.position.pixels / maxExtent;
    if (progress >= 0.75) {
      ref
          .read(devotionalDetailControllerProvider.notifier)
          .reportReadComplete();
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

    await ref.read(devotionalDetailControllerProvider.notifier).registerShare();
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    await ref
        .read(devotionalCommentsControllerProvider.notifier)
        .addComment(content);
    _commentController.clear();
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
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.inputPlaceholder.withValues(
                          alpha: 0.78,
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

    if (!mounted || reason == null) return;

    final selectedReason = reason == 'WITH_DETAILS' ? 'OTHER' : reason;
    final success = await ref
        .read(devotionalDetailControllerProvider.notifier)
        .report(reason: selectedReason, details: detailController.text.trim());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? l10n.devotionalReportSuccess : l10n.devotionalsSaveError,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(devotionalDetailControllerProvider);
    final commentsState = ref.watch(devotionalCommentsControllerProvider);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.midnightFaith,
      appBar: HolyChildAppBar(title: l10n.devotionalDetailTitle),
      body: SafeArea(
        top: false,
        child: switch (state.status) {
          DevotionalDetailStatus.loading => const Center(
            child: CircularProgressIndicator(color: AppColors.holyGold),
          ),
          DevotionalDetailStatus.error => _DetailError(
            message: state.errorMessage ?? l10n.genericError,
            onRetry: () => ref
                .read(devotionalDetailControllerProvider.notifier)
                .load(widget.devotionalId),
          ),
          _ => _DetailContent(
            devotional: state.devotional,
            commentsState: commentsState,
            commentController: _commentController,
            scrollController: _scrollController,
            onRefresh: () async {
              await ref
                  .read(devotionalDetailControllerProvider.notifier)
                  .load(widget.devotionalId);
              await ref
                  .read(devotionalCommentsControllerProvider.notifier)
                  .refresh();
            },
            onToggleLike: () => ref
                .read(devotionalDetailControllerProvider.notifier)
                .toggleLike(),
            onToggleSave: () => ref
                .read(devotionalDetailControllerProvider.notifier)
                .toggleSave(),
            onShare: _share,
            onReport: _showReportSheet,
            onSubmitComment: _submitComment,
            onOpenAuthor: () async {
              final authorId = state.devotional?.author.id;
              if (authorId == null || authorId.isEmpty) return;
              await context.push('/users/$authorId');
            },
          ),
        },
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.devotional,
    required this.commentsState,
    required this.commentController,
    required this.scrollController,
    required this.onRefresh,
    required this.onToggleLike,
    required this.onToggleSave,
    required this.onShare,
    required this.onReport,
    required this.onSubmitComment,
    required this.onOpenAuthor,
  });

  final Devotional? devotional;
  final DevotionalCommentsState commentsState;
  final TextEditingController commentController;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleSave;
  final Future<void> Function(Devotional devotional) onShare;
  final Future<void> Function() onReport;
  final Future<void> Function() onSubmitComment;
  final Future<void> Function() onOpenAuthor;

  @override
  Widget build(BuildContext context) {
    final devotional = this.devotional;
    if (devotional == null) {
      return const SizedBox.shrink();
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          if (devotional.coverImageUrl != null &&
              devotional.coverImageUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              child: CachedNetworkImage(
                imageUrl: devotional.coverImageUrl!,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                alignment: Alignment(0, devotional.coverImageFocusY),
                errorWidget: (context, url, error) => Container(
                  height: 220,
                  color: AppColors.midnightFaithDark,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.softMist,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Text(
            devotional.title,
            style: AppTextStyles.headline2.copyWith(
              color: AppColors.pureWhite,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          InkWell(
            onTap: onOpenAuthor,
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.holyGold.withValues(alpha: 0.18),
                  backgroundImage:
                      devotional.author.avatarUrl != null &&
                          devotional.author.avatarUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(devotional.author.avatarUrl!)
                      : null,
                  child:
                      devotional.author.avatarUrl == null ||
                          devotional.author.avatarUrl!.isEmpty
                      ? Text(
                          devotional.author.name.isNotEmpty
                              ? devotional.author.name.characters.first
                                    .toUpperCase()
                              : '?',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.holyGold,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      devotional.author.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.holyGold,
                      ),
                    ),
                    if (devotional.author.handle != null &&
                        devotional.author.handle!.isNotEmpty)
                      Text(
                        '@${devotional.author.handle}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.softMist,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (devotional.moderationReason != null &&
              devotional.moderationReason!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
              ),
              child: Text(
                devotional.moderationReason!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.pureWhite,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (devotional.content != null)
            DevotionalContentView(content: devotional.content!),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: onToggleLike,
                icon: Icon(
                  devotional.liked ? Icons.favorite : Icons.favorite_border,
                ),
                label: Text(
                  '${context.l10n.likesLabel} ${devotional.likesCount}',
                ),
              ),
              OutlinedButton.icon(
                onPressed: onToggleSave,
                icon: Icon(
                  devotional.saved ? Icons.bookmark : Icons.bookmark_border,
                ),
                label: Text(
                  '${context.l10n.devotionalSave} ${devotional.saveCount}',
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => onShare(devotional),
                icon: const Icon(Icons.share_outlined),
                label: Text(
                  '${context.l10n.shareDevotional} ${devotional.shareCount}',
                ),
              ),
              OutlinedButton.icon(
                onPressed: onReport,
                icon: const Icon(Icons.flag_outlined),
                label: Text(context.l10n.devotionalReportAction),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            '${context.l10n.commentsLabel} (${commentsState.total})',
            style: AppTextStyles.headline3.copyWith(
              color: AppColors.pureWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: commentController,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: context.l10n.writeComment,
              filled: true,
              fillColor: AppColors.inputBackground,
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.inputPlaceholder.withValues(alpha: 0.82),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                borderSide: BorderSide(
                  color: AppColors.inputBorder.withValues(alpha: 0.7),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                borderSide: const BorderSide(
                  color: AppColors.holyGold,
                  width: 1.2,
                ),
              ),
              suffixIcon: IconButton(
                onPressed: onSubmitComment,
                icon: const Icon(Icons.send_rounded, color: AppColors.holyGold),
              ),
            ),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.pureWhite,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (commentsState.items.isEmpty)
            Text(
              context.l10n.devotionalCommentsEmpty,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.softMist,
              ),
            ),
          ...commentsState.items.map(
            (comment) => _CommentItem(comment: comment),
          ),
        ],
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  const _CommentItem({required this.comment});

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

class _DetailError extends StatelessWidget {
  const _DetailError({required this.message, required this.onRetry});

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
