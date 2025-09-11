// providers/prescription_provider.dart
import 'dart:async';
import 'package:andhealth/models/prescription_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import '../models/medication_event.dart';
import '../services/PrescriptionScheduleService.dart';

class PrescriptionProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _schedule = PrescriptionScheduleService();

  List<Prescription> _prescriptions = [];
  bool _loaded = false;

  Map<DateTime, List<MedicationEvent>> _events = {};
  bool _eventsBuilt = false;
  bool _isBuildingEvents = false;
  String _eventsSignature = '';

  List<Prescription> get prescriptions => _prescriptions;
  bool get isLoaded => _loaded;
  Map<DateTime, List<MedicationEvent>> get events => _events;
  bool get isBuildingEvents => _isBuildingEvents;

  Future<void> loadPrescriptions(String userId) async {
    if (_loaded) return;
    final snap = await _firestore
        .collection('prescriptions')
        .where('userId', isEqualTo: userId)
        .get();

    _prescriptions = snap.docs.map((d) => Prescription.fromDoc(d)).toList();
    _loaded = true;
    _eventsBuilt = false;
    notifyListeners();
  }

  Future<void> refreshPrescriptions(String userId) async {
    final snap = await _firestore
        .collection('prescriptions')
        .where('userId', isEqualTo: userId)
        .get();

    _prescriptions = snap.docs.map((d) => Prescription.fromDoc(d)).toList();
    _loaded = true;
    _eventsBuilt = false;
    notifyListeners();
  }

  void clear() {
    _prescriptions = [];
    _loaded = false;
    _events.clear();
    _eventsBuilt = false;
    _eventsSignature = '';
    notifyListeners();
  }

  // prescription caching
  Future<void> ensureEventsBuilt() async {
    if (!_loaded) return;
    final sig = _computeSignature();
    if (_eventsBuilt && sig == _eventsSignature) return;

    _isBuildingEvents = true;
    notifyListeners();

final fbUser = fb.FirebaseAuth.instance.currentUser;
      final doc = await FirebaseFirestore.instance
        .collection("profiles")
        .doc(fbUser?.uid)
        .get();

    // Default to 7:00 if not found
    String startOfDayStr = "07:00";
    if (doc.exists && doc.data()?["startOfDay"] != null) {
      startOfDayStr = doc["startOfDay"];
    }

    final built = await _schedule.getCalendarEvents(_prescriptions, startOfDayStr);
    _events = built;
    _eventsSignature = sig;
    _eventsBuilt = true;
    _isBuildingEvents = false;
    notifyListeners();
  }

  String _computeSignature() {
    return _prescriptions
        .where((p) => p.isActive)
        .map((p) => '${p.id}|${p.name}|${p.dosage}|${p.frequency}|${p.isActive}')
        .join(';');
  }

  // prescription CRUD operations
  Future<void> updatePrescriptionFields(
    String id, {
    String? name,
    String? dosage,
    String? frequency,
    bool? isActive,
    String? notes,
  }) async {
    final data = <String, dynamic>{
      if (name != null) 'name': name,
      if (dosage != null) 'dosage': dosage,
      if (frequency != null) 'frequency': frequency,
      if (isActive != null) 'isActive': isActive,
      if (notes != null) 'notes': notes,
    };

    await _firestore.collection('prescriptions').doc(id).update(data);

    // Update local cache so UI reacts instantly
    final idx = _prescriptions.indexWhere((p) => p.id == id);
    if (idx != -1) {
      final current = _prescriptions[idx];
      _prescriptions[idx] = Prescription(
        id: current.id,
        userId: current.userId,
        name: name ?? current.name,
        dosage: dosage ?? current.dosage,
        frequency: frequency ?? current.frequency,
        notes: notes ?? current.notes,
        isActive: isActive ?? current.isActive,
        createdAt: current.createdAt,
      );
    }

    _eventsBuilt = false; // schedule inputs may have changed
    notifyListeners();
    await ensureEventsBuilt(); // rebuild once
  }

  Future<void> toggleActive(String id, bool value) async {
    await updatePrescriptionFields(id, isActive: value);
  }

  Future<void> addPrescription(Prescription p) async {
    final doc = await _firestore.collection('prescriptions').add(p.toMap());
    _prescriptions.add(Prescription(
      id: doc.id,
      userId: p.userId,
      name: p.name,
      dosage: p.dosage,
      frequency: p.frequency,
      notes: p.notes,
      isActive: p.isActive,
      createdAt: p.createdAt,
    ));
    _eventsBuilt = false;
    notifyListeners();
    await ensureEventsBuilt();
  }

  Future<void> deletePrescription(String id) async {
    await _firestore.collection('prescriptions').doc(id).delete();
    _prescriptions.removeWhere((p) => p.id == id);
    _eventsBuilt = false;
    notifyListeners();
    await ensureEventsBuilt();
  }
}
