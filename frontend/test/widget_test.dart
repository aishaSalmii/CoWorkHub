import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coworkhub_frontend/main.dart';

void main() {
  testWidgets('App starts on the Dashboard and can navigate', (tester) async {
    await tester.pumpWidget(const CoWorkHubApp());

    // All menu entries are shown in the navigation rail.
    expect(find.text('Resources'), findsOneWidget);
    expect(find.text('New Booking'), findsOneWidget);
    expect(find.text('Bookings'), findsOneWidget);
    expect(find.text('Members'), findsOneWidget);

    // The Dashboard is selected first: its name is shown in the title bar.
    expect(find.widgetWithText(AppBar, 'Dashboard'), findsOneWidget);

    // Tapping "Members" opens the Members screen.
    await tester.tap(find.text('Members'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Members'), findsOneWidget);
  });
}