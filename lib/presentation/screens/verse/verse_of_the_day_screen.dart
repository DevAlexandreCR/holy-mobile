import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:holy_mobile/core/l10n/app_localizations.dart';
import 'package:holy_mobile/domain/verse/verse_of_the_day.dart';
import 'package:holy_mobile/presentation/state/verse/verse_controller.dart';
import 'package:share_plus/share_plus.dart';

class VerseOfTheDayScreen extends ConsumerStatefulWidget {
  const VerseOfTheDayScreen({super.key});

  @override
  ConsumerState<VerseOfTheDayScreen> createState() => _VerseOfTheDayScreenState();
}

class _VerseOfTheDayScreenState extends ConsumerState<VerseOfTheDayScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(verseControllerProvider.notifier).loadVerse();
    });
  }

  Future<void> _onRefresh() {
    return ref.read(verseControllerProvider.notifier).loadVerse(forceRefresh: true);
  }

  void _onShare(VerseOfTheDay verse) {
    final l10n = context.l10n;
    final shareText = '"${verse.text}"\n${verse.reference}\n${verse.versionName} '
        '(${verse.displayVersionCode})';
    Share.share(
      shareText,
      subject: l10n.shareSubject,
    );
  }

  @override
  Widget build(BuildContext context) {
    final verseState = ref.watch(verseControllerProvider);
    final verse = verseState.verse;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final accent = colorScheme.tertiary;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(l10n.verseScreenTitle),
        actions: [
          IconButton(
            tooltip: l10n.shareTooltip,
            onPressed: verse == null ? null : () => _onShare(verse),
            icon: const Icon(Icons.ios_share_outlined),
          ),
          IconButton(
            tooltip: l10n.settingsTooltip,
            onPressed: () => context.go('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: -140,
            left: -80,
            child: _GlowCircle(size: 260, color: colorScheme.primary),
          ),
          Positioned(
            bottom: -120,
            right: -40,
            child: _GlowCircle(size: 220, color: colorScheme.tertiary),
          ),
          SafeArea(
            child: RefreshIndicator(
              color: accent,
              backgroundColor: colorScheme.surface,
              onRefresh: _onRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  _buildHeader(context, verse),
                  const SizedBox(height: 16),
                  _VerseCard(
                    verse: verse,
                    isLoading: verseState.isLoading,
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 16),
                  _ActionsRow(
                    isLoading: verseState.isLoading,
                    onRefresh: _onRefresh,
                    onShare: verse == null ? null : () => _onShare(verse),
                    colorScheme: colorScheme,
                  ),
                  if (verseState.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _ErrorBanner(
                        message: verseState.errorMessage ??
                            l10n.verseLoadError,
                        colorScheme: colorScheme,
                        onRetry: _onRefresh,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, VerseOfTheDay? verse) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final muted = colorScheme.onSurface.withOpacity(0.7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.primary.withOpacity(0.18)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.wb_twilight_outlined,
                    color: colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.verseOfDayTag,
                    style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (verse != null && verse.date.isNotEmpty)
              Text(
                verse.date,
                style:
                    textTheme.labelMedium?.copyWith(color: colorScheme.onSurface),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l10n.verseSubtitle,
          style: textTheme.bodyLarge?.copyWith(
                color: muted,
              ),
        ),
      ],
    );
  }
}

class _VerseCard extends StatelessWidget {
  const _VerseCard({
    required this.verse,
    required this.isLoading,
    required this.colorScheme,
  });

  final VerseOfTheDay? verse;
  final bool isLoading;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final accent = colorScheme.tertiary;
    final textTheme = Theme.of(context).textTheme;
    final onSurface = colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.surfaceContainerHighest,
            colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: accent, size: 22),
              const SizedBox(width: 8),
              Text(
                context.l10n.verseSectionTitle,
                style: textTheme.labelLarge?.copyWith(
                      color: onSurface,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              if (isLoading)
                SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: onSurface.withOpacity(0.7),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: verse != null
                ? Column(
                    key: const ValueKey('content'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '"${verse!.text}"',
                        style: textTheme.titleLarge?.copyWith(
                              color: onSurface,
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        verse!.reference,
                        style: textTheme.titleMedium?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${verse!.displayVersionCode} • ${verse!.versionName}',
                        style: textTheme.bodyMedium?.copyWith(
                              color: onSurface.withOpacity(0.72),
                              letterSpacing: 0.2,
                            ),
                      ),
                    ],
                  )
                : _SkeletonPlaceholder(colorScheme: colorScheme),
          ),
        ],
      ),
    );
  }
}

class _ActionsRow extends StatelessWidget {
  const _ActionsRow({
    required this.isLoading,
    required this.onRefresh,
    required this.onShare,
    required this.colorScheme,
  });

  final bool isLoading;
  final Future<void> Function() onRefresh;
  final VoidCallback? onShare;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accent = colorScheme.tertiary;
    final onSurface = colorScheme.onSurface;

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: isLoading ? null : onRefresh,
            icon: isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            label: Text(l10n.updateAction),
            style: FilledButton.styleFrom(
              backgroundColor: accent.withOpacity(0.16),
              foregroundColor: onSurface,
              side: BorderSide(color: accent.withOpacity(0.6)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onShare,
            icon: const Icon(Icons.ios_share_outlined),
            label: Text(l10n.shareAction),
            style: OutlinedButton.styleFrom(
              foregroundColor: onSurface,
              side: BorderSide(color: colorScheme.outline.withOpacity(0.6)),
              backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.4),
            ),
          ),
        ),
      ],
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
  final Future<void> Function() onRetry;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withOpacity(0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.error.withOpacity(0.25)),
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

class _SkeletonPlaceholder extends StatelessWidget {
  const _SkeletonPlaceholder({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final accent = colorScheme.tertiary;
    final baseColor = colorScheme.onSurface;
    return Column(
      key: const ValueKey('skeleton'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ShimmerBlock(height: 22, width: double.infinity, baseColor: baseColor),
        const SizedBox(height: 10),
        _ShimmerBlock(height: 22, width: double.infinity, baseColor: baseColor),
        const SizedBox(height: 10),
        _ShimmerBlock(
          height: 22,
          width: MediaQuery.sizeOf(context).width * 0.7,
          baseColor: baseColor,
        ),
        const SizedBox(height: 18),
        _ShimmerBlock(height: 16, width: 140, baseColor: accent),
        const SizedBox(height: 6),
        _ShimmerBlock(height: 14, width: 200, baseColor: baseColor),
      ],
    );
  }
}

class _ShimmerBlock extends StatelessWidget {
  const _ShimmerBlock({
    required this.height,
    required this.width,
    required this.baseColor,
  });

  final double height;
  final double width;
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({this.size = 220, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(0.12),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
