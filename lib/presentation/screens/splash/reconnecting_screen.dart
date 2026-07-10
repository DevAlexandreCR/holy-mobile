import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_design_tokens.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';
import 'package:holyverso/presentation/state/auth/auth_controller.dart';

// No connectivity-change signal is available (connectivity_plus is not a
// project dependency), so auto-retry falls back to: resuming from background
// (a reasonable proxy for connectivity regain) plus a bounded periodic timer.
class ReconnectingScreen extends ConsumerStatefulWidget {
  const ReconnectingScreen({super.key});

  @override
  ConsumerState<ReconnectingScreen> createState() =>
      _ReconnectingScreenState();
}

class _ReconnectingScreenState extends ConsumerState<ReconnectingScreen>
    with WidgetsBindingObserver {
  static const _autoRetryInterval = Duration(seconds: 8);
  static const _maxAutoRetries = 6;

  Timer? _autoRetryTimer;
  int _autoRetryCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleAutoRetry();
  }

  @override
  void dispose() {
    _autoRetryTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _retry();
    }
  }

  void _scheduleAutoRetry() {
    if (_autoRetryCount >= _maxAutoRetries) return;
    _autoRetryTimer = Timer(_autoRetryInterval, () {
      if (!mounted) return;
      _autoRetryCount++;
      _retry();
      _scheduleAutoRetry();
    });
  }

  void _retry() {
    if (!mounted) return;
    if (ref.read(authControllerProvider).isLoading) return;
    ref.read(authControllerProvider.notifier).restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isRetrying = ref.watch(
      authControllerProvider.select((state) => state.isLoading),
    );

    return Scaffold(
      backgroundColor: AppColors.midnightFaith,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: AppColors.holyGold,
                  strokeWidth: 3,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.reconnectingTitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headline2.copyWith(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.reconnectingMessage,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.softMist.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: isRetrying ? null : _retry,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.holyGold,
                    foregroundColor: AppColors.midnightFaithDark,
                    minimumSize: const Size(
                      double.infinity,
                      AppSizes.buttonHeight,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppBorderRadius.button,
                    ),
                  ),
                  child: isRetrying
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.midnightFaithDark,
                          ),
                        )
                      : Text(l10n.errorRetry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
