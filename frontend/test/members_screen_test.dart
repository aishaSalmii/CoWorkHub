import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coworkhub_frontend/models/booking.dart';
import 'package:coworkhub_frontend/models/member.dart';
import 'package:coworkhub_frontend/models/resource.dart';
import 'package:coworkhub_frontend/screens/members_screen.dart';
import 'package:coworkhub_frontend/services/api_service.dart';
class FakeMembersApiService extends ApiService {
  List<Member> members;
  List<Booking> memberBookings;
  String? createMemberError;
  String? updateMemberError;
  FakeMembersApiService({
    required this.members,
    this.memberBookings = const [],
    this.createMemberError,
    this.updateMemberError,
  });
  @override
  Future<List<Member>> getMembers() async {
    return List<Member>.from(members);
  }
  @override
  Future<Member> createMember(Member member) async {
    if (createMemberError != null) {
      throw ApiException(createMemberError!);
    }
    final created = Member(
      id: members.length + 1,
      fullName: member.fullName,
      email: member.email,
      phoneNumber: member.phoneNumber,
    );
    members = [
      ...members,
      created,
    ];
    return created;
  }
  @override
  Future<Member> updateMember(int id, Member member) async {
    if (updateMemberError != null) {
      throw ApiException(updateMemberError!);
    }
    final updated = Member(
      id: id,
      fullName: member.fullName,
      email: member.email,
      phoneNumber: member.phoneNumber,
    );
    members = [
      for (final m in members) m.id == id ? updated : m,
    ];
    return updated;
  }
  @override
  Future<List<Booking>> getMemberBookings(int memberId) async {
    return List<Booking>.from(memberBookings);
  }
}
Member makeMember({
  int id = 1,
  String fullName = 'Sara Ahmed',
  String email = 'sara@example.com',
  String phoneNumber = '55555555',
}) {
  return Member(
    id: id,
    fullName: fullName,
    email: email,
    phoneNumber: phoneNumber,
  );
}
Resource makeResource() {
  return Resource(
    id: 1,
    name: 'Meeting Room A',
    location: 'Floor 1',
    capacity: 8,
    hourlyRate: 100.0,
    status: 'ACTIVE',
    resourceType: 'MEETING_ROOM',
    hasProjector: true,
    hasVideoConference: true,
  );
}
Booking makeBooking() {
  final start = DateTime.now().add(
    const Duration(days: 2),
  );
  return Booking(
    id: 1,
    startDateTime: start,
    endDateTime: start.add(
      const Duration(hours: 1),
    ),
    attendees: 2,
    status: 'CONFIRMED',
    totalCost: 100.0,
    member: makeMember(),
    resource: makeResource(),
  );
}
void main() {
  testWidgets(
    'Member list loads',
    (tester) async {
      final api = FakeMembersApiService(
        members: [
          makeMember(),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MembersScreen(api: api),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Sara Ahmed'),
        findsOneWidget,
      );
      expect(
        find.text('sara@example.com'),
        findsOneWidget,
      );
      expect(
        find.text('55555555'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'Invalid member form fields are blocked',
    (tester) async {
      final api = FakeMembersApiService(
        members: [],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MembersScreen(api: api),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.text('Add member'),
      );
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      expect(
        fields,
        findsNWidgets(3),
      );
      await tester.enterText(
        fields.at(1),
        'wrong-email',
      );
      await tester.tap(
        find.text('Save'),
      );
      await tester.pump();
      expect(
        find.text('Name is required.'),
        findsOneWidget,
      );
      expect(
        find.text('Enter a valid email.'),
        findsOneWidget,
      );
      expect(
        find.text('Phone is required.'),
        findsOneWidget,
      );
      expect(
        api.members,
        isEmpty,
      );
    },
  );
  testWidgets(
    'New member is added and list refreshes',
    (tester) async {
      final api = FakeMembersApiService(
        members: [],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MembersScreen(api: api),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.text('Add member'),
      );
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      await tester.enterText(
        fields.at(0),
        'Omar Khalid',
      );
      await tester.enterText(
        fields.at(1),
        'omar@example.com',
      );
      await tester.enterText(
        fields.at(2),
        '55551234',
      );
      await tester.tap(
        find.text('Save'),
      );
      await tester.pump();
      await tester.pump(
        const Duration(milliseconds: 500),
      );
      expect(
        find.text('Member Omar Khalid added.'),
        findsOneWidget,
      );
      expect(
        find.text('Omar Khalid'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'Duplicate email shows backend error',
    (tester) async {
      final api = FakeMembersApiService(
        members: [],
        createMemberError:
            'A member with email omar@example.com already exists.',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MembersScreen(api: api),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.text('Add member'),
      );
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      await tester.enterText(
        fields.at(0),
        'Omar Khalid',
      );
      await tester.enterText(
        fields.at(1),
        'omar@example.com',
      );
      await tester.enterText(
        fields.at(2),
        '55551234',
      );
      await tester.tap(
        find.text('Save'),
      );
      await tester.pump();
      await tester.pump(
        const Duration(milliseconds: 500),
      );
      expect(
        find.textContaining('already exists'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'Tapping a member shows that member bookings',
    (tester) async {
      final api = FakeMembersApiService(
        members: [
          makeMember(),
        ],
        memberBookings: [
          makeBooking(),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MembersScreen(api: api),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.text('Sara Ahmed'),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Sara Ahmed - Bookings'),
        findsOneWidget,
      );
      expect(
        find.text('Booking #1'),
        findsOneWidget,
      );
      expect(
        find.text('Status: CONFIRMED'),
        findsOneWidget,
      );
      expect(
        find.text('Resource: Meeting Room A'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'Edit member opens a filled form, saves and refreshes the list',
    (tester) async {
      final api = FakeMembersApiService(members: [makeMember()]);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: MembersScreen(api: api))),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Edit member'));
      await tester.pumpAndSettle();
      expect(find.text('Edit member'), findsWidgets);
      final fields = find.byType(TextFormField);
      expect(
        tester.widget<TextFormField>(fields.at(0)).controller!.text,
        'Sara Ahmed',
      );
      await tester.enterText(fields.at(2), '55519999');
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Member Sara Ahmed updated.'), findsOneWidget);
      expect(find.text('55519999'), findsOneWidget);
      expect(api.members.single.phoneNumber, '55519999');
    },
  );
  testWidgets(
    'Edit with a duplicate email shows backend error',
    (tester) async {
      final api = FakeMembersApiService(
        members: [makeMember()],
        updateMemberError:
            'A member with email omar@example.com already exists.',
      );
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: MembersScreen(api: api))),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Edit member'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(1), 'omar@example.com');
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('already exists'), findsOneWidget);
      expect(api.members.single.email, 'sara@example.com');
    },
  );
}