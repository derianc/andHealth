import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Example prescriptions
  List<String> activePrescriptions = [
    "Atorvastatin 10mg",
    "Lisinopril 20mg",
  ];

  List<String> inactivePrescriptions = [
    "Metformin 500mg",
  ];

  bool _showActive = true;
  bool _showInactive = false;

  void _editPrescription(List<String> list, int index) async {
    final controller = TextEditingController(text: list[index]);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Prescription"),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        list[index] = result;
      });
    }
  }

  void _showFabOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.qr_code_scanner),
                title: const Text("Scan Prescription"),
                onTap: () {
                  Navigator.pop(ctx);
                  // TODO: Navigate to scanner
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_note),
                title: const Text("Enter Prescription Manually"),
                onTap: () {
                  Navigator.pop(ctx);
                  // TODO: Navigate to manual entry
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, List<String> items, bool isExpanded, VoidCallback toggle) {
    return Card(
      color: Colors.white.withOpacity(0.9),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        initiallyExpanded: isExpanded,
        onExpansionChanged: (_) => toggle(),
        children: items.map((item) {
          final index = items.indexOf(item);
          return ListTile(
            title: Text(item),
            trailing: IconButton(
              icon: const Icon(Icons.edit, color: Colors.deepPurple),
              onPressed: () => _editPrescription(items, index),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          title: const Text("My Prescriptions"),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: ListView(
          children: [
            _buildSection(
              "Active Prescriptions",
              activePrescriptions,
              _showActive,
              () => setState(() => _showActive = !_showActive),
            ),
            _buildSection(
              "Inactive Prescriptions",
              inactivePrescriptions,
              _showInactive,
              () => setState(() => _showInactive = !_showInactive),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showFabOptions,
          backgroundColor: Colors.deepPurple,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
