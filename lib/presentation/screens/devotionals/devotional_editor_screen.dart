import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_design_tokens.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';
import 'package:holyverso/data/devotionals/devotionals_repository.dart';
import 'package:holyverso/domain/devotionals/devotional.dart';
import 'package:holyverso/domain/devotionals/devotional_status.dart';
import 'package:holyverso/domain/devotionals/devotional_verse_reference.dart';
import 'package:holyverso/presentation/state/auth/auth_controller.dart';
import 'package:holyverso/presentation/widgets/holy_button.dart';
import 'package:image_picker/image_picker.dart';

class DevotionalEditorScreen extends ConsumerStatefulWidget {
  const DevotionalEditorScreen({super.key, this.devotionalId});

  final String? devotionalId;

  @override
  ConsumerState<DevotionalEditorScreen> createState() =>
      _DevotionalEditorScreenState();
}

class _DevotionalEditorScreenState
    extends ConsumerState<DevotionalEditorScreen> {
  final TextEditingController _titleController = TextEditingController();
  late QuillController _quillController;
  final ScrollController _editorScrollController = ScrollController();
  final FocusNode _editorFocusNode = FocusNode();
  final List<DevotionalVerseReference> _references = [];
  String? _coverImageUrl;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isPublishing = false;
  bool _isUploadingCover = false;
  int _wordCount = 0;
  Devotional? _loadedDevotional;

  @override
  void initState() {
    super.initState();
    _quillController = QuillController.basic();
    _quillController.addListener(_handleEditorChange);
    _updateWordCount();
    if (widget.devotionalId != null) {
      _loadDevotional();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _editorScrollController.dispose();
    _editorFocusNode.dispose();
    _quillController.removeListener(_handleEditorChange);
    _quillController.dispose();
    super.dispose();
  }

  Future<void> _loadDevotional() async {
    setState(() => _isLoading = true);
    try {
      final devotional = await ref
          .read(devotionalsRepositoryProvider)
          .getDevotional(widget.devotionalId!);
      _loadedDevotional = devotional;
      _titleController.text = devotional.title;
      _coverImageUrl = devotional.coverImageUrl;
      _references
        ..clear()
        ..addAll(devotional.verseReferences);

      final contentOps = devotional.content ?? [];
      _quillController.removeListener(_handleEditorChange);
      _quillController = QuillController(
        document: Document.fromJson(contentOps),
        selection: const TextSelection.collapsed(offset: 0),
      )..addListener(_handleEditorChange);
      _updateWordCount();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.devotionalsLoadError),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleEditorChange() {
    _updateWordCount();
  }

  void _updateWordCount() {
    final text = _quillController.document.toPlainText().trim();
    final count = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
    if (count != _wordCount) {
      setState(() => _wordCount = count);
    }
  }

  Future<void> _pickCoverImage() async {
    if (_isUploadingCover) return;
    setState(() => _isUploadingCover = true);

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        imageQuality: 85,
      );
      if (image == null) return;

      final url = await ref
          .read(devotionalsRepositoryProvider)
          .uploadImage(File(image.path));
      setState(() => _coverImageUrl = url);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.devotionalsImageUploadError),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingCover = false);
      }
    }
  }

  bool _validateForm() {
    final l10n = context.l10n;
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.devotionalTitleRequired),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return false;
    }

    if (_references.isEmpty || !_references.any((ref) => ref.isPrimary)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.devotionalPrimaryReferenceRequired),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> _save({required bool publish}) async {
    if (_isSaving) return;
    if (!_validateForm()) return;

    setState(() {
      _isSaving = true;
      _isPublishing = publish;
    });

    try {
      final contentOps = _quillController.document.toDelta().toJson();
      final repository = ref.read(devotionalsRepositoryProvider);

      Devotional saved;
      if (widget.devotionalId == null) {
        saved = await repository.createDevotional(
          title: _titleController.text.trim(),
          content: contentOps,
          verseReferences: _references,
          coverImageUrl: _coverImageUrl,
          status: publish ? DevotionalStatus.published : DevotionalStatus.draft,
        );
      } else {
        saved = await repository.updateDevotional(
          devotionalId: widget.devotionalId!,
          title: _titleController.text.trim(),
          content: contentOps,
          verseReferences: _references,
          coverImageUrl: _coverImageUrl,
        );

        if (publish && saved.status != DevotionalStatus.published) {
          saved = await repository.publishDevotional(saved.id);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              publish
                  ? context.l10n.devotionalPublished
                  : context.l10n.devotionalSaved,
            ),
            backgroundColor: AppColors.holyGold,
          ),
        );
        if (publish) {
          context.go('/devotionals/${saved.id}');
        } else {
          context.go('/devotionals');
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.devotionalsSaveError),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isPublishing = false;
        });
      }
    }
  }

  void _openPreview() {
    if (!_validateForm()) return;

    final authState = ref.read(authControllerProvider);
    final payload = DevotionalPreviewPayload(
      title: _titleController.text.trim(),
      content: _quillController.document.toDelta().toJson(),
      coverImageUrl: _coverImageUrl,
      references: List<DevotionalVerseReference>.from(_references),
      authorName: authState.user?.name ?? '',
    );

    context.push('/devotionals/preview', extra: payload);
  }

  Future<void> _showReferenceDialog({DevotionalVerseReference? existing}) async {
    final l10n = context.l10n;
    final bookController = TextEditingController(text: existing?.book ?? '');
    final chapterController = TextEditingController(
      text: existing?.chapter.toString() ?? '',
    );
    final verseStartController = TextEditingController(
      text: existing?.verseStart.toString() ?? '',
    );
    final verseEndController = TextEditingController(
      text: existing?.verseEnd?.toString() ?? '',
    );
    bool isPrimary = existing?.isPrimary ?? _references.isEmpty;

    final result = await showDialog<DevotionalVerseReference>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.addVerseReference),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: bookController,
                  decoration: InputDecoration(
                    labelText: l10n.devotionalBookLabel,
                  ),
                ),
                TextField(
                  controller: chapterController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.devotionalChapterLabel,
                  ),
                ),
                TextField(
                  controller: verseStartController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.devotionalVerseStartLabel,
                  ),
                ),
                TextField(
                  controller: verseEndController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.devotionalVerseEndLabel,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SwitchListTile.adaptive(
                  value: isPrimary,
                  onChanged: (value) {
                    setDialogState(() {
                      isPrimary = value;
                    });
                  },
                  title: Text(l10n.primaryVerseReference),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancelAction),
            ),
            TextButton(
              onPressed: () {
                final book = bookController.text.trim();
                final chapter = int.tryParse(chapterController.text.trim());
                final verseStart =
                    int.tryParse(verseStartController.text.trim());
                final verseEnd = int.tryParse(verseEndController.text.trim());

                if (book.isEmpty || chapter == null || verseStart == null) {
                  return;
                }

                Navigator.pop(
                  context,
                  DevotionalVerseReference(
                    id: existing?.id ??
                        DateTime.now().millisecondsSinceEpoch.toString(),
                    book: book,
                    chapter: chapter,
                    verseStart: verseStart,
                    verseEnd: verseEnd,
                    isPrimary: isPrimary,
                  ),
                );
              },
              child: Text(l10n.saveAction),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (existing != null) {
          final index = _references.indexWhere((ref) => ref.id == existing.id);
          if (index != -1) {
            _references[index] = result;
          }
        } else {
          _references.add(result);
        }
      });
    }
  }

  void _removeReference(DevotionalVerseReference reference) {
    setState(() {
      _references.removeWhere((ref) => ref.id == reference.id);
    });
  }

  void _showEmojiPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.midnightFaith,
      builder: (context) => EmojiPicker(
        onEmojiSelected: (_, emoji) {
          final index = _quillController.selection.baseOffset;
          final insertIndex = index >= 0 ? index : 0;
          _quillController.document.insert(insertIndex, emoji.emoji);
          _quillController.updateSelection(
            TextSelection.collapsed(offset: insertIndex + emoji.emoji.length),
            ChangeSource.local,
          );
        },
        config: Config(
          emojiViewConfig: EmojiViewConfig(
            backgroundColor: AppColors.midnightFaith,
          ),
          categoryViewConfig: CategoryViewConfig(
            backgroundColor: AppColors.midnightFaith,
            indicatorColor: AppColors.holyGold,
            iconColor: AppColors.softMist,
            iconColorSelected: AppColors.holyGold,
          ),
          bottomActionBarConfig: BottomActionBarConfig(
            backgroundColor: AppColors.midnightFaithDark,
            buttonColor: AppColors.holyGold,
            buttonIconColor: AppColors.midnightFaith,
          ),
          searchViewConfig: SearchViewConfig(
            backgroundColor: AppColors.midnightFaith,
            buttonColor: AppColors.holyGold.withValues(alpha: 0.2),
            buttonIconColor: AppColors.holyGold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.midnightFaith,
      appBar: AppBar(
        title: Text(
          widget.devotionalId == null
              ? l10n.createDevotional
              : l10n.editDevotional,
          style: AppTextStyles.headline3.copyWith(
            color: AppColors.pureWhite,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(decoration: BoxDecoration(gradient: AppColors.midnightGradient)),
          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.holyGold),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    children: [
                      _buildTitleField(l10n),
                      const SizedBox(height: AppSpacing.lg),
                      _buildCoverImage(l10n),
                      const SizedBox(height: AppSpacing.lg),
                      _buildReferencesSection(l10n),
                      const SizedBox(height: AppSpacing.lg),
                      _buildEditor(l10n),
                      const SizedBox(height: AppSpacing.xl),
                      _buildActions(l10n),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField(AppLocalizations l10n) {
    return TextField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: l10n.devotionalTitleLabel,
        hintText: l10n.devotionalTitleHint,
        filled: true,
        fillColor: AppColors.inputBackground,
        labelStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.softMist.withValues(alpha: 0.8),
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.inputPlaceholder.withValues(alpha: 0.9),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.input,
          borderSide: BorderSide(
            color: AppColors.inputBorder.withValues(alpha: 0.8),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.input,
          borderSide: const BorderSide(color: AppColors.holyGold, width: 1.2),
        ),
      ),
      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.pureWhite),
    );
  }

  Widget _buildCoverImage(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.coverImage,
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.pureWhite),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_coverImageUrl != null)
          ClipRRect(
            borderRadius: AppBorderRadius.card,
            child: CachedNetworkImage(
              imageUrl: _coverImageUrl!,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Container(
                height: 180,
                color: AppColors.midnightFaithDark,
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        ElevatedButton.icon(
          onPressed: _isUploadingCover ? null : _pickCoverImage,
          icon: const Icon(Icons.photo_library_outlined),
          label: Text(
            _coverImageUrl == null
                ? l10n.devotionalSelectCover
                : l10n.devotionalChangeCover,
          ),
        ),
      ],
    );
  }

  Widget _buildReferencesSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                l10n.primaryVerseReferences,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.pureWhite,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            TextButton.icon(
              onPressed: () => _showReferenceDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: Text(
                l10n.addVerseReference,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.holyGold,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: const Size(0, 0),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_references.isEmpty)
          Text(
            l10n.devotionalReferenceHint,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.softMist.withValues(alpha: 0.8),
            ),
          ),
        ..._references.map(
          (reference) => Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              border: Border.all(
                color: AppColors.inputBorder.withValues(alpha: 0.7),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reference.referenceLabel,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.pureWhite,
                        ),
                      ),
                      if (reference.isPrimary)
                        Text(
                          l10n.primaryVerseReference,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.holyGold,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showReferenceDialog(existing: reference),
                  icon: const Icon(Icons.edit_outlined),
                  color: AppColors.softMist,
                ),
                IconButton(
                  onPressed: () => _removeReference(reference),
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.error,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditor(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.devotionalContentLabel,
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.pureWhite,
              ),
            ),
            Text(
              '$_wordCount palabras',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.softMist.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            border: Border.all(
              color: AppColors.inputBorder.withValues(alpha: 0.7),
            ),
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppBorderRadius.md),
                ),
                child: Container(
                  color: AppColors.midnightFaithDark.withValues(alpha: 0.35),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: QuillToolbar.simple(
                    configurations: QuillSimpleToolbarConfigurations(
                      controller: _quillController,
                      color: Colors.transparent,
                      showDividers: false,
                      toolbarSectionSpacing: AppSpacing.xs,
                      toolbarIconAlignment: WrapAlignment.start,
                      buttonOptions: QuillSimpleToolbarButtonOptions(
                        base: QuillToolbarBaseButtonOptions(
                          iconSize: 18,
                          iconButtonFactor: 1.8,
                          iconTheme: QuillIconTheme(
                            iconButtonUnselectedData: IconButtonData(
                              color: AppColors.softMist.withValues(alpha: 0.85),
                              splashRadius: 18,
                            ),
                            iconButtonSelectedData: IconButtonData(
                              color: AppColors.holyGold,
                              style: ButtonStyle(
                                backgroundColor: MaterialStatePropertyAll(
                                  AppColors.holyGold.withValues(alpha: 0.18),
                                ),
                                shape: MaterialStatePropertyAll(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      customButtons: [
                        QuillToolbarCustomButtonOptions(
                          icon: Icon(
                            Icons.emoji_emotions_outlined,
                            color: AppColors.softMist.withValues(alpha: 0.85),
                          ),
                          tooltip: l10n.devotionalEmojiLabel,
                          onPressed: _showEmojiPicker,
                        ),
                      ],
                      showFontFamily: false,
                      showFontSize: false,
                      showHeaderStyle: false,
                      showInlineCode: false,
                      showCodeBlock: false,
                      showStrikeThrough: false,
                      showSubscript: false,
                      showSuperscript: false,
                      showSmallButton: false,
                      showBackgroundColorButton: false,
                      showColorButton: false,
                      showClearFormat: false,
                      showSearchButton: false,
                      showDirection: false,
                      showIndent: false,
                      showListCheck: false,
                      showAlignmentButtons: false,
                      showQuote: true,
                      showListNumbers: true,
                      showListBullets: true,
                      dialogTheme: QuillDialogTheme(
                        dialogBackgroundColor: AppColors.midnightFaithDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        labelTextStyle: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.softMist,
                        ),
                        inputTextStyle: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.pureWhite,
                        ),
                        buttonTextStyle: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.holyGold,
                        ),
                        buttonStyle: TextButton.styleFrom(
                          foregroundColor: AppColors.holyGold,
                        ),
                        linkDialogConstraints:
                            const BoxConstraints(maxWidth: 360),
                      ),
                    ),
                  ),
                ),
              ),
              Divider(
                height: 1,
                color: AppColors.inputBorder.withValues(alpha: 0.6),
              ),
              SizedBox(
                height: 340,
                child: QuillEditor.basic(
                  focusNode: _editorFocusNode,
                  scrollController: _editorScrollController,
                  configurations: QuillEditorConfigurations(
                    controller: _quillController,
                    scrollable: true,
                    autoFocus: false,
                    readOnly: false,
                    expands: false,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    placeholder: l10n.devotionalContentHint,
                    keyboardAppearance: Brightness.dark,
                    scrollBottomInset: 120,
                    textSelectionThemeData: TextSelectionThemeData(
                      cursorColor: AppColors.holyGold,
                      selectionColor:
                          AppColors.holyGold.withValues(alpha: 0.25),
                      selectionHandleColor: AppColors.holyGold,
                    ),
                    embedBuilders: FlutterQuillEmbeds.defaultEditorBuilders(),
                    customStyles: DefaultStyles(
                      paragraph: DefaultTextBlockStyle(
                        AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.pureWhite.withValues(alpha: 0.95),
                          height: 1.6,
                        ),
                        const VerticalSpacing(0, 10),
                        const VerticalSpacing(0, 0),
                        null,
                      ),
                      placeHolder: DefaultTextBlockStyle(
                        AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.inputPlaceholder.withValues(
                            alpha: 0.9,
                          ),
                          height: 1.6,
                        ),
                        const VerticalSpacing(0, 0),
                        const VerticalSpacing(0, 0),
                        null,
                      ),
                      lists: DefaultListBlockStyle(
                        AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.pureWhite.withValues(alpha: 0.95),
                          height: 1.6,
                        ),
                        const VerticalSpacing(0, 6),
                        const VerticalSpacing(0, 0),
                        null,
                        null,
                      ),
                      quote: DefaultTextBlockStyle(
                        AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.softMist.withValues(alpha: 0.9),
                          height: 1.6,
                          fontStyle: FontStyle.italic,
                        ),
                        const VerticalSpacing(0, 8),
                        const VerticalSpacing(0, 0),
                        BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: AppColors.holyGold.withValues(alpha: 0.5),
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                      link: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.holyGold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    dialogTheme: QuillDialogTheme(
                      dialogBackgroundColor: AppColors.midnightFaithDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      labelTextStyle: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.softMist,
                      ),
                      inputTextStyle: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.pureWhite,
                      ),
                      buttonTextStyle: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.holyGold,
                      ),
                      buttonStyle: TextButton.styleFrom(
                        foregroundColor: AppColors.holyGold,
                      ),
                      linkDialogConstraints: const BoxConstraints(
                        maxWidth: 360,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions(AppLocalizations l10n) {
    final isPublishing = _isSaving && _isPublishing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton(
          onPressed: _isSaving ? null : () => _save(publish: false),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.holyGold,
            side: BorderSide(
              color: AppColors.holyGold.withValues(alpha: 0.7),
            ),
            minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
            shape: RoundedRectangleBorder(
              borderRadius: AppBorderRadius.button,
            ),
            textStyle: AppTextStyles.button.copyWith(
              color: AppColors.holyGold,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: _isSaving && !isPublishing
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.holyGold,
                    ),
                  ),
                )
              : Text(l10n.saveDraft),
        ),
        const SizedBox(height: AppSpacing.sm),
        HolyButton(
          label: l10n.publish,
          onPressed: _isSaving ? null : () => _save(publish: true),
          isLoading: isPublishing,
        ),
        const SizedBox(height: AppSpacing.xs),
        TextButton(
          onPressed: _isSaving ? null : _openPreview,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.holyGold,
            textStyle: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Text(l10n.preview),
        ),
      ],
    );
  }
}

class DevotionalPreviewPayload {
  const DevotionalPreviewPayload({
    required this.title,
    required this.content,
    required this.coverImageUrl,
    required this.references,
    required this.authorName,
  });

  final String title;
  final List<dynamic> content;
  final String? coverImageUrl;
  final List<DevotionalVerseReference> references;
  final String authorName;
}
