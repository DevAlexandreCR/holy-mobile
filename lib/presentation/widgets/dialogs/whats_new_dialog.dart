import 'package:flutter/material.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_design_tokens.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';
import 'package:holyverso/domain/models/release_note.dart';

class WhatsNewDialog extends StatelessWidget {
  const WhatsNewDialog({super.key, required this.releaseNote});

  final ReleaseNote releaseNote;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.75;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: Container(
        constraints: BoxConstraints(maxWidth: 460, maxHeight: maxHeight),
        decoration: BoxDecoration(
          borderRadius: AppBorderRadius.card,
          gradient: AppColors.midnightGradient,
          border: Border.all(
            color: AppColors.pureWhite.withValues(alpha: 0.08),
          ),
          boxShadow: AppShadows.cardShadow,
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.holyGold.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.holyGold.withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.holyGold,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                '¿Qué hay de nuevo?',
                textAlign: TextAlign.center,
                style: AppTextStyles.headline3.copyWith(
                  color: AppColors.pureWhite,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: Text(
                'Versión ${releaseNote.version}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.softMist.withValues(alpha: 0.85),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                child: Column(
                  children: releaseNote.changes
                      .map((change) => _ChangeItem(text: change))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.holyGold,
                  foregroundColor: AppColors.midnightFaith,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Entendido'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangeItem extends StatelessWidget {
  const _ChangeItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.holyGold,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.holyGold.withValues(alpha: 0.35),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.softMist.withValues(alpha: 0.92),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
