import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:holy_mobile/core/l10n/app_localizations.dart';
import 'package:holy_mobile/core/theme/app_colors.dart';
import 'package:holy_mobile/core/theme/app_design_tokens.dart';
import 'package:holy_mobile/core/theme/app_text_styles.dart';
import 'package:holy_mobile/presentation/state/auth/auth_controller.dart';
import 'package:holy_mobile/presentation/widgets/holy_button.dart';
import 'package:holy_mobile/presentation/widgets/holy_input_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(authControllerProvider.notifier);
    final success = await notifier.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    final state = ref.read(authControllerProvider);
    if (success) {
      context.go('/verse');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.welcomeBack)),
      );
    } else if (state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.errorMessage!)),
      );
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
                      l10n.loginHeadline,
                      style: AppTextStyles.headline2.copyWith(
                        color: AppColors.pureWhite,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.loginSubtitle,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.softMist.withOpacity(0.85),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _AuthToggle(
                      active: 'login',
                      onLogin: () {},
                      onRegister: state.isLoading
                          ? null
                          : () => context.go('/register'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    HolyInputField(
                      label: l10n.emailLabel,
                      hintText: 'tu@email.com',
                      controller: _emailController,
                      enabled: !state.isLoading,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
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
                    const SizedBox(height: AppSpacing.md),
                    HolyInputField(
                      label: l10n.passwordLabel,
                      hintText: '••••••••',
                      controller: _passwordController,
                      enabled: !state.isLoading,
                      textInputAction: TextInputAction.done,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.softMist.withOpacity(0.9),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.missingPasswordError;
                        }
                        if (value.length < 6) {
                          return l10n.shortPasswordError;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: state.isLoading
                            ? null
                            : () => context.go('/forgot-password'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.holyGold,
                          padding: EdgeInsets.zero,
                          textStyle: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: Text(l10n.forgotPassword),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    HolyButton(
                      label: l10n.loginAction,
                      isLoading: state.isLoading,
                      onPressed: state.isLoading ? null : _onSubmit,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextButton(
                      onPressed:
                          state.isLoading ? null : () => context.go('/register'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.holyGold,
                        textStyle: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Text(l10n.createAccount),
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
                  AppColors.holyGold.withOpacity(0.22),
                  Colors.transparent,
                ],
              ),
              border: Border.all(
                color: AppColors.holyGold.withOpacity(0.4),
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

class _AuthToggle extends StatelessWidget {
  const _AuthToggle({
    required this.active,
    required this.onLogin,
    required this.onRegister,
  });

  final String active;
  final VoidCallback? onLogin;
  final VoidCallback? onRegister;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.pureWhite.withOpacity(0.06),
        borderRadius: AppBorderRadius.button,
        border: Border.all(
          color: AppColors.pureWhite.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _AuthToggleButton(
              label: context.l10n.loginTitle,
              isActive: active == 'login',
              onTap: onLogin,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _AuthToggleButton(
              label: context.l10n.registerTitle,
              isActive: active == 'register',
              onTap: onRegister,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthToggleButton extends StatelessWidget {
  const _AuthToggleButton({
    required this.label,
    required this.isActive,
    this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final background = isActive
        ? AppColors.holyGold
        : AppColors.pureWhite.withOpacity(0.02);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppBorderRadius.button,
          boxShadow: isActive ? AppShadows.goldGlow : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.labelLarge.copyWith(
            color: isActive ? AppColors.midnightFaith : AppColors.softMist,
            fontWeight: FontWeight.w700,
          ),
        ),
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
          colors: [
            AppColors.midnightFaithDark,
            AppColors.midnightFaith,
          ],
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
                    AppColors.holyGold.withOpacity(0.16),
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
                    AppColors.morningLight.withOpacity(0.18),
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
