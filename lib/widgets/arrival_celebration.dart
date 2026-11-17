import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../l10n/app_localizations_context.dart';

/// The moment a countdown hits zero.
///
/// A confetti burst, an expanding ring, an animated check and the event's own
/// title as the punchline — the native counterpart of the web app's arrival
/// celebration. Confetti is a real widget layer here rather than CSS spans, so
/// it rains over the whole screen exactly as it does on the web.
class ArrivalCelebration extends StatefulWidget {
  const ArrivalCelebration({
    super.key,
    required this.title,
    this.description,
  });

  final String title;
  final String? description;

  @override
  State<ArrivalCelebration> createState() => _ArrivalCelebrationState();
}

class _ArrivalCelebrationState extends State<ArrivalCelebration>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confetti = ConfettiController(
    duration: const Duration(seconds: 6),
  );
  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void initState() {
    super.initState();
    // A short delay lets the card mount before the burst, so the first frame of
    // confetti is not clipped by the route transition.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _confetti.play();
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _ring,
                      builder: (context, _) {
                        final t = Curves.easeOut.transform(_ring.value);
                        return Opacity(
                          opacity: (1 - t).clamp(0.0, 1.0),
                          child: Container(
                            width: 56 + t * 20,
                            height: 56 + t * 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: colors.accent, width: 2),
                            ),
                          ),
                        );
                      },
                    ),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: colors.accentSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_rounded,
                          size: 32, color: colors.accent),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.dayHasCome,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: colors.accent),
              ),
              const SizedBox(height: 10),
              Text(
                widget.description?.isNotEmpty == true
                    ? l10n.eventArrivedWithDescription(
                        widget.title,
                        widget.description!,
                      )
                    : l10n.eventArrivedTitleOnly(widget.title),
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 14, height: 1.5, color: colors.muted),
              ),
            ],
          ),
        ),
        // Aligned to the top of the stack and allowed to overflow: confetti
        // confined to the card would be clipped out of sight before it lands.
        ConfettiWidget(
          confettiController: _confetti,
          blastDirectionality: BlastDirectionality.explosive,
          emissionFrequency: 0.02,
          numberOfParticles: 14,
          gravity: 0.22,
          shouldLoop: true,
          maxBlastForce: 28,
          minBlastForce: 8,
          blastDirection: math.pi / 2,
          colors: AppColors.party,
          createParticlePath: _shapeFor,
        ),
      ],
    );
  }

  /// Mixes bars, dots and chips so the burst reads as confetti rather than a
  /// uniform spray of rectangles.
  Path _shapeFor(Size size) {
    final index = (size.width.hashCode % 3).abs();
    final path = Path();
    if (index == 0) {
      path.addOval(Rect.fromCircle(center: Offset.zero, radius: 4));
    } else if (index == 1) {
      path.addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-3, -5, 6, 10),
        const Radius.circular(1.5),
      ));
    } else {
      path.addRect(const Rect.fromLTWH(-4, -3, 8, 6));
    }
    return path;
  }
}
