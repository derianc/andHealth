import 'dart:convert';
import 'dart:io';
import 'package:andhealth/models/prescription_model.dart';
import 'package:andhealth/providers/user_provider.dart';
import 'package:andhealth/widgets/image_slot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../providers/prescription_provider.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  File? _imageFront;
  File? _imageBack;
  bool _loading = false;
  String _responseText = "";

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage({required bool isFront}) async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission denied')),
        );
      }
      return;
    }

    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked == null) return;

    setState(() {
      if (isFront) {
        _imageFront = File(picked.path);
      } else {
        _imageBack = File(picked.path);
      }
      _responseText = "";
    });
  }

  Future<String> _fileToDataUrl(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final isPng = imageFile.path.toLowerCase().endsWith('.png');
    final mime = isPng ? 'image/png' : 'image/jpeg';
    return 'data:$mime;base64,${base64Encode(bytes)}';
    // OpenAI vision accepts data URLs; no need to upload elsewhere.
  }

  Future<void> _analyzeAndSave() async {
    if (_imageFront == null && _imageBack == null) {
      setState(() => _responseText = "Please scan at least one side first.");
      return;
    }

    setState(() {
      _loading = true;
      _responseText = "";
    });

    try {
      final apiKey = dotenv.env['OPENAI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('OPENAI_API_KEY missing in .env');
      }

      final List<Map<String, dynamic>> userContent = [
        {
          "type": "text",
          "text":
              "These are photos of the SAME prescription bottle (front and back). "
              "Use BOTH images to extract and MERGE details. If a field is unclear, use an empty string."
        },
      ];

      if (_imageFront != null) {
        final frontUrl = await _fileToDataUrl(_imageFront!);
        userContent.add({
          "type": "image_url",
          "image_url": {"url": frontUrl}
        });
      }

      if (_imageBack != null) {
        final backUrl = await _fileToDataUrl(_imageBack!);
        userContent.add({
          "type": "image_url",
          "image_url": {"url": backUrl}
        });
      }

      final uri = Uri.parse('https://api.openai.com/v1/chat/completions');

      final payload = {
        "model": "gpt-4o-mini",
        "response_format": {"type": "json_object"},
        "messages": [
          {
            "role": "system",
            "content": [
              {
                "type": "text",
                "text":
                    "You are a medical OCR assistant. Extract prescription details from images. "
                    "Return ONLY JSON with keys: name, dosage, frequency, notes. "
                    "If conflicting info appears across images, prefer the clearest text and combine where appropriate."
              }
            ]
          },
          {
            "role": "user",
            "content": userContent,
          }
        ],
        "temperature": 0,
        "max_tokens": 300
      };

      final res = await http.post(
        uri,
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode(payload),
      );

      if (res.statusCode >= 400) {
        throw Exception("OpenAI error ${res.statusCode}: ${res.body}");
      }

      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      final content =
          (decoded['choices'] as List).first['message']['content'] as String;

      // Parse JSON content
      final Map<String, dynamic> data = jsonDecode(content);

      // Get user id from your UserProvider
      final user = context.read<UserProvider>().user;
      if (user == null) throw Exception("No logged-in user.");

      final prescription = Prescription(
        id: "", // Firestore will assign this in addPrescription
        userId: user.id,
        name: (data["name"] ?? "Unknown").toString(),
        dosage: (data["dosage"] ?? "").toString(),
        frequency: (data["frequency"] ?? "").toString(),
        notes: (data["notes"] ?? "").toString(),
        isActive: true,
        createdAt: DateTime.now(),
      );

      await context.read<PrescriptionProvider>().addPrescription(prescription);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Prescription saved!")),
        );
        Navigator.of(context).pop(true); // back to list screen
      }
    } catch (e) {
      setState(() => _responseText = "Error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  

  @override
  Widget build(BuildContext context) {
    final canAnalyze = _imageFront != null || _imageBack != null;

    return Scaffold(
      appBar: AppBar(title: const Text("Scan Prescription")),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    ImageSlot(
                      label: "Front",
                      file: _imageFront,
                      onCapture: () => _pickImage(isFront: true),
                      onClear: () => setState(() => _imageFront = null),
                    ),
                    const SizedBox(width: 12),
                    ImageSlot(
                      label: "Back",
                      file: _imageBack,
                      onCapture: () => _pickImage(isFront: false),
                      onClear: () => setState(() => _imageBack = null),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Tip: Front usually has the patient name & drug; back has directions/warnings.",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                const SizedBox(height: 16),
                if (_responseText.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_responseText),
                  ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: canAnalyze ? _analyzeAndSave : null,
                  icon: const Icon(Icons.check_circle),
                  label: const Text("Analyze & Save"),
                ),
              ],
            ),
          ),
          if (_loading)
            Container(
              color: Colors.black.withOpacity(0.25),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
