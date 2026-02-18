import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
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
import 'package:url_launcher/url_launcher.dart';

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
  double _coverImageFocusY = 0;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isPublishing = false;
  bool _isUploadingCover = false;
  bool _isEditorFullscreen = false;
  int _wordCount = 0;
  bool _isApplyingWhatsappAutoFormat = false;

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
      _titleController.text = devotional.title;
      _coverImageUrl = devotional.coverImageUrl;
      _coverImageFocusY = devotional.coverImageFocusY;
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
      _maybeAutoFormatWhatsappText();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
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
    _maybeAutoFormatWhatsappText();
  }

  void _maybeAutoFormatWhatsappText() {
    if (_isApplyingWhatsappAutoFormat) {
      return;
    }

    final transformedDelta = _convertWhatsappMarkersInDelta(
      _quillController.document.toDelta(),
    );
    if (transformedDelta == null) {
      return;
    }

    final selection = _quillController.selection;

    _isApplyingWhatsappAutoFormat = true;
    try {
      _quillController.setContents(transformedDelta);
      final maxOffset = _quillController.document.length - 1;
      final clampedBase = selection.baseOffset.clamp(0, maxOffset).toInt();
      final clampedExtent = selection.extentOffset.clamp(0, maxOffset).toInt();
      _quillController.updateSelection(
        TextSelection(baseOffset: clampedBase, extentOffset: clampedExtent),
        ChangeSource.local,
      );
    } finally {
      _isApplyingWhatsappAutoFormat = false;
    }
  }

  bool _looksLikeWhatsappMarkup(String text) {
    if (text.isEmpty) {
      return false;
    }
    if (!RegExp(r'[*_~`]').hasMatch(text)) {
      return false;
    }
    return text.contains('*') ||
        text.contains('_') ||
        text.contains('~') ||
        text.contains('`');
  }

  Delta? _convertWhatsappMarkersInDelta(Delta source) {
    final result = Delta();
    var changed = false;

    for (final op in source.toList()) {
      if (!op.isInsert) {
        result.push(op);
        continue;
      }

      final data = op.data;
      if (data is! String || data.isEmpty || !_looksLikeWhatsappMarkup(data)) {
        result.insert(
          data,
          op.attributes == null
              ? null
              : Map<String, dynamic>.from(op.attributes!),
        );
        continue;
      }

      final parsed = _parseWhatsappFormattedText(data);
      final hasStyles = parsed.runs.any(
        (run) => run.bold || run.italic || run.strike || run.monospace,
      );
      if (!hasStyles && parsed.text == data) {
        result.insert(
          data,
          op.attributes == null
              ? null
              : Map<String, dynamic>.from(op.attributes!),
        );
        continue;
      }

      changed = true;
      final baseAttributes = op.attributes == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(op.attributes!);

      for (final run in parsed.runs) {
        if (run.length <= 0) {
          continue;
        }

        final segment = parsed.text.substring(
          run.start,
          run.start + run.length,
        );
        final segmentAttributes = Map<String, dynamic>.from(baseAttributes);
        if (run.bold) {
          segmentAttributes[Attribute.bold.key] = Attribute.bold.value;
        }
        if (run.italic) {
          segmentAttributes[Attribute.italic.key] = Attribute.italic.value;
        }
        if (run.strike) {
          segmentAttributes[Attribute.strikeThrough.key] =
              Attribute.strikeThrough.value;
        }
        if (run.monospace) {
          segmentAttributes[Attribute.inlineCode.key] =
              Attribute.inlineCode.value;
        }

        result.insert(
          segment,
          segmentAttributes.isEmpty ? null : segmentAttributes,
        );
      }
    }

    if (!changed) {
      return null;
    }

    if (result.isEmpty ||
        result.last.data is! String ||
        !(result.last.data as String).endsWith('\n')) {
      result.insert('\n');
    }
    return result;
  }

  void _enterFullscreenEditor() {
    if (_isEditorFullscreen) return;
    setState(() => _isEditorFullscreen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FocusScope.of(context).requestFocus(_editorFocusNode);
    });
  }

  void _exitFullscreenEditor() {
    if (!_isEditorFullscreen) return;
    FocusScope.of(context).unfocus();
    setState(() => _isEditorFullscreen = false);
  }

  void _hideKeyboard() {
    FocusScope.of(context).unfocus();
  }

  void _updateWordCount() {
    final text = _quillController.document.toPlainText().trim();
    final count = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
    if (count != _wordCount) {
      setState(() => _wordCount = count);
    }
  }

  Future<void> _launchExternalUrl(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(uri);
      }
    } catch (_) {
      await launchUrl(uri);
    }
  }

  Future<void> _pasteFromClipboard(SelectionChangedCause cause) async {
    final selection = _quillController.selection;
    if (!selection.isValid) {
      return;
    }

    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final rawText = clipboardData?.text;
    if (rawText == null || rawText.isEmpty) {
      return;
    }

    final parsed = _parseWhatsappFormattedText(
      rawText.replaceAll('\r\n', '\n').replaceAll('\r', '\n'),
    );
    final start = selection.start;
    final replaceLength = selection.end - start;

    _quillController.replaceText(
      start,
      replaceLength,
      parsed.text,
      TextSelection.collapsed(offset: start + parsed.text.length),
    );

    for (final run in parsed.runs) {
      if (run.length <= 0) {
        continue;
      }

      final offset = start + run.start;
      if (run.bold) {
        _quillController.formatText(offset, run.length, Attribute.bold);
      }
      if (run.italic) {
        _quillController.formatText(offset, run.length, Attribute.italic);
      }
      if (run.strike) {
        _quillController.formatText(
          offset,
          run.length,
          Attribute.strikeThrough,
        );
      }
      if (run.monospace) {
        _quillController.formatText(offset, run.length, Attribute.inlineCode);
      }
    }

    _quillController.updateSelection(
      TextSelection.collapsed(offset: start + parsed.text.length),
      ChangeSource.local,
    );
    _quillController.ignoreFocusOnTextChange = false;

    if (cause == SelectionChangedCause.toolbar && mounted) {
      FocusScope.of(context).requestFocus(_editorFocusNode);
    }
  }

  Widget _buildCustomContextMenu(
    BuildContext context,
    QuillRawEditorState state,
  ) {
    final buttonItems = state.contextMenuButtonItems
        .map(
          (item) => item.type == ContextMenuButtonType.paste
              ? item.copyWith(
                  onPressed: () {
                    _pasteFromClipboard(SelectionChangedCause.toolbar);
                    state.hideToolbar();
                  },
                )
              : item,
        )
        .toList();

    return TextFieldTapRegion(
      child: AdaptiveTextSelectionToolbar.buttonItems(
        buttonItems: buttonItems,
        anchors: state.contextMenuAnchors,
      ),
    );
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
      setState(() {
        _coverImageUrl = url;
        _coverImageFocusY = 0;
      });
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
          coverImageFocusY: _coverImageUrl == null ? null : _coverImageFocusY,
          status: publish ? DevotionalStatus.published : DevotionalStatus.draft,
        );
      } else {
        saved = await repository.updateDevotional(
          devotionalId: widget.devotionalId!,
          title: _titleController.text.trim(),
          content: contentOps,
          verseReferences: _references,
          coverImageUrl: _coverImageUrl,
          coverImageFocusY: _coverImageUrl == null ? null : _coverImageFocusY,
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
        context.go('/devotionals');
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
      coverImageFocusY: _coverImageFocusY,
      references: List<DevotionalVerseReference>.from(_references),
      authorName: authState.user?.name ?? '',
    );

    context.push('/devotionals/preview', extra: payload);
  }

  Future<void> _showReferenceDialog({
    DevotionalVerseReference? existing,
  }) async {
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
                final verseStart = int.tryParse(
                  verseStartController.text.trim(),
                );
                final verseEnd = int.tryParse(verseEndController.text.trim());

                if (book.isEmpty || chapter == null || verseStart == null) {
                  return;
                }

                Navigator.pop(
                  context,
                  DevotionalVerseReference(
                    id:
                        existing?.id ??
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
      appBar: _isEditorFullscreen
          ? null
          : AppBar(
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
      body: PopScope(
        canPop: !_isEditorFullscreen,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && _isEditorFullscreen) {
            _exitFullscreenEditor();
          }
        },
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(gradient: AppColors.midnightGradient),
            ),
            SafeArea(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.holyGold,
                      ),
                    )
                  : _isEditorFullscreen
                  ? _buildFullscreenEditor(l10n)
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

  double _normalizeCoverImageFocusY(double value) {
    if (value < -1) return -1;
    if (value > 1) return 1;
    return value;
  }

  void _adjustCoverFocus(DragUpdateDetails details) {
    if (_coverImageUrl == null) return;
    setState(() {
      _coverImageFocusY = _normalizeCoverImageFocusY(
        _coverImageFocusY + (details.delta.dy / 140),
      );
    });
  }

  void _centerCoverImage() {
    if (_coverImageUrl == null || _coverImageFocusY == 0) return;
    setState(() => _coverImageFocusY = 0);
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
        if (_coverImageUrl != null) ...[
          ClipRRect(
            borderRadius: AppBorderRadius.card,
            child: GestureDetector(
              onVerticalDragUpdate: _adjustCoverFocus,
              child: CachedNetworkImage(
                imageUrl: _coverImageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                alignment: Alignment(0, _coverImageFocusY),
                errorWidget: (context, url, error) =>
                    Container(height: 180, color: AppColors.midnightFaithDark),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.devotionalCoverAdjustHint,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.softMist.withValues(alpha: 0.8),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _centerCoverImage,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.holyGold,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.filter_center_focus_outlined, size: 18),
                label: Text(l10n.devotionalCoverCenter),
              ),
            ],
          ),
        ],
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
    final previewText = _quillController.document.toPlainText().trim();
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
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _enterFullscreenEditor,
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            child: Ink(
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                border: Border.all(
                  color: AppColors.inputBorder.withValues(alpha: 0.7),
                ),
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    previewText.isEmpty
                        ? l10n.devotionalContentHint
                        : previewText,
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: previewText.isEmpty
                        ? AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.inputPlaceholder.withValues(
                              alpha: 0.9,
                            ),
                            height: 1.6,
                          )
                        : AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.pureWhite.withValues(alpha: 0.95),
                            height: 1.6,
                          ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Icon(
                        Icons.open_in_full,
                        size: 16,
                        color: AppColors.holyGold.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        l10n.devotionalEditorTapToEdit,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.softMist.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFullscreenEditor(AppLocalizations l10n) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.devotionalEditorFullscreenTitle,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.pureWhite,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_wordCount palabras',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.softMist.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _hideKeyboard,
                tooltip: l10n.devotionalHideKeyboard,
                icon: const Icon(Icons.keyboard_hide_outlined),
                color: AppColors.softMist,
              ),
              TextButton(
                onPressed: _exitFullscreenEditor,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.holyGold,
                  textStyle: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(l10n.devotionalEditorDone),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Container(
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
                      color: AppColors.midnightFaithDark.withValues(
                        alpha: 0.35,
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                        horizontal:
                            Theme.of(context).platform == TargetPlatform.android
                            ? AppSpacing.sm
                            : 0,
                      ),
                      child: _buildQuillToolbar(l10n),
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: AppColors.inputBorder.withValues(alpha: 0.6),
                  ),
                  Expanded(
                    child: QuillEditor.basic(
                      focusNode: _editorFocusNode,
                      scrollController: _editorScrollController,
                      configurations: QuillEditorConfigurations(
                        controller: _quillController,
                        scrollable: true,
                        autoFocus: false,
                        readOnly: false,
                        expands: true,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        placeholder: l10n.devotionalContentHint,
                        keyboardAppearance: Brightness.dark,
                        scrollBottomInset: bottomInset + AppSpacing.lg,
                        textSelectionThemeData: TextSelectionThemeData(
                          cursorColor: AppColors.holyGold,
                          selectionColor: AppColors.holyGold.withValues(
                            alpha: 0.25,
                          ),
                          selectionHandleColor: AppColors.holyGold,
                        ),
                        onLaunchUrl: (url) {
                          _launchExternalUrl(url);
                        },
                        contextMenuBuilder: _buildCustomContextMenu,
                        customActions: <Type, Action<Intent>>{
                          PasteTextIntent: CallbackAction<PasteTextIntent>(
                            onInvoke: (intent) {
                              _pasteFromClipboard(intent.cause);
                              return null;
                            },
                          ),
                        },
                        embedBuilders:
                            FlutterQuillEmbeds.defaultEditorBuilders(),
                        customStyles: DefaultStyles(
                          paragraph: DefaultTextBlockStyle(
                            AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.pureWhite.withValues(
                                alpha: 0.95,
                              ),
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
                              color: AppColors.pureWhite.withValues(
                                alpha: 0.95,
                              ),
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
                                  color: AppColors.holyGold.withValues(
                                    alpha: 0.5,
                                  ),
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
          ),
        ),
      ],
    );
  }

  Widget _buildQuillToolbar(AppLocalizations l10n) {
    return QuillToolbar.simple(
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
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                splashRadius: 18,
              ),
              iconButtonSelectedData: IconButtonData(
                color: AppColors.holyGold,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(
                    AppColors.holyGold.withValues(alpha: 0.18),
                  ),
                  shape: WidgetStatePropertyAll(
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
          linkDialogConstraints: const BoxConstraints(maxWidth: 360),
        ),
      ),
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
            side: BorderSide(color: AppColors.holyGold.withValues(alpha: 0.7)),
            minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
            shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.button),
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
    required this.coverImageFocusY,
    required this.references,
    required this.authorName,
  });

  final String title;
  final List<dynamic> content;
  final String? coverImageUrl;
  final double coverImageFocusY;
  final List<DevotionalVerseReference> references;
  final String authorName;
}

