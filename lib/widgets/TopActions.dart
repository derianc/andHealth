// lib/widgets/top_actions.dart
import 'package:flutter/material.dart';

class TopActions extends StatelessWidget {
  final VoidCallback onScan;
  final VoidCallback onEnterManual;

  const TopActions({
    super.key,
    required this.onScan,
    required this.onEnterManual,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan Prescription'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton.icon(
              onPressed: onEnterManual,
              icon: const Icon(Icons.edit_note),
              label: const Text('Enter Manually'),
            ),
          ),
        ],
      ),
    );
  }
}
