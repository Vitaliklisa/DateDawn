import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/countdown.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../providers/app_providers.dart';
import '../router.dart';
import '../services/event_repository.dart';
import '../widgets/arrival_celebration.dart';
import '../widgets/brand_kit.dart';
import '../widgets/countdown_face.dart';
import '../widgets/event_actions_sheet.dart';
import '../widgets/invitations_inbox.dart';

/// The countdown home: one hero countdown, then everything else below it.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(activeAuthStateProvider);
    final eventsAsync = ref.watch(eventsProvider);
    final featured = ref.watch(featuredEventProvider);
    final now = ref.watch(clockProvider).value ?? DateTime.now();

    if (auth.isLoading) return const _LoadingScaffold();

    final events = eventsAsync.value ?? const <CountdownEvent>[];
    final hasError = eventsAsync.hasError;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                color: context.colors.accent,
                backgroundColor: context.colors.surface,
                onRefresh: () async {
                  ref.invalidate(eventsProvider);
                  await Future<void>.delayed(const Duration(milliseconds: 400));
                },
                child: featured == null
                    ? _EmptyHome(hasError: hasError, error: eventsAsync.error)
                    : _HeroHome(
                        featured: featured,
                        others:
                            events.where((e) => e.id != featured.id).toList(),
                        now: now,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.colors.accent.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

/// Nothing to count down to yet — or nothing reachable.
class _EmptyHome extends ConsumerWidget {
  const _EmptyHome({required this.hasError, this.error});

  final bool hasError;
  final Object? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final user = ref.watch(currentUserProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      children: [
        const _TopBar(),
        const SizedBox(height: 12),
        const InvitationsInbox(),
        const SizedBox(height: 40),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.hourglass_empty_rounded,
              size: 26, color: colors.accent),
        ),
        const SizedBox(height: 22),
        Text('Name a day.', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 12),
        Text(
          'Pick a future moment — a wedding, a launch, a trip home. Date Dawn '
          'counts the years, months, days and hours left, then celebrates when '
          'it arrives.',
          style: TextStyle(fontSize: 15, height: 1.5, color: colors.muted),
        ),
        const SizedBox(height: 28),
        if (hasError)
          _ErrorCard(error: error)
        else if (user == null)
          _GuestCard(onSignIn: () => context.push(Routes.login)),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: () => context.push(Routes.newEvent),
          icon: const Icon(Icons.add_rounded, size: 20),
          // Signed out, this leads to the editor's sign-in prompt rather than a
          // form that cannot be saved — so the label says as much.
          label: Text(user == null ? 'Get started' : 'Create countdown'),
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final message = error is DataFailure
        ? (error as DataFailure).message
        : 'Could not reach your countdowns. Pull down to try again.';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.danger.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 18, color: colors.danger),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
                style: TextStyle(fontSize: 13, color: colors.muted)),
          ),
        ],
      ),
    );
  }
}

class _GuestCard extends StatelessWidget {
  const _GuestCard({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sync_rounded, size: 18, color: colors.accent),
              const SizedBox(width: 10),
              const Text('Keep them everywhere',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to sync your countdowns across phone, tablet and web — and to '
            'share them with the people counting down with you.',
            style: TextStyle(fontSize: 13, height: 1.45, color: colors.muted),
          ),
          const SizedBox(height: 14),
          OutlinedButton(onPressed: onSignIn, child: const Text('Sign in')),
        ],
      ),
    );
  }
}

/// The main state: a hero countdown plus the rest of the list.
class _HeroHome extends ConsumerWidget {
  const _HeroHome(
      {required this.featured, required this.others, required this.now});

  final CountdownEvent featured;
  final List<CountdownEvent> others;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final arrived = !featured.at.isAfter(now);

