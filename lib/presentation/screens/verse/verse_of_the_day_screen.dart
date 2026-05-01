import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/core/services/verse_image_service.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_design_tokens.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';
import 'package:holyverso/domain/verse/reference_parser.dart';
import 'package:holyverso/domain/verse/verse_of_the_day.dart';
import 'package:holyverso/presentation/screens/verse/chapter_reader_screen.dart';
import 'package:holyverso/presentation/state/auth/auth_controller.dart';
import 'package:holyverso/presentation/state/verse/saved_verses_controller.dart';
import 'package:holyverso/presentation/state/verse/chapter_reader_state.dart';
import 'package:holyverso/presentation/state/verse/widget_adoption_prompt_controller.dart';
import 'package:holyverso/presentation/state/verse/verse_controller.dart';
import 'package:holyverso/presentation/state/verse/verse_state.dart';
import 'package:holyverso/presentation/widgets/holy_button.dart';
import 'package:holyverso/presentation/widgets/common/holy_bottom_sheet.dart';
import 'package:share_plus/share_plus.dart';

class VerseOfTheDayScreen extends ConsumerStatefulWidget {
  const VerseOfTheDayScreen({super.key});

  @override
  ConsumerState<VerseOfTheDayScreen> createState() =>
      _VerseOfTheDayScreenState();
}

