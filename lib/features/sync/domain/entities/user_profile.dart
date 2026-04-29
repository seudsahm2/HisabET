import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String phoneNumber;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final List<String> roles;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.phoneNumber,
    this.email,
    this.displayName,
    this.photoUrl,
    this.roles = const [],
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      phoneNumber: (json['phone_number'] ?? json['phone'] ?? '') as String,
      email: json['email'] as String?,
      displayName: json['display_name'] ?? json['name'] as String?,
      photoUrl: json['photoUrl'] as String?,
      roles: (json['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(), // Fallback if missing
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber, // Sync with DB representation if needed, though Onboarding uses 'phone'
      'phone': phoneNumber,
      'email': email,
      'display_name': displayName,
      'name': displayName,
      'photoUrl': photoUrl,
      'roles': roles,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, phoneNumber, email, displayName, photoUrl, roles, createdAt];
}