_ParsedWhatsappText _parseWhatsappFormattedText(String text) {
  final buffer = StringBuffer();
  final runs = <_WhatsappTextRun>[];
  var state = const _WhatsappStyleState();
  var i = 0;

  bool appendChar(String char) {
    final start = buffer.length;
    buffer.write(char);
    final length = buffer.length - start;
    if (length <= 0) {
      return false;
    }

    if (runs.isNotEmpty && runs.last.canMergeWith(state)) {
      final last = runs.removeLast();
      runs.add(last.copyWith(length: last.length + length));
      return true;
    }

    runs.add(
      _WhatsappTextRun(
        start: start,
        length: length,
        bold: state.bold,
        italic: state.italic,
        strike: state.strike,
        monospace: state.monospace,
      ),
    );
    return true;
  }

  while (i < text.length) {
    final marker = _markerAt(text, i);
    if (marker == null) {
      appendChar(String.fromCharCode(text.codeUnitAt(i)));
      i += 1;
      continue;
    }

    final isActive = state.isActive(marker.kind);
    if (isActive) {
      if (_isValidClosingMarker(text, i, marker.value)) {
        state = state.toggle(marker.kind);
        i += marker.value.length;
        continue;
      }
      appendChar(String.fromCharCode(text.codeUnitAt(i)));
      i += 1;
      continue;
    }

    if (_isValidOpeningMarker(text, i, marker.value) &&
        _findClosingMarker(text, i + marker.value.length, marker.value) != -1) {
      state = state.toggle(marker.kind);
      i += marker.value.length;
      continue;
    }

    appendChar(String.fromCharCode(text.codeUnitAt(i)));
    i += 1;
  }

  return _ParsedWhatsappText(text: buffer.toString(), runs: runs);
}

