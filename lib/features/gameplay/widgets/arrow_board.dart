import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/utils/grid_utils.dart';
import '../../progression/progress_repository.dart';
import '../engine/arrow_engine.dart';
import '../engine/game_controller.dart';
import '../models/arrow_model.dart';
import '../models/game_state.dart';
import '../painters/arrow_painter.dart';
import '../painters/shape_board_painter.dart';

class _Flight {
  _Flight(this.arrow, this.path, this.startMs, this.durationMs);
  final ArrowModel arrow;
  final List<Cell> path;
  final int startMs;
  final int durationMs;
  double get distance => (path.length - arrow.length).toDouble();
}

class _Bounce {
  _Bounce(this.event, this.path, this.startMs, this.durationMs);
  final ArrowBlockedEvent event;
  final List<Cell> path;
  final int startMs;
  final int durationMs;
}

class _Hint {
  _Hint(this.arrowId, this.startMs);
  final int arrowId;
  final int startMs;
}

/// Interactive puzzle board. The logical board lives in [GameController];
/// this widget only renders it and plays the escape / bounce / hint
/// animations described by [GameState.lastEvent].
class ArrowBoard extends ConsumerStatefulWidget {
  const ArrowBoard({super.key});

  @override
  ConsumerState<ArrowBoard> createState() => _ArrowBoardState();
}

