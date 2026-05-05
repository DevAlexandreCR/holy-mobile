import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/core/errors/app_error_mapper.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/data/devotionals/devotionals_repository.dart';
import 'package:holyverso/domain/devotionals/devotional.dart';
import 'package:holyverso/domain/devotionals/devotional_audio_config.dart';
import 'package:holyverso/domain/devotionals/devotional_audio_segment.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_listening_state.dart';
import 'package:just_audio/just_audio.dart';

class DevotionalListeningController extends Notifier<DevotionalListeningState> {
  static const _l10n = AppLocalizations(Locale('es'));

  late final DevotionalsRepository _repository;
  late final AudioPlayer _player;
  Timer? _pollTimer;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;

  @override
  DevotionalListeningState build() {
    _repository = ref.read(devotionalsRepositoryProvider);
    _player = AudioPlayer();
    _bindPlayer();
    ref.onDispose(_dispose);
    return const DevotionalListeningState();
  }

  Future<void> primeConfig() async {
    if (state.configLoaded) {
      return;
    }

    try {
      final config = await _repository.fetchDevotionalAudioConfig();
      _applyConfig(config);
    } catch (_) {}
  }

  Future<void> togglePlayback(Devotional devotional) async {
    if (state.activeDevotionalId == devotional.id &&
        !state.isPlayerVisible &&
        state.hasActiveSession) {
      showPlayer();
      return;
    }

    if (state.activeDevotionalId == devotional.id) {
      if (state.status == DevotionalListeningStatus.loading) {
        return;
      }

      if (state.status == DevotionalListeningStatus.playing ||
          state.status == DevotionalListeningStatus.buffering) {
        await pause();
        return;
      }

      if (state.status == DevotionalListeningStatus.paused) {
        await resume();
        return;
      }
    }

    await playDevotional(devotional.id);
  }

  Future<void> playDevotional(
    String devotionalId, {
    bool showPlayer = true,
  }) async {
    await _cancelPolling();
    await _player.stop();

    state = state.copyWith(
      activeDevotionalId: devotionalId,
      completedDevotionalId: null,
      status: DevotionalListeningStatus.loading,
      isPlayerVisible: showPlayer,
      retryAfterMs: null,
      position: Duration.zero,
      duration: Duration.zero,
      clearError: true,
    );

    final config = await _loadConfig();
    if (config == null) {
      state = state.copyWith(
        status: DevotionalListeningStatus.error,
        isPlayerVisible: false,
        errorMessage: _l10n.devotionalListeningError,
      );
      return;
    }

    if (!config.enabled) {
      state = state.copyWith(
        status: DevotionalListeningStatus.disabled,
        enabled: false,
        isPlayerVisible: false,
        unavailableMessage: config.unavailableMessage,
      );
      return;
    }

    try {
      final response = await _repository.requestDevotionalAudio(devotionalId);
      if (state.activeDevotionalId != devotionalId) {
        return;
      }

      if (response.isGenerating) {
        final retryAfterMs =
            response.retryAfterMs == null || response.retryAfterMs! <= 0
            ? 2500
            : response.retryAfterMs!;
        state = state.copyWith(
          status: DevotionalListeningStatus.loading,
          retryAfterMs: retryAfterMs,
        );
        _schedulePoll(devotionalId, retryAfterMs);
        return;
      }

      await _loadAndPlaySegments(devotionalId, response.segments);
    } catch (error) {
      if (state.activeDevotionalId != devotionalId) {
        return;
      }

      final backendCode = AppErrorMapper.backendCode(error);
      if (backendCode == 'DEVOTIONAL_AUDIO_DISABLED') {
        final disabledMessage =
            _backendMessage(error) ??
            state.unavailableMessage ??
            _l10n.devotionalListeningComingSoon;
        state = state.copyWith(
          status: DevotionalListeningStatus.disabled,
          configLoaded: true,
          enabled: false,
          isPlayerVisible: false,
          unavailableMessage: disabledMessage,
          errorMessage: null,
        );
        return;
      }

      state = state.copyWith(
        status: DevotionalListeningStatus.error,
        isPlayerVisible: false,
        errorMessage: _resolveErrorMessage(error),
        retryAfterMs: null,
      );
    }
  }

  Future<void> pause() async {
    await _player.pause();
    if (state.activeDevotionalId == null) {
      return;
    }

    state = state.copyWith(status: DevotionalListeningStatus.paused);
  }

  Future<void> resume() async {
    if (state.activeDevotionalId == null) {
      return;
    }

    await _player.play();
    state = state.copyWith(status: DevotionalListeningStatus.playing);
  }

  void showPlayer() {
    if (state.activeDevotionalId == null) {
      return;
    }

    state = state.copyWith(isPlayerVisible: true);
  }

  void hidePlayer() {
    if (state.activeDevotionalId == null) {
      return;
    }

    state = state.copyWith(isPlayerVisible: false);
  }

