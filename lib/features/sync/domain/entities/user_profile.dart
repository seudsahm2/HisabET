import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String phoneNumber;
  final String? displayName;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.phoneNumber,
    this.displayName,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      phoneNumber: json['phone_number'] as String,
      displayName: json['display_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'display_name': displayName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, phoneNumber, displayName, createdAt];
}
