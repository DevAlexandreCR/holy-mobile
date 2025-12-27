import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_design_tokens.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';
import 'package:holyverso/domain/verse/reference_parser.dart';
import 'package:holyverso/domain/verse/saved_verse.dart';
import 'package:holyverso/presentation/screens/verse/chapter_reader_screen.dart';
import 'package:holyverso/presentation/state/verse/chapter_reader_state.dart';
import 'package:holyverso/presentation/state/verse/saved_verses_controller.dart';
import 'package:holyverso/presentation/state/verse/saved_verses_state.dart';
import 'package:holyverso/presentation/state/verse/verse_controller.dart';
import 'package:share_plus/share_plus.dart';

class SavedVersesScreen extends ConsumerStatefulWidget {
  const SavedVersesScreen({super.key});

  @override
  ConsumerState<SavedVersesScreen> createState() => _SavedVersesScreenState();
}

class _SavedVersesScreenState extends ConsumerState<SavedVersesScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(savedVersesControllerProvider.notifier).loadInitialSaved();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final state = ref.read(savedVersesControllerProvider);
    if (state.isFetchingMore || state.nextCursor == null) return;

    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(savedVersesControllerProvider.notifier).loadMoreSaved();
    }
  }

  ChapterHighlightRange? _highlightFromReference(String reference) {
    final parsed = ReferenceParser.parseHighlightRange(reference);
    if (parsed == null) return null;
    return ChapterHighlightRange(start: parsed.start, end: parsed.end);
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(savedVersesControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.midnightFaithDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.pureWhite),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          l10n.savedVersesTitle,
          style: AppTextStyles.headline3.copyWith(
            color: AppColors.pureWhite,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.midnightGradient),
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _buildBody(state, l10n),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(SavedVersesState state, AppLocalizations l10n) {
    if (state.isLoading) {
      return const _SavedVersesSkeleton();
    }

    if (state.hasError && state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ErrorBanner(message: state.error ?? l10n.genericError),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () =>
                    ref.read(savedVersesControllerProvider.notifier).loadInitialSaved(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.holyGold,
                  foregroundColor: AppColors.midnightFaithDark,
                ),
                child: Text(l10n.errorRetry),
              ),
            ],
          ),
        ),
      );
    }

    if (state.items.isEmpty) {
      return _EmptySavedState(
        onDiscover: () => context.push('/verse'),
      );
    }

    return Column(
      children: [
        if (state.hasError)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: _ErrorBanner(message: state.error ?? l10n.genericError),
          ),
        Expanded(
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            itemBuilder: (context, index) {
              if (index >= state.items.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.holyGold),
                    ),
                  ),
                );
              }

              final verse = state.items[index];
              final isProcessing =
                  state.pendingIds.contains(verse.libraryVerseId);
              return _SavedVerseCard(
                verse: verse,
                formattedDate: _formatDate(verse.savedAt),
                onShare: () => _shareVerse(verse),
                onUnsave: () =>
                    ref.read(savedVersesControllerProvider.notifier).toggleSave(
                          verse.libraryVerseId,
                        ),
                onReadChapter: () {
                  final highlight = _highlightFromReference(verse.reference);
                  context.push(
                    '/verse/chapter',
                    extra: ChapterReaderArgs.saved(
                      libraryVerseId: verse.libraryVerseId,
                      versionCode: verse.versionCode,
                      highlightRange: highlight,
                    ),
                  );
                },
                isProcessing: isProcessing,
              );
            },
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.md),
            itemCount: state.items.length + (state.isFetchingMore ? 1 : 0),
          ),
        ),
      ],
    );
  }

  void _shareVerse(SavedVerse verse) {
    final shareText =
        '"${verse.text}"\n${verse.reference}\n${verse.versionName} (${verse.displayVersionCode})';
    Share.share(shareText);
    ref.read(verseControllerProvider.notifier).shareVerse(verse.libraryVerseId);
  }
}

class _SavedVerseCard extends StatelessWidget {
  const _SavedVerseCard({
    required this.verse,
    required this.formattedDate,
    required this.onShare,
    required this.onUnsave,
    required this.onReadChapter,
    this.isProcessing = false,
  });

  final SavedVerse verse;
  final String formattedDate;
  final VoidCallback onShare;
  final VoidCallback onUnsave;
  final VoidCallback onReadChapter;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.midnightFaith.withValues(alpha: 0.65),
            AppColors.midnightFaithDark.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.pureWhite.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.holyGold.withValues(alpha: 0.12),
                  borderRadius: AppBorderRadius.button,
                  border: Border.all(
                    color: AppColors.holyGold.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  verse.theme.isNotEmpty ? verse.theme : '•',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.holyGold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.bookmark, color: AppColors.holyGold.withValues(alpha: 0.9)),
              const SizedBox(width: AppSpacing.xs),
              Text(
                formattedDate,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.softMist.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            verse.reference,
            style: AppTextStyles.headline3.copyWith(
              color: AppColors.pureWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${verse.versionName} (${verse.displayVersionCode})',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.softMist.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            verse.text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.pureWhite,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: isProcessing ? null : onReadChapter,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.holyGold.withValues(alpha: 0.18),
                  foregroundColor: AppColors.holyGold,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppBorderRadius.button,
                    side: BorderSide(
                      color: AppColors.holyGold.withValues(alpha: 0.35),
                    ),
                  ),
                ),
                icon: const Icon(Icons.menu_book_rounded),
                label: Text(
                  l10n.readFullChapter,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              _CircleAction(
                icon: Icons.ios_share,
                onTap: isProcessing ? null : onShare,
              ),
              const SizedBox(width: AppSpacing.sm),
              _CircleAction(
                icon: Icons.bookmark_remove_outlined,
                onTap: isProcessing ? null : onUnsave,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite.withValues(alpha: 0.08),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.pureWhite.withValues(alpha: 0.08)),
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.pureWhite),
        onPressed: onTap,
      ),
    );
  }
}

class _EmptySavedState extends StatelessWidget {
  const _EmptySavedState({this.onDiscover});

  final VoidCallback? onDiscover;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.pureWhite.withValues(alpha: 0.06),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.pureWhite.withValues(alpha: 0.1)),
              ),
              child: const Icon(
                Icons.bookmark_border,
                size: 42,
                color: AppColors.holyGold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.savedVersesEmptyTitle,
              style: AppTextStyles.headline3.copyWith(
                color: AppColors.pureWhite,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.savedVersesEmptySubtitle,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.softMist.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onDiscover,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.holyGold,
                foregroundColor: AppColors.midnightFaithDark,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppBorderRadius.button,
                ),
              ),
              icon: const Icon(Icons.auto_awesome),
              label: Text(
                l10n.savedVersesEmptyCta,
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.14),
        borderRadius: AppBorderRadius.card,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
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

class _SavedVersesSkeleton extends StatelessWidget {
  const _SavedVersesSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.pureWhite.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 14,
                width: 120,
                decoration: BoxDecoration(
                  color: AppColors.pureWhite.withValues(alpha: 0.08),
                  borderRadius: AppBorderRadius.button,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                height: 18,
                width: 200,
                decoration: BoxDecoration(
                  color: AppColors.pureWhite.withValues(alpha: 0.08),
                  borderRadius: AppBorderRadius.button,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                height: 48,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.pureWhite.withValues(alpha: 0.06),
                  borderRadius: AppBorderRadius.card,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
