import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:holyverso/core/errors/app_error_mapper.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/core/services/app_runtime_storage.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_design_tokens.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';
import 'package:holyverso/data/devotionals/devotionals_repository.dart';
import 'package:holyverso/data/roles/role_repository.dart';
import 'package:holyverso/domain/devotionals/devotional.dart';
import 'package:holyverso/domain/devotionals/devotional_comment.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_comments_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_comments_state.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_detail_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_detail_state.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_review_queue_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotionals_feed_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotionals_list_controller.dart';
import 'package:holyverso/presentation/state/roles/role_provider.dart';
import 'package:holyverso/presentation/widgets/devotionals/devotional_content_view.dart';
import 'package:holyverso/presentation/widgets/devotionals/devotional_feed_context_copy.dart';
import 'package:share_plus/share_plus.dart';

const double _detailCoverImageHeight = 129;
const SystemUiOverlayStyle _lightTopOverlayStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarColor: AppColors.midnightFaith,
  systemNavigationBarIconBrightness: Brightness.light,
);

enum _DetailMenuAction { report }

class DevotionalDetailScreen extends ConsumerStatefulWidget {
  const DevotionalDetailScreen({
    super.key,
    required this.devotionalId,
    this.initialDeliveryToken,
    this.initialShareToken,
  });

  final String devotionalId;
  final String? initialDeliveryToken;
  final String? initialShareToken;

  @override
  ConsumerState<DevotionalDetailScreen> createState() =>
      _DevotionalDetailScreenState();
}

