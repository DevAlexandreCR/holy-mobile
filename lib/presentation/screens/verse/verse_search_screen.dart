import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_design_tokens.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';
import 'package:holyverso/core/services/verse_image_service.dart';
import 'package:holyverso/domain/verse/book_suggestion.dart';
import 'package:holyverso/domain/verse/search_result.dart';
import 'package:holyverso/domain/verse/verse_of_the_day.dart';
import 'package:holyverso/presentation/state/verse/autocomplete_provider.dart';
import 'package:holyverso/presentation/state/verse/search_history_provider.dart';
import 'package:holyverso/presentation/state/verse/search_results_provider.dart';
import 'package:holyverso/presentation/widgets/common/holy_bottom_sheet.dart';
import 'package:share_plus/share_plus.dart';

class VerseSearchScreen extends ConsumerStatefulWidget {
  const VerseSearchScreen({super.key});

  @override
  ConsumerState<VerseSearchScreen> createState() => _VerseSearchScreenState();
}

class _VerseSearchScreenState extends ConsumerState<VerseSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final VerseImageService _verseImageService = VerseImageService();

  Timer? _debounce;
  String _submittedQuery = '';
  String _debouncedQuery = '';
  bool _isSharingImage = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    if (mounted) {
      setState(() {});
    }
    if (value.trim().isEmpty && _submittedQuery.isNotEmpty) {
      setState(() => _submittedQuery = '');
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _debouncedQuery = value);
    });
  }

  void _submitQuery(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    setState(() => _submittedQuery = trimmed);
    ref.read(searchHistoryProvider.notifier).addSearch(trimmed);
    _focusNode.unfocus();
  }

  void _clearSearch() {
    _debounce?.cancel();
    _controller.clear();
    setState(() {
      _submittedQuery = '';
      _debouncedQuery = '';
    });
    _focusNode.unfocus();
  }

  void _applySuggestion(BookSuggestion suggestion) {
    final nextValue = '${suggestion.bookName} ';
    _controller.value = TextEditingValue(
      text: nextValue,
      selection: TextSelection.collapsed(offset: nextValue.length),
    );
    setState(() => _debouncedQuery = nextValue);
    _focusNode.requestFocus();
  }

  void _applyHistory(String query) {
    _controller.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
    setState(() {
      _debouncedQuery = query;
      _submittedQuery = query;
    });
    _focusNode.unfocus();
  }

  Future<void> _shareAsImage(SearchResult result, Rect? shareOrigin) async {
    if (_isSharingImage || !result.canShareAsImage) return;

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
      if (!mounted) return;
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

  void _shareAsText(SearchResult result, Rect? shareOrigin) {
    final l10n = context.l10n;
    final shareText = _buildShareText(result);
    Share.share(
      shareText,
      subject: l10n.shareSubject,
      sharePositionOrigin: shareOrigin,
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

  String _resolveErrorMessage(Object error, AppLocalizations l10n) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final message = data['error']?['message']?.toString();
        if (message != null && message.isNotEmpty) return message;
      }
    }
    return l10n.genericError;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final suggestions = ref.watch(autocompleteProvider(_debouncedQuery));
    final history = ref.watch(searchHistoryProvider);
    final results = ref.watch(searchResultsProvider(_submittedQuery));

    return Scaffold(
      backgroundColor: AppColors.midnightFaith,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          l10n.verseSearchTitle,
          style: AppTextStyles.headline3.copyWith(
            color: AppColors.pureWhite,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _SearchBar(
              controller: _controller,
              focusNode: _focusNode,
              hintText: l10n.verseSearchPlaceholder,
              onChanged: _onQueryChanged,
              onSubmitted: _submitQuery,
              onClear: _clearSearch,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_focusNode.hasFocus)
              suggestions.when(
                data: (items) => items.isEmpty
                    ? const SizedBox.shrink()
                    : _SuggestionsList(
                        suggestions: items,
                        onSelected: _applySuggestion,
                      ),
                loading: () => const SizedBox.shrink(),
                error: (_, stackTrace) => const SizedBox.shrink(),
              ),
            if (_submittedQuery.isEmpty && history.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.verseSearchRecentTitle,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.softMist,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _HistoryList(items: history, onSelected: _applyHistory),
            ],
            if (_submittedQuery.isEmpty && history.isEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              _EmptyState(
                title: l10n.verseSearchEmptyTitle,
                subtitle: l10n.verseSearchEmptySubtitle,
              ),
            ],
            if (_submittedQuery.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              results.when(
                data: (result) {
                  if (result == null) {
                    return _EmptyState(
                      title: l10n.verseSearchNoResults,
                      subtitle: l10n.verseSearchNoResultsSubtitle,
                    );
                  }
                  return _SearchResultCard(
                    result: result,
                    isSharingImage: _isSharingImage,
                    onShare: _showShareOptions,
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.holyGold,
                      ),
                    ),
                  ),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: _ErrorPill(message: _resolveErrorMessage(error, l10n)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showShareOptions(SearchResult result, Rect? sharePositionOrigin) {
    final l10n = context.l10n;
    final canShareImage = result.canShareAsImage;
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
                      Navigator.pop(context);
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
                _shareAsText(result, sharePositionOrigin);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.midnightFaithDark,
        borderRadius: AppBorderRadius.input,
        border: Border.all(color: AppColors.holyGold.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: AppColors.holyGold.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.softMist),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              onTapOutside: (_) => focusNode.unfocus(),
              cursorColor: AppColors.holyGold,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.pureWhite,
              ),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.softMist.withValues(alpha: 0.6),
                ),
                contentPadding: EdgeInsets.zero,
                filled: true,
                fillColor: Colors.transparent,
                border: InputBorder.none,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.close),
              color: AppColors.softMist.withValues(alpha: 0.8),
              tooltip: 'Limpiar búsqueda',
            ),
        ],
      ),
    );
  }
}

