import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/circles.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../providers/app_providers.dart';

/// One inbox for everything waiting on an answer: countdown invitations and
/// circle invitations.
///
/// They are different objects with different consequences — a countdown invite
/// adds you to one event, a circle invite adds you to a standing group — so
/// each card says plainly which it is before you tap Accept.
class InvitationsInbox extends ConsumerWidget {
  const InvitationsInbox({super.key, this.showWhenEmpty = false});

  /// On the invitations screen an empty inbox still needs to say so; on the
  /// home screen it should take no space at all.
  final bool showWhenEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final eventInvites =
        ref.watch(invitationsProvider).value ?? const <Invitation>[];
    final circleInvites = ref.watch(circleInvitationsProvider).value ??
        const <CircleInvitation>[];

    if (eventInvites.isEmpty && circleInvites.isEmpty) {
      return showWhenEmpty ? const _EmptyInbox() : const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The keys are load-bearing, not decoration.
        //
        // These cards are emitted from two separate loops into one `Column`, so
        // without a key Flutter matches them to element slots **by position**.
        // When the first list changes length — exactly what happens the moment a
        // circle invitation is answered — every event card shifts position and
        // is rebuilt as a brand-new widget, discarding its `_busy` flag and the
        // in-flight guard with it. That is what let one Accept/Decline send a
        // stream of requests: each rebuild re-entered the handler on an
        // invitation that had already been settled. A stable key per invitation
        // makes each card keep its own state, so answering one cannot disturb
        // the next.
        for (final invite in circleInvites) ...[
          _CircleInviteCard(
              key: ValueKey('circle-${invite.id}'), invite: invite),
          const SizedBox(height: 10),
        ],
        for (final invite in eventInvites) ...[
          _EventInviteCard(key: ValueKey('event-${invite.id}'), invite: invite),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        const SizedBox(height: 40),
        Icon(Icons.mark_email_read_outlined, size: 30, color: colors.subtle),
        const SizedBox(height: 16),
        Text(
          'Nothing waiting',
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, color: colors.fg),
        ),
        const SizedBox(height: 8),
        Text(
          'Invitations people send you will appear here. Until you answer one, '
          'nothing is shared with you.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, height: 1.5, color: colors.muted),
        ),
      ],
    );
  }
}

/// Shared shell: a titled card with Accept / Decline.
class _InviteShell extends StatelessWidget {
  const _InviteShell({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.onAccept,
    required this.onDecline,
    required this.acceptLabel,
    this.busy = false,
  });

