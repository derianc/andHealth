import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/auth_service.dart';
import 'providers/user_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 50,
              backgroundImage: user?.photoUrl != null
                  ? NetworkImage(user!.photoUrl)
                  : null,
              child: user?.photoUrl == null
                  ? const Icon(Icons.person, size: 50)
                  : null,
            ),
            const SizedBox(height: 20),

            // Display Name
            Text(
              user?.displayName ?? "No Name",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Email
            Text(
              user?.email ?? "No Email",
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const Spacer(),
            SafeArea(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await AuthService().signOut();
                  userProvider.logout();

                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (Route<dynamic> route) => false,
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.red),
                ),
                style:
                    OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      side: const BorderSide(
                        color: Colors.red,
                        width: 1.5,
                        style: BorderStyle
                            .solid, // Flutter doesn't support dotted natively
                      ),
                    ).copyWith(
                      // 👇 Hacky way to simulate dotted by using dashed border in decoration
                      side: MaterialStateProperty.all(
                        const BorderSide(
                          color: Colors.red,
                          width: 1.5,
                          style: BorderStyle.solid,
                        ),
                      ),
                    ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
