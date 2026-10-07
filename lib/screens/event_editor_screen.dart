import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/circles.dart';
import '../core/countdown.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../providers/app_providers.dart';
import '../router.dart';
import '../services/event_repository.dart';
import '../widgets/brand_kit.dart';

/// Create or edit one countdown.
///
/// Everything a new countdown needs is on this screen: a title, an optional
/// note, the moment itself, and — once it exists — the people it is shared
/// with. The live preview under the date pickers shows exactly what the
/// countdown will read, so the date can be adjusted without saving first.
class EventEditorScreen extends ConsumerStatefulWidget {
  const EventEditorScreen({super.key, this.event});

  /// `null` creates; a value edits.
  final CountdownEvent? event;

  @override
  ConsumerState<EventEditorScreen> createState() => _EventEditorScreenState();
}

class _EventEditorScreenState extends ConsumerState<EventEditorScreen> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late DateTime _at;
  String? _error;
  bool _busy = false;
  bool _confirmDelete = false;

  /// Circles this countdown will be shared with. Only used when creating: an
  /// existing countdown manages its circles from the detail screen, where the
  /// current sharing is visible.
  final Set<String> _selectedCircleIds = {};

  /// Quick jumps for the dates people actually pick — days to years ahead.
  static const _presets = <(String, int)>[
    ('+1 week', 7),
    ('+1 month', 30),
    ('+1 year', 365),
    ('+5 years', 1826),
  ];

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _title = TextEditingController(text: event?.title ?? '');
    _description = TextEditingController(text: event?.description ?? '');
    // Default to 30 days out at 6pm — far enough ahead to feel like a plan,
    // close enough to be real.
    final thirtyDaysOut = DateTime.now().add(const Duration(days: 30));
    _at = event?.at ??
        DateTime(
            thirtyDaysOut.year, thirtyDaysOut.month, thirtyDaysOut.day, 18);

    // Pre-tick whatever this countdown is already shared with, so editing does
    // not silently drop a circle.
    if (event != null) _selectedCircleIds.addAll(event.sharedWithCircleIds);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _at.isAfter(DateTime.now())
          ? _at
          : DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 60)),
      builder: (context, child) => Theme(
        data: Theme.of(context),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      _at =
          DateTime(picked.year, picked.month, picked.day, _at.hour, _at.minute);
      _error = null;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_at),
    );
    if (picked == null) return;
    setState(() {
      _at = DateTime(_at.year, _at.month, _at.day, picked.hour, picked.minute);
      _error = null;
    });
  }

  void _applyPreset(int days) {
    final next = DateTime.now().add(Duration(days: days));
    setState(() {
      _at = DateTime(next.year, next.month, next.day, _at.hour, _at.minute);
      _error = null;
    });
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Give this countdown a title.');
      return;
    }
    if (!_at.isAfter(DateTime.now())) {
      setState(() => _error = 'Pick a moment still ahead of you.');
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) {
      setState(() => _error = 'Sign in to save countdowns.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final repository = ref.read(eventRepositoryProvider);
    final existing = widget.event;

    try {
      CountdownEvent? created;
      if (existing == null) {
        created = await repository.createEvent(
          userId: user.id,
          email: user.email,
          title: title,
          description: _description.text,
          at: _at,
          displayName: user.displayName,
          photoUrl: user.photoUrl,
          // Circles ticked in the composer: a couple circle shares silently,
          // any other circle's members get an invitation to accept.
          autoShareCircleIds: _selectedCircleIds.toList(),
          circles: ref.read(circlesProvider).value ?? const [],
        );
      } else {
        await repository.updateEvent(
          event: existing,
          userId: user.id,
          title: title,
          description: _description.text,
          at: _at,
        );
        // Sharing is a separate write: `updateEvent` deliberately touches only
        // the fields the rules allow in one diff, and circle membership is its
        // own permission decision.
        await repository.setEventCircles(
          event: existing,
          userId: user.id,
          circleIds: _selectedCircleIds.toList(),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                existing == null ? 'Countdown created.' : 'Changes saved.')),
      );
      if (created != null) {
        // A brand-new countdown is pinned as the hero and the creator is taken
        // straight back to the home screen, where the thing they just made is
        // already counting down. `go` (rather than `pop`) resets the stack, so
        // Back never bounces into the now-stale composer and the freshly
        // created countdown is visible without an extra tap.
        ref.read(selectedEventIdProvider.notifier).set(created.id);
        context.go(Routes.home);
      } else {
        context.pop();
      }
    } on DataFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Could not save: $e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final existing = widget.event;
    final user = ref.read(currentUserProvider);
    if (existing == null || user == null) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(eventRepositoryProvider)
          .deleteEvent(event: existing, userId: user.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Countdown deleted.')),
      );
      context.pop();
    } on DataFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final editing = widget.event != null;
    final user = ref.watch(currentUserProvider);
    final canEdit = widget.event?.canEdit(user?.id) ?? true;

    // Every write path needs an account: a countdown is owned by its creator in
    // Firestore, and security rules require a uid. Gate here rather than letting
    // someone fill in a form they cannot save.
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          leading: DangerHoverIconButton(
            icon: Icons.arrow_back_rounded,
            onPressed: () => context.pop(),
          ),
          title: Text(editing ? 'Edit countdown' : 'New countdown'),
        ),
        body: _SignInPrompt(onSignIn: () => context.push(Routes.login)),
      );
    }
    return Scaffold(
      appBar: AppBar(
        leading: DangerHoverIconButton(
          icon: Icons.arrow_back_rounded,
          onPressed: () => context.pop(),
        ),
        title: Text(editing ? 'Edit countdown' : 'New countdown'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            const _Label('Title'),
            TextField(
              controller: _title,
              enabled: canEdit,
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Wedding, launch, reunion',
                counterText: '',
              ),
            ),
            const SizedBox(height: 18),
            const _Label('Description'),
            TextField(
              controller: _description,
              enabled: canEdit,
              maxLines: 3,
              maxLength: 280,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'A short note about the day',
                counterStyle: TextStyle(fontSize: 11),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _Label('When'),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final (label, days) in _presets)
                      _PresetChip(
                        label: label,
                        onTap: canEdit ? () => _applyPreset(days) : null,
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MomentTile(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: DateFormat('EEE, MMM d, yyyy').format(_at),
                    onTap: canEdit ? _pickDate : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MomentTile(
                    icon: Icons.schedule_rounded,
                    label: 'Time',
                    value: DateFormat('h:mm a').format(_at),
                    onTap: canEdit ? _pickTime : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _PreviewStrip(at: _at),
            const SizedBox(height: 22),
            _CirclePicker(
              selected: _selectedCircleIds,
              onToggle: (circleId, on) => setState(() {
                if (on) {
                  _selectedCircleIds.add(circleId);
                } else {
                  _selectedCircleIds.remove(circleId);
                }
              }),
            ),
            if (editing) ...[
              const SizedBox(height: 28),
              Divider(color: colors.border),
              const SizedBox(height: 20),
              _Collaborators(event: widget.event!),
            ],
            if (_error != null) ...[
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 17, color: colors.danger),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(_error!,
                        style: TextStyle(fontSize: 13.5, color: colors.danger)),
                  ),
                ],
              ),
            ],
            if (_confirmDelete) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delete this countdown? The countdown cannot be undone.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                setState(() => _confirmDelete = false),
                            child: const Text('Keep'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                                backgroundColor: colors.danger),
                            onPressed: _busy ? null : _delete,
                            child: const Text('Delete'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 26),
            Row(
              children: [
                if (editing &&
                    (widget.event
                            ?.canManage(ref.watch(currentUserProvider)?.id) ??
                        false))
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() => _confirmDelete = true),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(96, 50),
                        foregroundColor: colors.muted,
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: (_busy || !canEdit) ? null : _save,
                    icon: const Icon(Icons.check_rounded, size: 20),
                    label: Text(editing ? 'Save changes' : 'Create countdown'),
                  ),
                ),
              ],
            ),
            if (!canEdit) ...[
              const SizedBox(height: 14),
              Text(
                'You can view this countdown but not change it.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: colors.subtle),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: context.colors.muted,
          ),
        ),
      );
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: colors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: onTap == null ? colors.subtle : colors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _MomentTile extends StatelessWidget {
  const _MomentTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 13, color: colors.subtle),
                  const SizedBox(width: 6),
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.5,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                      color: colors.subtle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Live preview of what this date actually counts down to.
class _PreviewStrip extends ConsumerWidget {
  const _PreviewStrip({required this.at});