class _ArrowBoardState extends ConsumerState<ArrowBoard> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final Stopwatch _clock = Stopwatch()..start();
  final ValueNotifier<int> _frame = ValueNotifier(0);

  final List<_Flight> _flights = [];
  final Map<int, _Bounce> _bounces = {};
  _Hint? _hint;
  BoardGeometry? _geometry;

  int get _now => _clock.elapsedMilliseconds;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  void _ensureTicking() {
    if (!_ticker.isActive) _ticker.start();
  }

  void _onTick(Duration _) {
    final now = _now;
    final hadFlights = _flights.isNotEmpty;
    _flights.removeWhere((f) => now - f.startMs >= f.durationMs);
    final bounceCount = _bounces.length;
    _bounces.removeWhere((_, b) => now - b.startMs >= b.durationMs);
    if (bounceCount != _bounces.length) setState(() {}); // un-hide in static layer
    if (_hint != null && now - _hint!.startMs >= GameConstants.hintPulseMs) {
      _hint = null;
      ref.read(gameControllerProvider.notifier).clearHint();
    }
    if (hadFlights && _flights.isEmpty) {
      ref.read(gameControllerProvider.notifier).animationsSettled();
    }
    if (_flights.isEmpty && _bounces.isEmpty && _hint == null) _ticker.stop();
    _frame.value++;
  }

  void _onEvent(BoardEvent? event) {
    final s = ref.read(gameControllerProvider);
    if (s == null) return;
    if (event == null) {
      // New level or restart: drop any in-flight visuals.
      setState(() {
        _flights.clear();
        _bounces.clear();
        _hint = null;
      });
      return;
    }
    final settings = ref.read(settingsProvider);
    final rows = s.level.gridRows, cols = s.level.gridColumns;
    switch (event) {
      case ArrowEscapedEvent(:final arrow, :final exitPath):
        final dist = exitPath.length - arrow.length;
        final ms = (GameConstants.escapeBaseMs + dist * 10).clamp(
          GameConstants.escapeBaseMs,
          GameConstants.escapeMaxMs,
        );
        _flights.add(_Flight(arrow, exitPath, _now, ms));
        if (_hint?.arrowId == arrow.id) _hint = null;
        if (settings.haptics) HapticFeedback.lightImpact();
        if (settings.sound) SystemSound.play(SystemSoundType.click);
      case ArrowBlockedEvent(:final arrow, :final freeSteps):
        final path = [...arrow.cells, ...rayCells(arrow.head, arrow.direction, rows, cols)];
        final ms = GameConstants.bounceMs + math.min(freeSteps, 8) * 25;
        setState(() => _bounces[arrow.id] = _Bounce(event, path, _now, ms));
        if (settings.haptics) HapticFeedback.heavyImpact();
      case HintEvent(:final arrowId):
        _hint = _Hint(arrowId, _now);
        if (settings.haptics) HapticFeedback.selectionClick();
    }
    _ensureTicking();
  }

  void _onTapUp(TapUpDetails d) {
    final s = ref.read(gameControllerProvider);
    final g = _geometry;
    if (s == null || g == null || !s.isInteractive) return;
    final id = _hitTest(s, g, d.localPosition);
    if (id == null || _bounces.containsKey(id)) return; // ignore taps mid-bounce
    ref.read(gameControllerProvider.notifier).tapArrow(id);
  }

  int? _hitTest(GameState s, BoardGeometry g, Offset p) {
    final rows = s.level.gridRows, cols = s.level.gridColumns;
    final occ = ArrowEngine.occupancy(s.arrows, rows, cols);
    final cell = g.cellAt(p);
    if (cell.inBounds(rows, cols) && occ[cell.index(cols)] != -1) return occ[cell.index(cols)];
    // Forgiving taps: nearest arrow cell within ~0.8 cells.
    int? best;
    var bestD = g.cellSize * 0.8;
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        final c = Cell(cell.row + dr, cell.col + dc);
        if (!c.inBounds(rows, cols)) continue;
        final id = occ[c.index(cols)];
        if (id == -1) continue;
        final dist = (g.center(c) - p).distance;
        if (dist < bestD) {
          bestD = dist;
          best = id;
        }
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(gameControllerProvider.select((s) => s?.lastEvent), (_, next) => _onEvent(next));
    final s = ref.watch(gameControllerProvider);
    if (s == null) return const SizedBox.shrink();
    final level = s.level;

    return LayoutBuilder(
      builder: (context, c) {
        final cs = math.min(c.maxWidth / level.gridColumns, c.maxHeight / level.gridRows).clamp(8.0, 64.0);
        final size = Size(cs * level.gridColumns, cs * level.gridRows);
        _geometry = BoardGeometry(cellSize: cs, origin: Offset.zero);
        return Center(
          child: SizedBox.fromSize(
            size: size,
            child: GestureDetector(
              key: const Key('arrow-board'),
              behavior: HitTestBehavior.opaque,
              onTapUp: _onTapUp,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: ShapeBoardPainter(
                          mask: level.occupancyMask,
                          arrows: s.arrows,
                          cellSize: cs,
                          hiddenIds: _bounces.keys.toSet(),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _AnimationPainter(
                        repaint: _frame,
                        state: this,
                        cellSize: cs,
                        arrows: s.arrows,
                        rows: level.gridRows,
                        cols: level.gridColumns,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Dynamic layer: escaping arrows, bouncing arrows, blocker flashes, hints.
class _AnimationPainter extends CustomPainter {
  _AnimationPainter({
    required Listenable repaint,
    required this.state,
    required this.cellSize,
    required this.arrows,
    required this.rows,
    required this.cols,
  }) : super(repaint: repaint);

  final _ArrowBoardState state;
  final double cellSize;
  final List<ArrowModel> arrows;
  final int rows, cols;

  @override
  void paint(Canvas canvas, Size size) {
    final g = BoardGeometry(cellSize: cellSize, origin: Offset.zero);
    final now = state._now;

    // Hint: pulsing glow + dashed exit ray.
    final hint = state._hint;
    if (hint != null) {
      final a = arrows.where((x) => x.id == hint.arrowId).firstOrNull;
      if (a != null) {
        final p = ((now - hint.startMs) / 420.0);
        final glow = 0.55 + 0.45 * math.sin(p * math.pi);
        _dashedRay(canvas, g, a);
        ArrowPainter.paintArrow(canvas, g, a, style: ArrowStyle(glow: glow.abs()));
      }
    }

    // Blocker flash.
    for (final b in state._bounces.values) {
      final p = ((now - b.startMs) / b.durationMs).clamp(0.0, 1.0);
      final blocker = arrows.where((x) => x.id == b.event.blockerId).firstOrNull;
      if (blocker != null && !state._bounces.containsKey(blocker.id)) {
        final flash = math.sin(p * math.pi);
        ArrowPainter.paintArrow(
          canvas,
          g,
          blocker,
          style: ArrowStyle(
            tint: Color.lerp(SketchColors.arrowPalette[blocker.colorIndex], SketchColors.coral, flash),
            outlineColor: Color.lerp(SketchColors.outline, const Color(0xFFD2372E), flash),
          ),
        );
      }
    }

    // Bouncing (blocked) arrows slide up to the blocker and spring back.
    for (final b in state._bounces.values) {
      final p = ((now - b.startMs) / b.durationMs).clamp(0.0, 1.0);
      final peak = b.event.freeSteps + 0.28;
      final t = p < 0.45
          ? Curves.easeOut.transform(p / 0.45) * peak
          : peak * (1 - Curves.easeInOut.transform((p - 0.45) / 0.55));
      final shake = p > 0.4 ? math.sin(p * math.pi * 10) * (1 - p) * 0.06 : 0.0;
      ArrowPainter.paintSliding(
        canvas,
        g,
        b.event.arrow,
        b.path,
        (t + shake).clamp(0.0, peak),
        style: ArrowStyle(
          tint: Color.lerp(
            SketchColors.arrowPalette[b.event.arrow.colorIndex],
            SketchColors.coral,
            math.sin(p * math.pi),
          ),
        ),
      );
    }

    // Escaping arrows.
    for (final f in state._flights) {
      final p = ((now - f.startMs) / f.durationMs).clamp(0.0, 1.0);
      final t = Curves.easeInCubic.transform(p) * f.distance;
      final opacity = p < 0.65 ? 1.0 : 1 - (p - 0.65) / 0.35;
      final hl = p < 0.12 ? 1 - p / 0.12 : 0.0; // brief highlight at launch
      ArrowPainter.paintSliding(
        canvas,
        g,
        f.arrow,
        f.path,
        t,
        style: ArrowStyle(opacity: opacity.clamp(0.0, 1.0), glow: hl * 0.7),
      );
    }
  }

  void _dashedRay(Canvas canvas, BoardGeometry g, ArrowModel a) {
    final paint = Paint()
      ..color = SketchColors.outline.withValues(alpha: 0.35)
      ..strokeWidth = cellSize * 0.07
      ..strokeCap = StrokeCap.round;
    final dv = Offset(a.direction.dCol.toDouble(), a.direction.dRow.toDouble());
    var p = g.center(a.head) + dv * cellSize * 0.6;
    final end = g.center(a.head.step(a.direction, math.max(rows, cols) + 1));
    final dash = cellSize * 0.22;
    while ((end - p).distance > dash &&
        Rect.fromLTWH(-cellSize, -cellSize, (cols + 2) * cellSize, (rows + 2) * cellSize).contains(p)) {
      canvas.drawLine(p, p + dv * dash, paint);
      p += dv * dash * 2;
    }
  }

  @override
  bool shouldRepaint(covariant _AnimationPainter old) => true;
}