class _VerseOfTheDayScreenState extends ConsumerState<VerseOfTheDayScreen>
    with WidgetsBindingObserver {
  bool _isFavorite = false;
  final VerseImageService _verseImageService = VerseImageService();
  bool _isGeneratingImage = false;
  String? _lastSoftErrorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(verseControllerProvider.notifier).loadVerse());
      unawaited(
        ref
            .read(widgetAdoptionPromptControllerProvider.notifier)
            .refreshStatus(),
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      unawaited(
        ref
            .read(widgetAdoptionPromptControllerProvider.notifier)
            .refreshStatus(),
      );
    }
  }

  Future<void> _onRefresh() {
    return ref
        .read(verseControllerProvider.notifier)
        .loadVerse(forceRefresh: true);
  }

  void _promptLogin() {
    context.go('/login', extra: context.l10n.loginRequiredMessage);
  }

  void _onShare(VerseOfTheDay verse, Rect? sharePositionOrigin) {
    final l10n = context.l10n;
    final shareText =
        '"${verse.text}"\n${verse.reference}\n${verse.versionName} '
        '(${verse.displayVersionCode})';
    Share.share(
      shareText,
      subject: l10n.shareSubject,
      sharePositionOrigin: sharePositionOrigin,
    );

    if (verse.libraryVerseId != null) {
      ref
          .read(verseControllerProvider.notifier)
          .shareVerse(verse.libraryVerseId!);
    }
  }

  void _openChapterReader(VerseOfTheDay verse) {
    final highlight = _extractHighlightRange(verse.reference);
    context.push(
      '/verse/chapter',
      extra: ChapterReaderArgs.today(highlightRange: highlight),
    );
  }

  ChapterHighlightRange? _extractHighlightRange(String reference) {
    final parsed = ReferenceParser.parseHighlightRange(reference);
    if (parsed == null) return null;
    return ChapterHighlightRange(start: parsed.start, end: parsed.end);
  }

  Future<void> _onShareAsImage(
    VerseOfTheDay verse,
    Rect? sharePositionOrigin,
  ) async {
    if (_isGeneratingImage) return;

    setState(() => _isGeneratingImage = true);

    try {
      final l10n = context.l10n;
      await _verseImageService.shareVerseAsImage(
        verse,
        sharePositionOrigin: sharePositionOrigin,
        subject: l10n.shareSubject,
      );

      if (verse.libraryVerseId != null) {
        ref
            .read(verseControllerProvider.notifier)
            .shareVerse(verse.libraryVerseId!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.shareImageError),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingImage = false);
      }
    }
  }

  void _showShareOptions(VerseOfTheDay verse, Rect? sharePositionOrigin) {
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => HolyBottomSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.shareOptionsTitle,
              style: AppTextStyles.headline3.copyWith(
                color: AppColors.pureWhite,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.holyGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.image_outlined, color: AppColors.holyGold),
              ),
              title: Text(
                l10n.shareAsImage,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.pureWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                l10n.shareAsImageDescription,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.softMist.withValues(alpha: 0.7),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _onShareAsImage(verse, sharePositionOrigin);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.pureWhite.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.text_fields, color: AppColors.pureWhite),
              ),
              title: Text(
                l10n.shareAsText,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.pureWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                l10n.shareAsTextDescription,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.softMist.withValues(alpha: 0.7),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _onShare(verse, sharePositionOrigin);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _showWidgetSetupSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _WidgetSetupSheet(
          onRefreshStatus: () async {
            Navigator.of(sheetContext).pop();
            await ref
                .read(widgetAdoptionPromptControllerProvider.notifier)
                .refreshStatus();
          },
        );
      },
    );
  }

  Future<void> _toggleSave(VerseOfTheDay verse) async {
    final libraryVerseId = verse.libraryVerseId;
    if (libraryVerseId == null) return;

    final savedNotifier = ref.read(savedVersesControllerProvider.notifier);
    final previousError = ref.read(savedVersesControllerProvider).error;
    await savedNotifier.toggleSave(libraryVerseId);

    final savedState = ref.read(savedVersesControllerProvider);
    if (savedState.error != null && savedState.error != previousError) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(savedState.error!),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    final isSavedNow = savedNotifier.isSaved(libraryVerseId);
    ref
        .read(verseControllerProvider.notifier)
        .updateSavedFlag(libraryVerseId, isSavedNow);

    if (!mounted) return;
    final l10n = context.l10n;
    final message = isSavedNow
        ? l10n.savedVerseToastAdded
        : l10n.savedVerseToastRemoved;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSavedNow
            ? AppColors.holyGold.withValues(alpha: 0.85)
            : AppColors.midnightFaith,
      ),
    );
  }

  void _toggleFavorite() {
    final isAuthenticated = ref.read(authControllerProvider).isAuthenticated;
    if (!isAuthenticated) {
      _promptLogin();
      return;
    }

    final verse = ref.read(verseControllerProvider).verse;
    final newFavoriteState = !_isFavorite;

    setState(() => _isFavorite = newFavoriteState);

    if (newFavoriteState && verse?.libraryVerseId != null) {
      ref
          .read(verseControllerProvider.notifier)
          .likeVerse(verse!.libraryVerseId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<VerseState>(verseControllerProvider, (previous, next) {
      final nextMessage = next.errorMessage;
      if (!mounted ||
          next.verse == null ||
          nextMessage == null ||
          nextMessage == _lastSoftErrorMessage) {
        return;
      }

      _lastSoftErrorMessage = nextMessage;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(nextMessage)));
    });

    final verseState = ref.watch(verseControllerProvider);
    final verse = verseState.verse;
    final l10n = context.l10n;
    final authState = ref.watch(authControllerProvider);
    final isGuest = !authState.isAuthenticated;
    final savedState = ref.watch(savedVersesControllerProvider);
    final widgetPromptState = ref.watch(widgetAdoptionPromptControllerProvider);
    final verseId = verse?.libraryVerseId;
    final isSaved = verseId != null && savedState.savedIds.contains(verseId);
    final isSaving = verseId != null && savedState.pendingIds.contains(verseId);

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
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: AppColors.midnightGradient),
        child: SafeArea(
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
                _VerseCard(verse: verse, isLoading: verseState.isLoading),
                if (verse != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _VerseActionBar(
                    isSaved: isSaved,
                    isSaving: isSaving,
                    isFavorite: _isFavorite,
                    isGeneratingImage: _isGeneratingImage,
                    canUseAccountFeatures: !isGuest,
                    onToggleSave: isGuest ? null : () => _toggleSave(verse),
                    onToggleFavorite: isGuest ? null : _toggleFavorite,
                    onShare: isGuest
                        ? null
                        : (rect) => _showShareOptions(verse, rect),
                  ),
                ],
                if (verse != null && !isGuest) ...[
                  const SizedBox(height: AppSpacing.md),
                  _ChapterEntryCard(onTap: () => _openChapterReader(verse)),
                  if (widgetPromptState.shouldShowPrompt) ...[
                    const SizedBox(height: AppSpacing.md),
                    _WidgetAdoptionCard(
                      onShowInstructions: _showWidgetSetupSheet,
                      onDismiss: () => ref
                          .read(widgetAdoptionPromptControllerProvider.notifier)
                          .dismissPrompt(),
                    ),
                  ],
                ],
                if (isGuest) ...[
                  const SizedBox(height: AppSpacing.md),
                  _GuestCtaCard(
                    onRegister: () => context.go('/register'),
                    onLogin: _promptLogin,
                  ),
                ],
                if (verseState.hasError && verse == null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: _ErrorPill(
                      message: verseState.errorMessage ?? l10n.verseLoadError,
                    ),
                  ),
              ],
            ),
          ),
        ),
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
  const _VerseCard({required this.verse, required this.isLoading});

  final VerseOfTheDay? verse;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.midnightFaith.withValues(alpha: 0.85),
        borderRadius: AppBorderRadius.card,
        border: Border.all(color: AppColors.pureWhite.withValues(alpha: 0.08)),
        boxShadow: AppShadows.cardShadow,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: verse != null
            ? _VerseContent(verse: verse!)
            : isLoading
            ? _SkeletonPlaceholder()
            : const _EmptyState(),
      ),
    );
  }
}

