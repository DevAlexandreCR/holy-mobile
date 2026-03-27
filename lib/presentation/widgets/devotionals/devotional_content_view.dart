import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';
import 'package:url_launcher/url_launcher.dart';

class DevotionalContentView extends StatelessWidget {
  const DevotionalContentView({
    super.key,
    required this.content,
    this.emphasizeLeadingParagraph = false,
  });

  final List<dynamic> content;
  final bool emphasizeLeadingParagraph;

  @override
  Widget build(BuildContext context) {
    final splitContent = emphasizeLeadingParagraph
        ? _LeadingParagraphSplit.fromContent(content)
        : null;

    if (splitContent == null || splitContent.remainder.isEmpty) {
      return _ReadOnlyQuillView(
        content: content,
        styles: _buildReadingStyles(emphasizeParagraph: false),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReadOnlyQuillView(
          content: splitContent.leading,
          styles: _buildReadingStyles(emphasizeParagraph: true),
        ),
        const SizedBox(height: 8),
        _ReadOnlyQuillView(
          content: splitContent.remainder,
          styles: _buildReadingStyles(emphasizeParagraph: false),
        ),
      ],
    );
  }

  DefaultStyles _buildReadingStyles({required bool emphasizeParagraph}) {
    final paragraphStyle = AppTextStyles.bodyLarge.copyWith(
      fontSize: 17,
      height: 1.72,
      fontWeight: emphasizeParagraph ? FontWeight.w500 : FontWeight.w400,
      color: AppColors.pureWhite.withValues(
        alpha: emphasizeParagraph ? 0.96 : 0.9,
      ),
    );
    final listStyle = AppTextStyles.bodyLarge.copyWith(
      fontSize: 17,
      height: 1.72,
      color: AppColors.pureWhite.withValues(alpha: 0.9),
    );

    return DefaultStyles(
      paragraph: DefaultTextBlockStyle(
        paragraphStyle,
        const VerticalSpacing(0, 16),
        const VerticalSpacing(0, 0),
        null,
      ),
      h1: DefaultTextBlockStyle(
        AppTextStyles.headline2.copyWith(
          color: AppColors.pureWhite,
          fontWeight: FontWeight.w700,
        ),
        const VerticalSpacing(0, 16),
        const VerticalSpacing(0, 0),
        null,
      ),
      h2: DefaultTextBlockStyle(
        AppTextStyles.headline3.copyWith(
          color: AppColors.pureWhite,
          fontWeight: FontWeight.w700,
        ),
        const VerticalSpacing(0, 12),
        const VerticalSpacing(0, 0),
        null,
      ),
      lists: DefaultListBlockStyle(
        listStyle,
        const VerticalSpacing(0, 10),
        const VerticalSpacing(0, 0),
        null,
        null,
      ),
      quote: DefaultTextBlockStyle(
        AppTextStyles.bodyLarge.copyWith(
          fontSize: 17,
          color: AppColors.softMist.withValues(alpha: 0.92),
          height: 1.72,
          fontStyle: FontStyle.italic,
        ),
        const VerticalSpacing(0, 12),
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
    );
  }
}

class _ReadOnlyQuillView extends StatefulWidget {
  const _ReadOnlyQuillView({required this.content, required this.styles});

  final List<dynamic> content;
  final DefaultStyles styles;

  @override
  State<_ReadOnlyQuillView> createState() => _ReadOnlyQuillViewState();
}

class _ReadOnlyQuillViewState extends State<_ReadOnlyQuillView> {
  late QuillController _controller;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = _buildController(widget.content);
  }

  @override
  void didUpdateWidget(covariant _ReadOnlyQuillView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.content, widget.content)) {
      _controller.dispose();
      _controller = _buildController(widget.content);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  QuillController _buildController(List<dynamic> content) {
    return QuillController(
      document: Document.fromJson(content),
      selection: const TextSelection.collapsed(offset: 0),
    );
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

  @override
  Widget build(BuildContext context) {
    return QuillEditor.basic(
      focusNode: _focusNode,
      scrollController: _scrollController,
      configurations: QuillEditorConfigurations(
        controller: _controller,
        scrollable: false,
        autoFocus: false,
        readOnly: true,
        expands: false,
        padding: EdgeInsets.zero,
        showCursor: false,
        enableInteractiveSelection: false,
        onLaunchUrl: _launchExternalUrl,
        embedBuilders: FlutterQuillEmbeds.defaultEditorBuilders(),
        customStyles: widget.styles,
      ),
    );
  }
}

class _LeadingParagraphSplit {
  const _LeadingParagraphSplit({
    required this.leading,
    required this.remainder,
  });

  final List<dynamic> leading;
  final List<dynamic> remainder;

  static _LeadingParagraphSplit? fromContent(List<dynamic> content) {
    final leading = <Map<String, dynamic>>[];
    final remainder = <Map<String, dynamic>>[];
    var splitReached = false;

    for (final rawOperation in content) {
      if (rawOperation is! Map) {
        continue;
      }

      final operation = Map<String, dynamic>.from(rawOperation);
      if (splitReached) {
        remainder.add(operation);
        continue;
      }

      final insert = operation['insert'];
      if (insert is! String) {
        leading.add(operation);
        continue;
      }

      final newlineIndex = insert.indexOf('\n');
      if (newlineIndex == -1) {
        leading.add(operation);
        continue;
      }

      final firstParagraphChunk = insert.substring(0, newlineIndex + 1);
      if (firstParagraphChunk.isNotEmpty) {
        leading.add({...operation, 'insert': firstParagraphChunk});
      }

      final remainingChunk = insert.substring(newlineIndex + 1);
      if (remainingChunk.isNotEmpty) {
        remainder.add({...operation, 'insert': remainingChunk});
      }
      splitReached = true;
    }

    if (!splitReached || remainder.isEmpty) {
      return null;
    }

    return _LeadingParagraphSplit(leading: leading, remainder: remainder);
  }
}