  final String eyebrow;
  final String title;
  final String body;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final String acceptLabel;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mail_outline_rounded, size: 16, color: colors.accent),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  eyebrow.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.3,
                    color: colors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          Text(body,
              style:
                  TextStyle(fontSize: 13, height: 1.45, color: colors.muted)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(42),
                    // A guest cannot join anything: there is no uid to add.
                    backgroundColor: busy ? colors.borderStrong : colors.accent,
                  ),
                  onPressed: busy ? null : onAccept,
                  child: busy
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.accentFg,
                          ),
                        )
                      : Text(acceptLabel),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(42)),
                  onPressed: busy ? null : onDecline,
                  child: const Text('Decline'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EventInviteCard extends ConsumerStatefulWidget {
  const _EventInviteCard({super.key, required this.invite});

  final Invitation invite;

  @override
  ConsumerState<_EventInviteCard> createState() => _EventInviteCardState();
}

class _EventInviteCardState extends ConsumerState<_EventInviteCard> {
  bool _busy = false;

  /// True from the first tap until the widget is disposed or the invite is
  /// settled. Unlike `_busy` this is *not* visual state — it is the re-entry
  /// lock that stops a second tap (or a rebuild that re-enters the handler)
  /// from writing again while the first write is still in flight.
  bool _submitted = false;

  Future<void> _accept() async {
    if (_submitted) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _busy = true);
    final confirmed = await _confirm(
      context,
      title: 'Join “${widget.invite.eventTitle}”?',
      body:
          'It will appear in your list and you will get its countdown on this device.',
      action: 'Join',
    );
    if (!confirmed) {
      if (mounted) setState(() => _busy = false);
      return;
    }
    // `mounted` again after the dialog's own await: the user may have dismissed
    // the sheet while the confirm was open.
    if (!mounted) return;
    _submitted = true;
    await runAction(
      context,
      () => ref.read(eventRepositoryProvider).acceptInvitation(
            invitation: widget.invite,
            userId: user.id,
            email: user.email,
            displayName: user.displayName,
            photoUrl: user.photoUrl,
          ),
      successMessage: 'You joined “${widget.invite.eventTitle}”.',
    );
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _decline() async {
    if (_submitted) return;
    final user = ref.read(currentUserProvider);
    setState(() => _busy = true);
    _submitted = true;
    await runAction(
      context,
      () => ref.read(eventRepositoryProvider).rejectInvitation(
            widget.invite,
            responderEmail: user?.email,
            responderName: user?.displayName,
            userId: user?.id,
          ),
      successMessage: 'Invitation declined.',
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final invite = widget.invite;
    return _InviteShell(
      eyebrow: 'Countdown invitation',
      title:
          invite.eventTitle.isEmpty ? 'A countdown' : '“${invite.eventTitle}”',
      body:
          'You have been invited to follow this countdown. Accepting adds it to '
          'your list as ${_roleLabel(invite.role).toLowerCase()}.',
      acceptLabel: 'Accept',
      busy: _busy,
      onAccept: _accept,
      onDecline: _decline,
    );
  }
}

class _CircleInviteCard extends ConsumerStatefulWidget {
  const _CircleInviteCard({super.key, required this.invite});

  final CircleInvitation invite;

  @override
  ConsumerState<_CircleInviteCard> createState() => _CircleInviteCardState();
}

class _CircleInviteCardState extends ConsumerState<_CircleInviteCard> {
  bool _busy = false;

  /// See `_EventInviteCardState._submitted` — the re-entry lock that stops a
  /// settled invitation from being answered twice.
  bool _submitted = false;

  Future<void> _accept() async {
    if (_submitted) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _busy = true);
    _submitted = true;
    await runAction(
      context,
      () => ref.read(eventRepositoryProvider).acceptCircleInvitation(
            invitation: widget.invite,
            userId: user.id,
            email: user.email,
            displayName: user.displayName,
            photoUrl: user.photoUrl,
          ),
      successMessage: 'You joined “${widget.invite.circleName}”.',
    );
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _decline() async {
    if (_submitted) return;
    setState(() => _busy = true);
    _submitted = true;
    await runAction(
      context,
      () => ref
          .read(eventRepositoryProvider)
          .rejectCircleInvitation(widget.invite),
      successMessage: 'Invitation declined.',
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final invite = widget.invite;
    final invitedBy = invite.invitedByName?.trim();
    final from =
        (invitedBy != null && invitedBy.isNotEmpty) ? invitedBy : 'Someone';

    return _InviteShell(
      eyebrow: invite.isCouple ? 'Partner invitation' : 'Circle invitation',
      title: invite.isCouple
          ? "Become $from's partner"
          : "$from invited you to “${invite.circleName}”",
      body: invite.isCouple
          ? 'Once you accept, anything either of you adds to “${invite.circleName}” '
              'is shared with the other automatically — no invitations to accept each time.'
          : 'Joining “${invite.circleName}” means the countdowns they share with this '
              'circle will show up in your list.',
      acceptLabel: invite.isCouple ? 'Become partners' : 'Join circle',
      busy: _busy,
      onAccept: _accept,
      onDecline: _decline,
    );
  }
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Not now'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(88, 42)),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(action),
        ),
      ],
    ),
  );
  return result ?? false;
}

String _roleLabel(ParticipantRole role) => switch (role) {
      ParticipantRole.admin => 'Admin',
      ParticipantRole.editor => 'Editor',
      ParticipantRole.viewer => 'Viewer',
    };
