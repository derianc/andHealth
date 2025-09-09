import 'package:andhealth/add_prescription_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PrescriptionsScreen extends StatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  bool _showActive = true;
  bool _showInactive = false;

  Widget _buildSection(
    String title,
    List<DocumentSnapshot> docs,
    bool isExpanded,
    VoidCallback toggle,
  ) {
    return Card(
      color: Colors.white.withOpacity(0.9),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        initiallyExpanded: isExpanded,
        onExpansionChanged: (_) => toggle(),
        children: docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final name = data['name'] as String? ?? "Unnamed";

          return ListTile(
            title: Text(name),
            trailing: IconButton(
              icon: const Icon(Icons.edit, color: Colors.deepPurple),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddPrescriptionPage(prescription: doc),
                  ),
                ).then((saved) {
                  if (saved == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Prescription updated successfully"),
                      ),
                    );
                  }
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0F2027), // dark blue-gray
            Color(0xFF203A43), // slate blue
            Color(0xFF2C5364), // teal-blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              tooltip: "Scan Prescription",
              onPressed: () {
                // TODO: Replace with your scan logic
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Scan prescription tapped")),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit_note),
              tooltip: "Enter Prescription Manually",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddPrescriptionPage(),
                  ),
                ).then((saved) {
                  if (saved == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Prescription added successfully"),
                      ),
                    );
                  }
                });
              },
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("prescriptions")
              .where("userId", isEqualTo: user?.uid)
              .orderBy("createdAt", descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No prescriptions found"));
            }

            final activeDocs = snapshot.data!.docs
                .where((doc) => (doc['isActive'] ?? true) == true)
                .toList();

            final inactiveDocs = snapshot.data!.docs
                .where((doc) => (doc['isActive'] ?? true) == false)
                .toList();

            return ListView(
              children: [
                _buildSection(
                  "Active Prescriptions",
                  activeDocs,
                  _showActive,
                  () => setState(() => _showActive = !_showActive),
                ),
                _buildSection(
                  "Inactive Prescriptions",
                  inactiveDocs,
                  _showInactive,
                  () => setState(() => _showInactive = !_showInactive),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
