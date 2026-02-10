import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/data/devotionals/devotionals_repository.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_detail_state.dart';

class DevotionalDetailController extends Notifier<DevotionalDetailState> {
  late final DevotionalsRepository _repository;
  static const _l10n = AppLocalizations(Locale('es'));

  @override
  DevotionalDetailState build() {
    _repository = ref.read(devotionalsRepositoryProvider);
    return const DevotionalDetailState();
  }

  Future<void> load(String devotionalId) async {
    state = state.copyWith(
      status: DevotionalDetailStatus.loading,
      clearError: true,
    );

    try {
      final devotional = await _repository.getDevotional(devotionalId);
      state = state.copyWith(
        devotional: devotional,
        status: DevotionalDetailStatus.success,
      );
    } catch (error) {
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
    if (error is DioException) {
      final data = error.response?.data;
      final responseMessage = data is Map && data['error']?['message'] is String
          ? data['error']['message'] as String
          : null;
      return responseMessage ?? error.message ?? _l10n.genericError;
    }
    return _l10n.genericError;
  }
}

final devotionalDetailControllerProvider =
    NotifierProvider<DevotionalDetailController, DevotionalDetailState>(
  DevotionalDetailController.new,
);
