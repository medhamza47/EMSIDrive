import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_semantic_colors.dart';

/// Visual states of the fingerprint unlock.
enum BiometricVisual {
  /// Waiting for the user: a few soft pulses invite a tap, then it rests.
  idle,

  /// The system prompt is open: rings keep radiating until it answers.
  scanning,

  /// Recognized: the icon pops into a check on the success color.
  success,

  /// Not recognized: the icon shakes and turns to the error color.
  failure,

  /// Too many attempts: a clock-lock on the warning color, no motion.
  lockedOut,

  /// No usable sensor or no enrolled fingerprint: static error state.
  unavailable,
}

/// Animated fingerprint badge driven by a [BiometricVisual].
///
/// Each state has its own color, icon and motion. Icons cross-fade with a
/// scale, colors tween, and the one-shot motions (shake, pop) replay when
/// [attempt] changes so a second failure shakes again.
///
/// Honors the platform "reduce motion" setting: rings, shake and pop are
/// skipped and only the color and icon change.
class BiometricIndicator extends StatefulWidget {
  const BiometricIndicator({
    required this.visual,
    this.attempt = 0,
    this.size = 168,
    super.key,
  });

  final BiometricVisual visual;

  /// Increment to replay the one-shot motion of the same [visual].
  final int attempt;

  final double size;

  @override
  State<BiometricIndicator> createState() => _BiometricIndicatorState();
}

class _BiometricIndicatorState extends State<BiometricIndicator>
    with TickerProviderStateMixin {
  /// Number of idle pulses before the badge rests.
  static const _idlePulses = 3;

  late final AnimationController _rings = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  bool _synced = false;
  int _run = 0;

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_synced) {
      _synced = true;
      _sync();
    }
  }

  @override
  void didUpdateWidget(BiometricIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visual != widget.visual ||
        oldWidget.attempt != widget.attempt) {
      _sync();
    }
  }

  void _sync() {
    final run = ++_run;
    _rings.stop();
    if (_reduceMotion) {
      _rings.value = 0;
      _shake.value = 0;
      _pop.value = 0;
      return;
    }
    switch (widget.visual) {
      case BiometricVisual.idle:
        unawaited(_pulse(run));
      case BiometricVisual.scanning:
        _rings.repeat();
      case BiometricVisual.success:
        _rings.value = 0;
        _pop.forward(from: 0);
      case BiometricVisual.failure:
        _rings.value = 0;
        _shake.forward(from: 0);
      case BiometricVisual.lockedOut || BiometricVisual.unavailable:
        _rings.value = 0;
    }
  }

  /// A few pulses, then rest: it invites a tap without looping forever.
  Future<void> _pulse(int run) async {
    for (var i = 0; i < _idlePulses; i++) {
      if (!mounted || run != _run) return;
      try {
        await _rings.forward(from: 0).orCancel;
      } on TickerCanceled {
        return;
      }
    }
    if (mounted && run == _run) _rings.value = 0;
  }

  @override
  void dispose() {
    _rings.dispose();
    _shake.dispose();
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic =
        Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    final accent = switch (widget.visual) {
      BiometricVisual.idle || BiometricVisual.scanning => scheme.primary,
      BiometricVisual.success => semantic.success,
      BiometricVisual.failure || BiometricVisual.unavailable => scheme.error,
      BiometricVisual.lockedOut => semantic.warning,
    };
    final icon = switch (widget.visual) {
      BiometricVisual.success => Icons.check_rounded,
      BiometricVisual.lockedOut => Icons.lock_clock_outlined,
      BiometricVisual.unavailable => Icons.error_outline_rounded,
      _ => Icons.fingerprint,
    };
    final core = widget.size * 0.66;
    final motion = _reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 280);

    return SizedBox.square(
      dimension: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Radiating rings: two staggered waves while scanning, one when idle.
          AnimatedBuilder(
            animation: _rings,
            builder: (context, _) => Stack(
              alignment: Alignment.center,
              children: [
                _Ring(progress: _rings.value, color: accent, size: core),
                if (widget.visual == BiometricVisual.scanning)
                  _Ring(
                    progress: (_rings.value + 0.5) % 1,
                    color: accent,
                    size: core,
                  ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: Listenable.merge([_shake, _pop]),
            builder: (context, child) {
              final t = _shake.value;
              // Damped horizontal shake: three swings fading out.
              final dx = math.sin(t * math.pi * 6) * 12 * (1 - t);
              // Overshoot pop: grows then settles back to 1.
              final scale = 1 + 0.14 * math.sin(math.pi * _pop.value);
              return Transform.translate(
                offset: Offset(dx, 0),
                child: Transform.scale(scale: scale, child: child),
              );
            },
            child: AnimatedContainer(
              duration: motion,
              curve: Curves.easeOutCubic,
              width: core,
              height: core,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.12),
                border: Border.all(
                  color: accent.withValues(alpha: 0.35),
                  width: 2,
                ),
              ),
              child: AnimatedSwitcher(
                duration: motion,
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: TweenAnimationBuilder<Color?>(
                  key: ValueKey(icon),
                  duration: motion,
                  tween: ColorTween(end: accent),
                  builder: (context, color, _) =>
                      Icon(icon, size: core * 0.5, color: color),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One expanding, fading circle.
class _Ring extends StatelessWidget {
  const _Ring({
    required this.progress,
    required this.color,
    required this.size,
  });

  final double progress;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (progress == 0) return const SizedBox.shrink();
    final eased = Curves.easeOut.transform(progress);
    return Transform.scale(
      scale: 1 + 0.5 * eased,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withValues(alpha: 0.45 * (1 - eased)),
            width: 2,
          ),
        ),
      ),
    );
  }
}
