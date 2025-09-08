import 'package:andhealth/models/user_model.dart';
import 'package:andhealth/providers/user_provider.dart';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

class AuthService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final fb.User? user = userCredential.user;

      if (user != null && context.mounted) {
        // Save into your provider
        final userModel = UserModel(
          id: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? '',
          photoUrl: user.photoURL ?? '',
        );

        Provider.of<UserProvider>(context, listen: false).setUser(userModel);

        // Navigate to home
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      print("❌ Google Sign-In error: $e");
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }

  UserModel? getCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) return null;

    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      photoUrl: user.photoURL ?? '',
    );
  }

  Stream<fb.User?> get authStateChanges => _auth.authStateChanges();
}
