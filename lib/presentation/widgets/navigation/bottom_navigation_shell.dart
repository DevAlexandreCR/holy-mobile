import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';
import 'package:holyverso/presentation/providers/navigation_provider.dart';
import 'package:holyverso/presentation/state/roles/role_provider.dart';

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
  void dispose() {
    _navigationListener?.close();
    super.dispose();
  }

  void _onTap(int branchIndex) {
    final currentIndex = widget.navigationShell.currentIndex;
    widget.navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == currentIndex,
    );
    ref.read(bottomNavigationIndexProvider.notifier).setIndex(branchIndex);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currentBranchIndex = widget.navigationShell.currentIndex;
    final canManageUsers = ref.watch(canManageUsersProvider);
    final items = _buildItems(l10n, canManageUsers);
    final currentIndex = items.indexWhere(
      (item) => item.branchIndex == currentBranchIndex,
    );

    return Scaffold(
      backgroundColor: AppColors.midnightFaith,
      body: widget.navigationShell,
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: AppColors.holyGold.withValues(alpha: 0.18),
          highlightColor: AppColors.holyGold.withValues(alpha: 0.08),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex < 0 ? 0 : currentIndex,
          onTap: (index) => _onTap(items[index].branchIndex),
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
          items: items
              .map(
                (item) => BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  activeIcon: _ActiveNavIcon(icon: item.icon),
                  label: item.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _ActiveNavIcon extends StatelessWidget {
  const _ActiveNavIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.holyGold.withValues(alpha: 0.22),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Icon(icon),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.branchIndex,
    required this.icon,
    required this.label,
  });

  final int branchIndex;
  final IconData icon;
  final String label;
}

List<_NavItem> _buildItems(AppLocalizations l10n, bool canManageUsers) {
  final items = [
    _NavItem(
      branchIndex: 0,
      icon: Icons.home_rounded,
      label: l10n.navHomeLabel,
    ),
    _NavItem(
      branchIndex: 2,
      icon: Icons.bookmark_rounded,
      label: l10n.navSavedLabel,
    ),
    _NavItem(
      branchIndex: 1,
      icon: Icons.search_rounded,
      label: l10n.navSearchLabel,
    ),
  ];

  if (canManageUsers) {
    items.add(
      _NavItem(
        branchIndex: 4,
        icon: Icons.people_alt_rounded,
        label: l10n.navUsersLabel,
      ),
    );
  }

  items.add(
    _NavItem(
      branchIndex: 3,
      icon: Icons.settings_rounded,
      label: l10n.navSettingsLabel,
    ),
  );

  return items;
}
