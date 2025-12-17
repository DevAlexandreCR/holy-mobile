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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(authControllerProvider.notifier);
    final success = await notifier.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    final state = ref.read(authControllerProvider);

    if (success) {
      context.go('/verse');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.accountCreated)));
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
                      l10n.registerHeadline,
                      style: AppTextStyles.headline1.copyWith(
                        color: AppColors.pureWhite,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.registerSubtitle,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.softMist.withValues(alpha: 0.85),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _AuthToggle(
                      active: 'register',
                      onLogin: state.isLoading
                          ? null
                          : () => context.go('/login'),
                      onRegister: () {},
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    HolyInputField(
                      label: l10n.nameLabel,
                      hintText: 'Juan Perez',
                      controller: _nameController,
                      enabled: !state.isLoading,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.missingNameError;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
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
                      textInputAction: TextInputAction.next,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.softMist.withValues(alpha: 0.9),
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
                    const SizedBox(height: AppSpacing.md),
                    HolyInputField(
                      label: l10n.confirmPasswordLabel,
                      hintText: '••••••••',
                      controller: _confirmPasswordController,
                      enabled: !state.isLoading,
                      textInputAction: TextInputAction.done,
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        ),
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.softMist.withValues(alpha: 0.9),
                        ),
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return l10n.passwordMismatchError;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    HolyButton(
                      label: l10n.registerAction,
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
                        textStyle: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Text(l10n.alreadyHaveAccount),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.holyGold.withValues(alpha: 0.18),
                  Colors.transparent,
                ],
              ),
              border: Border.all(
                color: AppColors.holyGold.withValues(alpha: 0.35),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: ClipOval(
                child: Image.asset(
                  'assets/icon/app_icon.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'HolyVerso',
            style: AppTextStyles.headline3.copyWith(
              color: AppColors.pureWhite,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
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
        color: AppColors.pureWhite.withValues(alpha: 0.06),
        borderRadius: AppBorderRadius.button,
        border: Border.all(color: AppColors.pureWhite.withValues(alpha: 0.08)),
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
        : AppColors.pureWhite.withValues(alpha: 0.02);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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
