import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_design_tokens.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';
import 'package:holyverso/domain/devotionals/devotional.dart';
import 'package:holyverso/presentation/widgets/devotionals/devotional_content_view.dart';

class DevotionalCard extends StatelessWidget {
  const DevotionalCard({
    super.key,
    required this.devotional,
    required this.isExpanded,
    required this.onToggle,
    this.content,
    this.isLoadingContent = false,
    this.contentError,
    this.onRetryContent,
    this.expandedFooter,
  });

  final Devotional devotional;
  final bool isExpanded;
  final VoidCallback onToggle;
  final List<dynamic>? content;
  final bool isLoadingContent;
  final String? contentError;
  final VoidCallback? onRetryContent;
  final Widget? expandedFooter;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final primaryRefs = devotional.primaryReferences;
    final referenceLabel = primaryRefs.isNotEmpty
        ? primaryRefs.map((ref) => ref.referenceLabel).join(', ')
        : '';
    final publishedLabel = _formatPublishedDate(devotional.publishedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.midnightFaith.withValues(alpha: 0.85),
        borderRadius: AppBorderRadius.card,
        boxShadow: AppShadows.cardShadow,
        border: Border.all(
          color: AppColors.pureWhite.withValues(alpha: 0.08),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppBorderRadius.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (devotional.coverImageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppBorderRadius.lg),
                ),
                child: CachedNetworkImage(
                  imageUrl: devotional.coverImageUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    height: 160,
                    color: AppColors.midnightFaithDark,
                  ),
                ),
              ),
            InkWell(
              borderRadius: AppBorderRadius.card,
              onTap: onToggle,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      devotional.title,
                      style: AppTextStyles.headline3.copyWith(
                        color: AppColors.pureWhite,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (referenceLabel.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        referenceLabel,
                        style: AppTextStyles.reference.copyWith(
                          color: AppColors.holyGold,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      devotional.author.name,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.softMist.withValues(alpha: 0.8),
                      ),
                    ),
                    if (publishedLabel.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: AppColors.softMist.withValues(alpha: 0.75),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Publicado • $publishedLabel',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.softMist.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        _StatChip(
                          icon: Icons.favorite_border,
                          value: devotional.likesCount.toString(),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _StatChip(
                          icon: Icons.chat_bubble_outline,
                          value: devotional.commentsCount.toString(),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _StatChip(
                          icon: Icons.remove_red_eye_outlined,
                          value: devotional.viewCount.toString(),
                        ),
                        const Spacer(),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          child: const Icon(
                            Icons.expand_more_rounded,
                            color: AppColors.holyGold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      isExpanded
                          ? l10n.devotionalsCollapse
                          : l10n.devotionalsExpand,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.holyGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _ExpandableSection(
              isExpanded: isExpanded,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 1,
                      color: AppColors.pureWhite.withValues(alpha: 0.08),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ExpandedContent(
                      content: content,
                      isLoadingContent: isLoadingContent,
                      contentError: contentError,
                      onRetryContent: onRetryContent,
                    ),
                    if (expandedFooter != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      expandedFooter!,
                    ],
                    const SizedBox(height: AppSpacing.md),
                    TextButton.icon(
                      onPressed: onToggle,
                      icon: const Icon(Icons.expand_less_rounded, size: 18),
                      label: Text(l10n.devotionalsCollapse),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.holyGold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPublishedDate(DateTime? date) {
    if (date == null) return '';
    final local = date.toLocal();
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    final month = months[local.month - 1];
    return '${local.day} $month ${local.year}';
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.pureWhite.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.softMist),
          const SizedBox(width: 6),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.softMist,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandedContent extends StatelessWidget {
  const _ExpandedContent({
    required this.content,
    required this.isLoadingContent,
    required this.contentError,
    required this.onRetryContent,
  });

  final List<dynamic>? content;
  final bool isLoadingContent;
  final String? contentError;
  final VoidCallback? onRetryContent;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (isLoadingContent) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              color: AppColors.holyGold,
              strokeWidth: 2.2,
            ),
          ),
        ),
      );
    }

    if (contentError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            contentError!,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: onRetryContent,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.holyGold,
            ),
            child: Text(l10n.errorRetry),
          ),
        ],
      );
    }

    if (content == null || content!.isEmpty) {
      return Text(
        l10n.devotionalsContentMissing,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.softMist.withValues(alpha: 0.85),
        ),
      );
    }

    return DevotionalContentView(content: content!);
  }
}

class _ExpandableSection extends StatefulWidget {
  const _ExpandableSection({required this.isExpanded, required this.child});

  final bool isExpanded;
  final Widget child;

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _height;
  late final Animation<double> _fade;
  late final Animation<double> _stretch;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
      reverseDuration: const Duration(milliseconds: 260),
    );
    _height = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _stretch = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    if (widget.isExpanded) {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant _ExpandableSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.isExpanded && _controller.isDismissed,
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) {
          return ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: _height.value,
              child: Opacity(
                opacity: _fade.value,
                child: Transform(
                  alignment: Alignment.topCenter,
                  transform: Matrix4.identity()..scale(1.0, _stretch.value),
                  child: child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
