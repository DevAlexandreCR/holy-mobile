import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:holy_mobile/domain/verse/verse_of_the_day.dart';
import 'package:holy_mobile/presentation/state/verse/verse_controller.dart';
import 'package:share_plus/share_plus.dart';

const _background = Color(0xFF0D1117);
const _cardTop = Color(0xFF121A2A);
const _cardBottom = Color(0xFF1A2940);
const _accent = Color(0xFFF4D27A);

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
    final shareText = '"${verse.text}"\n${verse.reference}\n${verse.versionName} '
        '(${verse.displayVersionCode})';
    Share.share(
      shareText,
      subject: 'Versículo de hoy',
    );
  }

  @override
  Widget build(BuildContext context) {
    final verseState = ref.watch(verseControllerProvider);
    final verse = verseState.verse;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: const Text('Versículo del día'),
        actions: [
          IconButton(
            tooltip: 'Compartir',
            onPressed: verse == null ? null : () => _onShare(verse),
            icon: const Icon(Icons.ios_share_outlined),
          ),
          IconButton(
            tooltip: 'Configuración',
            onPressed: () => context.go('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned(top: -140, left: -80, child: _GlowCircle(size: 260)),
          const Positioned(bottom: -120, right: -40, child: _GlowCircle(size: 220)),
          SafeArea(
            child: RefreshIndicator(
              color: _accent,
              backgroundColor: _background,
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
                    accent: _accent,
                  ),
                  const SizedBox(height: 16),
                  _ActionsRow(
                    isLoading: verseState.isLoading,
                    onRefresh: _onRefresh,
                    onShare: verse == null ? null : () => _onShare(verse),
                    accent: _accent,
                  ),
                  if (verseState.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _ErrorBanner(
                        message: verseState.errorMessage ??
                            'No pudimos cargar el versículo de hoy.',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wb_twilight_outlined, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Versículo de hoy',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
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
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: Colors.white70),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Renueva tu espíritu con la palabra diaria.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white70,
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
    required this.accent,
  });

  final VerseOfTheDay? verse;
  final bool isLoading;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_cardTop, _cardBottom],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
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
                'Palabra viva',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              if (isLoading)
                const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white70,
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        verse!.reference,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${verse!.displayVersionCode} • ${verse!.versionName}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                              letterSpacing: 0.2,
                            ),
                      ),
                    ],
                  )
                : _SkeletonPlaceholder(accent: accent),
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
    required this.accent,
  });

  final bool isLoading;
  final Future<void> Function() onRefresh;
  final VoidCallback? onShare;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: isLoading ? null : onRefresh,
            icon: isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh),
            label: const Text('Actualizar'),
            style: FilledButton.styleFrom(
              backgroundColor: accent.withOpacity(0.16),
              foregroundColor: Colors.white,
              side: BorderSide(color: accent.withOpacity(0.6)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onShare,
            icon: const Icon(Icons.ios_share_outlined),
            label: const Text('Compartir'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white24),
              backgroundColor: Colors.white.withOpacity(0.04),
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
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
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

class _SkeletonPlaceholder extends StatelessWidget {
  const _SkeletonPlaceholder({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('skeleton'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ShimmerBlock(height: 22, width: double.infinity),
        const SizedBox(height: 10),
        _ShimmerBlock(height: 22, width: double.infinity),
        const SizedBox(height: 10),
        _ShimmerBlock(height: 22, width: MediaQuery.sizeOf(context).width * 0.7),
        const SizedBox(height: 18),
        _ShimmerBlock(height: 16, width: 140, color: accent.withOpacity(0.4)),
        const SizedBox(height: 6),
        _ShimmerBlock(height: 14, width: 200),
      ],
    );
  }
}

class _ShimmerBlock extends StatelessWidget {
  const _ShimmerBlock({
    required this.height,
    required this.width,
    this.color,
  });

  final double height;
  final double width;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: (color ?? Colors.white).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({this.size = 220});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
