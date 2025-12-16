import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_design_tokens.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';
import 'package:holyverso/domain/verse/verse_of_the_day.dart';
import 'package:holyverso/presentation/state/verse/verse_controller.dart';
import 'package:share_plus/share_plus.dart';

class VerseOfTheDayScreen extends ConsumerStatefulWidget {
  const VerseOfTheDayScreen({super.key});

  @override
  ConsumerState<VerseOfTheDayScreen> createState() =>
      _VerseOfTheDayScreenState();
}

class _VerseOfTheDayScreenState extends ConsumerState<VerseOfTheDayScreen> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(verseControllerProvider.notifier).loadVerse();
    });
  }

  Future<void> _onRefresh() {
    return ref
        .read(verseControllerProvider.notifier)
        .loadVerse(forceRefresh: true);
  }

  void _onShare(VerseOfTheDay verse) {
    final l10n = context.l10n;
    final shareText =
        '"${verse.text}"\n${verse.reference}\n${verse.versionName} '
        '(${verse.displayVersionCode})';
    Share.share(shareText, subject: l10n.shareSubject);
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
  }

  @override
  Widget build(BuildContext context) {
    final verseState = ref.watch(verseControllerProvider);
    final verse = verseState.verse;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.midnightFaith,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Text(
          l10n.verseScreenTitle,
          style: AppTextStyles.headline3.copyWith(
            color: AppColors.pureWhite,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: l10n.shareTooltip,
            onPressed: verse == null ? null : () => _onShare(verse),
            icon: Icon(
              Icons.ios_share,
              color: verse == null
                  ? AppColors.softMist.withValues(alpha: 0.4)
                  : AppColors.pureWhite,
            ),
          ),
          IconButton(
            tooltip: l10n.settingsTooltip,
            onPressed: () => context.push('/settings'),
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.pureWhite,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const _VerseBackground(),
          SafeArea(
            child: RefreshIndicator(
              color: AppColors.holyGold,
              backgroundColor: AppColors.midnightFaith,
              onRefresh: _onRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                children: [
                  _Header(verse: verse),
                  const SizedBox(height: AppSpacing.md),
                  _VerseCard(
                    verse: verse,
                    isLoading: verseState.isLoading,
                    isFavorite: _isFavorite,
                    onToggleFavorite: _toggleFavorite,
                    onShare: verse == null ? null : () => _onShare(verse),
                  ),
                  if (verseState.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: _ErrorPill(
                        message:
                            verseState.errorMessage ?? l10n.verseLoadError,
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
}

class _Header extends StatelessWidget {
  const _Header({this.verse});

  final VerseOfTheDay? verse;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.pureWhite.withValues(alpha: 0.06),
            borderRadius: AppBorderRadius.button,
            border: Border.all(
              color: AppColors.pureWhite.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome,
                color: AppColors.holyGold,
                size: AppSizes.iconSmall,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                l10n.verseOfDayTag,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.pureWhite,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.verseSubtitle,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.softMist.withValues(alpha: 0.85),
          ),
        ),
        if (verse != null && verse!.date.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            verse!.date,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.softMist.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }
}

class _VerseCard extends StatelessWidget {
  const _VerseCard({
    required this.verse,
    required this.isLoading,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onShare,
  });

  final VerseOfTheDay? verse;
  final bool isLoading;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final contentWidth = screenSize.width - (AppSpacing.lg * 2);
    final baseHeight = contentWidth / (9 / 19.5);
    final minHeight = screenSize.height * 0.42;
    final maxHeight = screenSize.height * 0.62;
    final cardHeight = baseHeight.clamp(minHeight, maxHeight).toDouble();

    return SizedBox(
      height: cardHeight,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: AppColors.midnightGradient,
          borderRadius: BorderRadius.circular(AppBorderRadius.xl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 34,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: verse != null
                  ? _VerseContent(verse: verse!)
                  : isLoading
                      ? _SkeletonPlaceholder()
                      : const _EmptyState(),
            ),
            Positioned(
              bottom: AppSpacing.md,
              right: AppSpacing.md,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _CircleIconButton(
                    icon: isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: isFavorite
                        ? AppColors.holyGold
                        : AppColors.pureWhite.withValues(alpha: 0.85),
                    onPressed: onToggleFavorite,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _CircleIconButton(
                    icon: Icons.ios_share,
                    color: AppColors.pureWhite.withValues(alpha: 0.85),
                    onPressed: onShare,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerseContent extends StatelessWidget {
  const _VerseContent({required this.verse});

  final VerseOfTheDay verse;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('verse-content'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.topRight,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.pureWhite.withValues(alpha: 0.06),
              borderRadius: AppBorderRadius.button,
              border: Border.all(
                color: AppColors.pureWhite.withValues(alpha: 0.08),
              ),
            ),
            child: Text(
              '${verse.displayVersionCode} • ${verse.versionName}',
              style: AppTextStyles.referenceSmall.copyWith(
                color: AppColors.morningLight,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"${verse.text}"',
                  style: AppTextStyles.headline1.copyWith(
                    color: AppColors.pureWhite,
                    height: 1.35,
                    shadows: AppShadows.textGlow,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  verse.reference,
                  style: AppTextStyles.reference.copyWith(
                    shadows: [
                      Shadow(
                        color: AppColors.holyGold.withValues(alpha: 0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.color,
    this.onPressed,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite.withValues(alpha: 0.08),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.pureWhite.withValues(alpha: 0.1),
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: AppSizes.iconMedium),
      ),
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

class _SkeletonPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('skeleton'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 18,
          width: 120,
          decoration: BoxDecoration(
            color: AppColors.pureWhite.withValues(alpha: 0.06),
            borderRadius: AppBorderRadius.button,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _ShimmerBlock(height: 22, width: double.infinity),
        const SizedBox(height: 10),
        _ShimmerBlock(height: 22, width: double.infinity),
        const SizedBox(height: 10),
        _ShimmerBlock(
          height: 22,
          width: MediaQuery.sizeOf(context).width * 0.7,
        ),
        const SizedBox(height: AppSpacing.lg),
        _ShimmerBlock(height: 16, width: 140),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('empty'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.info_outline,
          size: 48,
          color: AppColors.holyGold.withValues(alpha: 0.8),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'No hay versículo disponible',
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.pureWhite,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Configura tus versiones de la Biblia en Ajustes para ver el versículo del día',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.softMist.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: () => context.push('/settings'),
          icon: const Icon(Icons.settings_outlined),
          label: const Text('Ir a Ajustes'),
        ),
      ],
    );
  }
}

class _ShimmerBlock extends StatelessWidget {
  const _ShimmerBlock({
    required this.height,
    required this.width,
  });

  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.pureWhite.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class _VerseBackground extends StatelessWidget {
  const _VerseBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.midnightFaithDark,
            AppColors.midnightFaith,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -140,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
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
            bottom: -140,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.morningLight.withValues(alpha: 0.16),
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
