import 'package:cloud_firestore/cloud_firestore.dart';

class Prescription {
  final String id;
  final String userId;
  final String name;
  final String dosage;
  final String frequency;
  final String? notes;
  final bool isActive;
  final DateTime? createdAt;

  Prescription({
    required this.id,
    required this.userId,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.notes,
    required this.isActive,
    this.createdAt,
  });

  factory Prescription.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Prescription(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      dosage: data['dosage'] ?? '',
      frequency: data['frequency'] ?? '',
      isActive: data['isActive'] ?? true,
      notes: data['notes'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }
}
