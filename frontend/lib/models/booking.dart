import 'member.dart';
import 'resource.dart';

/// A booking of one resource by one member for a time interval.
///
/// Matches the JSON returned by the backend: the booking includes
/// the full member and resource objects.
class Booking {
  final int id;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final int attendees;
  final String status; // "CONFIRMED" or "CANCELLED"
  final double totalCost;
  final Member member;
  final Resource resource;

  Booking({
    required this.id,
    required this.startDateTime,
    required this.endDateTime,
    required this.attendees,
    required this.status,
    required this.totalCost,
    required this.member,
    required this.resource,
  });

  bool get isCancelled => status == 'CANCELLED';

  /// A booking is "past" when it has already ended.
  bool get isPast => endDateTime.isBefore(DateTime.now());

  /// Builds a Booking from the backend JSON.
  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as int,
      startDateTime: DateTime.parse(json['startDateTime'] as String),
      endDateTime: DateTime.parse(json['endDateTime'] as String),
      attendees: json['attendees'] as int,
      status: json['status'] as String,
      totalCost: (json['totalCost'] as num? ?? 0).toDouble(),
      member: Member.fromJson(json['member'] as Map<String, dynamic>),
      resource: Resource.fromJson(json['resource'] as Map<String, dynamic>),
    );
  }
}