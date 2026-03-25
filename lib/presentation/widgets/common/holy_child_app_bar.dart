import 'package:flutter/material.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';

class HolyChildAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HolyChildAppBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle = true,
    this.showBackButton = true,
  });

  final String title;
  final List<Widget>? actions;
  final bool centerTitle;
  final bool showBackButton;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.midnightFaith.withValues(alpha: 0.94),
      foregroundColor: AppColors.pureWhite,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      leading: showBackButton ? const BackButton() : null,
      title: Text(
        title,
        style: AppTextStyles.headline3.copyWith(
          color: AppColors.pureWhite,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: actions,
    );
  }
}