class _VerseActionBar extends StatelessWidget {
  const _VerseActionBar({
    required this.isSaved,
    required this.isSaving,
    required this.isFavorite,
    required this.isGeneratingImage,
    required this.canUseAccountFeatures,
    required this.onToggleSave,
    required this.onToggleFavorite,
    required this.onShare,
  });

  final bool isSaved;
  final bool isSaving;
  final bool isFavorite;
  final bool isGeneratingImage;
  final bool canUseAccountFeatures;
  final VoidCallback? onToggleSave;
  final VoidCallback? onToggleFavorite;
  final void Function(Rect?)? onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _VerseActionButton(
            icon: isSaved
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            tooltip: isSaved ? l10n.savedAction : l10n.saveAction,
            selected: isSaved,
            enabled: canUseAccountFeatures,
            isLoading: isSaving,
            onPressed: onToggleSave,
          ),
          _VerseActionButton(
            icon: isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            tooltip: l10n.likesLabel,
            selected: isFavorite,
            enabled: canUseAccountFeatures,
            onPressed: onToggleFavorite,
          ),
          Builder(
            builder: (BuildContext context) {
              return _VerseActionButton(
                icon: Icons.share_outlined,
                tooltip: l10n.shareTooltip,
                selected: false,
                enabled: canUseAccountFeatures,
                isLoading: isGeneratingImage,
                onPressed: onShare == null
                    ? null
                    : () {
                        final box = context.findRenderObject() as RenderBox?;
                        final sharePositionOrigin = box == null
                            ? null
                            : box.localToGlobal(Offset.zero) & box.size;
                        onShare!(sharePositionOrigin);
                      },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _VerseActionButton extends StatelessWidget {
  const _VerseActionButton({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.enabled,
    required this.onPressed,
    this.isLoading = false,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final bool enabled;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final effectiveEnabled = enabled && onPressed != null && !isLoading;
    final foreground = !enabled
        ? AppColors.softMist.withValues(alpha: 0.36)
        : selected
        ? AppColors.holyGold
        : AppColors.pureWhite.withValues(alpha: 0.86);

    return Semantics(
      button: true,
      enabled: effectiveEnabled,
      label: tooltip,
      selected: selected,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: effectiveEnabled ? onPressed : null,
            borderRadius: BorderRadius.circular(AppBorderRadius.full),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: ExcludeSemantics(
                child: isLoading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(foreground),
                        ),
                      )
                    : Icon(icon, color: foreground, size: 24),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GuestCtaCard extends StatelessWidget {
  const _GuestCtaCard({required this.onRegister, required this.onLogin});

  final VoidCallback onRegister;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.pureWhite.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.pureWhite.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.guestCtaTitle,
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.pureWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.guestAccessFeatureMessage,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.softMist.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.guestAccessFreeMessage,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.softMist.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          HolyButton(label: l10n.guestCtaAction, onPressed: onRegister),
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            onPressed: onLogin,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.holyGold,
              textStyle: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(l10n.loginTitle),
          ),
        ],
      ),
    );
  }
}

class _ChapterEntryCard extends StatelessWidget {
  const _ChapterEntryCard({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.pureWhite.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(color: AppColors.pureWhite.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.holyGold.withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.holyGold.withValues(alpha: 0.35),
                ),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: AppColors.holyGold,
                size: AppSizes.iconMedium,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.readFullChapter,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.pureWhite,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.readFullChapterSubtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.softMist.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.pureWhite.withValues(alpha: 0.8),
              size: AppSizes.iconSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _WidgetAdoptionCard extends StatelessWidget {
  const _WidgetAdoptionCard({
    required this.onShowInstructions,
    required this.onDismiss,
  });

  final VoidCallback onShowInstructions;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.pureWhite.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.pureWhite.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.holyGold.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.holyGold.withValues(alpha: 0.35),
                  ),
                ),
                child: const Icon(
                  Icons.widgets_outlined,
                  color: AppColors.holyGold,
                  size: AppSizes.iconMedium,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.widgetPromptTitle,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.pureWhite,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.widgetPromptBody,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.softMist.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          HolyButton(
            label: l10n.widgetPromptPrimaryAction,
            onPressed: onShowInstructions,
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            onPressed: onDismiss,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.softMist,
              textStyle: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(l10n.widgetPromptDismissAction),
          ),
        ],
      ),
    );
  }
}

