import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holy_mobile/data/bible/models/bible_version.dart';
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
    final notifier = ref.read(versionsControllerProvider.notifier);
    final success = await notifier.selectVersion(versionId);
    if (!mounted) return;

    final authState = ref.read(authControllerProvider);
    final message = success
        ? 'Versión actualizada.'
        : authState.errorMessage ?? 'No pudimos guardar tu preferencia.';

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final versionsState = ref.watch(versionsControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final isUpdating = authState.isUpdatingSettings;

    const background = Color(0xFF0D1117);
    const highlight = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Configuración'),
      ),
      body: Stack(
        children: [
          const Positioned(
            top: -120,
            left: -80,
            child: _GlowCircle(),
          ),
          const Positioned(
            bottom: -140,
            right: -90,
            child: _GlowCircle(),
          ),
          SafeArea(
            child: RefreshIndicator(
              color: highlight,
              backgroundColor: background,
              onRefresh: () =>
                  ref.read(versionsControllerProvider.notifier).loadVersions(forceRefresh: true),
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                children: [
                  Text(
                    'Preferencias',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Elige tu traducción favorita para sincronizar el versículo diario.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 18),
                  _SectionCard(
                    title: 'Versiones de la Biblia',
                    subtitle: 'Selecciona la versión que prefieras leer',
                    child: _buildVersionsList(
                      versionsState: versionsState,
                      selectedId: authState.preferredVersionId,
                      isUpdating: isUpdating,
                      highlight: highlight,
                      background: background,
                    ),
                  ),
                  if (versionsState.hasError && versionsState.versions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _ErrorBanner(
                      message: versionsState.errorMessage!,
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
    required Color highlight,
    required Color background,
  }) {
    if (versionsState.isLoading && !versionsState.hasLoaded) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: SizedBox(
            height: 26,
            width: 26,
            child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white),
          ),
        ),
      );
    }

    if (versionsState.hasError && versionsState.versions.isEmpty) {
      return _ErrorBanner(
        message: versionsState.errorMessage ??
            'No pudimos cargar las versiones. Intenta nuevamente.',
        onRetry: () =>
            ref.read(versionsControllerProvider.notifier).loadVersions(forceRefresh: true),
      );
    }

    if (versionsState.versions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Text(
          'Aún no hay versiones disponibles.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
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
              highlight: highlight,
              background: background,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
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
    required this.highlight,
    required this.background,
    required this.onTap,
    required this.showLoader,
  });

  final BibleVersion version;
  final bool selected;
  final bool disabled;
  final bool showLoader;
  final Color highlight;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? highlight : Colors.white24;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor.withOpacity(selected ? 1 : 0.6)),
          gradient: LinearGradient(
            colors: selected
                ? [highlight.withOpacity(0.16), background]
                : [background.withOpacity(0.5), background.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: highlight.withOpacity(0.3),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            _RadioBadge(selected: selected, highlight: highlight),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    version.name,
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${version.apiCode.toUpperCase()} • ${version.language.toUpperCase()}',
                    style: textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            if (showLoader)
              const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            else
              Icon(
                selected ? Icons.check_circle : Icons.chevron_right,
                color: selected ? highlight : Colors.white54,
              ),
          ],
        ),
      ),
    );
  }
}

class _RadioBadge extends StatelessWidget {
  const _RadioBadge({required this.selected, required this.highlight});

  final bool selected;
  final Color highlight;

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
          color: selected ? highlight : Colors.white54,
          width: 2,
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? highlight : Colors.transparent,
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            const Color(0xFFD4AF37).withOpacity(0.15),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
