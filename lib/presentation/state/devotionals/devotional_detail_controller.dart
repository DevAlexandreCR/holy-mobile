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
      hasReportedReadComplete: false,
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

  Future<void> toggleSave() async {
    final devotional = state.devotional;
    if (devotional == null || state.isTogglingSave) return;

    state = state.copyWith(isTogglingSave: true, clearError: true);
    try {
      final result = devotional.saved
          ? await _repository.unsaveDevotional(devotional.id)
          : await _repository.saveDevotional(devotional.id);
      state = state.copyWith(
        devotional: devotional.copyWith(
          saveCount: result.saveCount,
          saved: result.saved,
        ),
      );
    } catch (error) {
      state = state.copyWith(errorMessage: _mapError(error));
    } finally {
      state = state.copyWith(isTogglingSave: false);
    }
  }

  Future<void> registerShare() async {
    final devotional = state.devotional;
    if (devotional == null) return;

    try {
      final shareCount = await _repository.shareDevotional(devotional.id);
      state = state.copyWith(
        devotional: devotional.copyWith(shareCount: shareCount),
      );
    } catch (_) {}
  }

  Future<void> reportReadComplete() async {
    final devotional = state.devotional;
    if (devotional == null || state.hasReportedReadComplete) return;

    try {
      final count = await _repository.markReadComplete(devotional.id);
      state = state.copyWith(
        devotional: devotional.copyWith(readCompleteCount: count),
        hasReportedReadComplete: true,
      );
    } catch (_) {}
  }

  Future<bool> report({required String reason, String? details}) async {
    final devotional = state.devotional;
    if (devotional == null || state.isReporting) return false;

    state = state.copyWith(isReporting: true, clearError: true);
    try {
      await _repository.reportDevotional(
        devotionalId: devotional.id,
        reason: reason,
        details: details,
      );
      return true;
    } catch (error) {
      state = state.copyWith(errorMessage: _mapError(error));
      return false;
    } finally {
      state = state.copyWith(isReporting: false);
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
