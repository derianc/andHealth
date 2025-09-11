import 'package:andhealth/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  TimeOfDay startOfDay = const TimeOfDay(hour: 7, minute: 0);

  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;

  void setUser(UserModel? user) {
    _user = user;
    if (user != null) {
      startOfDay = user.startOfDay; // keep provider in sync
    }
    notifyListeners();
  }

  void logout() {
    _user = null;
    notifyListeners();
  }

  Future<void> setStartOfDay(TimeOfDay time) async {
    startOfDay = time;
    notifyListeners();

    if (_user != null) {
      final startOfDayStr =
          "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";

      await FirebaseFirestore.instance
          .collection("profiles")
          .doc(_user!.id)
          .update({"startOfDay": startOfDayStr});

      // also update local _user model so everything stays consistent
      _user = UserModel(
        id: _user!.id,
        email: _user!.email,
        displayName: _user!.displayName,
        photoUrl: _user!.photoUrl,
        startOfDay: time,
      );
      notifyListeners();
    }
  }
}