  Future<void> stop() async {
    await _cancelPolling();
    await _player.stop();
    state = DevotionalListeningState(
      configLoaded: state.configLoaded,
      enabled: state.enabled,
      isPlayerVisible: false,
      unavailableMessage: state.unavailableMessage,
    );
  }

  Future<void> stopIfDifferentDevotional(String devotionalId) async {
    if (state.activeDevotionalId == null ||
        state.activeDevotionalId == devotionalId) {
      return;
    }

    await stop();
  }

  Future<void> handleAppBackgrounded() async {
    if (state.activeDevotionalId == null) {
      return;
    }

    await stop();
  }

  void acknowledgeCompletion() {
    state = state.copyWith(completedDevotionalId: null);
  }

  void _bindPlayer() {
    _playerStateSubscription = _player.playerStateStream.listen((playerState) {
      final activeDevotionalId = state.activeDevotionalId;
      if (activeDevotionalId == null) {
        return;
      }

      if (playerState.processingState == ProcessingState.completed) {
        unawaited(_cancelPolling());
        state = state.copyWith(
          status: DevotionalListeningStatus.completed,
          completedDevotionalId: activeDevotionalId,
          retryAfterMs: null,
          position: state.duration,
        );
        return;
      }

      if (playerState.processingState == ProcessingState.loading ||
          playerState.processingState == ProcessingState.buffering) {
        state = state.copyWith(status: DevotionalListeningStatus.buffering);
        return;
      }

      if (playerState.playing) {
        state = state.copyWith(status: DevotionalListeningStatus.playing);
        return;
      }

      if (state.status == DevotionalListeningStatus.loading ||
          state.status == DevotionalListeningStatus.error ||
          state.status == DevotionalListeningStatus.disabled) {
        return;
      }

      state = state.copyWith(status: DevotionalListeningStatus.paused);
    });

    _positionSubscription = _player.positionStream.listen((position) {
      if (state.activeDevotionalId == null) {
        return;
      }

      state = state.copyWith(position: position);
    });

    _durationSubscription = _player.durationStream.listen((duration) {
      if (state.activeDevotionalId == null) {
        return;
      }

      state = state.copyWith(duration: duration ?? Duration.zero);
    });
  }

  Future<DevotionalAudioConfig?> _loadConfig() async {
    if (state.configLoaded) {
      return DevotionalAudioConfig(
        enabled: state.enabled,
        unavailableMessage:
            state.unavailableMessage ?? _l10n.devotionalListeningComingSoon,
      );
    }

    try {
      final config = await _repository.fetchDevotionalAudioConfig();
      _applyConfig(config);
      return config;
    } catch (error) {
      state = state.copyWith(
        status: DevotionalListeningStatus.error,
        errorMessage: _resolveErrorMessage(error),
      );
      return null;
    }
  }

  void _applyConfig(DevotionalAudioConfig config) {
    state = state.copyWith(
      configLoaded: true,
      enabled: config.enabled,
      unavailableMessage: config.unavailableMessage,
    );
  }

  Future<void> _loadAndPlaySegments(
    String devotionalId,
    List<DevotionalAudioSegment> segments,
  ) async {
    if (segments.isEmpty) {
      state = state.copyWith(
        status: DevotionalListeningStatus.error,
        errorMessage: _l10n.devotionalListeningError,
      );
      return;
    }

    final children = segments
        .map((segment) => AudioSource.uri(Uri.parse(segment.url)))
        .toList();

    await _player.setAudioSources(children);
    if (state.activeDevotionalId != devotionalId) {
      return;
    }

    await _player.play();
  }

  void _schedulePoll(String devotionalId, int retryAfterMs) {
    _pollTimer?.cancel();
    _pollTimer = Timer(Duration(milliseconds: retryAfterMs), () {
      unawaited(playDevotional(devotionalId));
    });
  }

  Future<void> _cancelPolling() async {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  String _resolveErrorMessage(Object error) {
    final backendMessage = _backendMessage(error);
    if (backendMessage != null && backendMessage.isNotEmpty) {
      return backendMessage;
    }

    return AppErrorMapper.toMessage(
      error,
      l10n: _l10n,
      fallbackMessage: _l10n.devotionalListeningError,
      businessCodeMessages: {
        'DEVOTIONAL_AUDIO_TOO_LONG': _l10n.devotionalListeningTooLong,
      },
    );
  }

  String? _backendMessage(Object error) {
    if (error is! DioException) {
      return null;
    }

    final data = error.response?.data;
    if (data is Map && data['error'] is Map) {
      return data['error']['message']?.toString();
    }

    return null;
  }

  Future<void> _dispose() async {
    await _cancelPolling();
    await _playerStateSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _player.dispose();
  }
}

final devotionalListeningControllerProvider =
    NotifierProvider.autoDispose<
      DevotionalListeningController,
      DevotionalListeningState
    >(DevotionalListeningController.new);
