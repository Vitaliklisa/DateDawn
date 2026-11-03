import 'package:flutter/material.dart';

import '../core/countdown.dart';
import '../core/theme.dart';

/// The four big tiles: years, months, days, hours.
///
/// The unit that is still visibly ticking takes the accent halo — usually
/// hours, but a closer event highlights days or months instead. A zero reads as
/// "nothing left here", so it recedes instead of competing with the units that
/// still carry the countdown.
class CountdownFace extends StatelessWidget {
  const CountdownFace({
    super.key,
    required this.target,
    required this.now,
  });

  final DateTime target;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final remaining = remainingUntil(target, now);
    if (remaining.isPast) return const SizedBox.shrink();

    final liveUnit = remaining.hours > 0
        ? _Unit.hours
        : remaining.days > 0
            ? _Unit.days
            : _Unit.months;

    return Column(
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.45,
          children: [
            _UnitTile(
                value: remaining.years,
                label: 'Years',
                live: liveUnit == _Unit.years),
            _UnitTile(
                value: remaining.months,
                label: 'Months',
                live: liveUnit == _Unit.months),
            _UnitTile(
                value: remaining.days,
                label: 'Days',
                live: liveUnit == _Unit.days),
            _UnitTile(
                value: remaining.hours,
                label: 'Hours',
                live: liveUnit == _Unit.hours),
          ],
        ),
        const SizedBox(height: 18),
        _TickingLine(remaining: remaining),
      ],
    );
  }
}

enum _Unit { years, months, days, hours }

class _UnitTile extends StatelessWidget {
  const _UnitTile(
      {required this.value, required this.label, required this.live});

  final int value;
  final String label;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: live ? colors.accent.withValues(alpha: 0.4) : colors.border,
        ),
        boxShadow: live
            ? [
                BoxShadow(
                  color: colors.accent.withValues(alpha: 0.10),
                  blurRadius: 18,
                  spreadRadius: -4,
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          // Hairline highlight along the top edge of a live tile.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: live
                      ? [
                          Colors.transparent,
                          colors.accent.withValues(alpha: 0.7),
                          Colors.transparent
                        ]
                      : [
                          Colors.transparent,
                          colors.borderStrong,
                          Colors.transparent
                        ],
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    pad2(value),
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: value == 0 ? colors.subtle : colors.fg,
                        ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: live ? colors.accent : colors.subtle,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "04 min · 21 sec remaining", with the pulsing dot from the web app.
class _TickingLine extends StatelessWidget {
  const _TickingLine({required this.remaining});

  final Remaining remaining;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PulsingDot(color: colors.accent),
        const SizedBox(width: 8),
        Text(
          '${pad2(remaining.minutes)} min · ${pad2(remaining.seconds)} sec remaining',
          style: TextStyle(
            fontSize: 13.5,
            color: colors.muted,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});

  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 14,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: (1 - t) * 0.6,
                child: Container(
                  width: 6 + t * 8,
                  height: 6 + t * 8,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Container(
                width: 6,
                height: 6,
                decoration:
                    BoxDecoration(color: widget.color, shape: BoxShape.circle),
              ),
            ],
          );
        },
      ),
    );
  }
}
