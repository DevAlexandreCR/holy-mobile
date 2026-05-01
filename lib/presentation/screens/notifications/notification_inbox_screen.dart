import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_design_tokens.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';
import 'package:holyverso/domain/notifications/notification_inbox_item.dart';
import 'package:holyverso/presentation/state/notifications/notification_inbox_controller.dart';
import 'package:holyverso/presentation/state/notifications/notification_inbox_state.dart';
import 'package:holyverso/presentation/widgets/common/holy_child_app_bar.dart';

class NotificationInboxScreen extends ConsumerStatefulWidget {
  const NotificationInboxScreen({super.key});

  @override
  ConsumerState<NotificationInboxScreen> createState() =>
      _NotificationInboxScreenState();
}

class _NotificationInboxScreenState
    extends ConsumerState<NotificationInboxScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(notificationInboxControllerProvider.notifier).load());
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      unawaited(
        ref.read(notificationInboxControllerProvider.notifier).loadMore(),
      );
    }
  }

  Future<void> _openNotification(NotificationInboxItem item) async {
    await ref
        .read(notificationInboxControllerProvider.notifier)
        .markItemRead(item, opened: true);

    if (!mounted) {
      return;
    }

    final destination = item.destination;
    if (destination == null) {
      return;
    }

    if (destination.type == NotificationInboxDestinationType.creatorProfile &&
        destination.creatorId != null &&
        destination.creatorId!.isNotEmpty) {
      context.go('/users/${destination.creatorId}');
      return;
    }

    if (destination.devotionalId != null &&
        destination.devotionalId!.isNotEmpty) {
      context.go('/devotionals/${destination.devotionalId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationInboxControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.midnightFaith,
      appBar: HolyChildAppBar(
        title: 'Notificaciones',
        actions: [
          IconButton(
            tooltip: 'Marcar todo como leído',
            onPressed: state.items.isEmpty || state.isMarkingAllRead
                ? null
                : () => ref
                      .read(notificationInboxControllerProvider.notifier)
                      .markAllRead(),
            icon: state.isMarkingAllRead
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.holyGold,
                    ),
                  )
                : const Icon(Icons.done_all_rounded),
          ),
        ],
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  0,
                ),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Todas',
                      selected: state.filter == NotificationInboxFilter.all,
                      onTap: () => ref
                          .read(notificationInboxControllerProvider.notifier)
                          .setFilter(NotificationInboxFilter.all),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _FilterChip(
                      label: 'No leídas',
                      selected: state.filter == NotificationInboxFilter.unread,
                      onTap: () => ref
                          .read(notificationInboxControllerProvider.notifier)
                          .setFilter(NotificationInboxFilter.unread),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.holyGold,
                  backgroundColor: AppColors.midnightFaith,
                  onRefresh: () => ref
                      .read(notificationInboxControllerProvider.notifier)
                      .refresh(),
                  child: _NotificationInboxBody(
                    state: state,
                    scrollController: _scrollController,
                    onOpen: _openNotification,
                    onRetry: () => ref
                        .read(notificationInboxControllerProvider.notifier)
                        .load(force: true),
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

class _NotificationInboxBody extends StatelessWidget {
  const _NotificationInboxBody({
    required this.state,
    required this.scrollController,
    required this.onOpen,
    required this.onRetry,
  });

  final NotificationInboxState state;
  final ScrollController scrollController;
  final Future<void> Function(NotificationInboxItem item) onOpen;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.holyGold),
      );
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _InboxEmptyState(
            title: 'No pudimos cargar tus notificaciones',
            subtitle: state.errorMessage!,
            actionLabel: 'Intentar de nuevo',
            onTap: onRetry,
          ),
        ],
      );
    }

    if (state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _InboxEmptyState(
            title: state.filter == NotificationInboxFilter.unread
                ? 'No tienes notificaciones sin leer'
                : 'Aún no tienes actividad',
            subtitle: state.filter == NotificationInboxFilter.unread
                ? 'Cuando llegue algo nuevo, aparecerá aquí.'
                : 'Cuando tu comunidad interactúe con tus devocionales, lo verás aquí.',
          ),
        ],
      );
    }

    return ListView.separated(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      itemBuilder: (context, index) {
        if (index == state.items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.holyGold),
            ),
          );
        }

        final item = state.items[index];
        return _InboxCard(item: item, onTap: () => onOpen(item));
      },
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
    );
  }
}