class _DevotionalDetailScreenState
    extends ConsumerState<DevotionalDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _commentController = TextEditingController();
  bool _isBlockingAuthor = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDetail();
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
    final detailState = ref.read(devotionalDetailControllerProvider);
    final devotional = detailState.devotional;
    if (detailState.status != DevotionalDetailStatus.success ||
        devotional == null ||
        !devotional.isPubliclyVisible) {
      return;
    }
    final progress = _scrollController.position.pixels / maxExtent;
    if (progress >= 0.75) {
      ref
          .read(devotionalDetailControllerProvider.notifier)
          .reportReadComplete();
    }
  }

  Future<void> _loadDetail() async {
    final deviceId = await ref
        .read(appRuntimeStorageProvider)
        .getOrCreateDeviceId();
    if (!mounted) return;

    await ref
        .read(devotionalDetailControllerProvider.notifier)
        .load(
          widget.devotionalId,
          deliveryToken: widget.initialDeliveryToken,
          shareToken: widget.initialShareToken,
          deviceId: deviceId,
        );
  }

  Future<void> _share(Devotional devotional) async {
    final detailState = ref.read(devotionalDetailControllerProvider);
    final result = await ref
        .read(devotionalsRepositoryProvider)
        .shareDevotional(
          devotional.id,
          deliveryToken: detailState.deliveryToken,
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

    Share.share(
      shareText,
      subject: context.l10n.shareDevotional,
      sharePositionOrigin: origin,
    );

    await ref
        .read(devotionalDetailControllerProvider.notifier)
        .registerShare(shareCount: result.shareCount);
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

  bool get _canModerateCurrentDevotional {
    final devotional = ref.read(devotionalDetailControllerProvider).devotional;
    return devotional?.canModerate == true &&
        devotional?.moderationStatus.name == 'underReview';
  }

  Future<void> _refreshCollections() async {
    await Future.wait([
      ref.read(devotionalReviewQueueControllerProvider.notifier).refresh(),
      ref.read(devotionalsListControllerProvider.notifier).refresh(),
      ref.read(forYouFeedControllerProvider.notifier).refresh(),
      ref.read(followingFeedControllerProvider.notifier).refresh(),
    ]);
  }

  Future<void> _approveReview() async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.midnightFaithDark,
        title: Text(
          'Aprobar devocional',
          style: AppTextStyles.headline3.copyWith(color: AppColors.pureWhite),
        ),
        content: Text(
          'Este devocional volverá a quedar disponible para lectura pública.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.softMist),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );

    if (!mounted || approved != true) return;

    final success = await ref
        .read(devotionalDetailControllerProvider.notifier)
        .approveReview();
    if (!mounted) return;

    if (success) {
      await _refreshCollections();
    }
    if (!mounted) return;

    final message = success
        ? 'Devocional aprobado correctamente.'
        : AppErrorMapper.toMessage(
            Exception('approve-review'),
            l10n: context.l10n,
            fallbackMessage:
                ref.read(devotionalDetailControllerProvider).errorMessage ??
                'No se pudo aprobar el devocional.',
          );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppColors.holyGold : Colors.red.shade700,
      ),
    );
  }

  Future<void> _restrictReview() async {
    final reasonController = TextEditingController();
    final reason = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.midnightFaith,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        return SafeArea(
          top: false,
          child: Padding(
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
                  'Ocultar devocional',
                  style: AppTextStyles.headline3.copyWith(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Explica por qué se retira de la visibilidad pública.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.softMist,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: reasonController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Motivo para ocultar el devocional',
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
                    onPressed: () {
                      final value = reasonController.text.trim();
                      if (value.isEmpty) return;
                      Navigator.of(context).pop(value);
                    },
                    child: const Text('Ocultar devocional'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    reasonController.dispose();

    if (!mounted || reason == null || reason.isEmpty) return;

    final success = await ref
        .read(devotionalDetailControllerProvider.notifier)
        .restrictReview(reason);
    if (!mounted) return;

    if (success) {
      await _refreshCollections();
    }
    if (!mounted) return;

    final message = success
        ? 'Devocional ocultado correctamente.'
        : AppErrorMapper.toMessage(
            Exception('restrict-review'),
            l10n: context.l10n,
            fallbackMessage:
                ref.read(devotionalDetailControllerProvider).errorMessage ??
                'No se pudo restringir el devocional.',
          );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppColors.holyGold : Colors.red.shade700,
      ),
    );
  }

  Future<void> _blockAuthor() async {
    final devotional = ref.read(devotionalDetailControllerProvider).devotional;
    final recommendation = devotional?.authorBlockRecommendation;
    if (devotional == null || recommendation == null || _isBlockingAuthor) {
      return;
    }

    final reasonController = TextEditingController();
    final reason = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.midnightFaith,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        return SafeArea(
          top: false,
          child: Padding(
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
                  'Bloquear autor',
                  style: AppTextStyles.headline3.copyWith(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Este autor suma ${recommendation.restrictedDevotionalsCountLast30Days} devocionales restringidos en ${recommendation.windowDays} días. Escribe el motivo del bloqueo.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.softMist,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: reasonController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Motivo del bloqueo',
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
                      borderSide: BorderSide(
                        color: Colors.red.shade400,
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
                    onPressed: () {
                      final value = reasonController.text.trim();
                      if (value.isEmpty) return;
                      Navigator.of(context).pop(value);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: AppColors.pureWhite,
                    ),
                    child: const Text('Bloquear autor'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    reasonController.dispose();

    if (!mounted || reason == null || reason.isEmpty) return;

    setState(() => _isBlockingAuthor = true);
    try {
      await ref
          .read(roleRepositoryProvider)
          .blockUser(userId: devotional.author.id, reason: reason);
      await _loadDetail();
      await _refreshCollections();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Autor bloqueado correctamente.'),
          backgroundColor: AppColors.holyGold,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppErrorMapper.toMessage(
              error,
              l10n: context.l10n,
              fallbackMessage: 'No se pudo bloquear al autor.',
              businessCodeMessages: const {
                'BLOCK_REASON_REQUIRED': 'Debes indicar el motivo del bloqueo',
                'USER_ALREADY_BLOCKED': 'El autor ya está bloqueado',
                'USER_NOT_FOUND': 'No se encontró el autor',
                'FORBIDDEN': 'No tienes permisos para bloquear usuarios',
              },
            ),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isBlockingAuthor = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(devotionalDetailControllerProvider);
    final commentsState = ref.watch(devotionalCommentsControllerProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final hasCoverImage =
        state.devotional?.coverImageUrl != null &&
        state.devotional!.coverImageUrl!.isNotEmpty;

    ref.listen<bool>(
      devotionalDetailControllerProvider.select(
        (s) => s.readCompleteJustSucceeded,
      ),
      (_, justSucceeded) {
        if (!justSucceeded) return;
        ref
            .read(devotionalDetailControllerProvider.notifier)
            .acknowledgeReadComplete();
        ref.read(forYouFeedControllerProvider.notifier).refreshHeader();
      },
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _lightTopOverlayStyle,
      child: Scaffold(
        backgroundColor: AppColors.midnightFaith,
        extendBodyBehindAppBar: hasCoverImage,
        appBar: AppBar(
          backgroundColor: hasCoverImage
              ? Colors.transparent
              : AppColors.midnightFaith,
          foregroundColor: AppColors.pureWhite,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          systemOverlayStyle: _lightTopOverlayStyle,
          leading: const BackButton(),
          title: null,
          centerTitle: false,
          actionsPadding: const EdgeInsets.only(right: AppSpacing.xs),
          actions: state.devotional == null
              ? null
              : [
                  PopupMenuButton<_DetailMenuAction>(
                    icon: const Icon(Icons.more_horiz_rounded),
                    tooltip: context.l10n.devotionalReportAction,
                    color: AppColors.midnightFaithDark,
                    surfaceTintColor: Colors.transparent,
                    onSelected: (value) {
                      if (value == _DetailMenuAction.report) {
                        _showReportSheet();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<_DetailMenuAction>(
                        value: _DetailMenuAction.report,
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
        bottomNavigationBar: _canModerateCurrentDevotional
            ? _ReviewActionBar(
                isApproving: state.isApprovingReview,
                isRestricting: state.isRestrictingReview,
                onApprove: _approveReview,
                onRestrict: _restrictReview,
              )
            : null,
        body: SafeArea(
          top: false,
          child: switch (state.status) {
            DevotionalDetailStatus.loading => const Center(
              child: CircularProgressIndicator(color: AppColors.holyGold),
            ),
            DevotionalDetailStatus.error => _DetailError(
              message: state.errorMessage ?? context.l10n.genericError,
              onRetry: () {
                _loadDetail();
              },
            ),
            _ => _DetailContent(
              devotional: state.devotional,
              commentsState: commentsState,
              commentController: _commentController,
              scrollController: _scrollController,
              isTogglingLike: state.isTogglingLike,
              isTogglingSave: state.isTogglingSave,
              onRefresh: () async {
                await _loadDetail();
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
              onSubmitComment: _submitComment,
              isAdmin: isAdmin,
              isBlockingAuthor: _isBlockingAuthor,
              onBlockAuthor: _blockAuthor,
              onOpenAuthor: () async {
                final authorId = state.devotional?.author.id;
                if (authorId == null || authorId.isEmpty) return;
                await context.push('/users/$authorId');
              },
            ),
          },
        ),
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
    required this.isTogglingLike,
    required this.isTogglingSave,
    required this.onRefresh,
    required this.onToggleLike,
    required this.onToggleSave,
    required this.onShare,
    required this.onSubmitComment,
    required this.isAdmin,
    required this.isBlockingAuthor,
    required this.onBlockAuthor,
    required this.onOpenAuthor,
  });

  final Devotional? devotional;
  final DevotionalCommentsState commentsState;
  final TextEditingController commentController;
  final ScrollController scrollController;
  final bool isTogglingLike;
  final bool isTogglingSave;
  final Future<void> Function() onRefresh;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleSave;
  final Future<void> Function(Devotional devotional) onShare;
  final Future<void> Function() onSubmitComment;
  final bool isAdmin;
  final bool isBlockingAuthor;
  final Future<void> Function() onBlockAuthor;
  final Future<void> Function() onOpenAuthor;

  @override
  Widget build(BuildContext context) {
    final devotional = this.devotional;
    if (devotional == null) {
      return const SizedBox.shrink();
    }
    final referenceLabel = _referenceLabel(devotional);
    final continuityLabel = devotionalDetailContinuityLabel(
      context.l10n,
      devotional,
    );
    final hasContent =
        devotional.content != null && devotional.content!.isNotEmpty;
    final commentsHeading = commentsState.total > 0
        ? '${context.l10n.commentsLabel} (${commentsState.total})'
        : context.l10n.commentsLabel;
    final hasCoverImage =
        devotional.coverImageUrl != null &&
        devotional.coverImageUrl!.isNotEmpty;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          if (hasCoverImage)
            _DetailHero(
              imageUrl: devotional.coverImageUrl!,
              focusY: devotional.coverImageFocusY,
            ),
          Padding(
            key: const Key('devotional-detail-content'),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              hasCoverImage ? AppSpacing.lg : AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        backgroundColor: AppColors.holyGold.withValues(
                          alpha: 0.18,
                        ),
                        backgroundImage:
                            devotional.author.avatarUrl != null &&
                                devotional.author.avatarUrl!.isNotEmpty
                            ? CachedNetworkImageProvider(
                                devotional.author.avatarUrl!,
                              )
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
                if (referenceLabel != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    referenceLabel,
                    style: AppTextStyles.reference.copyWith(
                      color: AppColors.holyGold.withValues(alpha: 0.92),
                    ),
                  ),
                ],
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
                if (devotional.authorBlockRecommendation != null &&
                    devotional.canModerate &&
                    devotional.moderationStatus.name == 'underReview') ...[
                  const SizedBox(height: AppSpacing.md),
                  _AuthorBlockRecommendationCard(
                    devotional: devotional,
                    isAdmin: isAdmin,
                    isBlockingAuthor: isBlockingAuthor,
                    onBlockAuthor: onBlockAuthor,
                  ),
                ],
                if (hasContent) ...[
                  const SizedBox(height: AppSpacing.lg),
                  if (continuityLabel != null) ...[
                    Text(
                      continuityLabel,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.softMist.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  DevotionalContentView(
                    content: devotional.content!,
                    emphasizeLeadingParagraph: true,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    context.l10n.devotionalReflectionPrompt,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.softMist.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ] else ...[
                  const SizedBox(height: AppSpacing.lg),
                ],
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _PrimarySaveActionButton(
                      isSaved: devotional.saved,
                      isLoading: isTogglingSave,
                      onPressed: isTogglingSave ? null : onToggleSave,
                      label: devotional.saved
                          ? context.l10n.savedAction
                          : context.l10n.saveAction,
                    ),
                    _SecondaryActionButton(
                      onPressed: isTogglingLike ? null : onToggleLike,
                      icon: devotional.liked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      label: _actionLabel(
                        context.l10n.likesLabel,
                        devotional.likesCount,
                      ),
                      active: devotional.liked,
                      isLoading: isTogglingLike,
                    ),
                    _SecondaryActionButton(
                      onPressed: () => onShare(devotional),
                      icon: Icons.share_outlined,
                      label: _actionLabel(
                        context.l10n.shareDevotional,
                        devotional.shareCount,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  commentsHeading,
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
                      icon: const Icon(
                        Icons.send_rounded,
                        color: AppColors.holyGold,
                      ),
                    ),
                  ),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.pureWhite,
                  ),
                ),
                if (commentsState.items.isEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
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
                  ),
                ] else ...[
                  const SizedBox(height: AppSpacing.md),
                ],
                ...commentsState.items.map(
                  (comment) => _CommentItem(comment: comment),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailHero extends StatelessWidget {
  const _DetailHero({required this.imageUrl, required this.focusY});

  final String imageUrl;
  final double focusY;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final heroHeight = topInset + kToolbarHeight + _detailCoverImageHeight;

    return SizedBox(
      key: const Key('devotional-detail-hero'),
      height: heroHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            key: const Key('devotional-detail-hero-image'),
            imageUrl: imageUrl,
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
                stops: const [0, 0.3, 1],
                colors: [
                  Colors.black.withValues(alpha: 0.42),
                  Colors.black.withValues(alpha: 0.14),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimarySaveActionButton extends StatelessWidget {
  const _PrimarySaveActionButton({
    required this.isSaved,
    required this.isLoading,
    required this.onPressed,
    required this.label,
  });

  final bool isSaved;
  final bool isLoading;
  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final inactiveForeground = AppColors.holyGold;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 170),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
        gradient: LinearGradient(
          colors: isSaved
              ? [
                  AppColors.holyGold.withValues(alpha: 0.94),
                  const Color(0xFFE7C565),
                ]
              : [
                  AppColors.holyGold.withValues(alpha: 0.16),
                  AppColors.holyGold.withValues(alpha: 0.1),
                ],
        ),
        border: Border.all(
          color: AppColors.holyGold.withValues(alpha: isSaved ? 0.24 : 0.12),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppBorderRadius.full),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isSaved
                            ? AppColors.midnightFaithDark
                            : inactiveForeground,
                      ),
                    ),
                  )
                else
                  Icon(
                    isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    size: 17,
                    color: isSaved
                        ? AppColors.midnightFaithDark
                        : inactiveForeground,
                  ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isSaved
                        ? AppColors.midnightFaithDark
                        : inactiveForeground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.active = false,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final bool active;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = active
        ? AppColors.holyGold
        : AppColors.pureWhite.withValues(alpha: 0.82);

    return Material(
      color: AppColors.pureWhite.withValues(alpha: active ? 0.08 : 0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
        side: BorderSide(
          color: active
              ? AppColors.holyGold.withValues(alpha: 0.22)
              : AppColors.pureWhite.withValues(alpha: 0.08),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                  ),
                )
              else
                Icon(icon, size: 18, color: foregroundColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _actionLabel(String baseLabel, int count) {
  if (count <= 0) {
    return baseLabel;
  }

  return '$baseLabel $count';
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

class _DetailStatusPill extends StatelessWidget {
  const _DetailStatusPill({required this.label, this.isDanger = false});

  final String label;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? Colors.red.shade300 : AppColors.holyGold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.2)),
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

class _DetailMetaChip extends StatelessWidget {
  const _DetailMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.pureWhite.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.softMist),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.softMist),
          ),
        ],
      ),
    );
  }
}

class _AuthorBlockRecommendationCard extends StatelessWidget {
  const _AuthorBlockRecommendationCard({
    required this.devotional,
    required this.isAdmin,
    required this.isBlockingAuthor,
    required this.onBlockAuthor,
  });

  final Devotional devotional;
  final bool isAdmin;
  final bool isBlockingAuthor;
  final Future<void> Function() onBlockAuthor;

  @override
  Widget build(BuildContext context) {
    final recommendation = devotional.authorBlockRecommendation!;
    final shouldSuggestBlocking = recommendation.shouldSuggestBlocking;
    final summary =
        '${recommendation.restrictedDevotionalsCountLast30Days} devocionales restringidos en los últimos ${recommendation.windowDays} días.';
    final title = recommendation.authorIsBlocked
        ? 'Autor ya bloqueado'
        : shouldSuggestBlocking
        ? 'Se recomienda bloquear al autor'
        : 'Seguimiento del autor';
    final description = recommendation.authorIsBlocked
        ? 'La cuenta del autor ya tiene un bloqueo activo. Puedes ocultar este devocional sin repetir la acción sobre la cuenta.'
        : shouldSuggestBlocking
        ? '$summary Este umbral alcanzó la política actual de bloqueo manual.'
        : '$summary Aún no alcanza el umbral de ${recommendation.threshold} restricciones.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: shouldSuggestBlocking
            ? Colors.red.shade900.withValues(alpha: 0.22)
            : AppColors.inputBackground,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(
          color: shouldSuggestBlocking
              ? Colors.red.shade300.withValues(alpha: 0.3)
              : AppColors.pureWhite.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.pureWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            description,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.softMist.withValues(alpha: 0.88),
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _DetailMetaChip(
                icon: Icons.flag_outlined,
                label:
                    '${recommendation.restrictedDevotionalsCountLast30Days}/${recommendation.threshold}',
              ),
              _DetailMetaChip(
                icon: Icons.calendar_today_outlined,
                label: '${recommendation.windowDays} días',
              ),
              if (recommendation.authorIsBlocked)
                const _DetailStatusPill(
                  label: 'Autor bloqueado',
                  isDanger: true,
                )
              else if (shouldSuggestBlocking)
                const _DetailStatusPill(
                  label: 'Sugerencia de bloqueo',
                  isDanger: true,
                )
              else
                const _DetailStatusPill(label: 'Solo informativo'),
            ],
          ),
          if (isAdmin && shouldSuggestBlocking) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isBlockingAuthor ? null : () => onBlockAuthor(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: AppColors.pureWhite,
                ),
                child: isBlockingAuthor
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Bloquear autor'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewActionBar extends StatelessWidget {
  const _ReviewActionBar({
    required this.isApproving,
    required this.isRestricting,
    required this.onApprove,
    required this.onRestrict,
  });

  final bool isApproving;
  final bool isRestricting;
  final Future<void> Function() onApprove;
  final Future<void> Function() onRestrict;

  @override
  Widget build(BuildContext context) {
    final isBusy = isApproving || isRestricting;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.midnightFaithDark,
          border: Border(
            top: BorderSide(color: AppColors.pureWhite.withValues(alpha: 0.08)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isBusy ? null : () => onRestrict(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warning,
                  side: const BorderSide(color: AppColors.warning),
                ),
                child: isRestricting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Ocultar'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ElevatedButton(
                onPressed: isBusy ? null : () => onApprove(),
                child: isApproving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.midnightFaith,
                        ),
                      )
                    : const Text('Aprobar'),
              ),
            ),
          ],
        ),
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
