import 'package:andhealth/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class AddPrescriptionPage extends StatefulWidget {
  final DocumentSnapshot? prescription; // optional for edit

  const AddPrescriptionPage({super.key, this.prescription});

  @override
  State<AddPrescriptionPage> createState() => _AddPrescriptionPageState();
}

class _AddPrescriptionPageState extends State<AddPrescriptionPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.prescription != null) {
      final data = widget.prescription!.data() as Map<String, dynamic>;
      _nameController.text = data['name'] ?? '';
      _dosageController.text = data['dosage'] ?? '';
      _frequencyController.text = data['frequency'] ?? '';
    }
  }

  Future<void> _savePrescription() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = context.read<UserProvider>().user;

      if (widget.prescription == null) {
        // 🔹 Create new
        await FirebaseFirestore.instance.collection("prescriptions").add({
          "name": _nameController.text.trim(),
          "dosage": _dosageController.text.trim(),
          "frequency": _frequencyController.text.trim(),
          "createdAt": FieldValue.serverTimestamp(),
          "isActive": true,
          "userId": user?.id
        });
      } else {
        // 🔹 Update existing
        await FirebaseFirestore.instance
            .collection("prescriptions")
            .doc(widget.prescription!.id)
            .update({
          "name": _nameController.text.trim(),
          "dosage": _dosageController.text.trim(),
          "frequency": _frequencyController.text.trim(),
        });
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving prescription: $e")),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.prescription != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? "Edit Prescription" : "Add Prescription")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Prescription Name"),
                validator: (val) => val == null || val.isEmpty ? "Enter a name" : null,
              ),
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(labelText: "Dosage"),
              ),
              TextFormField(
                controller: _frequencyController,
                decoration: const InputDecoration(labelText: "Frequency"),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _savePrescription,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(isEdit ? "Update Prescription" : "Save Prescription"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
