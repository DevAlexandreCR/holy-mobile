import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/core/services/phase_three_runtime_service.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_design_tokens.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';
import 'package:holyverso/data/auth/models/user_settings.dart';
import 'package:holyverso/data/bible/models/bible_version.dart';
import 'package:holyverso/domain/roles/user_role.dart';
import 'package:holyverso/presentation/state/auth/auth_controller.dart';
import 'package:holyverso/presentation/state/roles/role_provider.dart';
import 'package:holyverso/presentation/state/settings/versions_controller.dart';
import 'package:holyverso/presentation/state/settings/versions_state.dart';
import 'package:holyverso/presentation/widgets/section_card.dart';
import 'package:holyverso/presentation/widgets/setting_tile.dart';
import 'package:holyverso/presentation/widgets/common/holy_bottom_sheet.dart';
import 'package:holyverso/presentation/widgets/common/holy_child_app_bar.dart';
import 'package:holyverso/presentation/widgets/legal/legal_links_section.dart';
import 'package:holyverso/presentation/widgets/users/role_badge.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, this.showBackButton = false});

  final bool showBackButton;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isAppInfoLoading = true;
  String? _appVersion;
  String? _buildNumber;
  bool _isDeletingAccount = false;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(versionsControllerProvider.notifier).loadVersions();
      ref
          .read(authControllerProvider.notifier)
          .refreshNotificationPreferences();
    });
  }

  Future<void> _loadAppInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;

      setState(() {
        _appVersion = info.version;
        _buildNumber = info.buildNumber;
        _isAppInfoLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isAppInfoLoading = false);
    }
  }

  Future<void> _onChangeVersion(int versionId) async {
    final l10n = context.l10n;
    final notifier = ref.read(versionsControllerProvider.notifier);
    final success = await notifier.selectVersion(versionId);
    if (!mounted) return;

    final authState = ref.read(authControllerProvider);
    final message = success
        ? l10n.versionsUpdateSuccess
        : authState.errorMessage ?? l10n.versionsUpdateError;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  BibleVersion? _selectedVersion(VersionsState versionsState, int? selectedId) {
    if (selectedId == null) return null;
    for (final version in versionsState.versions) {
      if (version.id == selectedId) return version;
    }
    return null;
  }

  PreferredSizeWidget _buildAppBar() {
    return HolyChildAppBar(
      title: context.l10n.settingsTitle,
      showBackButton: widget.showBackButton,
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.softMist.withValues(alpha: 0.6),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildRoleTile(AsyncValue<UserRole> roleAsync) {
    return roleAsync.when(
      data: (role) => SettingTile(
        icon: Icons.verified_user_outlined,
        title: 'Tu rol',
        subtitle: role.description,
        trailing: RoleBadge(role: role),
      ),
      loading: () => SettingTile(
        icon: Icons.verified_user_outlined,
        title: 'Tu rol',
        subtitle: 'Cargando rol...',
        trailing: const SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.holyGold,
          ),
        ),
      ),
      error: (_, stackTrace) => SettingTile(
        icon: Icons.verified_user_outlined,
        title: 'Tu rol',
        subtitle: 'No fue posible cargar el rol',
        trailing: Icon(
          Icons.info_outline,
          color: AppColors.softMist.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  String _getFontSizeLabel(WidgetFontSize size) {
    return switch (size) {
      WidgetFontSize.small => 'Pequeño',
      WidgetFontSize.medium => 'Mediano',
      WidgetFontSize.large => 'Grande',
      WidgetFontSize.extraLarge => 'Muy Grande',
    };
  }

  void _openFontSizeSheet({
    required WidgetFontSize selectedSize,
    required bool isUpdating,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return HolyBottomSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tamaño de letra del widget',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.pureWhite,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Selecciona el tamaño de letra para el versículo en el widget',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.softMist.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (_, index) {
                  final size = WidgetFontSize.values[index];
                  final isSelected = size == selectedSize;
                  return _FontSizeOption(
                    size: size,
                    label: _getFontSizeLabel(size),
                    selected: isSelected,
                    disabled: isUpdating,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _onChangeFontSize(size);
                    },
                  );
                },
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.sm),
                itemCount: WidgetFontSize.values.length,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onChangeFontSize(WidgetFontSize size) async {
    final success = await ref
        .read(authControllerProvider.notifier)
        .updateWidgetFontSize(size);

    if (!mounted) return;

    final message = success
        ? 'Tamaño de letra actualizado'
        : 'Error al actualizar el tamaño de letra';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppColors.holyGold : Colors.red,
      ),
    );
  }

  static const List<int> _reminderHourAnchors = [7, 12, 20];

  String _reminderHourLabel(int hour) {
    final period = hour < 12 ? 'a. m.' : 'p. m.';
    final displayHour = switch (hour % 12) {
      0 => 12,
      final h => h,
    };
    return '$displayHour:00 $period';
  }

  String _reminderAnchorName(int hour) {
    return switch (hour) {
      7 => 'Mañana',
      12 => 'Mediodía',
      20 => 'Noche',
      _ => 'Personalizado',
    };
  }

  void _openReminderHourSheet({
    required int? selectedHour,
    required bool isUpdating,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        var showCustom = selectedHour != null &&
            !_reminderHourAnchors.contains(selectedHour);
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void selectHour(int hour) {
              Navigator.of(sheetContext).pop();
              _updateNotificationPreferences(dailyReminderHour: hour);
            }

            return HolyBottomSheet(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hora del recordatorio',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.pureWhite,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Elige cuándo quieres tu momento con Dios',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.softMist.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ..._reminderHourAnchors.map(
                    (hour) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _ReminderHourOption(
                        label: _reminderAnchorName(hour),
                        subtitle: _reminderHourLabel(hour),
                        selected: selectedHour == hour,
                        disabled: isUpdating,
                        onTap: () => selectHour(hour),
                      ),
                    ),
                  ),
                  _ReminderHourOption(
                    label: 'Personalizado',
                    subtitle: showCustom && selectedHour != null
                        ? _reminderHourLabel(selectedHour)
                        : 'Elige cualquier hora del día',
                    selected: showCustom,
                    disabled: isUpdating,
                    onTap: () => setSheetState(() => showCustom = true),
                  ),
                  if (showCustom) ...[
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: 180,
                      child: GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: AppSpacing.sm,
                          crossAxisSpacing: AppSpacing.sm,
                          childAspectRatio: 1.6,
                        ),
                        itemCount: 24,
                        itemBuilder: (_, hour) {
                          final isSelected = selectedHour == hour;
                          return _ReminderHourChip(
                            hour: hour,
                            selected: isSelected,
                            disabled: isUpdating,
                            onTap: () => selectHour(hour),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateNotificationPreferences({
    bool? devotionalNotificationsEnabled,
    bool? followedCreatorNotificationsEnabled,
    bool? featuredDevotionalNotificationsEnabled,
    bool? streakRiskNotificationsEnabled,
    bool? authorModerationNotificationsEnabled,
    bool? editorReviewNotificationsEnabled,
    bool? socialActivityNotificationsEnabled,
    bool? commentNotificationsEnabled,
    bool? followNotificationsEnabled,
    bool? reactionNotificationsEnabled,
    bool? dailyReminderNotificationsEnabled,
    bool? streakMilestoneNotificationsEnabled,
    bool? winbackNotificationsEnabled,
    int? dailyReminderHour,
  }) async {
    final settings = ref.read(authControllerProvider).settings;
    if (settings == null) {
      return;
    }

    final targetDevotionalNotificationsEnabled =
        devotionalNotificationsEnabled ??
        settings.devotionalNotificationsEnabled;
    final targetAuthorModerationNotificationsEnabled =
        authorModerationNotificationsEnabled ??
        settings.authorModerationNotificationsEnabled;
    final targetStreakRiskNotificationsEnabled =
        streakRiskNotificationsEnabled ?? settings.streakRiskNotificationsEnabled;
    final targetEditorReviewNotificationsEnabled =
        editorReviewNotificationsEnabled ??
        settings.editorReviewNotificationsEnabled;
    final targetSocialActivityNotificationsEnabled =
        socialActivityNotificationsEnabled ??
        settings.socialActivityNotificationsEnabled;
    final targetCommentNotificationsEnabled =
        commentNotificationsEnabled ?? settings.commentNotificationsEnabled;
    final targetFollowNotificationsEnabled =
        followNotificationsEnabled ?? settings.followNotificationsEnabled;
    final targetReactionNotificationsEnabled =
        reactionNotificationsEnabled ?? settings.reactionNotificationsEnabled;
    final targetDailyReminderNotificationsEnabled =
        dailyReminderNotificationsEnabled ??
        settings.dailyReminderNotificationsEnabled;
    final targetStreakMilestoneNotificationsEnabled =
        streakMilestoneNotificationsEnabled ??
        settings.streakMilestoneNotificationsEnabled;
    final targetWinbackNotificationsEnabled =
        winbackNotificationsEnabled ?? settings.winbackNotificationsEnabled;
    final targetDailyReminderHour =
        dailyReminderHour ?? settings.dailyReminderHour;
    PushPermissionRequestResult permissionResult =
        PushPermissionRequestResult.unavailable;

    final shouldRequestPermission =
        (!settings.devotionalNotificationsEnabled &&
            targetDevotionalNotificationsEnabled) ||
        (!settings.streakRiskNotificationsEnabled &&
            targetStreakRiskNotificationsEnabled) ||
        (!settings.authorModerationNotificationsEnabled &&
            targetAuthorModerationNotificationsEnabled) ||
        (!settings.editorReviewNotificationsEnabled &&
            targetEditorReviewNotificationsEnabled) ||
        (!settings.socialActivityNotificationsEnabled &&
            targetSocialActivityNotificationsEnabled) ||
        (!settings.commentNotificationsEnabled &&
            targetCommentNotificationsEnabled) ||
        (!settings.followNotificationsEnabled &&
            targetFollowNotificationsEnabled) ||
        (!settings.reactionNotificationsEnabled &&
            targetReactionNotificationsEnabled) ||
        (!settings.dailyReminderNotificationsEnabled &&
            targetDailyReminderNotificationsEnabled);

    if (shouldRequestPermission) {
      permissionResult = await ref
          .read(phaseThreeRuntimeServiceProvider)
          .requestNotificationPermission();
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .updateNotificationPreferences(
          devotionalNotificationsEnabled: targetDevotionalNotificationsEnabled,
          followedCreatorNotificationsEnabled:
              followedCreatorNotificationsEnabled ??
              settings.followedCreatorNotificationsEnabled,
          featuredDevotionalNotificationsEnabled:
              featuredDevotionalNotificationsEnabled ??
              settings.featuredDevotionalNotificationsEnabled,
          streakRiskNotificationsEnabled: targetStreakRiskNotificationsEnabled,
          authorModerationNotificationsEnabled:
              targetAuthorModerationNotificationsEnabled,
          editorReviewNotificationsEnabled:
              targetEditorReviewNotificationsEnabled,
          socialActivityNotificationsEnabled:
              targetSocialActivityNotificationsEnabled,
          commentNotificationsEnabled: targetCommentNotificationsEnabled,
          followNotificationsEnabled: targetFollowNotificationsEnabled,
          reactionNotificationsEnabled: targetReactionNotificationsEnabled,
          dailyReminderHour: targetDailyReminderHour,
          dailyReminderNotificationsEnabled:
              targetDailyReminderNotificationsEnabled,
          streakMilestoneNotificationsEnabled:
              targetStreakMilestoneNotificationsEnabled,
          winbackNotificationsEnabled: targetWinbackNotificationsEnabled,
        );

    if (!mounted) return;
    final message = success
        ? permissionResult == PushPermissionRequestResult.denied
              ? 'Preferencias actualizadas. Activa el permiso del sistema para recibir notificaciones.'
              : 'Preferencias de notificación actualizadas'
        : (ref.read(authControllerProvider).errorMessage ??
              'No se pudieron actualizar las notificaciones');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppColors.holyGold : Colors.red.shade700,
      ),
    );
  }

  void _openVersionsSheet({
    required VersionsState versionsState,
    required int? selectedId,
    required bool isUpdating,
  }) {
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return HolyBottomSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.bibleVersionsTitle,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.pureWhite,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.bibleVersionsSubtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.softMist.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (versionsState.isLoading && versionsState.versions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Center(
                    child: SizedBox(
                      height: 26,
                      width: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.holyGold,
                      ),
                    ),
                  ),
                )
              else if (versionsState.hasError && versionsState.versions.isEmpty)
                _ErrorPill(
                  message: versionsState.errorMessage ?? l10n.versionsLoadError,
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (_, index) {
                      final version = versionsState.versions[index];
                      final isSelected = version.id == selectedId;
                      return _VersionOption(
                        version: version,
                        selected: isSelected,
                        disabled: isUpdating,
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          _onChangeVersion(version.id);
                        },
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemCount: versionsState.versions.length,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openDeleteAccountSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        var isDeleting = false;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> handleDelete() async {
              if (isDeleting) return;
              setSheetState(() => isDeleting = true);
              setState(() => _isDeletingAccount = true);

              final success = await ref
                  .read(authControllerProvider.notifier)
                  .deleteAccount();

              if (!mounted || !context.mounted) return;
              setState(() => _isDeletingAccount = false);

              if (success) {
                Navigator.of(context).pop();
                GoRouter.of(context).go('/login');
                return;
              }

              setSheetState(() => isDeleting = false);
              final errorMessage =
                  ref.read(authControllerProvider).errorMessage ??
                  context.l10n.deleteAccountError;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorMessage),
                  backgroundColor: Colors.red.shade700,
                ),
              );
            }

            final l10n = context.l10n;
            return HolyBottomSheet(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.deleteAccountTitle,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.pureWhite,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.deleteAccountSubtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.softMist.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: isDeleting
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.softMist,
                            textStyle: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: Text(l10n.deleteAccountCancel),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isDeleting ? null : handleDelete,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppBorderRadius.button,
                            ),
                            textStyle: AppTextStyles.button.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: isDeleting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(l10n.deleteAccountConfirm),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final versionsState = ref.watch(versionsControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final roleAsync = ref.watch(myRoleProvider);
    final isUpdating = authState.isUpdatingSettings;
    final l10n = context.l10n;
    final shouldShowRole = authState.user?.role != UserRole.user;
    final selectedVersion = _selectedVersion(
      versionsState,
      authState.preferredVersionId,
    );
    final versionSubtitle = versionsState.isLoading && selectedVersion == null
        ? l10n.splashLoading
        : selectedVersion?.name ?? l10n.versionsEmpty;
    final versionLabel = _appVersion != null
        ? 'v$_appVersion'
        : (_isAppInfoLoading ? 'Cargando...' : 'No disponible');
    final buildLabel = _buildNumber ?? (_isAppInfoLoading ? '--' : 'N/D');
    final notificationSettings = authState.settings;
    final devotionalNotificationsEnabled =
        notificationSettings?.devotionalNotificationsEnabled ?? true;
    final followedCreatorNotificationsEnabled =
        notificationSettings?.followedCreatorNotificationsEnabled ?? true;
    final featuredDevotionalNotificationsEnabled =
        notificationSettings?.featuredDevotionalNotificationsEnabled ?? true;
    final streakRiskNotificationsEnabled =
        notificationSettings?.streakRiskNotificationsEnabled ?? true;
    final authorModerationNotificationsEnabled =
        notificationSettings?.authorModerationNotificationsEnabled ?? true;
    final editorReviewNotificationsEnabled =
        notificationSettings?.editorReviewNotificationsEnabled ?? true;
    final socialActivityNotificationsEnabled =
        notificationSettings?.socialActivityNotificationsEnabled ?? true;
    final commentNotificationsEnabled =
        notificationSettings?.commentNotificationsEnabled ?? true;
    final followNotificationsEnabled =
        notificationSettings?.followNotificationsEnabled ?? true;
    final reactionNotificationsEnabled =
        notificationSettings?.reactionNotificationsEnabled ?? true;
    final dailyReminderNotificationsEnabled =
        notificationSettings?.dailyReminderNotificationsEnabled ?? true;
    final streakMilestoneNotificationsEnabled =
        notificationSettings?.streakMilestoneNotificationsEnabled ?? true;
    final winbackNotificationsEnabled =
        notificationSettings?.winbackNotificationsEnabled ?? true;
    final dailyReminderHour = notificationSettings?.dailyReminderHour;
    final canEditContent = authState.user?.role.canEditContent ?? false;

    return Scaffold(
      backgroundColor: AppColors.midnightFaith,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          const _SettingsBackground(),
          SafeArea(
            top: false,
            child: RefreshIndicator(
              color: AppColors.holyGold,
              backgroundColor: AppColors.midnightFaith,
              onRefresh: () => ref
                  .read(versionsControllerProvider.notifier)
                  .loadVersions(forceRefresh: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                children: [
                  _sectionLabel('Widget y Contenido'),
                  SectionCard(
                    children: [
                      SettingTile(
                        icon: Icons.menu_book_rounded,
                        title: l10n.bibleVersionsTitle,
                        subtitle: versionSubtitle,
                        trailing: _VersionTrailing(
                          version: selectedVersion,
                          isUpdating: isUpdating,
                        ),
                        onTap: versionsState.isLoading
                            ? null
                            : () => _openVersionsSheet(
                                versionsState: versionsState,
                                selectedId: authState.preferredVersionId,
                                isUpdating: isUpdating,
                              ),
                      ),
                      SettingTile(
                        icon: Icons.format_size,
                        title: 'Tamaño de letra del widget',
                        subtitle: 'Ajusta el tamaño del texto del verso',
                        trailing: Text(
                          _getFontSizeLabel(
                            authState.settings?.widgetFontSize ??
                                WidgetFontSize.large,
                          ),
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.softMist.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onTap: isUpdating
                            ? null
                            : () => _openFontSizeSheet(
                                selectedSize:
                                    authState.settings?.widgetFontSize ??
                                    WidgetFontSize.large,
                                isUpdating: isUpdating,
                              ),
                      ),
                      SettingTile(
                        icon: Icons.language,
                        title: 'Idioma',
                        subtitle: 'Ajusta el idioma de la app',
                        trailing: Text(
                          'ES',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.softMist.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Próximamente',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.midnightFaith,
                                ),
                              ),
                              backgroundColor: AppColors.holyGold,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  if (versionsState.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: _ErrorPill(
                        message:
                            versionsState.errorMessage ??
                            l10n.versionsLoadError,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  _sectionLabel('Recordatorio Diario'),
                  SectionCard(
                    children: [
                      SettingTile(
                        icon: Icons.alarm_outlined,
                        title: 'Recordatorio diario',
                        subtitle:
                            'Recibe un aviso para tu momento con Dios',
                        trailing: Switch.adaptive(
                          value: dailyReminderNotificationsEnabled,
                          activeThumbColor: AppColors.holyGold,
                          activeTrackColor: AppColors.holyGold.withValues(
                            alpha: 0.3,
                          ),
                          onChanged: isUpdating
                              ? null
                              : (value) => _updateNotificationPreferences(
                                  dailyReminderNotificationsEnabled: value,
                                ),
                        ),
                        onTap: isUpdating
                            ? null
                            : () => _updateNotificationPreferences(
                                dailyReminderNotificationsEnabled:
                                    !dailyReminderNotificationsEnabled,
                              ),
                      ),
                      SettingTile(
                        icon: Icons.schedule_outlined,
                        title: 'Hora del recordatorio',
                        subtitle: dailyReminderHour != null
                            ? _reminderHourLabel(dailyReminderHour)
                            : 'Elige una hora',
                        trailing: Icon(
                          Icons.chevron_right,
                          color: AppColors.softMist.withValues(alpha: 0.8),
                        ),
                        onTap:
                            isUpdating || !dailyReminderNotificationsEnabled
                            ? null
                            : () => _openReminderHourSheet(
                                selectedHour: dailyReminderHour,
                                isUpdating: isUpdating,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _sectionLabel('Notificaciones'),
                  SectionCard(
                    children: [
                      SettingTile(
                        icon: Icons.notifications_active_outlined,
                        title: 'Devocionales',
                        subtitle:
                            'Activa o pausa todas las notificaciones de devocionales',
                        trailing: Switch.adaptive(
                          value: devotionalNotificationsEnabled,
                          activeThumbColor: AppColors.holyGold,
                          activeTrackColor: AppColors.holyGold.withValues(
                            alpha: 0.3,
                          ),
                          onChanged: isUpdating
                              ? null
                              : (value) => _updateNotificationPreferences(
                                  devotionalNotificationsEnabled: value,
                                ),
                        ),
                        onTap: isUpdating
                            ? null
                            : () => _updateNotificationPreferences(
                                devotionalNotificationsEnabled:
                                    !devotionalNotificationsEnabled,
                              ),
                      ),
                      SettingTile(
                        icon: Icons.people_alt_outlined,
                        title: 'Creadores que sigues',
                        subtitle:
                            'Recibe alertas cuando publiquen un nuevo devocional',
                        trailing: Switch.adaptive(
                          value:
                              devotionalNotificationsEnabled &&
                              followedCreatorNotificationsEnabled,
                          activeThumbColor: AppColors.holyGold,
                          activeTrackColor: AppColors.holyGold.withValues(
                            alpha: 0.3,
                          ),
                          onChanged:
                              isUpdating || !devotionalNotificationsEnabled
                              ? null
                              : (value) => _updateNotificationPreferences(
                                  followedCreatorNotificationsEnabled: value,
                                ),
                        ),
                        onTap: isUpdating || !devotionalNotificationsEnabled
                            ? null
                            : () => _updateNotificationPreferences(
                                followedCreatorNotificationsEnabled:
                                    !followedCreatorNotificationsEnabled,
                              ),
                      ),
                      SettingTile(
                        icon: Icons.auto_awesome_outlined,
                        title: 'Destacados',
                        subtitle:
                            'Permite sugerencias editoriales y devocionales destacados',
                        trailing: Switch.adaptive(
                          value:
                              devotionalNotificationsEnabled &&
                              featuredDevotionalNotificationsEnabled,
                          activeThumbColor: AppColors.holyGold,
                          activeTrackColor: AppColors.holyGold.withValues(
                            alpha: 0.3,
                          ),
                          onChanged:
                              isUpdating || !devotionalNotificationsEnabled
                              ? null
                              : (value) => _updateNotificationPreferences(
                                  featuredDevotionalNotificationsEnabled: value,
                                ),
                        ),
                        onTap: isUpdating || !devotionalNotificationsEnabled
                            ? null
                            : () => _updateNotificationPreferences(
                                featuredDevotionalNotificationsEnabled:
                                    !featuredDevotionalNotificationsEnabled,
                              ),
                      ),
                      SettingTile(
                        icon: Icons.local_fire_department_outlined,
                        title: 'Racha en riesgo',
                        subtitle:
                            'Recibe un recordatorio en la tarde si todavía no has completado tu día',
                        trailing: Switch.adaptive(
                          value:
                              devotionalNotificationsEnabled &&
                              streakRiskNotificationsEnabled,
                          activeThumbColor: AppColors.holyGold,
                          activeTrackColor: AppColors.holyGold.withValues(
                            alpha: 0.3,
                          ),
                          onChanged:
                              isUpdating || !devotionalNotificationsEnabled
                              ? null
                              : (value) => _updateNotificationPreferences(
                                  streakRiskNotificationsEnabled: value,
                                ),
                        ),
                        onTap: isUpdating || !devotionalNotificationsEnabled
                            ? null
                            : () => _updateNotificationPreferences(
                                streakRiskNotificationsEnabled:
                                    !streakRiskNotificationsEnabled,
                              ),
                      ),
                      SettingTile(
                        icon: Icons.emoji_events_outlined,
                        title: 'Celebraciones de racha',
                        subtitle:
                            'Recibe un aviso cuando alcances un logro de racha',
                        trailing: Switch.adaptive(
                          value:
                              devotionalNotificationsEnabled &&
                              streakMilestoneNotificationsEnabled,
                          activeThumbColor: AppColors.holyGold,
                          activeTrackColor: AppColors.holyGold.withValues(
                            alpha: 0.3,
                          ),
                          onChanged:
                              isUpdating || !devotionalNotificationsEnabled
                              ? null
                              : (value) => _updateNotificationPreferences(
                                  streakMilestoneNotificationsEnabled: value,
                                ),
                        ),
                        onTap: isUpdating || !devotionalNotificationsEnabled
                            ? null
                            : () => _updateNotificationPreferences(
                                streakMilestoneNotificationsEnabled:
                                    !streakMilestoneNotificationsEnabled,
                              ),
                      ),
                      SettingTile(
                        icon: Icons.volunteer_activism_outlined,
                        title: 'Te extrañamos',
                        subtitle:
                            'Recibe un mensaje cálido si dejas de visitar la app',
                        trailing: Switch.adaptive(
                          value:
                              devotionalNotificationsEnabled &&
                              winbackNotificationsEnabled,
                          activeThumbColor: AppColors.holyGold,
                          activeTrackColor: AppColors.holyGold.withValues(
                            alpha: 0.3,
                          ),
                          onChanged:
                              isUpdating || !devotionalNotificationsEnabled
                              ? null
                              : (value) => _updateNotificationPreferences(
                                  winbackNotificationsEnabled: value,
                                ),
                        ),
                        onTap: isUpdating || !devotionalNotificationsEnabled
                            ? null
                            : () => _updateNotificationPreferences(
                                winbackNotificationsEnabled:
                                    !winbackNotificationsEnabled,
                              ),
                      ),
                      SettingTile(
                        icon: Icons.favorite_border_rounded,
                        title: 'Actividad social',
                        subtitle:
                            'Activa alertas cuando otros reaccionen a tu contenido',
                        trailing: Switch.adaptive(
                          value: socialActivityNotificationsEnabled,
                          activeThumbColor: AppColors.holyGold,
                          activeTrackColor: AppColors.holyGold.withValues(
                            alpha: 0.3,
                          ),
                          onChanged: isUpdating
                              ? null
                              : (value) => _updateNotificationPreferences(
                                  socialActivityNotificationsEnabled: value,
                                ),
                        ),
                        onTap: isUpdating
                            ? null
                            : () => _updateNotificationPreferences(
                                socialActivityNotificationsEnabled:
                                    !socialActivityNotificationsEnabled,
                              ),
                      ),
                      SettingTile(
                        icon: Icons.mode_comment_outlined,
                        title: 'Comentarios',
                        subtitle:
                            'Recibe una alerta cuando comenten uno de tus devocionales',
                        trailing: Switch.adaptive(
                          value:
                              socialActivityNotificationsEnabled &&
                              commentNotificationsEnabled,
                          activeThumbColor: AppColors.holyGold,
                          activeTrackColor: AppColors.holyGold.withValues(
                            alpha: 0.3,
                          ),
                          onChanged:
                              isUpdating || !socialActivityNotificationsEnabled
                              ? null
                              : (value) => _updateNotificationPreferences(
                                  commentNotificationsEnabled: value,
                                ),
                        ),
                        onTap: isUpdating || !socialActivityNotificationsEnabled
                            ? null
                            : () => _updateNotificationPreferences(
                                commentNotificationsEnabled:
                                    !commentNotificationsEnabled,
                              ),
                      ),
                      SettingTile(
                        icon: Icons.person_add_alt_rounded,
                        title: 'Nuevos seguidores',
                        subtitle:
                            'Recibe una alerta cuando alguien comience a seguirte',
                        trailing: Switch.adaptive(
                          value:
                              socialActivityNotificationsEnabled &&
                              followNotificationsEnabled,
                          activeThumbColor: AppColors.holyGold,
                          activeTrackColor: AppColors.holyGold.withValues(
                            alpha: 0.3,
                          ),
                          onChanged:
                              isUpdating || !socialActivityNotificationsEnabled
                              ? null
                              : (value) => _updateNotificationPreferences(
                                  followNotificationsEnabled: value,
                                ),
                        ),
                        onTap: isUpdating || !socialActivityNotificationsEnabled
                            ? null
                            : () => _updateNotificationPreferences(
                                followNotificationsEnabled:
                                    !followNotificationsEnabled,
                              ),
                      ),
                      SettingTile(
                        icon: Icons.thumb_up_alt_outlined,
                        title: 'Likes y compartidos',
                        subtitle:
                            'Agrupa reacciones a tus devocionales y te avisa con un resumen',
                        trailing: Switch.adaptive(
                          value:
                              socialActivityNotificationsEnabled &&
                              reactionNotificationsEnabled,
                          activeThumbColor: AppColors.holyGold,
                          activeTrackColor: AppColors.holyGold.withValues(
                            alpha: 0.3,
                          ),
                          onChanged:
                              isUpdating || !socialActivityNotificationsEnabled
                              ? null
                              : (value) => _updateNotificationPreferences(
                                  reactionNotificationsEnabled: value,
                                ),
                        ),
                        onTap: isUpdating || !socialActivityNotificationsEnabled
                            ? null
                            : () => _updateNotificationPreferences(
                                reactionNotificationsEnabled:
                                    !reactionNotificationsEnabled,
                              ),
                      ),
                      SettingTile(
                        icon: Icons.fact_check_outlined,
                        title: 'Estado de moderación',
                        subtitle:
                            'Recibe una alerta cuando aprueben o restrinjan uno de tus devocionales',
                        trailing: Switch.adaptive(
                          value: authorModerationNotificationsEnabled,
                          activeThumbColor: AppColors.holyGold,
                          activeTrackColor: AppColors.holyGold.withValues(
                            alpha: 0.3,
                          ),
                          onChanged: isUpdating
                              ? null
                              : (value) => _updateNotificationPreferences(
                                  authorModerationNotificationsEnabled: value,
                                ),
                        ),
                        onTap: isUpdating
                            ? null
                            : () => _updateNotificationPreferences(
                                authorModerationNotificationsEnabled:
                                    !authorModerationNotificationsEnabled,
                              ),
                      ),
                      if (canEditContent)
                        SettingTile(
                          icon: Icons.rule_folder_outlined,
                          title: 'Bandeja editorial',
                          subtitle:
                              'Recibe alertas cuando entre un nuevo devocional en revisión',
                          trailing: Switch.adaptive(
                            value: editorReviewNotificationsEnabled,
                            activeThumbColor: AppColors.holyGold,
                            activeTrackColor: AppColors.holyGold.withValues(
                              alpha: 0.3,
                            ),
                            onChanged: isUpdating
                                ? null
                                : (value) => _updateNotificationPreferences(
                                    editorReviewNotificationsEnabled: value,
                                  ),
                          ),
                          onTap: isUpdating
                              ? null
                              : () => _updateNotificationPreferences(
                                  editorReviewNotificationsEnabled:
                                      !editorReviewNotificationsEnabled,
                                ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _sectionLabel('Legal y Soporte'),
                  const SectionCard(children: [LegalLinksSection.settings()]),
                  const SizedBox(height: AppSpacing.lg),
                  _sectionLabel('Acerca de'),
                  SectionCard(
                    addDividers: false,
                    children: [
                      SettingTile(
                        icon: Icons.info_outline_rounded,
                        title: 'Acerca de',
                        subtitle: 'Versión $versionLabel • Build $buildLabel',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _sectionLabel('Cuenta'),
                  SectionCard(
                    addDividers: false,
                    children: [
                      if (shouldShowRole) _buildRoleTile(roleAsync),
                      SettingTile(
                        icon: Icons.logout_rounded,
                        title: 'Cerrar sesión',
                        trailing: Icon(
                          Icons.chevron_right,
                          color: AppColors.softMist.withValues(alpha: 0.8),
                        ),
                        onTap: () async {
                          final goRouter = GoRouter.of(context);
                          await ref
                              .read(authControllerProvider.notifier)
                              .logout();
                          if (!mounted) return;
                          goRouter.go('/login');
                        },
                      ),
                      SettingTile(
                        icon: Icons.delete_outline,
                        iconColor: Colors.red.shade700,
                        title: l10n.deleteAccountTitle,
                        trailing: _isDeletingAccount
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.holyGold,
                                ),
                              )
                            : Icon(
                                Icons.chevron_right,
                                color: AppColors.softMist.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                        onTap: _isDeletingAccount
                            ? null
                            : _openDeleteAccountSheet,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionTrailing extends StatelessWidget {
  const _VersionTrailing({required this.version, required this.isUpdating});

  final BibleVersion? version;
  final bool isUpdating;

  @override
  Widget build(BuildContext context) {
    if (isUpdating) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.holyGold,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          version != null ? version!.apiCode.toUpperCase() : '--',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.softMist.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Icon(
          Icons.chevron_right,
          color: AppColors.softMist.withValues(alpha: 0.8),
        ),
      ],
    );
  }
}

class _ErrorPill extends StatelessWidget {
  const _ErrorPill({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: AppBorderRadius.card,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.pureWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionOption extends StatelessWidget {
  const _VersionOption({
    required this.version,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final BibleVersion version;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppColors.holyGold
        : AppColors.softMist.withValues(alpha: 0.2);

    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: AppBorderRadius.input,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: AppBorderRadius.input,
          gradient: LinearGradient(
            colors: selected
                ? [
                    AppColors.holyGold.withValues(alpha: 0.14),
                    AppColors.pureWhite.withValues(alpha: 0.04),
                  ]
                : [
                    AppColors.pureWhite.withValues(alpha: 0.05),
                    AppColors.pureWhite.withValues(alpha: 0.02),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              height: 24,
              width: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 2),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.holyGold : Colors.transparent,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    version.name,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.pureWhite,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${version.apiCode.toUpperCase()} • ${version.language.toUpperCase()}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.softMist.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.chevron_right,
              color: selected
                  ? AppColors.holyGold
                  : AppColors.softMist.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsBackground extends StatelessWidget {
  const _SettingsBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.midnightFaithDark, AppColors.midnightFaith],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            left: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.holyGold.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.morningLight.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FontSizeOption extends StatelessWidget {
  const _FontSizeOption({
    required this.size,
    required this.label,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final WidgetFontSize size;
  final String label;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppColors.holyGold
        : AppColors.pureWhite.withValues(alpha: 0.1);

    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: AppBorderRadius.input,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: AppBorderRadius.input,
          gradient: LinearGradient(
            colors: selected
                ? [
                    AppColors.holyGold.withValues(alpha: 0.14),
                    AppColors.pureWhite.withValues(alpha: 0.04),
                  ]
                : [
                    AppColors.pureWhite.withValues(alpha: 0.05),
                    AppColors.pureWhite.withValues(alpha: 0.02),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              height: 24,
              width: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 2),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.holyGold : Colors.transparent,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.pureWhite,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ejemplo de verso',
                    style: TextStyle(
                      fontSize: size.size,
                      color: AppColors.softMist.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.chevron_right,
              color: selected
                  ? AppColors.holyGold
                  : AppColors.softMist.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderHourOption extends StatelessWidget {
  const _ReminderHourOption({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppColors.holyGold
        : AppColors.pureWhite.withValues(alpha: 0.1);

    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: AppBorderRadius.input,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: AppBorderRadius.input,
          gradient: LinearGradient(
            colors: selected
                ? [
                    AppColors.holyGold.withValues(alpha: 0.14),
                    AppColors.pureWhite.withValues(alpha: 0.04),
                  ]
                : [
                    AppColors.pureWhite.withValues(alpha: 0.05),
                    AppColors.pureWhite.withValues(alpha: 0.02),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              height: 24,
              width: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 2),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.holyGold : Colors.transparent,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.pureWhite,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.softMist.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.chevron_right,
              color: selected
                  ? AppColors.holyGold
                  : AppColors.softMist.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderHourChip extends StatelessWidget {
  const _ReminderHourChip({
    required this.hour,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final int hour;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppColors.holyGold
        : AppColors.pureWhite.withValues(alpha: 0.1);

    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: AppBorderRadius.input,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: AppBorderRadius.input,
          color: selected
              ? AppColors.holyGold.withValues(alpha: 0.16)
              : AppColors.pureWhite.withValues(alpha: 0.04),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          hour.toString().padLeft(2, '0'),
          style: AppTextStyles.labelMedium.copyWith(
            color: selected ? AppColors.holyGold : AppColors.pureWhite,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
