import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:holyverso/core/errors/app_error_mapper.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/core/services/verse_image_service.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_design_tokens.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';
import 'package:holyverso/data/bible/bible_repository.dart';
import 'package:holyverso/domain/devotionals/devotional.dart';
import 'package:holyverso/domain/devotionals/devotional_verse_reference.dart';
import 'package:holyverso/domain/verse/search_result.dart';
import 'package:holyverso/domain/verse/verse_of_the_day.dart';
import 'package:holyverso/presentation/state/auth/auth_controller.dart';
import 'package:holyverso/presentation/widgets/common/holy_bottom_sheet.dart';
import 'package:share_plus/share_plus.dart';

List<DevotionalVerseReference> devotionalPreviewReferences(
  Devotional devotional,
) {
  final source = devotional.primaryReferences.isNotEmpty
      ? devotional.primaryReferences
      : devotional.verseReferences.isNotEmpty
      ? [devotional.verseReferences.first]
      : const <DevotionalVerseReference>[];

  final seen = <String>{};
  final references = <DevotionalVerseReference>[];

  for (final reference in source) {
    final key = reference.id.isNotEmpty
        ? reference.id
        : reference.referenceLabel.toLowerCase();
    if (seen.add(key)) {
      references.add(reference);
    }
  }

  return references;
}

Future<void> showDevotionalReferencePreview(
  BuildContext context, {
  required DevotionalVerseReference reference,
}) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final authState = container.read(authControllerProvider);

  if (!authState.isAuthenticated) {
    final message = Uri.encodeComponent(context.l10n.loginRequiredMessage);
    context.go('/login?message=$message');
    return;
  }

  await showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (_) => _DevotionalReferencePreviewDialog(reference: reference),
  );
}

class DevotionalReferenceLinks extends StatelessWidget {
  const DevotionalReferenceLinks({
    super.key,
    required this.references,
    required this.onTap,
    this.compact = false,
  });

  final List<DevotionalVerseReference> references;
  final ValueChanged<DevotionalVerseReference> onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (references.isEmpty) {
      return const SizedBox.shrink();
    }

    final textStyle = compact
        ? AppTextStyles.labelSmall.copyWith(
            color: AppColors.holyGold.withValues(alpha: 0.95),
            fontWeight: FontWeight.w700,
          )
        : AppTextStyles.reference.copyWith(
            color: AppColors.holyGold.withValues(alpha: 0.95),
            fontWeight: FontWeight.w700,
          );

    final verticalPadding = compact ? 2.0 : 4.0;
    final horizontalPadding = compact ? 2.0 : 4.0;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        for (final reference in references)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onTap(reference),
              borderRadius: BorderRadius.circular(AppSpacing.xs),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Text('${reference.referenceLabel} ->', style: textStyle),
              ),
            ),
          ),
      ],
    );
  }
}

class _DevotionalReferencePreviewDialog extends ConsumerStatefulWidget {
  const _DevotionalReferencePreviewDialog({required this.reference});

  final DevotionalVerseReference reference;

  @override
  ConsumerState<_DevotionalReferencePreviewDialog> createState() =>
      _DevotionalReferencePreviewDialogState();
}