class _InboxCard extends StatelessWidget {
  const _InboxCard({required this.item, required this.onTap});

  final NotificationInboxItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final leadActor = item.actorPreview.isNotEmpty
        ? item.actorPreview.first
        : null;
    final previewImage = item.imageUrl ?? item.devotional?.imageUrl;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: item.isRead
                ? AppColors.midnightFaith.withValues(alpha: 0.62)
                : AppColors.midnightFaith.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            border: Border.all(
              color: item.isRead
                  ? AppColors.softMist.withValues(alpha: 0.12)
                  : AppColors.holyGold.withValues(alpha: 0.34),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InboxActorAvatar(
                leadActor: leadActor,
                unread: !item.isRead,
                extraActors: item.aggregateCount > 1
                    ? item.aggregateCount - 1
                    : 0,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.pureWhite,
                              fontSize: 17,
                              height: 1.1,
                              fontWeight: item.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          _formatRelativeTime(item.createdAt),
                          style: AppTextStyles.labelSmall.copyWith(
                            fontSize: 11,
                            color: AppColors.softMist.withValues(alpha: 0.74),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.softMist.withValues(alpha: 0.94),
                        fontSize: 12.5,
                        height: 1.25,
                      ),
                    ),
                    if (item.devotional?.title != null &&
                        item.devotional!.title.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.devotional!.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.holyGold,
                          fontSize: 13,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (previewImage != null && previewImage.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  child: CachedNetworkImage(
                    imageUrl: previewImage,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    placeholder: (context, _) => Container(
                      width: 44,
                      height: 44,
                      color: AppColors.midnightFaithDark,
                    ),
                    errorWidget: (context, _, _) => Container(
                      width: 44,
                      height: 44,
                      color: AppColors.midnightFaithDark,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.softMist,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InboxActorAvatar extends StatelessWidget {
  const _InboxActorAvatar({
    required this.leadActor,
    required this.unread,
    required this.extraActors,
  });

  final NotificationInboxActorPreview? leadActor;
  final bool unread;
  final int extraActors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: unread
                    ? AppColors.holyGold
                    : AppColors.softMist.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: ClipOval(
              child:
                  leadActor?.avatarUrl != null &&
                      leadActor!.avatarUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: leadActor!.avatarUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (context, _, _) =>
                          _AvatarFallback(label: leadActor?.name),
                    )
                  : _AvatarFallback(label: leadActor?.name),
            ),
          ),
          if (extraActors > 0)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.holyGold,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.midnightFaithDark,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    '+$extraActors',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.midnightFaithDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 8,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final initial = (label?.trim().isNotEmpty ?? false)
        ? label!.trim().characters.first.toUpperCase()
        : '?';

    return Container(
      color: AppColors.midnightFaithDark,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.holyGold,
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _InboxEmptyState extends StatelessWidget {
  const _InboxEmptyState({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.midnightFaith.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.softMist.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.notifications_off_outlined,
            color: AppColors.holyGold,
            size: 34,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.headline2.copyWith(
              color: AppColors.pureWhite,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.softMist.withValues(alpha: 0.86),
              height: 1.4,
            ),
          ),
          if (actionLabel != null && onTap != null) ...[
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.holyGold,
                foregroundColor: AppColors.midnightFaithDark,
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.holyGold
              : AppColors.midnightFaithDark.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(AppBorderRadius.full),
          border: Border.all(
            color: selected
                ? AppColors.holyGold
                : AppColors.softMist.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: selected
                ? AppColors.midnightFaithDark
                : AppColors.softMist.withValues(alpha: 0.9),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

String _formatRelativeTime(DateTime value) {
  final diff = DateTime.now().difference(value);

  if (diff.inMinutes < 1) {
    return 'Ahora';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes} min';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours} h';
  }
  if (diff.inDays < 7) {
    return '${diff.inDays} d';
  }

  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month';
}
