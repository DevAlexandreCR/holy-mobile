import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';

class DevotionalContentView extends StatefulWidget {
  const DevotionalContentView({super.key, required this.content});

  final List<dynamic> content;

  @override
  State<DevotionalContentView> createState() => _DevotionalContentViewState();
}

class _DevotionalContentViewState extends State<DevotionalContentView> {
  late final QuillController _controller;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = QuillController(
      document: Document.fromJson(widget.content),
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
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
        embedBuilders: FlutterQuillEmbeds.defaultEditorBuilders(),
        customStyles: DefaultStyles(
          paragraph: DefaultTextBlockStyle(
            AppTextStyles.bodyLarge.copyWith(
              color: AppColors.pureWhite.withValues(alpha: 0.9),
              height: 1.6,
            ),
            const VerticalSpacing(0, 12),
            const VerticalSpacing(0, 0),
            null,
          ),
          h1: DefaultTextBlockStyle(
            AppTextStyles.headline2.copyWith(
              color: AppColors.pureWhite,
              fontWeight: FontWeight.w700,
            ),
            const VerticalSpacing(0, 12),
            const VerticalSpacing(0, 0),
            null,
          ),
          h2: DefaultTextBlockStyle(
            AppTextStyles.headline3.copyWith(
              color: AppColors.pureWhite,
              fontWeight: FontWeight.w700,
            ),
            const VerticalSpacing(0, 10),
            const VerticalSpacing(0, 0),
            null,
          ),
          lists: DefaultListBlockStyle(
            AppTextStyles.bodyLarge.copyWith(
              color: AppColors.pureWhite.withValues(alpha: 0.9),
              height: 1.6,
            ),
            const VerticalSpacing(0, 6),
            const VerticalSpacing(0, 0),
            null,
            null,
          ),
        ),
      ),
    );
  }
}
