import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:new_hrms/login/screens/loginPage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter HRMS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const AuthCheckScreen(), // Determines where to navigate
    );
  }
}

/// **AuthCheckScreen: Checks JWT Authentication**
class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  _AuthCheckScreenState createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<bool> isUserLoggedIn() async {
    String? token = await _storage.read(key: 'auth_token');
    return token != null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isUserLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()), // Loading screen
          );
        }

        if (snapshot.hasData && snapshot.data == true) {
          return const AuthenticatedScreen(); // Temporary logged-in screen
        } else {
          return const LoginPage(); // Show login screen
        }
      },
    );
  }
}

/// **Temporary Screen for Logged-In Users**  
/// 🚀 Replace this with your actual home screen later
class AuthenticatedScreen extends StatelessWidget {
  const AuthenticatedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
      body: const Center(child: Text('You are logged in! Implement your home screen here.')),
    );
  }
}
