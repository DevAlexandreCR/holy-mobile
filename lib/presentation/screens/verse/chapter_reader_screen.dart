import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_design_tokens.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';
import 'package:holyverso/data/verse/chapter_repository.dart';
import 'package:holyverso/domain/verse/chapter.dart';
import 'package:holyverso/presentation/state/verse/chapter_reader_controller.dart';
import 'package:holyverso/presentation/state/verse/chapter_reader_state.dart';

class ChapterReaderArgs {
  const ChapterReaderArgs({
    this.book,
    this.chapter,
    this.versionCode,
    this.highlightRange,
    this.libraryVerseId,
  });

  const ChapterReaderArgs.today({ChapterHighlightRange? highlightRange})
    : book = null,
      chapter = null,
      versionCode = null,
      highlightRange = highlightRange,
      libraryVerseId = null;

  const ChapterReaderArgs.saved({
    required int libraryVerseId,
    ChapterHighlightRange? highlightRange,
    String? versionCode,
  })  : book = null,
        chapter = null,
        versionCode = versionCode,
        highlightRange = highlightRange,
        libraryVerseId = libraryVerseId;

  final String? book;
  final int? chapter;
  final String? versionCode;
  final ChapterHighlightRange? highlightRange;
  final int? libraryVerseId;

  ChapterRequest toRequest() {
    if (libraryVerseId != null) {
      return ChapterRequest.saved(
        libraryVerseId: libraryVerseId!,
        versionCode: versionCode,
      );
    }

    if (book != null && chapter != null) {
      return ChapterRequest(
        book: book!,
        chapter: chapter!,
        versionCode: versionCode,
      );
    }

    return const ChapterRequest.today();
  }
}

class ChapterReaderScreen extends ConsumerStatefulWidget {
  const ChapterReaderScreen({
    super.key,
    this.args = const ChapterReaderArgs.today(),
  });

  final ChapterReaderArgs args;

  @override
  ConsumerState<ChapterReaderScreen> createState() =>
      _ChapterReaderScreenState();
}

