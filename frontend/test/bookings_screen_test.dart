import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coworkhub_frontend/models/booking.dart';
import 'package:coworkhub_frontend/models/member.dart';
import 'package:coworkhub_frontend/models/resource.dart';
import 'package:coworkhub_frontend/screens/bookings_screen.dart';
import 'package:coworkhub_frontend/services/api_service.dart';
class FakeBookingsApiService extends ApiService {
  List<Booking> bookings;
  String? updateError;
  FakeBookingsApiService({
    required this.bookings,
    this.updateError,
  });
  @override
  Future<List<Booking>> getBookings() async {
    return List<Booking>.from(bookings);
  }
  @override
  Future<Booking> cancelBooking(int bookingId) async {
    final index = bookings.indexWhere(
      (booking) => booking.id == bookingId,
    );
    final old = bookings[index];
    final cancelled = Booking(
      id: old.id,
      startDateTime: old.startDateTime,
      endDateTime: old.endDateTime,
      attendees: old.attendees,
      status: 'CANCELLED',
      totalCost: old.totalCost,
      member: old.member,
      resource: old.resource,
    );
    bookings[index] = cancelled;
    return cancelled;
  }
  @override
  Future<Booking> updateBooking({
    required int bookingId,
    required int memberId,
    required int resourceId,
    required DateTime start,
    required DateTime end,
    required int attendees,
  }) async {
    if (updateError != null) {
      throw ApiException(updateError!);
    }
    final old = bookings.firstWhere(
      (booking) => booking.id == bookingId,
    );
    final updated = Booking(
      id: bookingId,
      startDateTime: start,
      endDateTime: end,
      attendees: attendees,
      status: 'CONFIRMED',
      totalCost: 120.0,
      member: old.member,
      resource: old.resource,
    );
    final index = bookings.indexWhere(
      (booking) => booking.id == bookingId,
    );
    bookings[index] = updated;
    return updated;
  }
}
Member makeTestMember() {
  return Member(
    id: 1,
    fullName: 'Sara Ahmed',
    email: 'sara@example.com',
    phoneNumber: '55555555',
  );
}
Resource makeTestResource() {
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
Booking makeTestBooking({
  required int id,
  required DateTime start,
  String status = 'CONFIRMED',
}) {
  return Booking(
    id: id,
    startDateTime: start,
    endDateTime: start.add(
      const Duration(hours: 1),
    ),
    attendees: 2,
    status: status,
    totalCost: 100.0,
    member: makeTestMember(),
    resource: makeTestResource(),
  );
}
void main() {
  testWidgets(
    'Current, Past and All filters display correct bookings',
    (tester) async {
      final futureBooking = makeTestBooking(
        id: 1,
        start: DateTime.now().add(
          const Duration(days: 2),
        ),
      );
      final pastBooking = makeTestBooking(
        id: 2,
        start: DateTime.now().subtract(
          const Duration(days: 2),
        ),
      );
      final api = FakeBookingsApiService(
        bookings: [
          futureBooking,
          pastBooking,
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingsScreen(api: api),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Booking #1'),
        findsOneWidget,
      );
      expect(
        find.text('Booking #2'),
        findsNothing,
      );
      await tester.tap(
        find.text('Past'),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Booking #1'),
        findsNothing,
      );
      expect(
        find.text('Booking #2'),
        findsOneWidget,
      );
      expect(
        find.text('Change'),
        findsNothing,
      );
      expect(
        find.text('Cancel'),
        findsNothing,
      );
      await tester.tap(
        find.text('All'),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Booking #1'),
        findsOneWidget,
      );
      expect(
        find.text('Booking #2'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'Cancel keeps booking in list as CANCELLED',
    (tester) async {
      final api = FakeBookingsApiService(
        bookings: [
          makeTestBooking(
            id: 1,
            start: DateTime.now().add(
              const Duration(days: 2),
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingsScreen(api: api),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.text('Cancel'),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Cancel booking?'),
        findsOneWidget,
      );
      await tester.tap(
        find.widgetWithText(
          TextButton,
          'Cancel booking',
        ),
      );
      await tester.pump();
      await tester.pump(
        const Duration(milliseconds: 500),
      );
      expect(
        find.text('Booking cancelled.'),
        findsOneWidget,
      );
      expect(
        find.text('Booking #1'),
        findsOneWidget,
      );
      expect(
        find.text('CANCELLED'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'Change booking shows backend conflict message',
    (tester) async {
      final api = FakeBookingsApiService(
        bookings: [
          makeTestBooking(
            id: 1,
            start: DateTime.now().add(
              const Duration(days: 2),
            ),
          ),
        ],
        updateError:
            'Resource already has a booking during this time.',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingsScreen(api: api),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.text('Change'),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Change booking'),
        findsOneWidget,
      );
      await tester.tap(
        find.text('Save'),
      );
      await tester.pump();
      await tester.pump(
        const Duration(milliseconds: 500),
      );
      expect(
        find.textContaining(
          'already has a booking',
        ),
        findsOneWidget,
      );
    },
  );
}
