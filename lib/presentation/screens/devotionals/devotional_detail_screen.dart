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
import 'package:holyverso/domain/devotionals/devotional_status.dart';
import 'package:holyverso/presentation/state/auth/auth_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_comments_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_comments_state.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_detail_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_detail_state.dart';
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
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _shareDevotional(Devotional devotional) {
    final l10n = context.l10n;
    final referenceLabel = devotional.primaryReferences.isNotEmpty
        ? devotional.primaryReferences.map((ref) => ref.referenceLabel).join(', ')
        : '';
    final shareText = [
      devotional.title,
      if (referenceLabel.isNotEmpty) referenceLabel,
      l10n.devotionalsShareFooter,
    ].join('\n');

    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null
        ? (box.localToGlobal(Offset.zero) & box.size)
        : const Rect.fromLTWH(0, 0, 1, 1);

    Share.share(
      shareText,
      subject: l10n.shareDevotional,
      sharePositionOrigin: origin,
    );
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    await ref
        .read(devotionalCommentsControllerProvider.notifier)
        .addComment(content);
    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final detailState = ref.watch(devotionalDetailControllerProvider);
    final commentsState = ref.watch(devotionalCommentsControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final devotional = detailState.devotional;

    return Scaffold(
      backgroundColor: AppColors.midnightFaith,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/devotionals');
            }
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.midnightFaithDark.withValues(alpha: 0.6),
            foregroundColor: AppColors.pureWhite,
            padding: const EdgeInsets.all(10),
          ),
        ),
        title: Text(
          l10n.devotionalsTitle,
          style: AppTextStyles.headline3.copyWith(
            color: AppColors.pureWhite,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (devotional != null &&
              devotional.isOwner &&
              devotional.status == DevotionalStatus.draft)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: IconButton(
                onPressed: () =>
                    context.push('/devotionals/${devotional.id}/edit'),
                icon: const Icon(Icons.edit_outlined),
                tooltip: l10n.editDevotional,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.holyGold,
                  foregroundColor: AppColors.midnightFaith,
                  padding: const EdgeInsets.all(10),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          Container(decoration: BoxDecoration(gradient: AppColors.midnightGradient)),
          SafeArea(
            child: _buildBody(
              detailState,
              commentsState,
              authState.isAuthenticated,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    DevotionalDetailState detailState,
    DevotionalCommentsState commentsState,
    bool isAuthenticated,
  ) {
    final l10n = context.l10n;

    if (detailState.status == DevotionalDetailStatus.loading &&
        detailState.devotional == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.holyGold),
      );
    }

    if (detailState.status == DevotionalDetailStatus.error &&
        detailState.devotional == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                detailState.errorMessage ?? l10n.genericError,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.pureWhite,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () => ref
                    .read(devotionalDetailControllerProvider.notifier)
                    .load(widget.devotionalId),
                child: Text(l10n.errorRetry),
              ),
            ],
          ),
        ),
      );
    }

    final devotional = detailState.devotional;
    if (devotional == null) {
      return const SizedBox.shrink();
    }
    final publishedLabel = _formatPublishedDate(devotional.publishedAt);

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(devotionalDetailControllerProvider.notifier)
            .load(widget.devotionalId);
        await ref
            .read(devotionalCommentsControllerProvider.notifier)
            .refresh();
      },
      color: AppColors.holyGold,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          if (devotional.coverImageUrl != null)
            ClipRRect(
              borderRadius: AppBorderRadius.card,
              child: CachedNetworkImage(
                imageUrl: devotional.coverImageUrl!,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  height: 220,
                  color: AppColors.midnightFaithDark,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            devotional.title,
            style: AppTextStyles.headline1.copyWith(
              color: AppColors.pureWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            devotional.author.name,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.softMist.withValues(alpha: 0.8),
            ),
          ),
          if (publishedLabel.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    border: Border.all(
                      color: AppColors.pureWhite.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: AppColors.holyGold,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        publishedLabel,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.holyGold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Publicado',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.softMist.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          if (devotional.primaryReferences.isNotEmpty)
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: devotional.primaryReferences
                  .map(
                    (ref) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.holyGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      ),
                      child: Text(
                        ref.referenceLabel,
                        style: AppTextStyles.reference.copyWith(
                          color: AppColors.holyGold,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: AppSpacing.lg),
          if (devotional.content != null && devotional.content!.isNotEmpty)
            DevotionalContentView(content: devotional.content!),
          if (devotional.content == null || devotional.content!.isEmpty)
            Text(
              l10n.devotionalsContentMissing,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.softMist.withValues(alpha: 0.8),
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
          _buildActions(detailState),
          const SizedBox(height: AppSpacing.xl),
          _buildComments(commentsState, isAuthenticated),
        ],
      ),
    );
  }

  String _formatPublishedDate(DateTime? date) {
    if (date == null) return '';
    final local = date.toLocal();
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    final month = months[local.month - 1];
    return '${local.day} $month ${local.year}';
  }

  Widget _buildActions(DevotionalDetailState state) {
    final l10n = context.l10n;
    final devotional = state.devotional;
    if (devotional == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: state.isTogglingLike
                ? null
                : () => ref
                    .read(devotionalDetailControllerProvider.notifier)
                    .toggleLike(),
            icon: Icon(
              devotional.liked ? Icons.favorite : Icons.favorite_border,
              color: devotional.liked ? Colors.redAccent : AppColors.holyGold,
            ),
            label: Text(
              '${l10n.likesLabel} ${devotional.likesCount}',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.midnightFaith,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.holyGold,
              foregroundColor: AppColors.midnightFaith,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _shareDevotional(devotional),
            icon: const Icon(Icons.share_outlined),
            label: Text(l10n.shareDevotional),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.holyGold,
              side: BorderSide(color: AppColors.holyGold.withValues(alpha: 0.6)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComments(
    DevotionalCommentsState state,
    bool isAuthenticated,
  ) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.commentsLabel} (${state.total})',
          style: AppTextStyles.headline3.copyWith(
            color: AppColors.pureWhite,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (!isAuthenticated)
          _LoginPrompt(onLogin: () {
            context.go('/login', extra: l10n.loginRequiredMessage);
          }),
        if (isAuthenticated)
          _CommentInput(
            controller: _commentController,
            onSubmit: _addComment,
          ),
        if (state.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              state.errorMessage!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        if (state.status == DevotionalCommentsStatus.loading &&
            state.items.isEmpty)
          const Center(
            child: CircularProgressIndicator(color: AppColors.holyGold),
          ),
        if (state.status == DevotionalCommentsStatus.error &&
            state.items.isEmpty)
          Text(
            state.errorMessage ?? l10n.genericError,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.softMist.withValues(alpha: 0.8),
            ),
          ),
        ...state.items.map((comment) => _CommentItem(comment: comment)).toList(),
        if (state.isFetchingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.holyGold),
            ),
          ),
      ],
    );
  }
}

class _CommentInput extends StatelessWidget {
  const _CommentInput({required this.controller, required this.onSubmit});

  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: l10n.writeComment,
              fillColor: AppColors.pureWhite.withValues(alpha: 0.08),
            ),
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.pureWhite),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton(
          onPressed: onSubmit,
          icon: const Icon(Icons.send_rounded, color: AppColors.holyGold),
        ),
      ],
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.pureWhite.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: AppColors.holyGold),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.devotionalsLoginToComment,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.softMist,
              ),
            ),
          ),
          TextButton(
            onPressed: onLogin,
            child: Text(l10n.loginAction),
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
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.holyGold,
            ),
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
