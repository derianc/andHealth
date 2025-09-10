// lib/prescriptions_screen.dart
import 'package:andhealth/models/prescription_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/prescription_provider.dart';
import 'providers/user_provider.dart';

class PrescriptionsScreen extends StatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  bool _showActive = true;
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    // Load prescriptions once, cache in provider, and prebuild calendar events.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = context.read<UserProvider>().user;
      if (user == null) return;

      final pp = context.read<PrescriptionProvider>();
      if (!pp.isLoaded) {
        await pp.loadPrescriptions(user.id);
        await pp.ensureEventsBuilt(); // keep Calendar in sync
      }
    });
  }

  // ——— Provider-backed actions ———
  Future<void> _refresh() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;
    final pp = context.read<PrescriptionProvider>();
    await pp.refreshPrescriptions(user.id);
    await pp.ensureEventsBuilt();
  }

  Future<void> _toggleActive(Prescription p, bool value) async {
    await context.read<PrescriptionProvider>().toggleActive(p.id, value);
    // ensureEventsBuilt is called inside provider after changes
  }

  Future<void> _saveEdit(
    Prescription p, {
    required String name,
    required String dosage,
    required String frequency,
    required bool isActive,
    String? notes,
  }) async {
    await context.read<PrescriptionProvider>().updatePrescriptionFields(
          p.id,
          name: name,
          dosage: dosage,
          frequency: frequency,
          isActive: isActive,
          notes: notes,
        );
  }

  Future<void> _addPrescriptionManual({
    required String name,
    required String dosage,
    required String frequency,
    required bool isActive,
    String? notes,
  }) async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;

    final newRx = Prescription(
      id: 'temp', // will be replaced by Firestore doc.id in provider.addPrescription
      userId: user.id,
      name: name,
      dosage: dosage,
      frequency: frequency,
      isActive: isActive,
      notes: notes,
      createdAt: DateTime.now(),
    );

    await context.read<PrescriptionProvider>().addPrescription(newRx);
  }

  Future<void> _deletePrescription(Prescription p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete prescription?'),
        content: Text('This will remove "${p.name}". You can’t undo this.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await context.read<PrescriptionProvider>().deletePrescription(p.id);
    }
  }

  // ——— UI helpers: Add/Edit sheets ———
  void _openAddSheet() {
    _openEditOrAddSheet(
      mode: _EditMode.add,
      onSubmit: (name, dosage, frequency, isActive, notes) async {
        await _addPrescriptionManual(
          name: name,
          dosage: dosage,
          frequency: frequency,
          isActive: isActive,
          notes: notes,
        );
      },
    );
  }

  void _openEditSheet(Prescription p) {
    _openEditOrAddSheet(
      mode: _EditMode.edit,
      initial: p,
      onSubmit: (name, dosage, frequency, isActive, notes) async {
        await _saveEdit(
          p,
          name: name,
          dosage: dosage,
          frequency: frequency,
          isActive: isActive,
          notes: notes,
        );
      },
      onDelete: () => _deletePrescription(p),
    );
  }

  void _openEditOrAddSheet({
    required _EditMode mode,
    Prescription? initial,
    required Future<void> Function(
      String name,
      String dosage,
      String frequency,
      bool isActive,
      String? notes,
    ) onSubmit,
    Future<void> Function()? onDelete,
  }) {
    final nameCtrl = TextEditingController(text: initial?.name ?? '');
    final dosageCtrl = TextEditingController(text: initial?.dosage ?? '');
    final frequencyCtrl = TextEditingController(text: initial?.frequency ?? '');
    final notesCtrl = TextEditingController(text: initial?.notes ?? '');
    bool isActive = initial?.isActive ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 8,
          ),
          child: StatefulBuilder(
            builder: (ctx, setModal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    mode == _EditMode.add ? 'Add Prescription' : 'Edit Prescription',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dosageCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Dosage',
                      hintText: 'e.g. 500mg',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: frequencyCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Frequency',
                      hintText: 'e.g. twice daily',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Active'),
                    value: isActive,
                    onChanged: (v) => setModal(() => isActive = v),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (mode == _EditMode.edit && onDelete != null)
                        TextButton.icon(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await onDelete();
                          },
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          label: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          final dosage = dosageCtrl.text.trim();
                          final frequency = frequencyCtrl.text.trim();
                          final notes = notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim();

                          if (name.isEmpty || dosage.isEmpty || frequency.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Name, dosage, and frequency are required')),
                            );
                            return;
                          }

                          Navigator.pop(ctx);
                          await onSubmit(name, dosage, frequency, isActive, notes);
                        },
                        child: Text(mode == _EditMode.add ? 'Add' : 'Save'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // ——— Top action buttons (Scan / Enter manually) ———
  Widget _topActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Navigate to your scanner flow
                // Navigator.pushNamed(context, '/scanPrescription');
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan Prescription'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton.icon(
              onPressed: _openAddSheet,
              icon: const Icon(Icons.edit_note),
              label: const Text('Enter Manually'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<PrescriptionProvider>();

    final active = pp.prescriptions.where((p) => p.isActive).toList();
    final inactive = pp.prescriptions.where((p) => !p.isActive).toList();

    return Scaffold(
      body: !pp.isLoaded
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                children: [
                  _topActions(), // ← moved actions to the top
                  _buildSection(
                    context: context,
                    title: 'Active Prescriptions',
                    items: active,
                    isExpanded: _showActive,
                    toggle: () => setState(() => _showActive = !_showActive),
                  ),
                  _buildSection(
                    context: context,
                    title: 'Inactive Prescriptions',
                    items: inactive,
                    isExpanded: _showInactive,
                    toggle: () => setState(() => _showInactive = !_showInactive),
                  ),
                ],
              ),
            ),
      // No FAB now — actions live at the top
    );
  }

  /// Expansion section with ListTiles; tap to edit; long-press to delete; trailing switch for active
  Widget _buildSection({
    required BuildContext context,
    required String title,
    required List<Prescription> items,
    required bool isExpanded,
    required VoidCallback toggle,
  }) {
    return Card(
      color: Colors.white.withOpacity(0.9),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        initiallyExpanded: isExpanded,
        onExpansionChanged: (_) => toggle(),
        children: items.map((p) {
          return ListTile(
            title: Text(p.name),
            subtitle: Text('${p.dosage} • ${p.frequency}'),
            trailing: Switch(
              value: p.isActive,
              onChanged: (val) => _toggleActive(p, val),
            ),
            onTap: () => _openEditSheet(p),
            onLongPress: () => _deletePrescription(p),
          );
        }).toList(),
      ),
    );
  }
}

enum _EditMode { add, edit }
