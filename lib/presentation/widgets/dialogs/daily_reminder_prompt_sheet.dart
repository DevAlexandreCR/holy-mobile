import 'package:flutter/material.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_design_tokens.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';
import 'package:holyverso/presentation/widgets/common/holy_bottom_sheet.dart';

class _DailyReminderAnchor {
  const _DailyReminderAnchor(this.hour, this.label, this.subtitle);

  final int hour;
  final String label;
  final String subtitle;
}

const List<_DailyReminderAnchor> _dailyReminderAnchors = [
  _DailyReminderAnchor(7, 'Mañana', '7:00 a. m.'),
  _DailyReminderAnchor(12, 'Mediodía', '12:00 p. m.'),
  _DailyReminderAnchor(20, 'Noche', '8:00 p. m.'),
];

/// One-time post-authentication prompt asking the user when they want their
/// daily devotional reminder. Selecting an anchor returns its hour; "Ahora
/// no" (or dismissing the sheet) returns null.
class DailyReminderPromptSheet extends StatelessWidget {
  const DailyReminderPromptSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return HolyBottomSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Cuándo es tu momento con Dios?',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.pureWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Elige un momento del día para recibir tu recordatorio devocional. Puedes cambiarlo luego en Ajustes.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.softMist.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ..._dailyReminderAnchors.map(
            (anchor) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _DailyReminderAnchorOption(
                label: anchor.label,
                subtitle: anchor.subtitle,
                onTap: () => Navigator.of(context).pop(anchor.hour),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Ahora no',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.softMist.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyReminderAnchorOption extends StatelessWidget {
  const _DailyReminderAnchorOption({
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppBorderRadius.input,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: AppBorderRadius.input,
          gradient: LinearGradient(
            colors: [
              AppColors.pureWhite.withValues(alpha: 0.05),
              AppColors.pureWhite.withValues(alpha: 0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: AppColors.pureWhite.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.pureWhite,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.softMist.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.softMist.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }
}
