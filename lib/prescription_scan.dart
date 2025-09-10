import 'dart:convert';
import 'dart:io';
import 'package:andhealth/models/prescription_model.dart';
import 'package:andhealth/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:dart_openai/dart_openai.dart';
import '../providers/prescription_provider.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  File? _image;
  bool _loading = false;
  String _responseText = "";

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Load prescriptions once, cache in provider, and prebuild calendar events.
    _pickImage();
  }

 Future<void> _pickImage() async {
  final status = await Permission.camera.request();
  if (!status.isGranted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Camera permission denied')),
    );
    return;
  }

  // ↓ shrink the capture to keep payload small
  final pickedFile = await _picker.pickImage(
    source: ImageSource.camera,
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 75,
  );
  if (pickedFile != null) {
    setState(() => _image = File(pickedFile.path));
    await _processImage(File(pickedFile.path));
  }
}

  Future<void> _processImage(File imageFile) async {
  setState(() {
    _loading = true;
    _responseText = "";
  });

  try {
    final bytes = await imageFile.readAsBytes();

    // Best-guess MIME from file extension
    final isPng = imageFile.path.toLowerCase().endsWith('.png');
    final mime = isPng ? 'image/png' : 'image/jpeg';

    // Data URL that OpenAI can read
    final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';

    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OPENAI_API_KEY missing in .env');
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
                  "You are a medical OCR assistant. Extract prescription details and return ONLY JSON with keys: name, dosage, frequency, notes."
            }
          ]
        },
        {
          "role": "user",
          "content": [
            {
              "type": "image_url",
              "image_url": {"url": dataUrl}
            }
          ]
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
    final content = (decoded['choices'] as List).first['message']['content'] as String;
    setState(() => _responseText = content);

    // Parse the JSON content
    final Map<String, dynamic> data = jsonDecode(content);

    // Get user id from your UserProvider
    final user = context.read<UserProvider>().user;
    if (user == null) throw Exception("No logged-in user.");

    final prescription = Prescription(
      id: "", // Firestore will set in addPrescription
      userId: user.id,
      name: (data["name"] ?? "Unknown").toString(),
      dosage: (data["dosage"] ?? "").toString(),
      frequency: (data["frequency"] ?? "").toString(),
      notes: (data["notes"] ?? "").toString(),
      isActive: true,
      createdAt: DateTime.now(),
    );

    // Save to Firestore via your provider
    await context.read<PrescriptionProvider>().addPrescription(prescription);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Prescription saved!")),
      );

      Navigator.of(context).pop(true);
    }
  } catch (e) {
    setState(() => _responseText = "Error: $e");
  } finally {
    setState(() => _loading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Prescription")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _image != null
                ? Image.file(_image!, height: 200)
                : const Placeholder(fallbackHeight: 200),
            const SizedBox(height: 20),
            _loading
                ? const CircularProgressIndicator()
                : Text(
                    _responseText.isEmpty
                        ? "No data extracted yet"
                        : _responseText,
                  ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.camera_alt),
              label: const Text("Scan Prescription"),
            ),
          ],
        ),
      ),
    );
  }
}
