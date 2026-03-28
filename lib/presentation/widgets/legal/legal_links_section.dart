import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/core/config/app_config.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_design_tokens.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';
import 'package:holyverso/presentation/widgets/setting_tile.dart';
import 'package:url_launcher/url_launcher.dart';

enum LegalLinksVariant { auth, settings }

class LegalLinksSection extends ConsumerWidget {
  const LegalLinksSection.auth({super.key}) : variant = LegalLinksVariant.auth;

  const LegalLinksSection.settings({super.key})
    : variant = LegalLinksVariant.settings;

  final LegalLinksVariant variant;

  Future<void> _openLink(
    BuildContext context, {
    required String? rawUrl,
    required String label,
  }) async {
    if (rawUrl == null || rawUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label no está configurado todavía.')),
      );
      return;
    }

    final uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No fue posible abrir $label.')));
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No fue posible abrir $label.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final items = [
      (
        label: 'Términos y condiciones',
        icon: Icons.gavel_outlined,
        url: config.termsUrl,
      ),
      (
        label: 'Política de privacidad',
        icon: Icons.privacy_tip_outlined,
        url: config.privacyPolicyUrl,
      ),
      (
        label: 'Contacto / Soporte',
        icon: Icons.support_agent_outlined,
        url: config.contactUrl,
      ),
    ];

    if (variant == LegalLinksVariant.settings) {
      return Column(
        children: items
            .map(
              (item) => SettingTile(
                icon: item.icon,
                title: item.label,
                subtitle: item.url?.isNotEmpty == true
                    ? 'Se abre fuera de la app'
                    : 'Pendiente por configurar',
                trailing: Icon(
                  Icons.open_in_new_rounded,
                  color: AppColors.softMist.withValues(alpha: 0.7),
                ),
                onTap: () =>
                    _openLink(context, rawUrl: item.url, label: item.label),
              ),
            )
            .toList(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Al continuar aceptas nuestros enlaces legales y canales de soporte.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.softMist.withValues(alpha: 0.74),
            height: 1.45,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: 2,
          children: items
              .map(
                (item) => TextButton(
                  onPressed: () =>
                      _openLink(context, rawUrl: item.url, label: item.label),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.holyGold,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: Size.zero,
                  ),
                  child: Text(item.label, textAlign: TextAlign.center),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
