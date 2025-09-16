import 'package:cloud_firestore/cloud_firestore.dart';

abstract class UserModel {
  final String uid;
  final String email;
  final String role;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson();
  
  factory UserModel.fromJson(Map<String, dynamic> json, String uid) {
    final role = json['role'] as String;
    switch (role) {
      case 'admin':
        return AdminModel.fromJson(json, uid);
      case 'consumer':
        return ConsumerModel.fromJson(json, uid);
      default:
        throw ArgumentError('Unknown role: $role');
    }
  }
}

class AdminModel extends UserModel {
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? profileImageUrl;
  final List<String> permissions;
  final bool isActive;

  const AdminModel({
    required super.uid,
    required super.email,
    required super.role,
    required super.createdAt,
    super.updatedAt,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.profileImageUrl,
    this.permissions = const ['read', 'write', 'admin'],
    this.isActive = true,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'permissions': permissions,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory AdminModel.fromJson(Map<String, dynamic> json, String uid) {
    return AdminModel(
      uid: uid,
      email: json['email'] as String,
      role: json['role'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      permissions: List<String>.from(json['permissions'] ?? ['read', 'write', 'admin']),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: json['updatedAt'] != null ? (json['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  AdminModel copyWith({
    String? uid,
    String? email,
    String? role,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? profileImageUrl,
    List<String>? permissions,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      permissions: permissions ?? this.permissions,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ConsumerModel extends UserModel {
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? profileImageUrl;
  final DateTime? dateOfBirth;
  final String? address;
  final String? emergencyContact;
  final String? emergencyPhone;
  final Map<String, dynamic> preferences;
  final bool isActive;
  final String? membershipType;
  final DateTime? membershipStartDate;

  const ConsumerModel({
    required super.uid,
    required super.email,
    required super.role,
    required super.createdAt,
    super.updatedAt,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.profileImageUrl,
    this.dateOfBirth,
    this.address,
    this.emergencyContact,
    this.emergencyPhone,
    this.preferences = const {},
    this.isActive = true,
    this.membershipType,
    this.membershipStartDate,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'address': address,
      'emergencyContact': emergencyContact,
      'emergencyPhone': emergencyPhone,
      'preferences': preferences,
      'isActive': isActive,
      'membershipType': membershipType,
      'membershipStartDate': membershipStartDate != null ? Timestamp.fromDate(membershipStartDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory ConsumerModel.fromJson(Map<String, dynamic> json, String uid) {
    return ConsumerModel(
      uid: uid,
      email: json['email'] as String,
      role: json['role'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      dateOfBirth: json['dateOfBirth'] != null ? (json['dateOfBirth'] as Timestamp).toDate() : null,
      address: json['address'] as String?,
      emergencyContact: json['emergencyContact'] as String?,
      emergencyPhone: json['emergencyPhone'] as String?,
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
      isActive: json['isActive'] as bool? ?? true,
      membershipType: json['membershipType'] as String?,
      membershipStartDate: json['membershipStartDate'] != null ? (json['membershipStartDate'] as Timestamp).toDate() : null,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: json['updatedAt'] != null ? (json['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  ConsumerModel copyWith({
    String? uid,
    String? email,
    String? role,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? profileImageUrl,
    DateTime? dateOfBirth,
    String? address,
    String? emergencyContact,
    String? emergencyPhone,
    Map<String, dynamic>? preferences,
    bool? isActive,
    String? membershipType,
    DateTime? membershipStartDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConsumerModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      preferences: preferences ?? this.preferences,
      isActive: isActive ?? this.isActive,
      membershipType: membershipType ?? this.membershipType,
      membershipStartDate: membershipStartDate ?? this.membershipStartDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}