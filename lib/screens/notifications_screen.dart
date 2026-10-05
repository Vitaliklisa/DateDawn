import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/circles.dart';
import '../core/theme.dart';
import '../core/notifications.dart';
import '../providers/app_providers.dart';

/// The Supabase realtime inbox alongside the existing invitation-response log.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final responses = ref.watch(responsesProvider);
    final notifications = ref.watch(appNotificationsProvider);
    final hasUnread = (responses.value ?? const []).any((r) => !r.read) ||
        (notifications.value ?? const []).any((n) => !n.isRead);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (user != null && hasUnread)
            TextButton(
              onPressed: () => runAction(
                context,
                () async {
                  final unreadResponses = (responses.value ?? const [])
                      .where((response) => !response.read);
                  await Future.wait([
                    for (final response in unreadResponses)
                      ref
                          .read(eventRepositoryProvider)
                          .markResponseRead(response.id),
                    ref
                        .read(supabaseServiceProvider)
                        .markAllNotificationsRead(user.id),
                  ]);
                },
                successMessage: 'Marked all read.',
              ),
              child:
                  const Text('Mark all read', style: TextStyle(fontSize: 13)),
            ),
        ],
      ),
      body: user == null
          ? const _Empty(
              icon: Icons.notifications_none_rounded,
              title: 'Sign in first',
              body: 'Notifications are tied to your account.',
            )
          : _InboxList(
              responses: responses,
              notifications: notifications,
              onResponseTap: (response) {
                if (!response.read) {
                  unawaited(runAction(
                    context,
                    () => ref
                        .read(eventRepositoryProvider)
                        .markResponseRead(response.id),
                  ));
                }
                if (response.eventId.isNotEmpty) {
                  context.push('/event/${response.eventId}');
                }
              },
              onNotificationTap: (notification) {
                if (!notification.isRead) {
                  unawaited(runAction(
                    context,
                    () => ref
                        .read(supabaseServiceProvider)
                        .markNotificationRead(notification.id),
                  ));
                }
              },
            ),
    );
  }
}

class _InboxList extends StatelessWidget {
  const _InboxList({
    required this.responses,
    required this.notifications,
    required this.onResponseTap,
    required this.onNotificationTap,
  });

  final AsyncValue<List<InvitationResponse>> responses;
  final AsyncValue<List<AppNotification>> notifications;
  final ValueChanged<InvitationResponse> onResponseTap;
  final ValueChanged<AppNotification> onNotificationTap;

  @override
  Widget build(BuildContext context) {
    final responseItems = responses.value ?? const <InvitationResponse>[];
    final notificationItems = notifications.value ?? const <AppNotification>[];

    if (responseItems.isEmpty &&
        notificationItems.isEmpty &&
        (responses.isLoading || notifications.isLoading)) {
      return const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (responseItems.isEmpty && notificationItems.isEmpty) {
      if (responses.hasError || notifications.hasError) {
        return const _Empty(
          icon: Icons.cloud_off_rounded,
          title: 'Could not load',
          body: 'Check your connection and try again.',
        );
      }
      return const _Empty(
        icon: Icons.notifications_none_rounded,
        title: 'Nothing yet',
        body:
            'When something happens with your countdowns or invitations, it will show up here.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      children: [
        if (notifications.hasError)
          const _LoadWarning(
              message: 'Live notifications could not be loaded.'),
        if (notificationItems.isNotEmpty) ...[
          const _SectionLabel('INBOX'),
          for (final notification in notificationItems) ...[
            _AppNotificationTile(
              key: ValueKey('notification-${notification.id}'),
              notification: notification,
              onTap: () => onNotificationTap(notification),
            ),
            const SizedBox(height: 8),
          ],
        ],
        if (responseItems.isNotEmpty) ...[
          if (notificationItems.isNotEmpty) const SizedBox(height: 20),
          const _SectionLabel('INVITATION RESPONSES'),
          for (final response in responseItems) ...[
            _ResponseTile(
              key: ValueKey('response-${response.id}'),
              message: response.message,
              accepted: response.accepted,
              unread: !response.read,
              onTap: () => onResponseTap(response),
            ),
            const SizedBox(height: 8),
          ],
        ],
        if (responses.hasError)
          const _LoadWarning(
            message: 'Invitation responses could not be loaded.',
          ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      );
}

class _LoadWarning extends StatelessWidget {
  const _LoadWarning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        message,
        style: TextStyle(color: colors.muted, fontSize: 12.5),
      ),
    );
  }
}

class _AppNotificationTile extends StatelessWidget {
  const _AppNotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.isRead
                  ? colors.border
                  : colors.accent.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colors.accentSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  notification.kind.icon,
                  size: 17,
                  color: colors.accent,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (notification.body.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: colors.muted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 5),
                    Text(
                      DateFormat.MMMd().add_jm().format(notification.createdAt),
                      style: TextStyle(fontSize: 11, color: colors.subtle),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: colors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResponseTile extends StatelessWidget {
  const _ResponseTile({
    super.key,
    required this.message,
    required this.accepted,
    required this.unread,
    required this.onTap,
  });

  final String message;
  final bool accepted;
  final bool unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: unread
                  ? colors.accent.withValues(alpha: 0.35)
                  : colors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accepted ? colors.accentSoft : colors.surface2,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  accepted ? Icons.check_rounded : Icons.close_rounded,
                  size: 18,
                  color: accepted ? colors.accent : colors.muted,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 13.5, height: 1.4),
                ),
              ),
              if (unread)
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: colors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: colors.subtle),
            const SizedBox(height: 18),
            Text(
              title,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: colors.fg),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 13.5, height: 1.5, color: colors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