class _WidgetSetupSheet extends StatelessWidget {
  const _WidgetSetupSheet({required this.onRefreshStatus});

  final Future<void> Function() onRefreshStatus;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final steps = isAndroid
        ? [
            l10n.widgetSetupAndroidStepOne,
            l10n.widgetSetupAndroidStepTwo,
            l10n.widgetSetupAndroidStepThree,
          ]
        : [
            l10n.widgetSetupIosStepOne,
            l10n.widgetSetupIosStepTwo,
            l10n.widgetSetupIosStepThree,
          ];

    return HolyBottomSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.widgetSetupTitle,
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.pureWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isAndroid
                ? l10n.widgetSetupAndroidSubtitle
                : l10n.widgetSetupIosSubtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.softMist.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (var index = 0; index < steps.length; index++) ...[
            _WidgetSetupStep(number: index + 1, text: steps[index]),
            if (index < steps.length - 1) const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.md),
          HolyButton(
            label: l10n.widgetSetupRefreshAction,
            onPressed: () {
              unawaited(onRefreshStatus());
            },
          ),
        ],
      ),
    );
  }
}

class _WidgetSetupStep extends StatelessWidget {
  const _WidgetSetupStep({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.holyGold.withValues(alpha: 0.16),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.holyGold.withValues(alpha: 0.35),
            ),
          ),
          child: Text(
            '$number',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.holyGold,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.pureWhite,
              ),
            ),
          ),
        ),
      ],
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
          onPressed: () => context.go('/profile/settings'),
          icon: const Icon(Icons.settings_outlined),
          label: const Text('Ir a Ajustes'),
        ),
      ],
    );
  }
}

class _ShimmerBlock extends StatelessWidget {
  const _ShimmerBlock({required this.height, required this.width});

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
