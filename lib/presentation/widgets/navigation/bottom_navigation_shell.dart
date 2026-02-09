import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';
import 'package:holyverso/presentation/providers/navigation_provider.dart';

class BottomNavigationShell extends ConsumerStatefulWidget {
  const BottomNavigationShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<BottomNavigationShell> createState() =>
      _BottomNavigationShellState();
}

class _BottomNavigationShellState
    extends ConsumerState<BottomNavigationShell> {
  ProviderSubscription<int>? _navigationListener;

  @override
  void initState() {
    super.initState();
    _syncProviderWithShell();
    _navigationListener = ref.listenManual<int>(
      bottomNavigationIndexProvider,
      (previous, next) {
        if (next != widget.navigationShell.currentIndex) {
          widget.navigationShell.goBranch(next);
        }
      },
    );
  }

  @override
  void didUpdateWidget(covariant BottomNavigationShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncProviderWithShell();
  }

  @override
  void dispose() {
    _navigationListener?.close();
    super.dispose();
  }

  void _syncProviderWithShell() {
    final currentIndex = widget.navigationShell.currentIndex;
    final providerIndex = ref.read(bottomNavigationIndexProvider);
    if (providerIndex != currentIndex) {
      ref
          .read(bottomNavigationIndexProvider.notifier)
          .setIndex(currentIndex);
    }
  }

  void _onTap(int index) {
    final currentIndex = widget.navigationShell.currentIndex;
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == currentIndex,
    );
    ref.read(bottomNavigationIndexProvider.notifier).setIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currentIndex = ref.watch(bottomNavigationIndexProvider);

    return Scaffold(
      backgroundColor: AppColors.midnightFaith,
      body: widget.navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.midnightFaith,
        selectedItemColor: AppColors.holyGold,
        unselectedItemColor: AppColors.softMist.withValues(alpha: 0.65),
        selectedLabelStyle: AppTextStyles.labelSmall.copyWith(
          color: AppColors.holyGold,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.labelSmall.copyWith(
          color: AppColors.softMist.withValues(alpha: 0.7),
          fontWeight: FontWeight.w500,
        ),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_rounded),
            label: l10n.navHomeLabel,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search_rounded),
            label: l10n.navSearchLabel,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_rounded),
            label: l10n.navSettingsLabel,
          ),
        ],
      ),
    );
  }
}