  final DateTime at;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final remaining = remainingUntil(at, now);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            remaining.isPast
                ? Icons.warning_amber_rounded
                : Icons.hourglass_bottom_rounded,
            size: 16,
            color: remaining.isPast ? colors.danger : colors.accent,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              remaining.isPast
                  ? 'Choose a future date to see the countdown.'
                  : 'Counting down ${describeRemaining(remaining)}',
              style: TextStyle(fontSize: 13, color: colors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

/// Invite people, and see who is already on the countdown.
class _Collaborators extends ConsumerStatefulWidget {
  const _Collaborators({required this.event});

  final CountdownEvent event;

  @override
  ConsumerState<_Collaborators> createState() => _CollaboratorsState();
}

class _CollaboratorsState extends ConsumerState<_Collaborators> {
  final _email = TextEditingController();
  ParticipantRole _role = ParticipantRole.viewer;
  bool _inviting = false;

  /// Set when an invitation is refused — most visibly when someone tries to
  /// invite their own address. Rendered as red text under the field.
  String? _inviteError;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final email = _email.text.trim();
    if (email.isEmpty) return;

    setState(() {
      _inviting = true;
      _inviteError = null;
    });
    try {
      final failure = await runAction(
        context,
        () => ref.read(eventRepositoryProvider).inviteByEmail(
              event: widget.event,
              inviterId: user.id,
              inviterEmail: user.email,
              email: email,
              role: _role,
            ),
        successMessage: 'Invitation sent to $email.',
      );
      if (failure == null) {
        _email.clear();
      } else if (mounted) {
        setState(() => _inviteError = failure);
      }
    } finally {
      if (mounted) setState(() => _inviting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final participants =
        ref.watch(participantsProvider(widget.event.id)).value ??
            widget.event.participants;
    final canManage =
        widget.event.canManage(ref.watch(currentUserProvider)?.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.people_alt_outlined, size: 18, color: colors.muted),
            const SizedBox(width: 9),
            const Text(
              'Collaborators',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          canManage
              ? 'Anyone you invite can follow this countdown on their own devices.'
              : 'People following this countdown.',
          style: TextStyle(fontSize: 12.5, color: colors.subtle),
        ),
        if (canManage) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration:
                      const InputDecoration(hintText: 'name@example.com'),
                ),
              ),
              const SizedBox(width: 10),
              _RoleDropdown(
                value: _role,
                onChanged: (role) => setState(() => _role = role),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _inviting ? null : _invite,
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 19),
              ),
            ],
          ),
          if (_inviteError != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 16, color: colors.danger),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _inviteError!,
                    style: TextStyle(fontSize: 13, color: colors.danger),
                  ),
                ),
              ],
            ),
          ],
        ],
        const SizedBox(height: 16),
        if (participants.isEmpty)
          Text(
            'No one else yet.',
            style: TextStyle(fontSize: 13, color: colors.subtle),
          )
        else
          for (final participant in participants)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    UserAvatar(
                      initials: participant.initials,
                      seed: participant.userId,
                      photoUrl: participant.photoUrl,
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            participant.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_roleLabel(participant.role)} · ${participant.inviteStatus.name}',
                            style:
                                TextStyle(fontSize: 11.5, color: colors.subtle),
                          ),
                        ],
                      ),
                    ),
                    if (canManage &&
                        participant.userId != widget.event.createdBy &&
                        participant.inviteStatus != InviteStatus.accepted)
                      IconButton(
                        tooltip: 'Remove',
                        iconSize: 18,
                        color: colors.subtle,
                        onPressed: () => _remove(participant),
                        icon: const Icon(Icons.close_rounded),
                      ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Future<void> _remove(Participant participant) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    // Removing someone is a role update to `viewer` plus a rejected invite —
    // the row stays so their history is not silently rewritten.
    await runAction(
      context,
      () => ref.read(eventRepositoryProvider).updateParticipantRole(
            eventId: widget.event.id,
            actorId: user.id,
            participant: participant,
            role: ParticipantRole.viewer,
          ),
      successMessage: '${participant.email} can now only view.',
    );
  }

  String _roleLabel(ParticipantRole role) => switch (role) {
        ParticipantRole.admin => 'Admin',
        ParticipantRole.editor => 'Editor',
        ParticipantRole.viewer => 'Viewer',
      };
}

