import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  bool _isLoading = false;

  Future<void> loginUser() async {
    setState(() {
      _isLoading = true;
    });

    String url = 'https://api.neophyte.live/hrms-api/api/auth/login'; // ✅ Replace with correct API URL
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    };
    Map<String, dynamic> body = {
      'email': _emailController.text,
      'password': _passwordController.text,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body); // Decode response

      // ✅ Check if the token exists and is a valid String
      if (response.statusCode == 200 && data.containsKey('token') && data['token'] != null) {
        String token = data['token'].toString(); // Ensure it's a String

        // Store JWT Token securely
        await _storage.write(key: 'auth_token', value: token);

        // Navigate to Authenticated Screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthenticatedScreen()),
        );
      } else {
        // ✅ Handle case where token is missing or null
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Login failed. Please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // **Illustration Image** (Remote URL or Local Path)
              Image.network(
                "https://www.pockethrms.com/wp-content/uploads/2022/01/Happy-Workforce.jpg", // ✅ Replace with actual image URL
                height: 150,
                width: double.infinity,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.error, color: Colors.red);
                },
              ),

              const SizedBox(height: 20),

              // **Login Card**
              Card(
                color: const Color.fromARGB(255, 252, 253, 253),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Login",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // **Email Field**
                      const Text(
                        "Email",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 10),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // **Password Field + Forgot Password**
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Password",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          GestureDetector(
                            onTap: () {
                              // TODO: Implement forgot password logic
                            },
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 5),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 10),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // **Login Button**
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : loginUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  "Login",
                                  style: TextStyle(fontSize: 18, color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // **Footer Section**
              Column(
                children: [
                  const Text(
                    "Developed by Neophyte Team",
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 10),

                  // **Social Icons**
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          // TODO: Add GitHub Link
                        },
                        icon: SvgPicture.asset(
                          "assets/github.svg",
                          height: 30,
                        ),
                      ),

                      IconButton(
                        onPressed: () {
                          // TODO: Add LinkedIn Link
                        },
                        icon: SvgPicture.asset(
                          "assets/linkedin.svg",
                          height: 30,
                        ),
                      ),

                      IconButton(
                        onPressed: () {
                          // TODO: Add DS Link
                        },
                        icon: Image.network(
                          "https://raw.githubusercontent.com/deepak-singh5219/Digital-Portfolio/main/public/favicon.ico", // ✅ Replace with actual DS logo URL
                          height: 30,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// **✅ Authenticated Screen (Temporary)**
/// Replace this with your actual dashboard or home screen
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
