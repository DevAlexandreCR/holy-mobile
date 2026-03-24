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
import 'package:holyverso/domain/devotionals/devotional_comment.dart';
import 'package:holyverso/domain/devotionals/devotional_status.dart';
import 'package:holyverso/presentation/state/auth/auth_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_comments_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_comments_state.dart';
import 'package:holyverso/presentation/state/devotionals/devotionals_list_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotionals_list_state.dart';
import 'package:holyverso/presentation/widgets/devotionals/devotional_card.dart';
import 'package:share_plus/share_plus.dart';

final devotionalContentProvider = FutureProvider.family<Devotional, String>((
  ref,
  devotionalId,
) async {
  final repository = ref.watch(devotionalsRepositoryProvider);
  return repository.getDevotional(devotionalId);
});

class DevotionalsListScreen extends ConsumerStatefulWidget {
  const DevotionalsListScreen({super.key, this.initialDevotionalId});

  final String? initialDevotionalId;

  @override
  ConsumerState<DevotionalsListScreen> createState() =>
      _DevotionalsListScreenState();
}

class _DevotionalsListScreenState extends ConsumerState<DevotionalsListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _commentController = TextEditingController();
  String? _expandedDevotionalId;

  @override
  void initState() {
    super.initState();
    _expandedDevotionalId = widget.initialDevotionalId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(devotionalsListControllerProvider.notifier).loadInitial();
      if (_expandedDevotionalId != null) {
        ref
            .read(devotionalCommentsControllerProvider.notifier)
            .load(_expandedDevotionalId!);
      }
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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(devotionalsListControllerProvider.notifier).loadMore();
    }
  }

  void _onModeSelected(DevotionalsListMode mode) {
    setState(() {
      _expandedDevotionalId = null;
    });
    ref.read(devotionalsListControllerProvider.notifier).setMode(mode);
  }

  void _onStatusSelected(DevotionalStatus status) {
    setState(() {
      _expandedDevotionalId = null;
    });
    ref
        .read(devotionalsListControllerProvider.notifier)
        .setStatusFilter(status);
  }

  void _toggleExpanded(String devotionalId) {
    final isExpanding = _expandedDevotionalId != devotionalId;
    setState(() {
      _expandedDevotionalId = isExpanding ? devotionalId : null;
    });
    if (isExpanding) {
      _commentController.clear();
      ref
          .read(devotionalCommentsControllerProvider.notifier)
          .load(devotionalId);
    }
  }

  String _mapContentError(Object error, AppLocalizations l10n) {
    return AppErrorMapper.toMessage(
      error,
      l10n: l10n,
      fallbackMessage: l10n.devotionalsLoadError,
    );
  }

  Future<void> _shareDevotional(Devotional devotional) async {
    final l10n = context.l10n;
    var devotionalToShare = devotional;
    if (devotionalToShare.content == null ||
        devotionalToShare.content!.isEmpty) {
      try {
        devotionalToShare = await ref
            .read(devotionalsRepositoryProvider)
            .getDevotional(devotional.id);
      } catch (_) {}
    }

    final devotionalText = _extractShareableText(devotionalToShare.content);
    final shareText = [
      devotionalToShare.title.trim(),
      if (devotionalText.isNotEmpty) devotionalText,
      _buildDevotionalShareUrl(devotionalToShare.id),
    ].join('\n\n');

    if (!mounted) return;

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

  String _buildDevotionalShareUrl(String devotionalId) {
    return 'https://holyverso.com/devotionals/$devotionalId';
  }

  String _extractShareableText(List<dynamic>? content) {
    if (content == null || content.isEmpty) {
      return '';
    }

    final buffer = StringBuffer();
    for (final op in content) {
      if (op is! Map) {
        continue;
      }

      final insert = op['insert'];
      if (insert is String) {
        buffer.write(insert);
      }
    }

    final normalized = buffer
        .toString()
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .trim();
    return normalized.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  }

  Future<void> _addComment(Devotional devotional) async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    await ref
        .read(devotionalCommentsControllerProvider.notifier)
        .addComment(content);
    _commentController.clear();
    final commentsState = ref.read(devotionalCommentsControllerProvider);
    if (commentsState.devotionalId == devotional.id) {
      ref
          .read(devotionalsListControllerProvider.notifier)
          .updateCommentsCount(devotional.id, commentsState.total);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(devotionalsListControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final canEdit = authState.user?.role.canEditContent ?? false;
    final commentsState = ref.watch(devotionalCommentsControllerProvider);

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
        centerTitle: true,
        actions: [
          if (canEdit)
            IconButton(
              onPressed: () => context.push('/devotionals/create'),
              icon: const Icon(Icons.add_circle_outline),
              tooltip: l10n.createDevotional,
            ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(gradient: AppColors.midnightGradient),
          ),
          SafeArea(
            child: Column(
              children: [
                if (canEdit)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    child: _ModeSelector(
                      mode: state.mode,
                      showMine: canEdit,
                      onSelected: _onModeSelected,
                    ),
                  ),
                if (state.mode == DevotionalsListMode.mine && canEdit)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    child: _StatusSelector(
                      current: state.statusFilter,
                      onSelected: _onStatusSelected,
                    ),
                  ),
                if (state.errorMessage != null && state.items.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    child: _ErrorBanner(message: state.errorMessage!),
                  ),
                Expanded(
                  child: _buildBody(
                    state,
                    commentsState,
                    authState.isAuthenticated,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton(
              onPressed: () => context.push('/devotionals/create'),
              backgroundColor: AppColors.holyGold,
              foregroundColor: AppColors.midnightFaith,
              child: const Icon(Icons.edit),
            )
          : null,
    );
  }

  Widget _buildBody(
    DevotionalsListState state,
    DevotionalCommentsState commentsState,
    bool isAuthenticated,
  ) {
    final l10n = context.l10n;

    if (state.status == DevotionalsListStatus.loading && state.items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.holyGold),
      );
    }

    if (state.status == DevotionalsListStatus.error && state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              state.errorMessage ?? l10n.genericError,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.pureWhite,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(devotionalsListControllerProvider.notifier)
                    .loadInitial(forceRefresh: true);
              },
              child: Text(l10n.errorRetry),
            ),
          ],
        ),
      );
    }

    if (state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.devotionalsEmptyTitle,
                style: AppTextStyles.headline3.copyWith(
                  color: AppColors.pureWhite,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.devotionalsEmptySubtitle,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.softMist.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(devotionalsListControllerProvider.notifier).refresh(),
      color: AppColors.holyGold,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        itemCount: state.items.length + (state.isFetchingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.holyGold),
              ),
            );
          }

          final devotional = state.items[index];
          final isExpanded = devotional.id == _expandedDevotionalId;
          final matchingComments = commentsState.devotionalId == devotional.id;
          final effectiveCommentsState = matchingComments
              ? commentsState
              : const DevotionalCommentsState(
                  status: DevotionalCommentsStatus.loading,
                );
          final shouldFetchContent =
              isExpanded &&
              (devotional.content == null || devotional.content!.isEmpty);
          final contentState = shouldFetchContent
              ? ref.watch(devotionalContentProvider(devotional.id))
              : null;
          final content = devotional.content ?? contentState?.value?.content;
          final isLoadingContent =
              shouldFetchContent && contentState?.isLoading == true;
          final contentError =
              shouldFetchContent && contentState?.hasError == true
              ? _mapContentError(contentState!.error!, l10n)
              : null;
          return DevotionalCard(
            devotional: devotional,
            isExpanded: isExpanded,
            onToggle: () => _toggleExpanded(devotional.id),
            content: content,
            isLoadingContent: isLoadingContent,
            contentError: contentError,
            onRetryContent: contentError != null
                ? () => ref.invalidate(devotionalContentProvider(devotional.id))
                : null,
            expandedFooter: isExpanded
                ? _buildExpandedFooter(
                    devotional: devotional,
                    commentsState: effectiveCommentsState,
                    isAuthenticated: isAuthenticated,
                    isTogglingLike: state.likingDevotionalId == devotional.id,
                  )
                : null,
          );
        },
      ),
    );
  }

  Widget _buildExpandedFooter({
    required Devotional devotional,
    required DevotionalCommentsState commentsState,
    required bool isAuthenticated,
    required bool isTogglingLike,
  }) {
    final l10n = context.l10n;
    final commentsTotal = commentsState.devotionalId == devotional.id
        ? commentsState.total
        : devotional.commentsCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (devotional.isOwner && devotional.status == DevotionalStatus.draft)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  context.push('/devotionals/${devotional.id}/edit'),
              icon: const Icon(Icons.edit_outlined),
              label: Text(l10n.editDevotional),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.holyGold,
                side: BorderSide(
                  color: AppColors.holyGold.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        if (devotional.isOwner && devotional.status == DevotionalStatus.draft)
          const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isTogglingLike
                    ? null
                    : () => ref
                          .read(devotionalsListControllerProvider.notifier)
                          .toggleLike(devotional.id),
                icon: Icon(
                  devotional.liked ? Icons.favorite : Icons.favorite_border,
                  color: devotional.liked
                      ? Colors.redAccent
                      : AppColors.holyGold,
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
                  side: BorderSide(
                    color: AppColors.holyGold.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          '${l10n.commentsLabel} ($commentsTotal)',
          style: AppTextStyles.headline3.copyWith(
            color: AppColors.pureWhite,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (!isAuthenticated)
          _LoginPrompt(
            onLogin: () {
              context.go('/login', extra: l10n.loginRequiredMessage);
            },
          ),
        if (isAuthenticated)
          _CommentInput(
            controller: _commentController,
            onSubmit: () => _addComment(devotional),
          ),
        if (commentsState.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              commentsState.errorMessage!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        if (commentsState.status == DevotionalCommentsStatus.loading &&
            commentsState.items.isEmpty)
          const Center(
            child: CircularProgressIndicator(color: AppColors.holyGold),
          ),
        if (commentsState.status == DevotionalCommentsStatus.error &&
            commentsState.items.isEmpty)
          Text(
            commentsState.errorMessage ?? l10n.genericError,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.softMist.withValues(alpha: 0.8),
            ),
          ),
        ...commentsState.items.map((comment) => _CommentItem(comment: comment)),
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
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.pureWhite,
            ),
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
          TextButton(onPressed: onLogin, child: Text(l10n.loginAction)),
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

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({
    required this.mode,
    required this.showMine,
    required this.onSelected,
  });

  final DevotionalsListMode mode;
  final bool showMine;
  final ValueChanged<DevotionalsListMode> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final options = [
      _ModeOption(label: l10n.devotionalsAll, value: DevotionalsListMode.all),
      if (showMine)
        _ModeOption(
          label: l10n.devotionalsMine,
          value: DevotionalsListMode.mine,
        ),
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      children: options
          .map(
            (option) => ChoiceChip(
              selected: mode == option.value,
              label: Text(option.label),
              labelStyle: AppTextStyles.labelMedium.copyWith(
                color: mode == option.value
                    ? AppColors.midnightFaith
                    : AppColors.softMist,
              ),
              selectedColor: AppColors.holyGold,
              backgroundColor: AppColors.inputBackground,
              checkmarkColor: AppColors.midnightFaith,
              onSelected: (_) => onSelected(option.value),
            ),
          )
          .toList(),
    );
  }
}

class _ModeOption {
  const _ModeOption({required this.label, required this.value});

  final String label;
  final DevotionalsListMode value;
}

class _StatusSelector extends StatelessWidget {
  const _StatusSelector({required this.current, required this.onSelected});

  final DevotionalStatus current;
  final ValueChanged<DevotionalStatus> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    String label;
    switch (current) {
      case DevotionalStatus.draft:
        label = l10n.devotionalsDrafts;
        break;
      case DevotionalStatus.published:
        label = l10n.devotionalsPublished;
        break;
      case DevotionalStatus.archived:
        label = l10n.devotionalsArchived;
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${l10n.devotionalsStatusLabel}: $label',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.softMist.withValues(alpha: 0.8),
          ),
        ),
        PopupMenuButton<DevotionalStatus>(
          icon: const Icon(Icons.tune_rounded, color: AppColors.pureWhite),
          tooltip: l10n.devotionalsStatusLabel,
          onSelected: onSelected,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: DevotionalStatus.draft,
              child: Text(l10n.devotionalsDrafts),
            ),
            PopupMenuItem(
              value: DevotionalStatus.published,
              child: Text(l10n.devotionalsPublished),
            ),
            PopupMenuItem(
              value: DevotionalStatus.archived,
              child: Text(l10n.devotionalsArchived),
            ),
          ],
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
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.pureWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