class _RoleDropdown extends StatelessWidget {
  const _RoleDropdown({required this.value, required this.onChanged});

  final ParticipantRole value;
  final ValueChanged<ParticipantRole> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ParticipantRole>(
          value: value,
          isDense: true,
          dropdownColor: colors.surface2,
          borderRadius: BorderRadius.circular(10),
          style: TextStyle(fontSize: 13.5, color: colors.fg),
          icon: Icon(Icons.expand_more_rounded, size: 18, color: colors.subtle),
          onChanged: (role) {
            if (role != null) onChanged(role);
          },
          items: const [
            DropdownMenuItem(
                value: ParticipantRole.viewer, child: Text('Viewer')),
            DropdownMenuItem(
                value: ParticipantRole.editor, child: Text('Editor')),
            DropdownMenuItem(
                value: ParticipantRole.admin, child: Text('Admin')),
          ],
        ),
      ),
    );
  }
}

/// Shown when someone reaches the editor without an account.
///
/// The app deliberately lets a visitor browse and try the countdown, but a
/// countdown is owned by its creator in Firestore, so saving needs a uid.
class _SignInPrompt extends StatelessWidget {
  const _SignInPrompt({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.lock_outline_rounded,
                    size: 24, color: colors.accent),
              ),
              const SizedBox(height: 22),
              Text(
                'Sign in to save it',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Countdowns live in your account, so they follow you to every '
                'device and can be shared with other people.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 14, height: 1.5, color: colors.muted),
              ),
              const SizedBox(height: 26),
              FilledButton(onPressed: onSignIn, child: const Text('Sign in')),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ticks the circles this countdown is shared with.
///
/// Renders nothing when the user has no circles — an empty picker would just be
/// noise on the screen of someone who has not set any up yet.
class _CirclePicker extends ConsumerWidget {
  const _CirclePicker({required this.selected, required this.onToggle});

  final Set<String> selected;
  final void Function(String circleId, bool selected) onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final circles = ref.watch(circlesProvider).value ?? const <Circle>[];
    if (circles.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.groups_outlined, size: 16, color: colors.muted),
            const SizedBox(width: 9),
            const Text(
              'Share with',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'A couple circle shares instantly. Other circles get an invitation.',
          style: TextStyle(fontSize: 12, color: colors.subtle),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final circle in circles)
              GestureDetector(
                onTap: () => onToggle(circle.id, !selected.contains(circle.id)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: selected.contains(circle.id)
                        ? colors.accentSoft
                        : colors.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected.contains(circle.id)
                          ? colors.accent
                          : colors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        circle.emoji ?? (circle.isCouple ? '💞' : '👥'),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        circle.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: selected.contains(circle.id)
                              ? colors.accent
                              : colors.fg,
                        ),
                      ),
                      if (selected.contains(circle.id)) ...[
                        const SizedBox(width: 7),
                        Icon(Icons.check_rounded,
                            size: 14, color: colors.accent),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
