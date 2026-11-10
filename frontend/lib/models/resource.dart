/// A bookable resource: a meeting room or a desk.
///
/// Matches the JSON returned by the backend, for example:
/// {"id":1,"name":"Boardroom","location":"Floor 2","capacity":10,
///  "hourlyRate":80.00,"status":"ACTIVE","resourceType":"MEETING_ROOM",
///  "hasProjector":true,"hasVideoConference":true}
class Resource {
  final int? id;
  final String name;
  final String location;
  final int capacity;
  final double hourlyRate;
  final String status; // "ACTIVE" or "OUT_OF_SERVICE"
  final String resourceType; // "MEETING_ROOM" or "DESK"

  // Meeting room only (null for desks)
  final bool? hasProjector;
  final bool? hasVideoConference;

  // Desk only (null for meeting rooms): "HOT_DESK", "DEDICATED_DESK", "STANDING_DESK"
  final String? deskType;

  Resource({
    this.id,
    required this.name,
    required this.location,
    required this.capacity,
    required this.hourlyRate,
    required this.status,
    required this.resourceType,
    this.hasProjector,
    this.hasVideoConference,
    this.deskType,
  });

  bool get isMeetingRoom => resourceType == 'MEETING_ROOM';
  bool get isDesk => resourceType == 'DESK';
  bool get isActive => status == 'ACTIVE';

  /// Builds a Resource from the backend JSON.
  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      id: json['id'] as int?,
      name: json['name'] as String,
      location: json['location'] as String,
      capacity: json['capacity'] as int,
      hourlyRate: (json['hourlyRate'] as num).toDouble(),
      status: json['status'] as String,
      resourceType: json['resourceType'] as String,
      hasProjector: json['hasProjector'] as bool?,
      hasVideoConference: json['hasVideoConference'] as bool?,
      deskType: json['deskType'] as String?,
    );
  }

  /// Builds the JSON body for creating or updating a resource.
  /// The id and resourceType are not sent: the URL decides them.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name,
      'location': location,
      'capacity': capacity,
      'hourlyRate': hourlyRate,
      'status': status,
    };
    if (isMeetingRoom) {
      json['hasProjector'] = hasProjector ?? false;
      json['hasVideoConference'] = hasVideoConference ?? false;
    } else {
      json['deskType'] = deskType ?? 'HOT_DESK';
    }
    return json;
  }
}