_WhatsappMarker? _markerAt(String text, int index) {
  if (_matchesAt(text, index, '```')) {
    return const _WhatsappMarker('```', _WhatsappFormat.monospace);
  }
  if (_matchesAt(text, index, '*')) {
    return const _WhatsappMarker('*', _WhatsappFormat.bold);
  }
  if (_matchesAt(text, index, '_')) {
    return const _WhatsappMarker('_', _WhatsappFormat.italic);
  }
  if (_matchesAt(text, index, '~')) {
    return const _WhatsappMarker('~', _WhatsappFormat.strike);
  }
  if (_matchesAt(text, index, '`')) {
    return const _WhatsappMarker('`', _WhatsappFormat.monospace);
  }
  return null;
}

bool _matchesAt(String text, int index, String marker) {
  if (index < 0 || index + marker.length > text.length) {
    return false;
  }
  return text.substring(index, index + marker.length) == marker;
}

int _findClosingMarker(String text, int from, String marker) {
  var index = from;
  while (index != -1) {
    index = text.indexOf(marker, index);
    if (index == -1) {
      return -1;
    }
    if (_isValidClosingMarker(text, index, marker)) {
      return index;
    }
    index += marker.length;
  }
  return -1;
}

bool _isValidOpeningMarker(String text, int index, String marker) {
  final before = index > 0 ? text.codeUnitAt(index - 1) : null;
  final afterIndex = index + marker.length;
  final after = afterIndex < text.length ? text.codeUnitAt(afterIndex) : null;

  final validBefore = before == null || _isBoundaryCodeUnit(before);
  final validAfter = after != null && !_isBoundaryCodeUnit(after);
  return validBefore && validAfter;
}

