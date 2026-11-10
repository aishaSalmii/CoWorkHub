import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:coworkhub_frontend/models/member.dart';
import 'package:coworkhub_frontend/screens/new_booking_screen.dart';
import 'package:coworkhub_frontend/services/api_service.dart';

// Fake backend data
final member = {
  'id': 1, 'fullName': 'Sara Ahmed', 'email': 'sara@example.com',
  'phoneNumber': '55510001'
};
final boardroom = {
  'id': 1, 'name': 'Boardroom', 'location': 'Floor 2', 'capacity': 10,
  'hourlyRate': 80.0, 'status': 'ACTIVE', 'resourceType': 'MEETING_ROOM',
  'hasProjector': true, 'hasVideoConference': true
};
final focusRoom = {
  'id': 2, 'name': 'Focus Room', 'location': 'Floor 1', 'capacity': 4,
  'hourlyRate': 40.0, 'status': 'ACTIVE', 'resourceType': 'MEETING_ROOM',
  'hasProjector': false, 'hasVideoConference': true
};

/// A fake backend: the Boardroom is already booked, the Focus Room is free.
MockClient fakeBackend() {
  return MockClient((request) async {
    final path = request.url.path;
    if (path == '/api/members') {
      return http.Response(jsonEncode([member]), 200);
    }
    if (path == '/api/resources/available') {
      return http.Response(jsonEncode([focusRoom]), 200);
    }
    if (path == '/api/resources') {
      return http.Response(jsonEncode([boardroom, focusRoom]), 200);
    }
    if (path == '/api/bookings' && request.method == 'POST') {
      final body = jsonDecode(request.body);
      if (body['resourceId'] == 1) {
        return http.Response(
            jsonEncode({
              'status': 409,
              'error': 'Conflict',
              'message': "'Boardroom' is already booked during the selected time."
            }),
            409);
      }
      return http.Response(
          jsonEncode({
            'id': 7, 'startDateTime': body['startDateTime'],
            'endDateTime': body['endDateTime'], 'attendees': body['attendees'],
            'status': 'CONFIRMED', 'totalCost': 40.0,
            'member': member, 'resource': focusRoom
          }),
          201);
    }
    return http.Response('Not found', 404);
  });
}

Future<void> openScreenAndSearch(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: NewBookingScreen(api: ApiService(client: fakeBackend()))),
  ));
  await tester.pumpAndSettle(); // members loaded

  await tester.tap(find.text('Check availability'));
  await tester.pumpAndSettle();
}

Future<void> chooseMemberAndAttendees(WidgetTester tester) async {
  await tester.tap(find.byType(DropdownButtonFormField<Member>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sara Ahmed (sara@example.com)').last);
  await tester.pumpAndSettle();
  await tester.enterText(find.widgetWithText(TextFormField, 'Attendees'), '2');
}

void main() {
  testWidgets('shows which resources are available and which are booked',
      (tester) async {
    await openScreenAndSearch(tester);

    expect(find.text('Boardroom'), findsOneWidget);
    expect(find.text('Focus Room'), findsOneWidget);
    expect(find.text('Booked'), findsOneWidget); // Boardroom
    expect(find.text('Available'), findsOneWidget); // Focus Room
  });

  testWidgets('booking a booked room shows the backend 409 message',
      (tester) async {
    await openScreenAndSearch(tester);

    await tester.tap(find.text('Boardroom'));
    await tester.pumpAndSettle();
    await chooseMemberAndAttendees(tester);
    await tester.tap(find.text('Book Boardroom'));
    await tester.pumpAndSettle();

    expect(find.text("'Boardroom' is already booked during the selected time."),
        findsOneWidget);
  });

  testWidgets('booking a free room shows the confirmation with total cost',
      (tester) async {
    await openScreenAndSearch(tester);

    await tester.tap(find.text('Focus Room'));
    await tester.pumpAndSettle();
    await chooseMemberAndAttendees(tester);
    await tester.tap(find.text('Book Focus Room'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Booking confirmed: Focus Room'), findsOneWidget);
    expect(find.textContaining('total cost 40.00 QAR'), findsOneWidget);
  });

  testWidgets('end time before start time is rejected before calling the backend',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: NewBookingScreen(api: ApiService(client: fakeBackend()))),
    ));
    await tester.pumpAndSettle();

    // Change the end time to 08:00 (before the 09:00 start) using the time picker.
    await tester.tap(find.textContaining('To '));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    final hourField = find.byType(TextField).first;
    await tester.enterText(hourField, '8');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Check availability'));
    await tester.pumpAndSettle();

    expect(find.text('The end time must be after the start time.'), findsOneWidget);
  });
}