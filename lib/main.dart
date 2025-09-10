import 'package:andhealth/providers/prescription_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:andhealth/providers/user_provider.dart';
import 'package:andhealth/splash_screen.dart';
import 'package:dart_openai/dart_openai.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  OpenAI.apiKey = "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";  
  runApp(
     MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => PrescriptionProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AndHealth Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SplashScreen(), // entry point
    );
  }
}
