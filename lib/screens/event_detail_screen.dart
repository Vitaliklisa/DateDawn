import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/countdown.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../providers/app_providers.dart';
import '../widgets/arrival_celebration.dart';
import '../widgets/brand_kit.dart';
import '../widgets/countdown_face.dart';
import '../widgets/event_actions_sheet.dart';
import '../widgets/share_event.dart';

/// One countdown, full screen: the face, the notes, the people, the actions.
class EventDetailScreen extends ConsumerStatefulWidget {
  const EventDetailScreen({
    super.key,
    required this.eventId,
    this.startInEditMode = false,
  });

  final String eventId;

  /// Set by `/event/:id?edit=1` — used when the hero's edit action is tapped.
  final bool startInEditMode;

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.startInEditMode) {
      // The editor owns saving; only routes to it.
      WidgetsBinding.instance.addPostFrameCallback((_) => _openEditor());
    }
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _openEditor() {
    final event = _find();
    if (event == null || !mounted) return;
    context.push('/event/${event.id}/edit', extra: event);
  }

  CountdownEvent? _find() {
    final events = ref.read(eventsProvider).value ?? const <CountdownEvent>[];
    for (final event in events) {
      if (event.id == widget.eventId) return event;
    }
    return null;
  }

  Future<void> _addNote(CountdownEvent event) async {
    final user = ref.read(currentUserProvider);
    if (user == null || _note.text.trim().isEmpty) return;
    final text = _note.text;
    _note.clear();
    await runAction(
      context,
      () => ref
          .read(eventRepositoryProvider)
          .addNote(eventId: event.id, userId: user.id, text: text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final eventsAsync = ref.watch(eventsProvider);
    final event = _find();
    final now = ref.watch(clockProvider).value ?? DateTime.now();

    if (eventsAsync.isLoading && event == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }

    if (event == null) {
      return Scaffold(
        appBar: AppBar(
          leading: HoverTintIconButton(
            icon: Icons.arrow_back_rounded,
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded, size: 34, color: colors.subtle),
                const SizedBox(height: 16),
                const Text(
                  'This countdown is no longer available.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final user = ref.watch(currentUserProvider);
    final arrived = !event.at.isAfter(now);
    final participants =
        ref.watch(participantsProvider(event.id)).value ?? event.participants;
    final notes = ref.watch(notesProvider(event.id)).value ?? event.notes;
    final others = participants.where((p) => p.userId != user?.id).toList();

    return Scaffold(
      appBar: AppBar(
        leading: HoverTintIconButton(
          icon: Icons.arrow_back_rounded,
          onPressed: () => context.pop(),
        ),
        title: const BrandMark(),
        actions: [
          IconButton(
            tooltip: 'Share',
            onPressed: () => shareEvent(context, event),
            icon: const Icon(Icons.ios_share_rounded, size: 20),
          ),
          IconButton(
            tooltip: 'Options',
            onPressed: () => showEventActionsSheet(context, ref, event: event),
            icon: const Icon(Icons.more_horiz_rounded, size: 22),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
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
          Text(event.title, style: Theme.of(context).textTheme.headlineMedium),
          if (event.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              event.description,
              style: TextStyle(fontSize: 14, height: 1.45, color: colors.muted),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 14, color: colors.subtle),
              const SizedBox(width: 7),
              Text(
                formatMomentFull(event.at),
                style: TextStyle(fontSize: 13, color: colors.subtle),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (arrived)
            ArrivalCelebration(
                title: event.title, description: event.description)
          else
            CountdownFace(target: event.at, now: now),
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      context.push('/event/${event.id}/edit', extra: event),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label:
                      Text(event.canEdit(user?.id) ? 'Edit' : 'View details'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => shareEvent(context, event),
                  icon: const Icon(Icons.ios_share_rounded, size: 18),
                  label: const Text('Share'),
                ),
              ),
            ],
          ),
          if (others.isNotEmpty) ...[
            const SizedBox(height: 32),
            Text('SHARED WITH', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final person in others)
                  Container(
                    padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        UserAvatar(
                          initials: person.initials,
                          seed: person.userId,
                          photoUrl: person.photoUrl,
                          size: 26,
                        ),
                        const SizedBox(width: 9),
                        Text(
                          person.displayName ?? person.email,
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 32),
          Text('NOTES', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 12),
          if (notes.isEmpty)
            Text(
              'Nothing yet. Leave a thought for everyone counting down with you.',
              style: TextStyle(fontSize: 13, color: colors.subtle),
            )
          else
            for (final note in notes)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(note.text,
                          style: const TextStyle(fontSize: 13.5, height: 1.4)),
                      const SizedBox(height: 6),
                      Text(
                        formatMomentShort(note.createdAt),
                        style: TextStyle(fontSize: 11, color: colors.subtle),
                      ),
                    ],
                  ),
                ),
              ),
          if (user != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _note,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(hintText: 'Add a note'),
                    onSubmitted: (_) => _addNote(event),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: () => _addNote(event),
                  icon: const Icon(Icons.send_rounded, size: 18),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
