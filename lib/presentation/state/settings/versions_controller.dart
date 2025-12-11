import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holy_mobile/data/bible/bible_repository.dart';
import 'package:holy_mobile/presentation/state/auth/auth_controller.dart';
import 'package:holy_mobile/presentation/state/settings/versions_state.dart';

class VersionsController extends Notifier<VersionsState> {
  late final BibleRepository _repository;

  @override
  VersionsState build() {
    _repository = ref.read(bibleRepositoryProvider);

    ref.listen(authControllerProvider, (previous, next) {
      if (previous?.isAuthenticated == true && !next.isAuthenticated) {
        state = const VersionsState();
      }
    });

    return const VersionsState();
  }

  Future<void> loadVersions({bool forceRefresh = false}) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final versions = await _repository.fetchVersions(forceRefresh: forceRefresh);
      state = state.copyWith(
        versions: versions,
        isLoading: false,
        hasLoaded: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        hasLoaded: true,
        errorMessage: _mapError(error),
      );
    }
  }

  Future<bool> selectVersion(int versionId) async {
    state = state.copyWith(clearError: true);
    final success =
        await ref.read(authControllerProvider.notifier).updatePreferredVersion(versionId);

    if (!success) {
      final authState = ref.read(authControllerProvider);
      state = state.copyWith(
        errorMessage: authState.errorMessage ?? 'No se pudo actualizar la versión.',
      );
    }

    return success;
  }

  String _mapError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      final responseMessage =
          data is Map && data['message'] is String ? data['message'] as String : null;
      return responseMessage ??
          error.message ??
          'No pudimos cargar las versiones. Inténtalo de nuevo.';
    }

    return 'No pudimos cargar las versiones. Inténtalo de nuevo.';
  }
}

final versionsControllerProvider =
    NotifierProvider<VersionsController, VersionsState>(VersionsController.new);
