import 'package:andhealth/home_screen.dart';
import 'package:andhealth/models/user_model.dart';
import 'package:andhealth/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Setup pulse animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // check for logged in user
    _checkUser();
  }

  // check userProvider for existing user session
  // send to home screen if session exists.
  // else send to login screen
  Future<void> _checkUser() async {
    await Future.delayed(const Duration(seconds: 3));

    final fb.User? fbUser = fb.FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (fbUser != null) {
      Provider.of<UserProvider>(context, listen: false).setUser(
        UserModel(
          id: fbUser.uid,
          email: fbUser.email ?? '',
          displayName: fbUser.displayName ?? '',
          photoUrl: fbUser.photoURL ?? '',
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F2027), 
              Color(0xFF203A43), 
              Color(0xFF2C5364), 
            ],
          ),
        ),
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Image.asset(
              'assets/AndHealth_Splash.png',
              width: 120,
              height: 120,
            ),
          ),
        ),
      ),
    );
  }
}