bool _isValidClosingMarker(String text, int index, String marker) {
  final beforeIndex = index - 1;
  final afterIndex = index + marker.length;
  final before = beforeIndex >= 0 ? text.codeUnitAt(beforeIndex) : null;
  final after = afterIndex < text.length ? text.codeUnitAt(afterIndex) : null;

  final validBefore = before != null && !_isBoundaryCodeUnit(before);
  final validAfter = after == null || _isBoundaryCodeUnit(after);
  return validBefore && validAfter;
}

bool _isBoundaryCodeUnit(int codeUnit) {
  const boundaryChars = ' \n\t\r.,;:!?()[]{}"\'<>/\\|-*_~`';
  return boundaryChars.contains(String.fromCharCode(codeUnit));
}

class _ParsedWhatsappText {
  const _ParsedWhatsappText({required this.text, required this.runs});

  final String text;
  final List<_WhatsappTextRun> runs;
}

enum _WhatsappFormat { bold, italic, strike, monospace }

class _WhatsappMarker {
  const _WhatsappMarker(this.value, this.kind);

  final String value;
  final _WhatsappFormat kind;
}

class _WhatsappStyleState {
  const _WhatsappStyleState({
    this.bold = false,
    this.italic = false,
    this.strike = false,
    this.monospace = false,
  });