class _DevotionalReferencePreviewDialogState
    extends ConsumerState<_DevotionalReferencePreviewDialog> {
  final VerseImageService _verseImageService = VerseImageService();

  SearchResult? _result;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isSharingImage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadPassage());
    });
  }

  Future<void> _loadPassage() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final result = await ref
          .read(bibleRepositoryProvider)
          .searchVerses(widget.reference.referenceLabel);
      if (!mounted) {
        return;
      }

      setState(() {
        _result = result;
        _isLoading = false;
        _errorMessage = result == null
            ? context.l10n.verseSearchNoResults
            : null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _result = null;
        _isLoading = false;
        _errorMessage = AppErrorMapper.toMessage(
          error,
          l10n: context.l10n,
          fallbackMessage: context.l10n.genericError,
        );
      });
    }
  }

  Future<void> _shareAsImage(SearchResult result, Rect? shareOrigin) async {
    if (_isSharingImage || !result.canShareAsImage) {
      return;
    }

    setState(() => _isSharingImage = true);

    try {
      final l10n = context.l10n;
      final verse = VerseOfTheDay(
        date: '',
        versionCode: result.version.abbreviation,
        versionName: result.version.name,
        reference: result.reference.displayReference,
        text: _buildVerseText(result),
      );

      await _verseImageService.shareVerseAsImage(
        verse,
        sharePositionOrigin: shareOrigin,
        subject: l10n.shareSubject,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.shareImageError),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSharingImage = false);
      }
    }
  }

  Future<void> _shareAsText(SearchResult result, Rect? shareOrigin) {
    return Share.share(
      _buildShareText(result),
      subject: context.l10n.shareSubject,
      sharePositionOrigin: shareOrigin,
    );
  }

  void _showShareOptions(SearchResult result, Rect? sharePositionOrigin) {
    final l10n = context.l10n;
    final canShareImage = result.canShareAsImage;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => HolyBottomSheet(
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
              enabled: canShareImage,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      (canShareImage ? AppColors.holyGold : AppColors.softMist)
                          .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.image_outlined,
                  color: canShareImage
                      ? AppColors.holyGold
                      : AppColors.softMist,
                ),
              ),
              title: Text(
                l10n.shareAsImage,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: canShareImage
                      ? AppColors.pureWhite
                      : AppColors.softMist,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                canShareImage
                    ? l10n.shareAsImageDescription
                    : l10n.verseSearchShareImageDisabled,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.softMist.withValues(alpha: 0.7),
                ),
              ),
              onTap: !canShareImage
                  ? null
                  : () {
                      Navigator.of(sheetContext).pop();
                      _shareAsImage(result, sharePositionOrigin);
                    },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.pureWhite.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.text_fields,
                  color: AppColors.pureWhite,
                ),
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
                Navigator.of(sheetContext).pop();
                _shareAsText(result, sharePositionOrigin);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _buildVerseText(SearchResult result) {
    final buffer = StringBuffer();
    for (final verse in result.verses) {
      buffer.writeln('${verse.verseNumber}. ${verse.text}');
      buffer.writeln();
    }
    return buffer.toString().trim();
  }

  String _buildShareText(SearchResult result) {
    final buffer = StringBuffer();
    buffer.writeln(result.reference.displayReference);
    buffer.writeln();
    buffer.writeln(_buildVerseText(result));
    buffer.writeln();
    buffer.writeln('📖 ${result.version.name}');
    return buffer.toString().trim();
  }

  List<InlineSpan> _buildVerseSpans(SearchResult result) {
    final spans = <InlineSpan>[];

    for (var index = 0; index < result.verses.length; index++) {
      final verse = result.verses[index];
      if (index > 0) {
        spans.add(const TextSpan(text: '\n\n'));
      }
      spans.add(
        TextSpan(
          text: '${verse.verseNumber}. ',
          style: AppTextStyles.reference.copyWith(
            color: AppColors.holyGold,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      spans.add(
        TextSpan(
          text: verse.text,
          style: AppTextStyles.headline3.copyWith(
            color: AppColors.pureWhite,
            fontWeight: FontWeight.w600,
            height: 1.55,
          ),
        ),
      );
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final result = _result;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: mediaQuery.size.height * 0.86,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.midnightFaithDark,
                AppColors.midnightFaith,
                AppColors.midnightFaith.withValues(alpha: 0.96),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppBorderRadius.xl),
            border: Border.all(
              color: AppColors.pureWhite.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 36,
                offset: const Offset(0, 24),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -72,
                right: -56,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.holyGold.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -96,
                left: -48,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.holyGold.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.reference.referenceLabel,
                                style: AppTextStyles.headline2.copyWith(
                                  color: AppColors.pureWhite,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                result != null
                                    ? '${result.version.name} (${result.version.abbreviation.toUpperCase()})'
                                    : context.l10n.chapterLoading,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.softMist.withValues(
                                    alpha: 0.82,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                          color: AppColors.pureWhite.withValues(alpha: 0.86),
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).closeButtonTooltip,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: _isLoading
                            ? const Center(
                                key: ValueKey('loading'),
                                child: CircularProgressIndicator(
                                  color: AppColors.holyGold,
                                ),
                              )
                            : _errorMessage != null
                            ? _PreviewStateCard(
                                key: const ValueKey('error'),
                                icon: Icons.menu_book_outlined,
                                title: _errorMessage!,
                                actionLabel: context.l10n.errorRetry,
                                onAction: _loadPassage,
                              )
                            : result == null
                            ? _PreviewStateCard(
                                key: const ValueKey('empty'),
                                icon: Icons.search_off_rounded,
                                title: context.l10n.verseSearchNoResults,
                                actionLabel: context.l10n.errorRetry,
                                onAction: _loadPassage,
                              )
                            : SingleChildScrollView(
                                key: const ValueKey('content'),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  decoration: BoxDecoration(
                                    color: AppColors.pureWhite.withValues(
                                      alpha: 0.05,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppBorderRadius.lg,
                                    ),
                                    border: Border.all(
                                      color: AppColors.pureWhite.withValues(
                                        alpha: 0.08,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '"',
                                        style: AppTextStyles.headline1.copyWith(
                                          color: AppColors.holyGold.withValues(
                                            alpha: 0.9,
                                          ),
                                          height: 0.8,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Text.rich(
                                        TextSpan(
                                          children: _buildVerseSpans(result),
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.lg),
                                      Text(
                                        result.reference.displayReference,
                                        style: AppTextStyles.reference.copyWith(
                                          color: AppColors.holyGold,
                                          shadows: [
                                            Shadow(
                                              color: AppColors.holyGold
                                                  .withValues(alpha: 0.42),
                                              blurRadius: 10,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Builder(
                      builder: (buttonContext) {
                        return SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: result == null
                                ? null
                                : () {
                                    final box =
                                        buttonContext.findRenderObject()
                                            as RenderBox?;
                                    final origin = box == null
                                        ? null
                                        : box.localToGlobal(Offset.zero) &
                                              box.size;
                                    _showShareOptions(result, origin);
                                  },
                            icon: _isSharingImage
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.midnightFaithDark,
                                    ),
                                  )
                                : const Icon(Icons.share_outlined),
                            label: Text(context.l10n.shareAction),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.holyGold,
                              foregroundColor: AppColors.midnightFaithDark,
                              disabledBackgroundColor: AppColors.pureWhite
                                  .withValues(alpha: 0.1),
                              disabledForegroundColor: AppColors.softMist,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.md,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppBorderRadius.full,
                                ),
                              ),
                              textStyle: AppTextStyles.labelLarge.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewStateCard extends StatelessWidget {
  const _PreviewStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String actionLabel;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.pureWhite.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(
            color: AppColors.pureWhite.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.holyGold, size: 28),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.pureWhite,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.holyGold,
                textStyle: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
