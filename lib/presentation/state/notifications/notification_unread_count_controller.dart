import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/data/notifications/notification_inbox_repository.dart';

class NotificationUnreadCountController extends AsyncNotifier<int> {
  @override
  Future<int> build() {
    return ref.read(notificationInboxRepositoryProvider).fetchUnreadCount();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(notificationInboxRepositoryProvider).fetchUnreadCount(),
    );
  }

  void decrement() {
    final currentValue = state.asData?.value;
    if (currentValue == null) {
      return;
    }

    state = AsyncValue.data(currentValue > 0 ? currentValue - 1 : 0);
  }

  void clear() {
    state = const AsyncValue.data(0);
  }
}

final notificationUnreadCountControllerProvider =
    AsyncNotifierProvider<NotificationUnreadCountController, int>(
      NotificationUnreadCountController.new,
    );
