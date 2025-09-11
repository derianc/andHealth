import 'package:andhealth/home_screen.dart';
import 'package:andhealth/models/user_model.dart';
import 'package:andhealth/providers/user_provider.dart';

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
      final userModel = UserModel(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        photoUrl: user.photoURL ?? '',
      );

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