class _ChapterReaderScreenState extends ConsumerState<ChapterReaderScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(chapterReaderControllerProvider.notifier)
          .loadChapter(
            request: widget.args.toRequest(),
            highlightRange: widget.args.highlightRange,
          );
    });
  }

  Future<void> _onRefresh() {
    return ref
        .read(chapterReaderControllerProvider.notifier)
        .loadChapter(
          request: widget.args.toRequest(),
          forceRefresh: true,
          highlightRange: widget.args.highlightRange,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chapterReaderControllerProvider);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.midnightFaithDark,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.midnightGradient),
        child: SafeArea(
          child: Column(
            children: [
              _ChapterHeader(state: state),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: _TextScaleControls(
                  textScale: state.textScale,
                  onIncrease: () => ref
                      .read(chapterReaderControllerProvider.notifier)
                      .increaseText(),
                  onDecrease: () => ref
                      .read(chapterReaderControllerProvider.notifier)
                      .decreaseText(),
                  onReset: () => ref
                      .read(chapterReaderControllerProvider.notifier)
                      .resetTextScale(),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.holyGold,
                  backgroundColor: AppColors.midnightFaith,
                  onRefresh: _onRefresh,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _buildBody(state, l10n),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ChapterReaderState state, AppLocalizations l10n) {
    if (state.isLoading && state.chapter == null) {
      return const _ChapterSkeleton();
    }

    if (state.hasError && state.chapter == null) {
      return _ChapterError(
        message: state.errorMessage ?? l10n.chapterLoadError,
        onRetry: _onRefresh,
      );
    }

    final chapter = state.chapter;
    if (chapter == null) {
      return _ChapterError(message: l10n.chapterLoadError, onRetry: _onRefresh);
    }

    return _ChapterContent(
      chapter: chapter,
      textScale: state.textScale,
      highlightRange: state.highlightRange,
      isRefreshing: state.isLoading,
    );
  }
}

class _ChapterHeader extends ConsumerWidget {
  const _ChapterHeader({required this.state});

  final ChapterReaderState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final chapter = state.chapter;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CircleButton(
            icon: Icons.arrow_back_ios_new,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chapter?.reference.isNotEmpty == true
                      ? chapter!.reference
                      : l10n.chapterReaderTitle,
                  style: AppTextStyles.headline2.copyWith(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      color: AppColors.holyGold,
                      size: AppSizes.iconSmall,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      chapter != null
                          ? '${chapter.versionName} (${chapter.displayVersionCode})'
                          : l10n.chapterLoading,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.softMist.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TextScaleControls extends StatelessWidget {
  const _TextScaleControls({
    required this.textScale,
    required this.onIncrease,
    required this.onDecrease,
    required this.onReset,
  });

  final double textScale;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isAtMin = (textScale - kChapterTextScaleMin) < 0.01;
    final isAtMax = (kChapterTextScaleMax - textScale) < 0.01;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.pureWhite.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.pureWhite.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.chapterTextSize,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${(textScale * 100).round()}%',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.softMist.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          _ControlPill(label: 'A-', onTap: isAtMin ? null : onDecrease),
          const SizedBox(width: AppSpacing.sm),
          _ControlPill(label: 'A+', onTap: isAtMax ? null : onIncrease),
          const SizedBox(width: AppSpacing.sm),
          _ControlPill(label: l10n.chapterResetText, onTap: onReset),
        ],
      ),
    );
  }
}

class _ChapterContent extends StatelessWidget {
  const _ChapterContent({
    required this.chapter,
    required this.textScale,
    required this.highlightRange,
    required this.isRefreshing,
  });

  final Chapter chapter;
  final double textScale;
  final ChapterHighlightRange? highlightRange;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          itemBuilder: (context, index) {
            final verse = chapter.verses[index];
            final isHighlighted =
                highlightRange?.contains(verse.number) ?? false;
            return _VerseTile(
              verse: verse,
              textScale: textScale,
              isHighlighted: isHighlighted,
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemCount: chapter.verses.length,
        ),
        if (isRefreshing)
          Positioned(
            right: AppSpacing.lg,
            top: AppSpacing.md,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.pureWhite.withValues(alpha: 0.08),
                borderRadius: AppBorderRadius.button,
                border: Border.all(
                  color: AppColors.pureWhite.withValues(alpha: 0.1),
                ),
              ),
              child: const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.holyGold),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _VerseTile extends StatelessWidget {
  const _VerseTile({
    required this.verse,
    required this.textScale,
    required this.isHighlighted,
  });

  final ChapterVerse verse;
  final double textScale;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final baseTextStyle = AppTextStyles.bodyLarge.copyWith(
      color: AppColors.pureWhite,
      height: 1.6,
      fontSize: 17 * textScale,
    );
    final numberStyle = AppTextStyles.bodySmall.copyWith(
      color: AppColors.holyGold.withValues(alpha: 0.85),
      fontWeight: FontWeight.w700,
      fontSize: 12 * textScale,
    );
    final studyStyle = AppTextStyles.bodySmall.copyWith(
      color: AppColors.softMist.withValues(alpha: 0.85),
      fontStyle: FontStyle.italic,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.holyGold.withValues(alpha: 0.08)
            : AppColors.pureWhite.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(
          color: isHighlighted
              ? AppColors.holyGold.withValues(alpha: 0.35)
              : AppColors.pureWhite.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('${verse.number}', style: numberStyle),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(verse.text, style: baseTextStyle)),
            ],
          ),
          if (verse.study != null && verse.study!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(verse.study!, style: studyStyle),
          ],
        ],
      ),
    );
  }
}

class _ChapterSkeleton extends StatelessWidget {
  const _ChapterSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      itemBuilder: (_, index) {
        final height = 70 + (index % 3) * 12;
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == 0 ? AppSpacing.md : AppSpacing.lg,
          ),
          child: Container(
            height: height.toDouble(),
            decoration: BoxDecoration(
              color: AppColors.pureWhite.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            ),
          ),
        );
      },
      itemCount: 8,
    );
  }
}

class _ChapterError extends StatelessWidget {
  const _ChapterError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 32),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.pureWhite,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.errorRetry),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.pureWhite.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.pureWhite.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, color: AppColors.pureWhite),
      ),
    );
  }
}

class _ControlPill extends StatelessWidget {
  const _ControlPill({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppBorderRadius.button,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: onTap == null
              ? AppColors.pureWhite.withValues(alpha: 0.04)
              : AppColors.pureWhite.withValues(alpha: 0.08),
          borderRadius: AppBorderRadius.button,
          border: Border.all(
            color: AppColors.pureWhite.withValues(
              alpha: onTap == null ? 0.04 : 0.14,
            ),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.pureWhite,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
