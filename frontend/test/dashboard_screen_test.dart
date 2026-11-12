import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:coworkhub_frontend/screens/dashboard_screen.dart';
import 'package:coworkhub_frontend/services/api_service.dart';

final member = {
  'id': 1,
  'fullName': 'Sara Ahmed',
  'email': 'sara@example.com',
  'phoneNumber': '55510001',
};
final boardroom = {
  'id': 1,
  'name': 'Boardroom',
  'location': 'Floor 2',
  'capacity': 10,
  'hourlyRate': 80.0,
  'status': 'ACTIVE',
  'resourceType': 'MEETING_ROOM',
};
final oldRoom = {
  'id': 2,
  'name': 'Old Room',
  'location': 'Floor 3',
  'capacity': 6,
  'hourlyRate': 50.0,
  'status': 'OUT_OF_SERVICE',
  'resourceType': 'MEETING_ROOM',
};
final desk = {
  'id': 3,
  'name': 'Hot Desk A1',
  'location': 'Floor 1',
  'capacity': 1,
  'hourlyRate': 10.0,
  'status': 'ACTIVE',
  'resourceType': 'DESK',
  'deskType': 'HOT_DESK',
};

Map<String, dynamic> booking(int id, DateTime start, String status) => {
  'id': id,
  'startDateTime': ApiService.formatDateTime(start),
  'endDateTime': ApiService.formatDateTime(start.add(const Duration(hours: 2))),
  'attendees': 4,
  'status': status,
  'totalCost': 160.0,
  'member': member,
  'resource': boardroom,
};

/// A fake backend: 3 resources (1 out of service), 2 members and 3 bookings:
/// one confirmed today, one cancelled today, one confirmed tomorrow.
MockClient fakeBackend() {
  final now = DateTime.now();
  final todayAt10 = DateTime(now.year, now.month, now.day, 10);
  final tomorrowAt9 = DateTime(now.year, now.month, now.day + 1, 9);
  return MockClient((request) async {
    switch (request.url.path) {
      case '/api/resources':
        return http.Response(jsonEncode([boardroom, oldRoom, desk]), 200);
      case '/api/members':
        return http.Response(
          jsonEncode([
            member,
            {...member, 'id': 2, 'fullName': 'Omar Khalid'},
          ]),
          200,
        );
      case '/api/bookings':
        return http.Response(
          jsonEncode([
            booking(1, todayAt10, 'CONFIRMED'),
            booking(2, todayAt10, 'CANCELLED'),
            booking(3, tomorrowAt9, 'CONFIRMED'),
          ]),
          200,
        );
    }
    return http.Response('Not found', 404);
  });
}

Future<void> openScreen(WidgetTester tester, MockClient client) async {
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DashboardScreen(api: ApiService(client: client)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Finds the big number inside the summary card with this title.
Finder cardValue(String title, String value) => find.descendant(
  of: find.ancestor(of: find.text(title).first, matching: find.byType(Card)),
  matching: find.text(value),
);

void main() {
  testWidgets('shows the summary numbers', (tester) async {
    await openScreen(tester, fakeBackend());

    expect(cardValue('Resources', '3'), findsOneWidget);
    expect(find.textContaining('2 rooms • 1 desks'), findsOneWidget);
    expect(find.textContaining('2 active • 1 out of service'), findsOneWidget);
    expect(cardValue('Members', '2'), findsOneWidget);
    expect(
      cardValue("Today's bookings", '1'),
      findsOneWidget,
    ); // cancelled one not counted
    expect(cardValue('Upcoming', '1'), findsOneWidget); // tomorrow's booking
  });

  testWidgets("lists today's confirmed bookings", (tester) async {
    await openScreen(tester, fakeBackend());

    expect(find.text('Boardroom'), findsOneWidget);
    expect(find.textContaining('10:00–12:00'), findsOneWidget);
    expect(find.text('160.00 QAR'), findsOneWidget);
  });

  testWidgets('shows an error with Retry when the backend fails', (
    tester,
  ) async {
    final failing = MockClient(
      (request) async => http.Response(
        jsonEncode({
          'status': 500,
          'error': 'Internal Server Error',
          'message': 'Database unavailable',
        }),
        500,
      ),
    );
    await openScreen(tester, failing);

    expect(find.text('Database unavailable'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
