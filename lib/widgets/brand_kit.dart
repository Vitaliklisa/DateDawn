import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/countdown.dart';
import '../core/theme.dart';

/// The "Date Dawn" wordmark with its clock glyph. The second hand sweeps once
/// on mount — the same greeting the web app's animated icon gives.
class BrandMark extends StatefulWidget {
  const BrandMark({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  State<BrandMark> createState() => _BrandMarkState();
}

class _BrandMarkState extends State<BrandMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    unawaited(_sweep.forward());
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _sweep,
              builder: (context, _) => SizedBox(
                width: 19,
                height: 19,
                child: CustomPaint(
                  painter: _ClockPainter(
                    color: colors.accent,
                    handProgress: _sweep.value,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'DATE DAWN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.4,
                color: colors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  _ClockPainter({required this.color, required this.handProgress});

  final Color color;
  final double handProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1;

    final ring = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawCircle(center, radius, ring);

    final hand = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    // A full sweep reads as a second hand; easing makes it land, not stop dead.
    final angle = -math.pi / 2 +
        Curves.easeOutCubic.transform(handProgress) * 2 * math.pi;
    canvas.drawLine(
      center,
      center +
          Offset(
              radius * 0.72 * math.cos(angle), radius * 0.72 * math.sin(angle)),
      hand,
    );
  }

  @override
  bool shouldRepaint(_ClockPainter old) =>
      old.handProgress != handProgress || old.color != color;
}

/// A small status label ("Upcoming" / "Passed") that colours itself from the
/// event rather than from its context.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.isPast});

  final bool isPast;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isPast ? Icons.history_rounded : Icons.calendar_today_rounded,
          size: 13,
          color: isPast ? colors.accent : colors.subtle,
        ),
        const SizedBox(width: 6),
        Text(
          isPast ? 'Passed' : 'Upcoming',
          style: TextStyle(
            fontSize: 12,
            color: isPast ? colors.accent : colors.subtle,
          ),
        ),
      ],
    );
  }
}

/// Round avatar with initials falling back to the account's first letters.
class UserAvatar extends StatelessWidget {
  const UserAvatar(
      {super.key, required this.initials, this.photoUrl, this.size = 32});

  final String initials;
  final String? photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: colors.surface2,
        alignment: Alignment.center,
        child: (photoUrl != null && photoUrl!.isNotEmpty)
            ? Image.network(
                photoUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(colors),
              )
            : _fallback(colors),
      ),
    );
  }

  Widget _fallback(AppPalette colors) => Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.34,
          fontWeight: FontWeight.w600,
          color: colors.muted,
        ),
      );
}

/// "3 days, 4 hours" — used under the hero title and in share text.
class RemainingSummary extends StatelessWidget {
  const RemainingSummary({super.key, required this.target, required this.now});

  final DateTime target;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final remaining = remainingUntil(target, now);
    return Text(
      remaining.isPast
          ? 'It has arrived.'
          : '${describeRemaining(remaining)} to go',
      style: TextStyle(fontSize: 13, color: colors.muted),
    );
  }
}
