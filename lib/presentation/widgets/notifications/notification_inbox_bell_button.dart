import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/presentation/state/notifications/notification_unread_count_controller.dart';

class NotificationInboxBellButton extends ConsumerWidget {
  const NotificationInboxBellButton({
    super.key,
    this.iconColor = AppColors.pureWhite,
  });

  final Color iconColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(notificationUnreadCountControllerProvider);
    final count = unreadCount.asData?.value ?? 0;

    return IconButton(
      tooltip: 'Notificaciones',
      onPressed: () async {
        await context.push('/notifications');
        if (!context.mounted) return;
        await ref
            .read(notificationUnreadCountControllerProvider.notifier)
            .refresh();
      },
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.notifications_none_rounded, color: iconColor),
          if (count > 0)
            Positioned(
              right: -5,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.holyGold,
                  borderRadius: BorderRadius.circular(999),
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Center(
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: AppColors.midnightFaithDark,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
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