  final bool bold;
  final bool italic;
  final bool strike;
  final bool monospace;

  bool isActive(_WhatsappFormat format) {
    switch (format) {
      case _WhatsappFormat.bold:
        return bold;
      case _WhatsappFormat.italic:
        return italic;
      case _WhatsappFormat.strike:
        return strike;
      case _WhatsappFormat.monospace:
        return monospace;
    }
  }

  _WhatsappStyleState toggle(_WhatsappFormat format) {
    switch (format) {
      case _WhatsappFormat.bold:
        return _WhatsappStyleState(
          bold: !bold,
          italic: italic,
          strike: strike,
          monospace: monospace,
        );
      case _WhatsappFormat.italic:
        return _WhatsappStyleState(
          bold: bold,
          italic: !italic,
          strike: strike,
          monospace: monospace,
        );
      case _WhatsappFormat.strike:
        return _WhatsappStyleState(
          bold: bold,
          italic: italic,
          strike: !strike,
          monospace: monospace,
        );
      case _WhatsappFormat.monospace:
        return _WhatsappStyleState(
          bold: bold,
          italic: italic,
          strike: strike,
          monospace: !monospace,
        );
    }
  }
}

class _WhatsappTextRun {
  const _WhatsappTextRun({
    required this.start,
    required this.length,
    required this.bold,
    required this.italic,
    required this.strike,
    required this.monospace,
  });

  final int start;
  final int length;
  final bool bold;
  final bool italic;
  final bool strike;
  final bool monospace;

  bool canMergeWith(_WhatsappStyleState style) {
    return bold == style.bold &&
        italic == style.italic &&
        strike == style.strike &&
        monospace == style.monospace;
  }

  _WhatsappTextRun copyWith({int? length}) {
    return _WhatsappTextRun(
      start: start,
      length: length ?? this.length,
      bold: bold,
      italic: italic,
      strike: strike,
      monospace: monospace,
    );
  }
}
