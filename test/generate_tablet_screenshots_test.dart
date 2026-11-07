import 'dart:io';
import 'dart:ui' as ui;

import 'package:datedawn/core/circles.dart';
import 'package:datedawn/core/models.dart';
import 'package:datedawn/core/notifications.dart';
import 'package:datedawn/core/recent_contacts.dart';

import 'package:datedawn/main.dart';
import 'package:datedawn/providers/app_providers.dart';
import 'package:datedawn/screens/circles_screen.dart';
import 'package:datedawn/screens/event_detail_screen.dart';
import 'package:datedawn/screens/event_editor_screen.dart';
import 'package:datedawn/screens/home_screen.dart';
import 'package:datedawn/screens/invitations_screen.dart';
import 'package:datedawn/screens/notifications_screen.dart';
import 'package:datedawn/screens/settings_screen.dart';
import 'package:datedawn/services/auth_service.dart';
import 'package:datedawn/services/event_repository.dart';
import 'package:datedawn/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFirebaseAuth extends Fake implements FirebaseAuth {}

class _TestAuthService extends AuthService {
  _TestAuthService(this._user) : super(auth: _FakeFirebaseAuth());
  final AppUser? _user;

  @override
  Stream<AppUser?> authStateChanges() => Stream.value(_user);
}

class _MockEventRepository extends Fake implements EventRepository {
  _MockEventRepository({
    required this.events,
    required this.circles,
    required this.invitations,
    required this.circleInvitations,
    required this.participants,
    required this.notes,
    required this.circleMembers,
  });

  final List<CountdownEvent> events;
  final List<Circle> circles;
  final List<Invitation> invitations;
  final List<CircleInvitation> circleInvitations;
  final Map<String, List<Participant>> participants;
  final Map<String, List<EventNote>> notes;
  final Map<String, List<CircleMember>> circleMembers;

  @override
  Stream<List<CountdownEvent>> watchEvents(String userId) => Stream.value(events);

  @override
  Stream<List<Circle>> watchCircles(String userId) => Stream.value(circles);

  @override
  Stream<List<Invitation>> watchInvitations(String email) => Stream.value(invitations);

  @override
  Stream<List<CircleInvitation>> watchCircleInvitations(String email) => Stream.value(circleInvitations);

  @override
  Stream<List<Participant>> watchParticipants(String eventId) => Stream.value(participants[eventId] ?? const []);

  @override
  Stream<List<EventNote>> watchNotes(String eventId) => Stream.value(notes[eventId] ?? const []);

  @override
  Stream<List<CircleMember>> watchCircleMembers(String circleId) => Stream.value(circleMembers[circleId] ?? const []);

  @override
  Stream<List<InvitationResponse>> watchResponses(String userId) => Stream.value(const []);

  @override
  Stream<List<RecentContact>> watchRecentContacts(String userId) => Stream.value(const []);

  @override
  Future<void> syncUserProfile(AppUser user) async {}
}

