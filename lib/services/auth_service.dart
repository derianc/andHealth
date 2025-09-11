import 'package:andhealth/home_screen.dart';
import 'package:andhealth/models/user_model.dart';
import 'package:andhealth/providers/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;

  Future<void> signInWithGoogle(BuildContext context) async {
  try {
    fb.User? user;

    if (kIsWeb) {
      // ---- Web: Use popup flow ----
      final provider = fb.GoogleAuthProvider();
      final userCredential = await fb.FirebaseAuth.instance.signInWithPopup(provider);
      user = userCredential.user;
    } else {
      // ---- Mobile: Use google_sign_in plugin ----
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await fb.FirebaseAuth.instance.signInWithCredential(credential);
      user = userCredential.user;
    }

    if (user != null && context.mounted) {
        final docRef = FirebaseFirestore.instance
            .collection("profiles")
            .doc(user.uid);
        final doc = await docRef.get();

        UserModel userModel;

        if (doc.exists) {
          userModel = UserModel.fromFirestore(doc.data()!, doc.id);
        } else {
          // Create profile if missing
          userModel = UserModel(
            id: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? '',
            photoUrl: user.photoURL ?? '',
            startOfDay: const TimeOfDay(hour: 7, minute: 0),
          );
          await docRef.set(userModel.toFirestore());
        }

        Provider.of<UserProvider>(context, listen: false).setUser(userModel);

        // Navigate to home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
  } catch (e) {
    print("❌ Google Sign-In error: $e");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google Sign-In failed: $e")),
      );
    }
  }
}

  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }

  Future <UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
      .collection("profiles")
      .doc(user.uid)
      .get();

    final startOfDay = doc["startOfDay"];

  if (!doc.exists) return null;

    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      photoUrl: user.photoURL ?? '',
      startOfDay: startOfDay
    );
  }

  Stream<fb.User?> get authStateChanges => _auth.authStateChanges();
}
