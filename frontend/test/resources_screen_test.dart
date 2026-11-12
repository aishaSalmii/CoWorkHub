import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:coworkhub_frontend/screens/resources_screen.dart';
import 'package:coworkhub_frontend/services/api_service.dart';

/// A fake backend with one room (id 1, has bookings) and one desk (id 2).
/// It records every request so the tests can check what was sent.
class FakeBackend {
  final requests = <http.Request>[];
  final resources = <Map<String, dynamic>>[
    {
      'id': 1, 'name': 'Boardroom', 'location': 'Floor 2', 'capacity': 10,
      'hourlyRate': 80.0, 'status': 'ACTIVE', 'resourceType': 'MEETING_ROOM',
      'hasProjector': true, 'hasVideoConference': true
    },
    {
      'id': 2, 'name': 'Hot Desk A1', 'location': 'Floor 1', 'capacity': 1,
      'hourlyRate': 10.0, 'status': 'ACTIVE', 'resourceType': 'DESK',
      'deskType': 'HOT_DESK'
    },
  ];

  late final client = MockClient((request) async {
    requests.add(request);
    final path = request.url.path;
    if (path == '/api/resources' && request.method == 'GET') {
      return http.Response(jsonEncode(resources), 200);
    }
    if (path == '/api/resources/rooms' && request.method == 'POST') {
      final created = {
        ...jsonDecode(request.body) as Map<String, dynamic>,
        'id': 3, 'resourceType': 'MEETING_ROOM'
      };
      resources.add(created);
      return http.Response(jsonEncode(created), 201);
    }
    if (path == '/api/resources/1/room' && request.method == 'PUT') {
      final updated = {
        ...jsonDecode(request.body) as Map<String, dynamic>,
        'id': 1, 'resourceType': 'MEETING_ROOM'
      };
      resources[0] = updated;
      return http.Response(jsonEncode(updated), 200);
    }
    if (path == '/api/resources/1' && request.method == 'DELETE') {
      return http.Response(
          jsonEncode({
            'status': 409, 'error': 'Conflict',
            'message': "Resource 'Boardroom' has bookings and cannot be deleted. "
                'Set its status to OUT_OF_SERVICE instead.'
          }),
          409);
    }
    return http.Response('Not found', 404);
  });
}

Future<FakeBackend> openScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final backend = FakeBackend();
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: ResourcesScreen(api: ApiService(client: backend.client))),
  ));
  await tester.pumpAndSettle();
  return backend;
}

void main() {
  testWidgets('shows meeting rooms and desks', (tester) async {
    await openScreen(tester);
    expect(find.text('Boardroom'), findsOneWidget);
    expect(find.text('Hot Desk A1'), findsOneWidget);
  });

  testWidgets('filters are sent to the backend', (tester) async {
    final backend = await openScreen(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Min capacity'), '5');
    await tester.enterText(find.widgetWithText(TextField, 'Location'), 'floor 2');
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();

    final url = backend.requests.last.url;
    expect(url.queryParameters['minCapacity'], '5');
    expect(url.queryParameters['location'], 'floor 2');
  });

  testWidgets('the form rejects invalid input before sending', (tester) async {
    final backend = await openScreen(tester);
    await tester.tap(find.text('Add meeting room'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Capacity'), '0');
    await tester.enterText(find.widgetWithText(TextFormField, 'Hourly rate (QAR)'), '-5');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Name is required.'), findsOneWidget);
    expect(find.text('Capacity must be a whole number of at least 1.'), findsOneWidget);
    expect(find.text('Hourly rate must be a number greater than 0.'), findsOneWidget);
    expect(backend.requests.where((r) => r.method == 'POST'), isEmpty);
  });

  testWidgets('creating a meeting room posts to /rooms and refreshes the list',
      (tester) async {
    final backend = await openScreen(tester);
    await tester.tap(find.text('Add meeting room'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Innovation Lab');
    await tester.enterText(find.widgetWithText(TextFormField, 'Location'), 'Floor 3');
    await tester.enterText(find.widgetWithText(TextFormField, 'Capacity'), '12');
    await tester.enterText(find.widgetWithText(TextFormField, 'Hourly rate (QAR)'), '95');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final post = backend.requests.firstWhere((r) => r.method == 'POST');
    expect(post.url.path, '/api/resources/rooms');
    expect(jsonDecode(post.body)['capacity'], 12);
    expect(find.text('Innovation Lab created.'), findsOneWidget);
    expect(find.text('Innovation Lab'), findsOneWidget); // list refreshed
  });

  testWidgets('editing a room can set it OUT_OF_SERVICE', (tester) async {
    final backend = await openScreen(tester);
    await tester.tap(find.byTooltip('Edit').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Active').last); // open the Status dropdown
    await tester.pumpAndSettle();
    await tester.tap(find.text('Out of service').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final put = backend.requests.firstWhere((r) => r.method == 'PUT');
    expect(put.url.path, '/api/resources/1/room');
    expect(jsonDecode(put.body)['status'], 'OUT_OF_SERVICE');
    expect(find.text('Boardroom updated.'), findsOneWidget);
  });

  testWidgets('deleting a resource with bookings shows the backend 409 message',
      (tester) async {
    await openScreen(tester);
    await tester.tap(find.byTooltip('Delete').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.textContaining('has bookings and cannot be deleted'), findsOneWidget);
  });

  testWidgets('tapping a resource shows its details', (tester) async {
    await openScreen(tester);
    await tester.tap(find.text('Hot Desk A1'));
    await tester.pumpAndSettle();

    expect(find.text('Type: Desk'), findsOneWidget);
    expect(find.text('Desk type: Hot desk'), findsOneWidget);
  });
}