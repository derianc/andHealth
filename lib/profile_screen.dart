import 'package:andhealth/login_screen.dart';
import 'package:andhealth/providers/prescription_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/auth_service.dart';
import 'providers/user_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  

  Future<void> _pickStartOfDay(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: userProvider.startOfDay,
    );
    if (picked != null) {
      userProvider.setStartOfDay(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final prescriptionProvider = Provider.of<PrescriptionProvider>(context);
    
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

            // start day
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text("Start of Day"),
              subtitle: Text(userProvider.startOfDay.format(context)),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _pickStartOfDay(context),
              ),
            ),

            const Spacer(),
            const Spacer(),
            SafeArea(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final rootNav = Navigator.of(context, rootNavigator: true);
                  
                  await AuthService().signOut();
                  userProvider.logout();
                  prescriptionProvider.clear();

                   Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
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
                            .solid, 
                      ),
                    )
              ),
            ),

          ],
        ),
      ),
    );
  }
}
