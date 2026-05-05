import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';
import 'package:holyverso/core/services/version_detector_service.dart';
import 'package:holyverso/domain/models/release_note.dart';
import 'package:holyverso/presentation/providers/navigation_provider.dart';
import 'package:holyverso/presentation/providers/whats_new_provider.dart';
import 'package:holyverso/presentation/state/auth/auth_controller.dart';
import 'package:holyverso/presentation/widgets/dialogs/whats_new_dialog.dart';

const SystemUiOverlayStyle _bottomNavigationOverlayStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarColor: AppColors.midnightFaith,
  systemNavigationBarIconBrightness: Brightness.light,
);

class BottomNavigationShell extends ConsumerStatefulWidget {
  const BottomNavigationShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<BottomNavigationShell> createState() =>
      _BottomNavigationShellState();
}

class _BottomNavigationShellState extends ConsumerState<BottomNavigationShell> {
  ProviderSubscription<int>? _navigationListener;
  ProviderSubscription<AsyncValue<ReleaseNote?>>? _whatsNewListener;
  bool _whatsNewHandled = false;

  @override
  void initState() {
    super.initState();
    _navigationListener = ref.listenManual<int>(bottomNavigationIndexProvider, (
      previous,
      next,
    ) {
      if (next != widget.navigationShell.currentIndex) {
        widget.navigationShell.goBranch(next);
      }
    });
    _whatsNewListener = ref.listenManual<AsyncValue<ReleaseNote?>>(
      whatsNewProvider,
      (previous, next) {
        next.whenData((note) {
          if (note == null || _whatsNewHandled) {
            return;
          }
          _whatsNewHandled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _showWhatsNewDialog(note);
          });
        });
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _navigationListener?.close();
    _whatsNewListener?.close();
    super.dispose();
  }

  Future<void> _showWhatsNewDialog(ReleaseNote note) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) =>
          Center(child: WhatsNewDialog(releaseNote: note)),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );

    if (!mounted) return;
    await ref.read(versionDetectorServiceProvider).markVersionAsSeen();
  }

  void _onTap(int branchIndex) {
    final currentIndex = widget.navigationShell.currentIndex;
    widget.navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == currentIndex,
    );
    ref.read(bottomNavigationIndexProvider.notifier).setIndex(branchIndex);
  }

  bool _shouldShowLabels(BuildContext context, List<_NavItem> items) {
    if (items.isEmpty) return false;
    final mediaQuery = MediaQuery.of(context);
    final availableWidth =
        mediaQuery.size.width -
        mediaQuery.padding.left -
        mediaQuery.padding.right;
    final perItemWidth = availableWidth / items.length;
    const horizontalPadding = 12.0;
    final maxLabelWidth = items
        .map((item) {
          final painter = TextPainter(
            text: TextSpan(text: item.label, style: AppTextStyles.labelSmall),
            maxLines: 1,
            textDirection: Directionality.of(context),
          )..layout();
          return painter.size.width;
        })
        .fold<double>(0, (max, value) => value > max ? value : max);

    return maxLabelWidth <= perItemWidth - horizontalPadding;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currentBranchIndex = widget.navigationShell.currentIndex;
    final canManageUsers =
        ref
            .watch(authControllerProvider.select((state) => state.user?.role))
            ?.canManageUsers ??
        false;
    final items = _buildItems(l10n, canManageUsers);
    final currentIndex = items.indexWhere(
      (item) => item.branchIndex == currentBranchIndex,
    );
    final showLabels = _shouldShowLabels(context, items);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _bottomNavigationOverlayStyle,
      child: Scaffold(
        backgroundColor: AppColors.midnightFaith,
        body: widget.navigationShell,
        bottomNavigationBar: Theme(
          data: Theme.of(context).copyWith(
            splashColor: AppColors.holyGold.withValues(alpha: 0.12),
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            splashFactory:
                Theme.of(context).platform == TargetPlatform.iOS ||
                    Theme.of(context).platform == TargetPlatform.macOS
                ? InkSparkle.splashFactory
                : Theme.of(context).splashFactory,
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
            showSelectedLabels: showLabels,
            showUnselectedLabels: showLabels,
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
      branchIndex: 5,
      icon: Icons.menu_book_rounded,
      label: l10n.navDevotionalsLabel,
    ),
    _NavItem(
      branchIndex: 0,
      icon: Icons.auto_awesome_rounded,
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
      icon: Icons.person_rounded,
      label: l10n.navProfileLabel,
    ),
  );

  return items;
}