    return Stack(
      children: [
        // The soft accent glow behind the hero — the app's only decorative
        // flourish, so it stays subtle and never competes with the numerals.
        Positioned(
          top: -90,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colors.accent.withValues(alpha: 0.20),
                      colors.accent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 1000) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 120),
                children: [
                  const _TopBar(),
                  const SizedBox(height: 12),
                  const InvitationsInbox(),
                  const SizedBox(height: 8),
                  _FeaturedContent(
                    featured: featured,
                    arrived: arrived,
                    now: now,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => showEventActionsSheet(
                            context,
                            ref,
                            event: featured,
                            onDeleted: () => ref
                                .read(selectedEventIdProvider.notifier)
                                .set(null),
                          ),
                          icon: const Icon(Icons.more_horiz_rounded, size: 18),
                          label: const Text('Options'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => context
                              .push('${Routes.eventDetail}/${featured.id}'),
                          icon: const Icon(Icons.tune_rounded, size: 18),
                          label: const Text('Open'),
                        ),
                      ),
                    ],
                  ),
                  if (others.isNotEmpty) ...[
                    const SizedBox(height: 34),
                    Text(
                      'OTHER COUNTDOWNS',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 12),
                    for (final event in others) ...[
                      _EventRow(event: event, now: now),
                      const SizedBox(height: 8),
                    ],
                  ],
                ],
              );
            }

            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(32, 22, 32, 8),
                  child: _TopBar(),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 7,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(40, 38, 36, 120),
                          children: [
                            _FeaturedContent(
                              featured: featured,
                              arrived: arrived,
                              now: now,
                            ),
                            const SizedBox(height: 28),
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => showEventActionsSheet(
                                    context,
                                    ref,
                                    event: featured,
                                    onDeleted: () => ref
                                        .read(selectedEventIdProvider.notifier)
                                        .set(null),
                                  ),
                                  icon: const Icon(Icons.more_horiz_rounded,
                                      size: 18),
                                  label: const Text('Options'),
                                ),
                                const SizedBox(width: 12),
                                FilledButton.icon(
                                  onPressed: () => context.push(
                                      '${Routes.eventDetail}/${featured.id}'),
                                  icon:
                                      const Icon(Icons.tune_rounded, size: 18),
                                  label: const Text('Open countdown'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        margin: const EdgeInsets.only(top: 22, bottom: 22),
                        color: colors.border,
                      ),
                      Expanded(
                        flex: 4,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(28, 24, 32, 120),
                          children: [
                            const InvitationsInbox(),
                            if (others.isNotEmpty) ...[
                              const SizedBox(height: 32),
                              Text(
                                'OTHER COUNTDOWNS',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              const SizedBox(height: 12),
                              for (final event in others) ...[
                                _EventRow(event: event, now: now),
                                const SizedBox(height: 8),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              24,
              14,
              24,
              14 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: colors.canvas.withValues(alpha: 0.94),
              border: Border(
                  top: BorderSide(color: colors.border.withValues(alpha: 0.6))),
            ),
            child: FilledButton.icon(
              onPressed: () => context.push(Routes.newEvent),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('New countdown'),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeaturedContent extends StatelessWidget {
  const _FeaturedContent({
    required this.featured,
    required this.arrived,
    required this.now,
  });

  final CountdownEvent featured;
  final bool arrived;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              arrived
                  ? Icons.celebration_rounded
                  : Icons.hourglass_bottom_rounded,
              size: 14,
              color: arrived ? colors.accent : colors.subtle,
            ),
            const SizedBox(width: 8),
            Text(
              arrived ? 'ARRIVED' : 'COUNTING DOWN',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: arrived ? colors.accent : colors.subtle,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(featured.title, style: Theme.of(context).textTheme.headlineLarge),
        if (featured.description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            featured.description,
            style: TextStyle(fontSize: 14, height: 1.45, color: colors.muted),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.schedule_rounded, size: 14, color: colors.subtle),
            const SizedBox(width: 7),
            Text(
              formatMomentFull(featured.at),
              style: TextStyle(fontSize: 13, color: colors.subtle),
            ),
          ],
        ),
        const SizedBox(height: 26),
        if (arrived)
          ArrivalCelebration(
            title: featured.title,
            description: featured.description,
          )
        else
          CountdownFace(target: featured.at, now: now),
      ],
    );
  }
}

/// A compact row in the "other countdowns" list.
class _EventRow extends ConsumerWidget {
  const _EventRow({required this.event, required this.now});

  final CountdownEvent event;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final past = event.isPast;
    final remaining = remainingUntil(event.at, now);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          ref.read(selectedEventIdProvider.notifier).set(event.id);
        },
        onLongPress: () => showEventActionsSheet(context, ref, event: event),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      past
                          ? formatMomentShort(event.at)
                          : '${describeRemaining(remaining, compact: true)} · ${formatMomentShort(event.at)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: colors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              StatusChip(isPast: past),
            ],
          ),
        ),
      ),
    );
  }
}

/// The persistent header: wordmark on the left, account and inboxes on the
/// right.
class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final pendingInvites = ref.watch(pendingInviteCountProvider);
    final unreadResponses = ref.watch(unreadResponseCountProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const BrandMark(),
        Row(
          children: [
            if (user != null) ...[
              _BadgedIconButton(
                tooltip: 'Circles',
                icon: Icons.groups_outlined,
                onPressed: () => context.push(Routes.circles),
              ),
              _BadgedIconButton(
                tooltip: 'Invitations',
                icon: Icons.mail_outline_rounded,
                count: pendingInvites,
                onPressed: () => context.push(Routes.invitations),
              ),
              _BadgedIconButton(
                tooltip: 'Notifications',
                icon: Icons.notifications_none_rounded,
                count: unreadResponses,
                onPressed: () => context.push(Routes.notifications),
              ),
            ],
            IconButton(
              tooltip: 'Settings',
              onPressed: () => context.push(Routes.settings),
              icon: const Icon(Icons.settings_outlined, size: 20),
            ),
            if (user != null)
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: GestureDetector(
                  onTap: () => context.push(Routes.settings),
                  child: UserAvatar(
                      initials: user.initials, photoUrl: user.photoUrl),
                ),
              )
            else
              TextButton(
                onPressed: () => context.push(Routes.login),
                child: const Text('Sign in'),
              ),
          ],
        ),
      ],
    );
  }
}

/// An icon button with an optional count badge.
///
/// The badge is how you notice an invitation arrived without opening anything —
/// the number only appears when it is non-zero, so the bar stays quiet when
/// there is nothing waiting.
class _BadgedIconButton extends StatelessWidget {
  const _BadgedIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.count = 0,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16),
              decoration: BoxDecoration(
                color: colors.accent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                count > 9 ? '9+' : '$count',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: colors.accentFg,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
