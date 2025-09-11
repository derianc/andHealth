import 'package:flutter/material.dart';

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String photoUrl;
  final TimeOfDay startOfDay;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.startOfDay,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    final startOfDayStr = data['startOfDay'] as String? ?? "07:00";
    final parts = startOfDayStr.split(":");
    final hour = int.tryParse(parts[0]) ?? 7;
    final minute = int.tryParse(parts[1]) ?? 0;

    return UserModel(
      id: id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      startOfDay: TimeOfDay(hour: hour, minute: minute),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'startOfDay':
          "${startOfDay.hour.toString().padLeft(2, '0')}:${startOfDay.minute.toString().padLeft(2, '0')}",
    };
  }
}
