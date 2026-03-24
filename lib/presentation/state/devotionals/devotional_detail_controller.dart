import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/core/errors/app_error_mapper.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/data/devotionals/devotionals_repository.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_detail_state.dart';

class DevotionalDetailController extends Notifier<DevotionalDetailState> {
  late final DevotionalsRepository _repository;
  String? _activeDevotionalId;
  static const _l10n = AppLocalizations(Locale('es'));

  @override
  DevotionalDetailState build() {
    _repository = ref.read(devotionalsRepositoryProvider);
    return const DevotionalDetailState();
  }

  Future<void> load(String devotionalId) async {
    _activeDevotionalId = devotionalId;
    state = state.copyWith(
      status: DevotionalDetailStatus.loading,
      clearError: true,
      clearDevotional: state.devotional?.id != devotionalId,
    );

    try {
      final devotional = await _repository.getDevotional(devotionalId);
      if (_activeDevotionalId != devotionalId) return;
      state = state.copyWith(
        devotional: devotional,
        status: DevotionalDetailStatus.success,
      );
    } catch (error) {
      if (_activeDevotionalId != devotionalId) return;
      state = state.copyWith(
        status: DevotionalDetailStatus.error,
        errorMessage: _mapError(error),
      );
    }
  }

  Future<void> toggleLike() async {
    final devotional = state.devotional;
    if (devotional == null || state.isTogglingLike) return;

    state = state.copyWith(isTogglingLike: true, clearError: true);
    try {
      final result = await _repository.toggleLike(devotional.id);
      state = state.copyWith(
        devotional: devotional.copyWith(
          likesCount: result.likesCount,
          liked: result.liked,
        ),
      );
    } catch (error) {
      state = state.copyWith(errorMessage: _mapError(error));
    } finally {
      state = state.copyWith(isTogglingLike: false);
    }
  }

  String _mapError(Object error) {
    return AppErrorMapper.toMessage(
      error,
      l10n: _l10n,
      fallbackMessage: _l10n.devotionalsLoadError,
    );
  }
}

final devotionalDetailControllerProvider =
    NotifierProvider<DevotionalDetailController, DevotionalDetailState>(
      DevotionalDetailController.new,
    );
