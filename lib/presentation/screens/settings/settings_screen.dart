import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holy_mobile/data/bible/models/bible_version.dart';
import 'package:holy_mobile/core/l10n/app_localizations.dart';
import 'package:holy_mobile/presentation/state/auth/auth_controller.dart';
import 'package:holy_mobile/presentation/state/settings/versions_controller.dart';
import 'package:holy_mobile/presentation/state/settings/versions_state.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
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

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final versionsState = ref.watch(versionsControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final isUpdating = authState.isUpdatingSettings;
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final background = colorScheme.background;
    final highlight = colorScheme.tertiary;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -120,
            left: -80,
            child: _GlowCircle(color: colorScheme.primary),
          ),
          Positioned(
            bottom: -140,
            right: -90,
            child: _GlowCircle(color: colorScheme.tertiary),
          ),
          SafeArea(
              child: RefreshIndicator(
                color: highlight,
                backgroundColor: colorScheme.surface,
                onRefresh: () =>
                    ref.read(versionsControllerProvider.notifier).loadVersions(forceRefresh: true),
                child: ListView(
                  physics:
                      const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                children: [
                  Text(
                    l10n.preferencesTitle,
                    style: textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onBackground,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.preferencesSubtitle,
                    style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onBackground.withOpacity(0.7),
                        ),
                  ),
                  const SizedBox(height: 18),
                  _SectionCard(
                    title: l10n.bibleVersionsTitle,
                    subtitle: l10n.bibleVersionsSubtitle,
                    child: _buildVersionsList(
                      versionsState: versionsState,
                      selectedId: authState.preferredVersionId,
                      isUpdating: isUpdating,
                      colorScheme: colorScheme,
                    ),
                  ),
                  if (versionsState.hasError && versionsState.versions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _ErrorBanner(
                      message: versionsState.errorMessage ?? l10n.versionsLoadError,
                      colorScheme: colorScheme,
                      onRetry: () => ref
                          .read(versionsControllerProvider.notifier)
                          .loadVersions(forceRefresh: true),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionsList({
    required VersionsState versionsState,
    required int? selectedId,
    required bool isUpdating,
    required ColorScheme colorScheme,
  }) {
    final l10n = context.l10n;
    final highlight = colorScheme.tertiary;
    final background = colorScheme.background;
    final onSurface = colorScheme.onSurface;

    if (versionsState.isLoading && !versionsState.hasLoaded) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: SizedBox(
            height: 26,
            width: 26,
            child: CircularProgressIndicator(strokeWidth: 2.6),
          ),
        ),
      );
    }

    if (versionsState.hasError && versionsState.versions.isEmpty) {
      return _ErrorBanner(
        message: versionsState.errorMessage ?? l10n.versionsLoadError,
        onRetry: () =>
            ref.read(versionsControllerProvider.notifier).loadVersions(forceRefresh: true),
        colorScheme: colorScheme,
      );
    }

    if (versionsState.versions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Text(
          l10n.versionsEmpty,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: onSurface.withOpacity(0.7)),
        ),
      );
    }

    return Column(
      children: versionsState.versions
          .map(
            (version) => _VersionTile(
              version: version,
              selected: version.id == selectedId,
              disabled: isUpdating,
              colorScheme: colorScheme,
              onTap: () => _onChangeVersion(version.id),
              showLoader: isUpdating && version.id == selectedId,
            ),
          )
          .toList(),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _VersionTile extends StatelessWidget {
  const _VersionTile({
    required this.version,
    required this.selected,
    required this.disabled,
    required this.colorScheme,
    required this.onTap,
    required this.showLoader,
  });

  final BibleVersion version;
  final bool selected;
  final bool disabled;
  final bool showLoader;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        selected ? colorScheme.tertiary : colorScheme.outline.withOpacity(0.5);
    final textTheme = Theme.of(context).textTheme;
    final onSurface = colorScheme.onSurface;

    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor.withOpacity(selected ? 1 : 0.7)),
          gradient: LinearGradient(
            colors: selected
                ? [colorScheme.tertiary.withOpacity(0.14), colorScheme.surface]
                : [
                    colorScheme.surface.withOpacity(0.6),
                    colorScheme.surfaceVariant.withOpacity(0.7),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colorScheme.tertiary.withOpacity(0.28),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            _RadioBadge(selected: selected, colorScheme: colorScheme),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    version.name,
                    style: textTheme.titleMedium?.copyWith(
                      color: onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${version.apiCode.toUpperCase()} • ${version.language.toUpperCase()}',
                    style: textTheme.bodySmall?.copyWith(
                      color: onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (showLoader)
              const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                selected ? Icons.check_circle : Icons.chevron_right,
                color: selected
                    ? colorScheme.tertiary
                    : onSurface.withOpacity(0.5),
              ),
          ],
        ),
      ),
    );
  }
}

class _RadioBadge extends StatelessWidget {
  const _RadioBadge({required this.selected, required this.colorScheme});

  final bool selected;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 22,
      width: 22,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? colorScheme.tertiary
              : colorScheme.onSurface.withOpacity(0.6),
          width: 2,
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? colorScheme.tertiary : Colors.transparent,
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.onRetry,
    required this.colorScheme,
  });

  final String message;
  final VoidCallback onRetry;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(l10n.errorRetry),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(0.15),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
