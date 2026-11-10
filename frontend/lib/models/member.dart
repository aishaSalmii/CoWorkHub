/// A coworking member who can make bookings.
///
/// Matches the JSON returned by the backend, for example:
/// {"id":1,"fullName":"Sara Ahmed","email":"sara.ahmed@example.com",
///  "phoneNumber":"55510001","createdAt":"2026-11-03T10:58:23.72512"}
class Member {
  final int? id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final DateTime? createdAt;

  Member({
    this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.createdAt,
  });

  /// Builds a Member from the backend JSON.
  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as int?,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Builds the JSON body for creating a member.
  /// The id and createdAt are set by the backend.
  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
    };
  }
}