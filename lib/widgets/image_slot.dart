import 'dart:io';

import 'package:flutter/material.dart';

Widget ImageSlot({
    required String label,
    required File? file,
    required VoidCallback onCapture,
    required VoidCallback onClear,
  }) {
    return Expanded(
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: file != null
                  ? Image.file(file, fit: BoxFit.cover)
                  : const Center(child: Text("No image")),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCapture,
                  icon: const Icon(Icons.camera_alt),
                  label: Text("Scan $label"),
                ),
              ),
              const SizedBox(width: 8),
              if (file != null)
                IconButton(
                  tooltip: "Clear $label",
                  onPressed: onClear,
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
        ],
      ),
    );
  }