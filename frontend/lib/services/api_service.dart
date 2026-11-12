import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/booking.dart';
import '../models/member.dart';
import '../models/resource.dart';

/// Thrown when a request to the backend fails.
/// [message] is the text to show to the user.
class ApiException implements Exception {
  final int? statusCode; // e.g. 400, 404, 409 (null when the server could not be reached)
  final String message;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// The ONLY class that talks to the Spring Boot backend.
/// Screens call these methods; they never use the http package directly.
class ApiService {
  /// Address of the backend REST API.
  static const String baseUrl = 'http://localhost:8080/api';

  final http.Client _client;

  /// [client] can be replaced in tests; normally a real http.Client is used.
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
  };

  // ------------------------------------------------------------------
  // Resources
  // ------------------------------------------------------------------

  /// GET /api/resources with optional filters.
  Future<List<Resource>> getResources({
    String? type,
    int? minCapacity,
    String? location,
    double? maxPrice,
  }) async {
    // Only the filters that were given are added to the URL.
    final query = <String, String>{};
    if (type != null) query['type'] = type;
    if (minCapacity != null) query['minCapacity'] = '$minCapacity';
    if (location != null && location.isNotEmpty) query['location'] = location;
    if (maxPrice != null) query['maxPrice'] = '$maxPrice';
    final data = await _send('GET', '/resources', query: query) as List;
    return data.map((item) => Resource.fromJson(item)).toList();
  }

  /// GET /api/resources/{id}
  Future<Resource> getResource(int id) async {
    final data = await _send('GET', '/resources/$id');
    return Resource.fromJson(data);
  }

  /// POST /api/resources/rooms or /api/resources/desks
  Future<Resource> createResource(Resource resource) async {
    final path = resource.isMeetingRoom ? '/resources/rooms' : '/resources/desks';
    final data = await _send('POST', path, body: resource.toJson());
    return Resource.fromJson(data);
  }

  /// PUT /api/resources/{id}/room or /api/resources/{id}/desk
  Future<Resource> updateResource(int id, Resource resource) async {
    final path = resource.isMeetingRoom
        ? '/resources/$id/room'
        : '/resources/$id/desk';
    final data = await _send('PUT', path, body: resource.toJson());
    return Resource.fromJson(data);
  }

  /// DELETE /api/resources/{id} (409 if the resource has bookings)
  Future<void> deleteResource(int id) async {
    await _send('DELETE', '/resources/$id');
  }

  /// GET /api/resources/available?start=...&end=...
  Future<List<Resource>> getAvailableResources({
    required DateTime start,
    required DateTime end,
    String? type,
    int? minCapacity,
  }) async {
    final query = <String, String>{
      'start': formatDateTime(start),
      'end': formatDateTime(end),
    };
    if (type != null) query['type'] = type;
    if (minCapacity != null) query['minCapacity'] = '$minCapacity';
    final data =
        await _send('GET', '/resources/available', query: query) as List;
    return data.map((item) => Resource.fromJson(item)).toList();
  }

  // ------------------------------------------------------------------
  // Members
  // ------------------------------------------------------------------

  /// GET /api/members
  Future<List<Member>> getMembers() async {
    final data = await _send('GET', '/members') as List;
    return data.map((item) => Member.fromJson(item)).toList();
  }

  /// POST /api/members (409 if the email already exists)
  Future<Member> createMember(Member member) async {
    final data = await _send('POST', '/members', body: member.toJson());
    return Member.fromJson(data);
  }

  /// PUT /api/members/{id} (409 if another member already has the email)
  Future<Member> updateMember(int id, Member member) async {
    final data = await _send('PUT', '/members/$id', body: member.toJson());
    return Member.fromJson(data);
  }

  /// GET /api/members/{id}/bookings
  Future<List<Booking>> getMemberBookings(int memberId) async {
    final data = await _send('GET', '/members/$memberId/bookings') as List;
    return data.map((item) => Booking.fromJson(item)).toList();
  }

  // ------------------------------------------------------------------
  // Bookings
  // ------------------------------------------------------------------

  /// GET /api/bookings
  Future<List<Booking>> getBookings() async {
    final data = await _send('GET', '/bookings') as List;
    return data.map((item) => Booking.fromJson(item)).toList();
  }

  /// POST /api/bookings
  /// The backend checks all booking rules and calculates the total cost.
  Future<Booking> createBooking({
    required int memberId,
    required int resourceId,
    required DateTime start,
    required DateTime end,
    required int attendees,
  }) async {
    final data = await _send('POST', '/bookings', body: {
      'memberId': memberId,
      'resourceId': resourceId,
      'startDateTime': formatDateTime(start),
      'endDateTime': formatDateTime(end),
      'attendees': attendees,
    });
    return Booking.fromJson(data);
  }

  /// PUT /api/bookings/{id}
  Future<Booking> updateBooking({
    required int bookingId,
    required int memberId,
    required int resourceId,
    required DateTime start,
    required DateTime end,
    required int attendees,
  }) async {
    final data = await _send('PUT', '/bookings/$bookingId', body: {
      'memberId': memberId,
      'resourceId': resourceId,
      'startDateTime': formatDateTime(start),
      'endDateTime': formatDateTime(end),
      'attendees': attendees,
    });
    return Booking.fromJson(data);
  }

  /// PUT /api/bookings/{id}/cancel
  Future<Booking> cancelBooking(int bookingId) async {
    final data = await _send('PUT', '/bookings/$bookingId/cancel');
    return Booking.fromJson(data);
  }

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------

  /// Formats a date as the backend expects: 2026-12-01T10:00:00
  static String formatDateTime(DateTime dateTime) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dateTime.year}-${two(dateTime.month)}-${two(dateTime.day)}'
        'T${two(dateTime.hour)}:${two(dateTime.minute)}:${two(dateTime.second)}';
  }

  /// Sends one request and returns the decoded JSON (or null when empty).
  /// Throws an [ApiException] with a user-friendly message on any error.
  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: (query == null || query.isEmpty) ? null : query,
    );

    final http.Response response;
    try {
      final request = http.Request(method, uri);
      if (body != null) {
        request.headers.addAll(_jsonHeaders);
        request.body = jsonEncode(body);
      }
      response = await http.Response.fromStream(await _client.send(request));
    } on SocketException {
      throw ApiException(
          'Cannot reach the server. Please check that the backend is running.');
    } on http.ClientException {
      throw ApiException(
          'Cannot reach the server. Please check that the backend is running.');
    }

    final text = utf8.decode(response.bodyBytes);
    final decoded = text.isEmpty ? null : _tryDecode(text);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    // The backend sends errors as {"status":409,"error":"Conflict","message":"..."}
    final message = (decoded is Map && decoded['message'] is String)
        ? decoded['message'] as String
        : 'Request failed (HTTP ${response.statusCode}).';
    throw ApiException(message, statusCode: response.statusCode);
  }

  dynamic _tryDecode(String text) {
    try {
      return jsonDecode(text);
    } on FormatException {
      return null;
    }
  }
}