# andHealth

A Flutter mobile application that allows users to scan or manually enter prescription information, manage active/inactive prescriptions, and receive reminders for their medications. The app integrates with Firebase (Auth + Firestore) and supports Google Sign-In.

---

## Features
- User authentication (Firebase Auth with Google Sign-In)
- Prescription management (active/inactive sections)
- Prescription scanning (camera + OCR integration + OpenAI)
- Calendar & reminders for medication schedules
- Gradient splash screen with animated logo
- Profile screen with user management and logout

---

## Installation

### 1. Prerequisites
- [Flutter](https://docs.flutter.dev/get-started/install) (3.27.0 or higher recommended)
- Dart SDK
- Firebase project configured
- Android Studio or VS Code

### 2. Install FlutterFire CLI
dart pub global activate flutterfire_cli

### 3. Environment Variables
OPENAI_API_KEY=your_openai_key_if_using

### 4. Project Structure
lib/
 ├─ models/          # Data models (UserModel, PrescriptionModel, etc.)
 ├─ providers/       # State management with Provider
 ├─ services/        # Firebase/Auth/AI services
 ├─ screens/         # App screens (Login, Profile, Prescriptions, Scan)
 ├─ widgets/         # Shared UI components

### 4. Run Project
flutter pub get
flutter run

