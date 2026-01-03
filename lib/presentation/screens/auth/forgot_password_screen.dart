import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_design_tokens.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';
import 'package:holyverso/presentation/state/auth/auth_controller.dart';
import 'package:holyverso/presentation/widgets/holy_button.dart';
import 'package:holyverso/presentation/widgets/holy_input_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(authControllerProvider.notifier);
    final success = await notifier.sendForgotPassword(
      _emailController.text.trim(),
    );
    if (!mounted) return;

    final state = ref.read(authControllerProvider);

    if (success) {
      final successMessage = context.l10n.instructionsSent;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
      context.go(
        Uri(
          path: '/login',
          queryParameters: {'message': successMessage},
        ).toString(),
        extra: successMessage,
      );
    } else if (state.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.midnightFaith,
      body: Stack(
        children: [
          const _BackgroundGlow(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.lg,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    const _LogoHeader(),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      l10n.forgotPasswordHeadline,
                      style: AppTextStyles.headline2.copyWith(
                        color: AppColors.pureWhite,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.forgotPasswordSubtitle,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.softMist.withValues(alpha: 0.85),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    HolyInputField(
                      label: l10n.emailLabel,
                      hintText: 'tu@email.com',
                      controller: _emailController,
                      enabled: !state.isLoading,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.missingEmailError;
                        }
                        if (!value.contains('@')) {
                          return l10n.invalidEmailError;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    HolyButton(
                      label: l10n.sendLink,
                      isLoading: state.isLoading,
                      onPressed: state.isLoading ? null : _onSubmit,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextButton(
                      onPressed: state.isLoading
                          ? null
                          : () => context.go('/login'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.holyGold,
                      ),
                      child: Text(l10n.backToLogin),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundGlow extends StatelessWidget {
  const _BackgroundGlow();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.midnightFaithDark, AppColors.midnightFaith],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -40,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.holyGold.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -140,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.morningLight.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoHeader extends StatelessWidget {
  const _LogoHeader();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.holyGold.withValues(alpha: 0.22),
                  Colors.transparent,
                ],
              ),
              border: Border.all(
                color: AppColors.holyGold.withValues(alpha: 0.4),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: ClipOval(
                child: Image.asset(
                  'assets/icon/app_icon.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'HolyVerso',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.pureWhite,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
