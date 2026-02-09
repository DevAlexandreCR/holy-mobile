import 'dart:async';

import 'package:flutter/material.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_design_tokens.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';

class UserSearchBar extends StatefulWidget {
  const UserSearchBar({
    super.key,
    required this.onSearch,
    this.debounce = const Duration(milliseconds: 500),
  });

  final ValueChanged<String> onSearch;
  final Duration debounce;

  @override
  State<UserSearchBar> createState() => _UserSearchBarState();
}

class _UserSearchBarState extends State<UserSearchBar> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(widget.debounce, () {
      widget.onSearch(query);
    });
  }

  void _clear() {
    _controller.clear();
    widget.onSearch('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.pureWhite),
      decoration: InputDecoration(
        hintText: 'Buscar por nombre o email...',
        hintStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.softMist.withValues(alpha: 0.7),
        ),
        prefixIcon: Icon(
          Icons.search,
          color: AppColors.holyGold.withValues(alpha: 0.8),
        ),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                color: AppColors.softMist.withValues(alpha: 0.8),
                onPressed: _clear,
              )
            : null,
        filled: true,
        fillColor: AppColors.pureWhite.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: AppBorderRadius.input,
          borderSide: BorderSide(
            color: AppColors.pureWhite.withValues(alpha: 0.12),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.input,
          borderSide: BorderSide(
            color: AppColors.pureWhite.withValues(alpha: 0.12),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.input,
          borderSide: BorderSide(
            color: AppColors.holyGold.withValues(alpha: 0.9),
          ),
        ),
      ),
      onChanged: _onSearchChanged,
      onSubmitted: widget.onSearch,
    );
  }
}
