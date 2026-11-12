import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:coworkhub_frontend/models/member.dart';
import 'package:coworkhub_frontend/services/api_service.dart';

void main() {
  test('getResources maps the backend JSON into Resource objects', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), 'http://localhost:8080/api/resources');
      return http.Response(
          jsonEncode([
            {
              'id': 1, 'name': 'Boardroom', 'location': 'Floor 2',
              'capacity': 10, 'hourlyRate': 80.00, 'status': 'ACTIVE',
              'resourceType': 'MEETING_ROOM',
              'hasProjector': true, 'hasVideoConference': true
            },
            {
              'id': 3, 'name': 'Hot Desk A1', 'location': 'Floor 1',
              'capacity': 1, 'hourlyRate': 10, 'status': 'ACTIVE',
              'resourceType': 'DESK', 'deskType': 'HOT_DESK'
            }
          ]),
          200);
    });

    final resources = await ApiService(client: client).getResources();

    expect(resources.length, 2);
    expect(resources[0].isMeetingRoom, isTrue);
    expect(resources[0].hourlyRate, 80.0);
    expect(resources[1].isDesk, isTrue);
    expect(resources[1].deskType, 'HOT_DESK');
  });

  test('an error response becomes an ApiException with the backend message',
      () async {
    final client = MockClient((request) async {
      return http.Response(
          jsonEncode({
            'status': 409,
            'error': 'Conflict',
            'message': "'Boardroom' is already booked during the selected time."
          }),
          409);
    });

    final api = ApiService(client: client);

    expect(
      () => api.createBooking(
        memberId: 1,
        resourceId: 1,
        start: DateTime(2026, 12, 1, 10),
        end: DateTime(2026, 12, 1, 12),
        attendees: 2,
      ),
      throwsA(isA<ApiException>()
          .having((e) => e.statusCode, 'statusCode', 409)
          .having((e) => e.message, 'message',
              "'Boardroom' is already booked during the selected time.")),
    );
  });

  test('formatDateTime uses the format the backend expects', () {
    expect(ApiService.formatDateTime(DateTime(2026, 12, 1, 9, 5)),
        '2026-12-01T09:05:00');
  });

  test('updateMember sends PUT /api/members/{id} with the member JSON',
      () async {
    final client = MockClient((request) async {
      expect(request.method, 'PUT');
      expect(request.url.toString(), 'http://localhost:8080/api/members/2');
      expect(jsonDecode(request.body)['phoneNumber'], '55519999');
      return http.Response(
          jsonEncode({
            'id': 2,
            'fullName': 'Omar Khalid',
            'email': 'omar.khalid@example.com',
            'phoneNumber': '55519999'
          }),
          200);
    });

    final updated = await ApiService(client: client).updateMember(
      2,
      Member(
        fullName: 'Omar Khalid',
        email: 'omar.khalid@example.com',
        phoneNumber: '55519999',
      ),
    );

    expect(updated.id, 2);
    expect(updated.phoneNumber, '55519999');
  });
}