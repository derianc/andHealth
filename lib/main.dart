import 'package:andhealth/providers/prescription_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:andhealth/providers/user_provider.dart';
import 'package:andhealth/splash_screen.dart';
import 'package:dart_openai/dart_openai.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env BEFORE using it
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
 
 final apiKey = dotenv.env['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
   print("⚠️ OPENAI_API_KEY is not set in .env file");
   return;
  } else {
    OpenAI.apiKey = apiKey;
  }
   
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