class _SuggestionsList extends StatelessWidget {
  const _SuggestionsList({required this.suggestions, required this.onSelected});

  final List<BookSuggestion> suggestions;
  final ValueChanged<BookSuggestion> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.midnightFaithDark,
        borderRadius: AppBorderRadius.card,
        border: Border.all(color: AppColors.softMist.withValues(alpha: 0.2)),
      ),
      child: ListView.separated(
        itemCount: suggestions.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        separatorBuilder: (_, index) => Divider(
          height: 1,
          color: AppColors.softMist.withValues(alpha: 0.2),
        ),
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return ListTile(
            title: Text(
              suggestion.bookName,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.pureWhite,
              ),
            ),
            subtitle: suggestion.abbreviations.isEmpty
                ? null
                : Text(
                    suggestion.abbreviations.join(' · '),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.softMist.withValues(alpha: 0.7),
                    ),
                  ),
            onTap: () => onSelected(suggestion),
          );
        },
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.items, required this.onSelected});

  final List<String> items;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history, color: AppColors.softMist),
              title: Text(
                item,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.pureWhite,
                ),
              ),
              onTap: () => onSelected(item),
            ),
          )
          .toList(),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.result,
    required this.isSharingImage,
    required this.onShare,
  });

  final SearchResult result;
  final bool isSharingImage;
  final void Function(SearchResult result, Rect? origin) onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.midnightFaithDark.withValues(alpha: 0.9),
        borderRadius: AppBorderRadius.card,
        border: Border.all(color: AppColors.softMist.withValues(alpha: 0.2)),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.reference.displayReference,
            style: AppTextStyles.headline3.copyWith(
              color: AppColors.pureWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            result.version.abbreviation.isEmpty
                ? result.version.name
                : '${result.version.name} (${result.version.abbreviation})',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.softMist.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: result.verses
                .map(
                  (verse) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      '${verse.verseNumber}. ${verse.text}',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.pureWhite,
                        height: 1.5,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Builder(
                builder: (BuildContext context) {
                  return _CircleIconButton(
                    icon: Icons.ios_share,
                    color: AppColors.pureWhite.withValues(alpha: 0.85),
                    isLoading: isSharingImage,
                    onPressed: () {
                      final box = context.findRenderObject() as RenderBox?;
                      final sharePositionOrigin = box == null
                          ? null
                          : box.localToGlobal(Offset.zero) & box.size;
                      onShare(result, sharePositionOrigin);
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.color,
    required this.onPressed,
    this.isLoading = false,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.pureWhite.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.pureWhite.withValues(alpha: 0.2),
            ),
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                : Icon(icon, color: color),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.search_off, size: 48, color: AppColors.softMist),
        const SizedBox(height: AppSpacing.sm),
        Text(
          title,
          style: AppTextStyles.headline3.copyWith(
            color: AppColors.pureWhite,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.softMist.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
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
        color: AppColors.holyGold.withValues(alpha: 0.2),
        borderRadius: AppBorderRadius.button,
        border: Border.all(color: AppColors.holyGold.withValues(alpha: 0.5)),
      ),
      child: Text(
        message,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.pureWhite),
      ),
    );
  }
}
