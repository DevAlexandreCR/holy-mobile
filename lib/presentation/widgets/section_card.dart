import 'package:flutter/material.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_design_tokens.dart';

/// Container for grouping settings or options with translucent background.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.addDividers = true,
    this.showShadow = false,
  });

  final List<Widget> children;
  final EdgeInsets padding;
  final bool addDividers;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final divider = Divider(
      height: 1,
      thickness: 1,
      color: Colors.white.withValues(alpha: 0.1),
    );

    final content = addDividers && children.length > 1
        ? _withDividers(children, divider)
        : children;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.pureWhite.withValues(alpha: 0.05),
        borderRadius: AppBorderRadius.card,
        border: Border.all(
          color: AppColors.pureWhite.withValues(alpha: 0.06),
        ),
        boxShadow: showShadow ? AppShadows.cardShadow : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: content,
      ),
    );
  }

  List<Widget> _withDividers(List<Widget> items, Widget divider) {
    final separated = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      separated.add(items[i]);
      if (i != items.length - 1) {
        separated.add(divider);
      }
    }
    return separated;
  }
}
