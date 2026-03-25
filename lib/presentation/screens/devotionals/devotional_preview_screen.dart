import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_design_tokens.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';
import 'package:holyverso/domain/devotionals/devotional_verse_reference.dart';
import 'package:holyverso/presentation/screens/devotionals/devotional_editor_screen.dart';
import 'package:holyverso/presentation/widgets/common/holy_child_app_bar.dart';
import 'package:holyverso/presentation/widgets/devotionals/devotional_content_view.dart';

class DevotionalPreviewScreen extends StatelessWidget {
  const DevotionalPreviewScreen({super.key, required this.payload});

  final DevotionalPreviewPayload payload;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final references = payload.references
        .where((ref) => ref.isPrimary)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.midnightFaith,
      appBar: HolyChildAppBar(title: l10n.preview),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(gradient: AppColors.midnightGradient),
          ),
          SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              children: [
                if (payload.coverImageUrl != null)
                  ClipRRect(
                    borderRadius: AppBorderRadius.card,
                    child: CachedNetworkImage(
                      imageUrl: payload.coverImageUrl!,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      alignment: Alignment(0, payload.coverImageFocusY),
                      errorWidget: (context, url, error) => Container(
                        height: 220,
                        color: AppColors.midnightFaithDark,
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  payload.title,
                  style: AppTextStyles.headline1.copyWith(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (payload.authorName.isNotEmpty)
                  Text(
                    payload.authorName,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.softMist.withValues(alpha: 0.8),
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                if (references.isNotEmpty)
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: references
                        .map((ref) => _ReferenceChip(reference: ref))
                        .toList(),
                  ),
                const SizedBox(height: AppSpacing.lg),
                DevotionalContentView(content: payload.content),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceChip extends StatelessWidget {
  const _ReferenceChip({required this.reference});

  final DevotionalVerseReference reference;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.holyGold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      child: Text(
        reference.referenceLabel,
        style: AppTextStyles.reference.copyWith(color: AppColors.holyGold),
      ),
    );
  }
}
