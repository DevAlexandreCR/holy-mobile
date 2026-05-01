import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_design_tokens.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_reading_settings_controller.dart';

class DevotionalReadingScaleGesture extends ConsumerStatefulWidget {
  const DevotionalReadingScaleGesture({super.key, required this.builder});

  final Widget Function(BuildContext context, double textScale) builder;

  @override
  ConsumerState<DevotionalReadingScaleGesture> createState() =>
      _DevotionalReadingScaleGestureState();
}

class _DevotionalReadingScaleGestureState
    extends ConsumerState<DevotionalReadingScaleGesture> {
  static const _overlayHideDelay = Duration(milliseconds: 650);

  final Map<int, Offset> _pointers = <int, Offset>{};
  Timer? _overlayTimer;
  double? _gestureStartDistance;
  double? _gestureStartScale;
  double? _panZoomStartScale;
  bool _isPinching = false;
  bool _showOverlay = false;

  @override
  void dispose() {
    _overlayTimer?.cancel();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    _pointers[event.pointer] = event.localPosition;
    if (_pointers.length == 2) {
      _beginPinch();
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!_pointers.containsKey(event.pointer)) {
      return;
    }

    _pointers[event.pointer] = event.localPosition;
    if (_pointers.length != 2) {
      return;
    }

    if (!_isPinching) {
      _beginPinch();
    }

    final startDistance = _gestureStartDistance;
    final startScale = _gestureStartScale;
    final currentDistance = _currentDistance();
    if (startDistance == null ||
        startScale == null ||
        startDistance <= 0 ||
        currentDistance <= 0) {
      return;
    }

    ref
        .read(devotionalReadingSettingsControllerProvider.notifier)
        .updateTextScale(startScale * (currentDistance / startDistance));
  }

  void _handlePointerUp(PointerUpEvent event) {
    _finishPointer(event.pointer);
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _finishPointer(event.pointer);
  }

  void _handlePanZoomStart(PointerPanZoomStartEvent event) {
    _overlayTimer?.cancel();
    _panZoomStartScale = ref
        .read(devotionalReadingSettingsControllerProvider)
        .textScale;
    setState(() {
      _showOverlay = true;
    });
  }

  void _handlePanZoomUpdate(PointerPanZoomUpdateEvent event) {
    final startScale = _panZoomStartScale;
    if (startScale == null) {
      return;
    }
    ref
        .read(devotionalReadingSettingsControllerProvider.notifier)
        .updateTextScale(startScale * event.scale);
  }

  void _handlePanZoomEnd(PointerPanZoomEndEvent event) {
    _panZoomStartScale = null;
    _commitAndScheduleOverlayHide();
  }

  void _finishPointer(int pointer) {
    _pointers.remove(pointer);
    if (_isPinching && _pointers.length < 2) {
      _endPinch();
    }
  }

  void _beginPinch() {
    final distance = _currentDistance();
    if (distance <= 0) {
      return;
    }

    _overlayTimer?.cancel();
    _gestureStartDistance = distance;
    _gestureStartScale = ref
        .read(devotionalReadingSettingsControllerProvider)
        .textScale;
    setState(() {
      _isPinching = true;
      _showOverlay = true;
    });
  }

  void _endPinch() {
    _isPinching = false;
    _gestureStartDistance = null;
    _gestureStartScale = null;
    _commitAndScheduleOverlayHide();
  }

  void _commitAndScheduleOverlayHide() {
    unawaited(
      ref
          .read(devotionalReadingSettingsControllerProvider.notifier)
          .commitTextScale(),
    );
    _overlayTimer?.cancel();
    _overlayTimer = Timer(_overlayHideDelay, () {
      if (!mounted) {
        return;
      }
      setState(() {
        _showOverlay = false;
      });
    });
  }

  double _currentDistance() {
    if (_pointers.length != 2) {
      return 0;
    }

    final positions = _pointers.values.toList(growable: false);
    return (positions[0] - positions[1]).distance;
  }

  @override
  Widget build(BuildContext context) {
    final textScale = ref.watch(
      devotionalReadingSettingsControllerProvider.select(
        (state) => state.textScale,
      ),
    );

    return Listener(
      key: const Key('devotional-reading-scale-gesture'),
      behavior: HitTestBehavior.opaque,
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      onPointerPanZoomStart: _handlePanZoomStart,
      onPointerPanZoomUpdate: _handlePanZoomUpdate,
      onPointerPanZoomEnd: _handlePanZoomEnd,
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            widget.builder(context, textScale),
            if (_showOverlay)
              Positioned.fill(
                child: IgnorePointer(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Transform.translate(
                      offset: const Offset(0, -10),
                      child: _ScaleOverlay(textScale: textScale),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScaleOverlay extends StatelessWidget {
  const _ScaleOverlay({required this.textScale});

  final double textScale;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('devotional-reading-scale-percentage'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.midnightFaithDark.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
        border: Border.all(color: AppColors.pureWhite.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        '${math.max(0, (textScale * 100).round())}%',
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.pureWhite,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