class _MockNotificationService extends Fake implements NotificationService {
  _MockNotificationService(this.notifications);
  final List<AppNotification> notifications;

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) => Stream.value(notifications);

  @override
  Future<String?> fetchThemeMode(String userId) async => 'dark';

  @override
  Future<String?> fetchTimeFormat(String userId) async => '12';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.now();
  final user = const AppUser(
    id: 'u1',
    email: 'alex@datedawn.app',
    displayName: 'Alex Friedman',
  );

  final events = <CountdownEvent>[
    CountdownEvent(
      id: 'e1',
      title: 'Tokyo Trip 2027 🗾',
      description: 'Exploring Shibuya, Kyoto, and Mt. Fuji with the group!',
      at: now.add(const Duration(days: 142, hours: 8, minutes: 30)),
      createdBy: 'u1',
      createdAt: now.subtract(const Duration(days: 10)),
      updatedAt: now.subtract(const Duration(days: 2)),
      circleId: 'c2',
      sharedWithCircleIds: const ['c2'],
      sharedWithMemberIds: const ['u1', 'u2', 'u3', 'u4'],
      participants: const [
        Participant(
          userId: 'u1',
          email: 'alex@datedawn.app',
          displayName: 'Alex Friedman',
          role: ParticipantRole.admin,
          inviteStatus: InviteStatus.accepted,
        ),
        Participant(
          userId: 'u2',
          email: 'sam@example.com',
          displayName: 'Sam Taylor',
          role: ParticipantRole.editor,
          inviteStatus: InviteStatus.accepted,
        ),
        Participant(
          userId: 'u3',
          email: 'sarah@example.com',
          displayName: 'Sarah Miller',
          role: ParticipantRole.viewer,
          inviteStatus: InviteStatus.accepted,
        ),
      ],
      notes: [
        EventNote(
          id: 'n1',
          userId: 'u2',
          text: 'Flights and hotel reservation confirmed! ✈️',
          createdAt: now.subtract(const Duration(days: 1)),
          updatedAt: now.subtract(const Duration(days: 1)),
        ),
      ],
    ),
    CountdownEvent(
      id: 'e2',
      title: 'Our 5th Anniversary 💞',
      description: 'Special romantic dinner & weekend getaway',
      at: now.add(const Duration(days: 18, hours: 4, minutes: 12)),
      createdBy: 'u1',
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now.subtract(const Duration(days: 5)),
      circleId: 'c1',
      sharedWithCircleIds: const ['c1'],
      sharedWithMemberIds: const ['u1', 'u2'],
      participants: const [
        Participant(
          userId: 'u1',
          email: 'alex@datedawn.app',
          displayName: 'Alex Friedman',
          role: ParticipantRole.admin,
          inviteStatus: InviteStatus.accepted,
        ),
        Participant(
          userId: 'u2',
          email: 'sam@example.com',
          displayName: 'Sam Taylor',
          role: ParticipantRole.editor,
          inviteStatus: InviteStatus.accepted,
        ),
      ],
    ),
    CountdownEvent(
      id: 'e3',
      title: 'New Year 2027 🎉',
      description: 'Counting down to 2027 together!',
      at: DateTime(2027, 1, 1, 0, 0),
      createdBy: 'u1',
      createdAt: now.subtract(const Duration(days: 50)),
      updatedAt: now.subtract(const Duration(days: 20)),
    ),
    CountdownEvent(
      id: 'e4',
      title: 'Product Launch v2.0 🚀',
      description: 'Major app launch day',
      at: now.add(const Duration(days: 5, hours: 14, minutes: 0)),
      createdBy: 'u1',
      createdAt: now.subtract(const Duration(days: 15)),
      updatedAt: now.subtract(const Duration(days: 1)),
    ),
  ];

  final circles = <Circle>[
    Circle(
      id: 'c1',
      name: 'Us',
      ownerId: 'u1',
      memberIds: const ['u1', 'u2'],
      isCouple: true,
      emoji: '💞',
      createdAt: now.subtract(const Duration(days: 60)),
      members: const [
        CircleMember(
          userId: 'u1',
          email: 'alex@datedawn.app',
          displayName: 'Alex Friedman',
          isOwner: true,
        ),
        CircleMember(
          userId: 'u2',
          email: 'sam@example.com',
          displayName: 'Sam Taylor',
          isOwner: false,
        ),
      ],
    ),
    Circle(
      id: 'c2',
      name: 'Japan Travelers',
      ownerId: 'u1',
      memberIds: const ['u1', 'u2', 'u3', 'u4'],
      isCouple: false,
      emoji: '🗾',
      createdAt: now.subtract(const Duration(days: 30)),
      members: const [
        CircleMember(
          userId: 'u1',
          email: 'alex@datedawn.app',
          displayName: 'Alex Friedman',
          isOwner: true,
        ),
        CircleMember(
          userId: 'u2',
          email: 'sam@example.com',
          displayName: 'Sam Taylor',
          isOwner: false,
        ),
        CircleMember(
          userId: 'u3',
          email: 'sarah@example.com',
          displayName: 'Sarah Miller',
          isOwner: false,
        ),
      ],
    ),
  ];

  final invitations = <Invitation>[
    Invitation(
      id: 'inv1',
      eventId: 'e1',
      invitedBy: 'u3',
      inviteeEmail: 'alex@datedawn.app',
      role: ParticipantRole.editor,
      status: InviteStatus.pending,
      createdAt: now.subtract(const Duration(hours: 3)),
      expiresAt: now.add(const Duration(days: 27)),
      eventTitle: 'Hawaii Summer Vacation 🏖️',
    ),
  ];

  final circleInvitations = <CircleInvitation>[
    CircleInvitation(
      id: 'cinv1',
      circleId: 'c3',
      circleName: 'Family Countdown',
      invitedBy: 'u4',
      invitedByName: 'Mom',
      inviteeEmail: 'alex@datedawn.app',
      status: InviteStatus.pending,
      createdAt: now.subtract(const Duration(hours: 12)),
      expiresAt: now.add(const Duration(days: 25)),
      isCouple: false,
    ),
  ];

  final appNotifications = <AppNotification>[
    AppNotification(
      id: 'notif1',
      userId: 'u1',
      title: 'Partner joined "Us"',
      body: 'Sam Taylor accepted your partner invitation.',
      kind: NotificationKind.circle,
      isRead: false,
      createdAt: now.subtract(const Duration(minutes: 45)),
    ),
    AppNotification(
      id: 'notif2',
      userId: 'u1',
      title: 'Note added on Tokyo Trip',
      body: 'Sam: "Flights and hotel reservation confirmed! ✈️"',
      kind: NotificationKind.invitation,
      isRead: true,
      createdAt: now.subtract(const Duration(hours: 3)),
    ),
  ];

  final mockRepo = _MockEventRepository(
    events: events,
    circles: circles,
    invitations: invitations,
    circleInvitations: circleInvitations,
    participants: {
      'e1': events[0].participants,
      'e2': events[1].participants,
    },
    notes: {
      'e1': events[0].notes,
    },
    circleMembers: {
      'c1': circles[0].members,
      'c2': circles[1].members,
    },
  );

  final mockNotifService = _MockNotificationService(appNotifications);

  Future<void> captureScreen({
    required WidgetTester tester,
    required Size size,
    required String filePath,
    required Widget child,
    ThemeMode themeMode = ThemeMode.dark,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repaintKey = GlobalKey();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(_TestAuthService(user)),
          eventRepositoryProvider.overrideWithValue(mockRepo),
          notificationServiceProvider.overrideWithValue(mockNotifService),
          clockProvider.overrideWith((ref) => Stream.value(now)),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeMode,
          home: RepaintBoundary(
            key: repaintKey,
            child: Scaffold(body: child),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));

    final boundary = repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    final file = File(filePath);
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(pngBytes);
  }

  final targetScreens = <String, Widget>{
    '1_home.png': const HomeScreen(),
    '2_event_detail.png': EventDetailScreen(eventId: events[0].id),
    '3_circles.png': const CirclesScreen(),
    '4_invitations.png': const InvitationsScreen(),
    '5_notifications.png': const NotificationsScreen(),
    '6_new_event.png': const EventEditorScreen(),
    '7_settings.png': const SettingsScreen(),
    '8_home_light.png': const HomeScreen(),
  };

  final sizeMap = <String, Size>{
    '7_inch': const Size(1200, 1920), // 7-inch tablet 9:16 aspect ratio
    '10_inch': const Size(1600, 2560), // 10-inch tablet 9:16 aspect ratio
  };

  for (final sizeEntry in sizeMap.entries) {
    final label = sizeEntry.key;
    final size = sizeEntry.value;

    group('$label Tablet Screenshots', () {
      for (final screenEntry in targetScreens.entries) {
        final fileName = screenEntry.key;
        final widget = screenEntry.value;
        final isLight = fileName.contains('light');

        testWidgets(fileName, (tester) async {
          await captureScreen(
            tester: tester,
            size: size,
            filePath: 'screenshots/$label/$fileName',
            themeMode: isLight ? ThemeMode.light : ThemeMode.dark,
            child: widget,
          );
        });
      }
    });
  }
}
