import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_design_tokens.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';
import 'package:holyverso/domain/devotionals/devotional.dart';

class DevotionalCard extends StatelessWidget {
  const DevotionalCard({
    super.key,
    required this.devotional,
    required this.onTap,
  });

  final Devotional devotional;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primaryRefs = devotional.primaryReferences;
    final referenceLabel = primaryRefs.isNotEmpty
        ? primaryRefs.map((ref) => ref.referenceLabel).join(', ')
        : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.midnightFaith.withValues(alpha: 0.85),
          borderRadius: AppBorderRadius.card,
          boxShadow: AppShadows.cardShadow,
          border: Border.all(
            color: AppColors.pureWhite.withValues(alpha: 0.08),
          ),
        ),
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
            Padding(
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
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
