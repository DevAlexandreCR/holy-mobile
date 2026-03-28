import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/core/errors/app_error_mapper.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/data/devotionals/devotionals_repository.dart';
import 'package:holyverso/domain/devotionals/devotional_comment.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_comments_state.dart';

class DevotionalCommentsController extends Notifier<DevotionalCommentsState> {
  late final DevotionalsRepository _repository;
  String? _activeDevotionalId;
  static const _l10n = AppLocalizations(Locale('es'));

  @override
  DevotionalCommentsState build() {
    _repository = ref.read(devotionalsRepositoryProvider);
    return const DevotionalCommentsState();
  }

  Future<void> load(String devotionalId) async {
    _activeDevotionalId = devotionalId;
    state = state.copyWith(
      status: DevotionalCommentsStatus.loading,
      devotionalId: devotionalId,
      page: 1,
      clearError: true,
    );

    await _fetchPage(devotionalId: devotionalId, page: 1);
  }

  Future<void> refresh() async {
    final devotionalId = state.devotionalId;
    if (devotionalId == null) return;
    await load(devotionalId);
  }

  Future<void> loadMore() async {
    final devotionalId = state.devotionalId;
    if (devotionalId == null || state.isFetchingMore || !state.hasMore) return;

    state = state.copyWith(isFetchingMore: true, clearError: true);
    await _fetchPage(
      devotionalId: devotionalId,
      page: state.page + 1,
      append: true,
    );
  }

  Future<void> addComment(String content) async {
    final devotionalId = state.devotionalId;
    if (devotionalId == null) return;

    try {
      final comment = await _repository.addComment(
        devotionalId: devotionalId,
        content: content,
      );
      state = state.copyWith(
        items: [comment, ...state.items],
        total: state.total + 1,
      );
    } catch (error) {
      state = state.copyWith(errorMessage: _mapError(error));
    }
  }

  Future<void> deleteComment(DevotionalComment comment) async {
    final devotionalId = state.devotionalId;
    if (devotionalId == null) return;

    try {
      await _repository.deleteComment(
        devotionalId: devotionalId,
        commentId: comment.id,
      );
      state = state.copyWith(
        items: state.items.where((item) => item.id != comment.id).toList(),
        total: state.total > 0 ? state.total - 1 : 0,
      );
    } catch (error) {
      state = state.copyWith(errorMessage: _mapError(error));
    }
  }

  Future<void> _fetchPage({
    required String devotionalId,
    required int page,
    bool append = false,
  }) async {
    try {
      final result = await _repository.fetchComments(
        devotionalId: devotionalId,
        page: page,
        limit: state.limit,
      );

      if (_activeDevotionalId != devotionalId) return;
      final items = append ? [...state.items, ...result.items] : result.items;

      state = state.copyWith(
        status: DevotionalCommentsStatus.success,
        items: items,
        page: result.page,
        limit: result.limit,
        total: result.total,
      );
    } catch (error) {
      if (_activeDevotionalId != devotionalId) return;
      state = state.copyWith(
        status: DevotionalCommentsStatus.error,
        errorMessage: _mapError(error),
      );
    } finally {
      final shouldUpdate = _activeDevotionalId == devotionalId;
      if (shouldUpdate && state.isFetchingMore) {
        state = state.copyWith(isFetchingMore: false);
      }
    }
  }

  String _mapError(Object error) {
    return AppErrorMapper.toMessage(
      error,
      l10n: _l10n,
      fallbackMessage: _l10n.genericError,
      businessCodeMessages: const {
        'USER_BLOCKED_COMMENT_CREATE':
            'Tu cuenta está bloqueada y no puede comentar.',
        'USER_BLOCKED_COMMENT_EDIT':
            'Tu cuenta está bloqueada y no puede editar comentarios.',
        'USER_BLOCKED_COMMENT_DELETE':
            'Tu cuenta está bloqueada y no puede eliminar comentarios.',
      },
    );
  }
}

final devotionalCommentsControllerProvider =
    NotifierProvider<DevotionalCommentsController, DevotionalCommentsState>(
      DevotionalCommentsController.new,
    );
