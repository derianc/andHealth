import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:andhealth/services/auth_service.dart';
import 'home_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _loading = false;
  String _version = "";

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = "v${info.version}+${info.buildNumber}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: _authService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          return _buildLoginUI();
        },
      ),
    );
  }

  Widget _buildLoginUI() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0F2027), // dark blue-gray
            Color(0xFF203A43), // slate blue
            Color(0xFF2C5364), // teal-blue
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(), // spacer for top

            // Center content
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Company Logo
                Image.asset(
                  "assets/AndHealth.png",
                  height: 120,
                ),
                const SizedBox(height: 24),
                // Text below logo
                const Text(
                  "Welcome to AndHealth\nYour partner in better health outcomes",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white, // white text on gradient
                  ),
                ),
                const SizedBox(height: 40),

                // Divider for social login
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: const [
                      Expanded(child: Divider(color: Colors.white70, thickness: 1)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          "continue with",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.white70, thickness: 1)),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Google login button
                _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.grey),
                          ),
                        ),
                        icon: Image.asset("assets/google.png", height: 24),
                        label: const Text("Sign in with Google"),
                        onPressed: () async {
                          setState(() => _loading = true);
                          await _authService.signInWithGoogle(context);
                          setState(() => _loading = false);
                        },
                      ),
              ],
            ),

            // Footer pinned at bottom
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                _version,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
