import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_design_tokens.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';
import 'package:holyverso/data/auth/models/user_settings.dart';
import 'package:holyverso/data/bible/models/bible_version.dart';
import 'package:holyverso/presentation/state/auth/auth_controller.dart';
import 'package:holyverso/presentation/state/settings/versions_controller.dart';
import 'package:holyverso/presentation/state/settings/versions_state.dart';
import 'package:holyverso/presentation/widgets/section_card.dart';
import 'package:holyverso/presentation/widgets/setting_tile.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _verseNotificationEnabled = true;
  bool _reminderEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(versionsControllerProvider.notifier).loadVersions();
    });
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

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.midnightFaith.withValues(alpha: 0.82),
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.pureWhite),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Text(
        context.l10n.settingsTitle,
        style: AppTextStyles.headline3.copyWith(
          color: AppColors.pureWhite,
          fontWeight: FontWeight.w700,
        ),
      ),
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(color: Colors.transparent),
        ),
      ),
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
        return Container(
          decoration: BoxDecoration(
            color: AppColors.midnightFaith.withValues(alpha: 0.98),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppBorderRadius.lg),
            ),
            border: Border.all(
              color: AppColors.pureWhite.withValues(alpha: 0.08),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.pureWhite.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
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
        return Container(
          decoration: BoxDecoration(
            color: AppColors.midnightFaith.withValues(alpha: 0.98),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppBorderRadius.lg),
            ),
            border: Border.all(
              color: AppColors.pureWhite.withValues(alpha: 0.08),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.pureWhite.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
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
                else if (versionsState.hasError &&
                    versionsState.versions.isEmpty)
                  _ErrorPill(
                    message:
                        versionsState.errorMessage ?? l10n.versionsLoadError,
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
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final versionsState = ref.watch(versionsControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final isUpdating = authState.isUpdatingSettings;
    final l10n = context.l10n;
    final selectedVersion = _selectedVersion(
      versionsState,
      authState.preferredVersionId,
    );
    final versionSubtitle = versionsState.isLoading && selectedVersion == null
        ? l10n.splashLoading
        : selectedVersion?.name ?? l10n.versionsEmpty;

    return Scaffold(
      backgroundColor: AppColors.midnightFaith,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          const _SettingsBackground(),
          SafeArea(
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
                  _sectionLabel('Notificaciones'),
                  SectionCard(
                    children: [
                      SettingTile(
                        icon: Icons.notifications_active_outlined,
                        title: 'Verso diario',
                        subtitle: 'Recibe el versículo al iniciar el día',
                        trailing: Switch.adaptive(
                          value: _verseNotificationEnabled,
                          activeThumbColor: AppColors.holyGold,
                          activeTrackColor: AppColors.holyGold.withValues(
                            alpha: 0.3,
                          ),
                          onChanged: (value) =>
                              setState(() => _verseNotificationEnabled = value),
                        ),
                        onTap: () => setState(
                          () => _verseNotificationEnabled =
                              !_verseNotificationEnabled,
                        ),
                      ),
                      SettingTile(
                        icon: Icons.alarm_outlined,
                        title: 'Recordatorios',
                        subtitle: 'Programa alertas suaves para orar',
                        trailing: Switch.adaptive(
                          value: _reminderEnabled,
                          activeThumbColor: AppColors.holyGold,
                          activeTrackColor: AppColors.holyGold.withValues(
                            alpha: 0.3,
                          ),
                          onChanged: (value) =>
                              setState(() => _reminderEnabled = value),
                        ),
                        onTap: () => setState(
                          () => _reminderEnabled = !_reminderEnabled,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _sectionLabel('Cuenta'),
                  SectionCard(
                    addDividers: false,
                    children: [
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
