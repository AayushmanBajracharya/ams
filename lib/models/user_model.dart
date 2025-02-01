// models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String username;
  final String email;
  final String role;
  final DateTime createdAt;
  final String? department;
  final String? faculty;

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    required this.role,
    required this.createdAt,
    this.department,
    this.faculty,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'department': department,
      'faculty': faculty,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      department: map['department'],
      faculty: map['faculty'],
    );
  }
}
