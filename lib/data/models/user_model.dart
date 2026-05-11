import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final DateTime createdAt;
  final int criteria;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.createdAt,
    this.criteria = 75,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      criteria: map['criteria'] ?? 75,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
      'criteria': criteria,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    DateTime? createdAt,
    int? criteria,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      criteria: criteria ?? this.criteria,
    );
  }
}
