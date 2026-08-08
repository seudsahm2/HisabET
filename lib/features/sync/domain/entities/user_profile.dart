import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String phoneNumber;

  /// Phone number the user supplied but has *not* verified. Display only —
  /// never used for identity matching. See ProfileSetupScreen for why.
  final String? contactPhone;
  final bool phoneVerified;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final List<String> roles;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.phoneNumber,
    this.contactPhone,
    this.phoneVerified = false,
    this.email,
    this.displayName,
    this.photoUrl,
    this.roles = const [],
    required this.createdAt,
  });

  /// Parses a `users/{uid}` document.
  ///
  /// Deliberately defensive: this profile feeds the app shell (greeting header,
  /// profile tab), so a single unexpected field type here blanks the whole UI.
  /// Field shapes genuinely vary across documents — `created_at` is an ISO
  /// string on profiles written by older builds and a Firestore `Timestamp` on
  /// ones written since, and Google sign-in documents may omit `id` entirely.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      phoneNumber:
          (json['phone_number'] ?? json['phone'] ?? '').toString(),
      contactPhone: json['contactPhone']?.toString(),
      phoneVerified: json['phoneVerified'] == true,
      email: json['email']?.toString(),
      displayName:
          (json['display_name'] ?? json['name'])?.toString(),
      photoUrl: json['photoUrl']?.toString(),
      roles: (json['roles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
    );
  }

  /// Accepts a Firestore `Timestamp`, a `DateTime`, an ISO-8601 string, or
  /// epoch milliseconds. Returns `null` when the value is absent or unusable.
  ///
  /// `Timestamp` is handled by duck-typing its `toDate()` rather than importing
  /// `cloud_firestore`, which would drag a data-layer dependency into a domain
  /// entity.
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) return DateTime.tryParse(value);
    try {
      final converted = (value as dynamic).toDate();
      if (converted is DateTime) return converted;
    } catch (_) {
      // Not a Timestamp-like object — fall through.
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'phone': phoneNumber,
      'contactPhone': contactPhone,
      'phoneVerified': phoneVerified,
      'email': email,
      'display_name': displayName,
      'name': displayName,
      'photoUrl': photoUrl,
      'roles': roles,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        phoneNumber,
        contactPhone,
        phoneVerified,
        email,
        displayName,
        photoUrl,
        roles,
        createdAt,
      ];
}
