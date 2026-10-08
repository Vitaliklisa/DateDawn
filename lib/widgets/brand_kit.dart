import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/countdown.dart';
import '../core/models.dart';
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

/// Round avatar drawn entirely in Flutter: the account's initials on a colour
/// derived from its id.
///
/// There is no image to load. Date Dawn launches without uploaded profile
/// pictures — Cloud Storage requires the Blaze plan — so this is the whole
/// avatar system: a hash, a palette and a `Text`. That also means it works
/// offline, costs nothing, and cannot show a broken-image box.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.initials,
    this.seed,
    this.photoUrl,
    this.size = 32,
  });

  final String initials;

  /// Anything stable per account — a uid or an email. Picks the colour; the
  /// same person is the same colour on every device.
  final String? seed;

  /// A picture straight from the sign-in provider (Google), when there is one.
  /// Never an uploaded file. Falls back to the initials tile if it will not
  /// load, so a network failure degrades instead of leaving a gap.
  final String? photoUrl;

  final double size;

  /// Muted, evenly-spaced hues. Kept low-chroma on purpose: the avatar sits on
  /// the app's own surface and must not compete with the countdown itself.
  static const List<Color> _palette = [
    Color(0xFF6C8EBF),
    Color(0xFF8E7CC3),
    Color(0xFFC27BA0),
    Color(0xFFCC7A6B),
    Color(0xFFC9A227),
    Color(0xFF7FA650),
    Color(0xFF4FA3A5),
    Color(0xFF7C8BA1),
  ];

  static Color tintFor(String? seed) {
    if (seed == null || seed.isEmpty) return _palette.last;
    var hash = 0;
    for (final unit in seed.trim().toLowerCase().codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return _palette[hash % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: (photoUrl != null && photoUrl!.isNotEmpty)
            ? Image.network(
                photoUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initialsTile(colors),
              )
            : _initialsTile(colors),
      ),
    );
  }

  /// The launch avatar: a flat tint with the initials on top.
  Widget _initialsTile(AppPalette colors) {
    final tint = tintFor(seed ?? initials);
    return Container(
      width: size,
      height: size,
      color: Color.alphaBlend(tint.withValues(alpha: 0.22), colors.surface2),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w600,
          height: 1,
          color: tint,
        ),
      ),
    );
  }
}

/// A coloured pill for an invitation's state.
///
/// Green means answered yes, amber means still waiting, red means answered no.
/// The point is that the owner can tell at a glance who has replied without
/// reading a word: previously every row said `pending` in the same grey, so a
/// settled invitation looked identical to one nobody had opened.
class InviteStatusChip extends StatelessWidget {
  const InviteStatusChip(
      {super.key, required this.status, this.compact = false});

  final InviteStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (label, tint) = switch (status) {
      InviteStatus.accepted => ('Accepted', colors.success),
      InviteStatus.declined => ('Declined', colors.danger),
      InviteStatus.rejected => ('Removed', colors.subtle),
      InviteStatus.reopened => ('Reopened', colors.warning),
      InviteStatus.pending => ('Waiting', colors.warning),
    };

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 7 : 9, vertical: compact ? 2 : 3),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tint.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: compact ? 10.5 : 11.5,
          fontWeight: FontWeight.w600,
          color: tint,
        ),
      ),
    );
  }
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

/// An icon button that turns red while the pointer hovers it or a finger is
/// pressing it, then eases back to its resting colour.
///
/// Used for the back arrows, the circle invite action and the inbox icons: the
/// red is a clear "this will change or leave something" cue, and giving every
/// such control the same reaction is what makes the app feel deliberate rather
/// than only styling one arrow. The colour animates over [duration] so the
/// change reads as a response, not a flicker.
class DangerHoverIconButton extends StatefulWidget {
  const DangerHoverIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.iconSize = 20,
    this.duration = const Duration(milliseconds: 140),
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double iconSize;
  final Duration duration;

  @override
  State<DangerHoverIconButton> createState() => _DangerHoverIconButtonState();
}

class _DangerHoverIconButtonState extends State<DangerHoverIconButton> {
  bool _active = false;

  void _set(bool value) {
    if (_active == value) return;
    setState(() => _active = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = widget.onPressed != null;
    final resting = enabled ? colors.fg : colors.subtle;
    final color = enabled && _active ? colors.danger : resting;

    // `Listener` observes the pointer without competing for the tap, so the
    // IconButton below still receives its own press. MouseRegion covers hover
    // on desktop/web; Listener covers press-and-hold on touch.
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: enabled ? (_) => _set(true) : null,
      onExit: enabled ? (_) => _set(false) : null,
      child: Listener(
        onPointerDown: enabled ? (_) => _set(true) : null,
        onPointerUp: enabled ? (_) => _set(false) : null,
        onPointerCancel: enabled ? (_) => _set(false) : null,
        child: IconButton(
          tooltip: widget.tooltip,
          onPressed: widget.onPressed,
          icon: TweenAnimationBuilder<Color?>(
            duration: widget.duration,
            curve: Curves.easeOut,
            tween: ColorTween(end: color),
            builder: (context, animated, _) => Icon(
              widget.icon,
              size: widget.iconSize,
              color: animated ?? color,
            ),
          ),
        ),
      ),
    );
  }
}
