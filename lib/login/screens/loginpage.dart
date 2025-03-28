import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:new_hrms/providers/auth_providers.dart'; // Import providers

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() {
    return _LoginPageState();
  }
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // Check if user is logged in using SharedPreferences
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return token != null && token.isNotEmpty;
  }

  // Get the user type (admin or employee) from SharedPreferences
  Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_type');
  }

  

  Future<void> loginUser() async {
    setState(() {
      _isLoading = true;
    });

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    String url = 'https://neoe2e.neophyte.live/hrms-api/api/auth/login';
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    };
    Map<String, dynamic> body = {
      'email': email,
      'password': password,
    };

    try {

       print("🔍 [DEBUG] Sending login request to: $url");
       print("🔍 [DEBUG] Request Body: ${jsonEncode(body)}");

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      print("🔍 [DEBUG] Response Code: ${response.statusCode}");
      print("🔍 [DEBUG] Response Body: ${response.body}");

      final data = jsonDecode(response.body);

      print("🔍 [DEBUG] Decoded Response: $data");

      if (response.statusCode == 200 && data['success'] == true) {
        var headers = response.headers;
        String userName = '';
        String userType = '';

        // Safely access 'name' and 'type' properties from the response
        if (data.containsKey('user') && data['user'] != null) {
          userName = data['user']?['name'] ?? '';
          userType = data['user']?['type'] ?? '';
          String accessToken = '';

        }

        if (headers.containsKey('set-cookie')) {
          String cookieHeader = headers['set-cookie']!;

          RegExp regex = RegExp(r'accessToken=([^;]+)');
          Match? match = regex.firstMatch(cookieHeader);

          if (match != null && match.groupCount >= 1) {
            String accessToken = match.group(1)!;

            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('auth_token', accessToken);
            await prefs.setString('user_name', userName);
            //await prefs.setString('user_type', userType);
            await prefs.setString('user_data', jsonEncode(data['user']));

            final userData = data['user'];
          await prefs.setString('user_id', userData['id'] ?? '');
          await prefs.setString('user_name', userData['name'] ?? '');
          await prefs.setString('user_email', userData['email'] ?? '');
          await prefs.setString('user_username', userData['username'] ?? '');
          await prefs.setString('user_mobile', userData['mobile'].toString());
          await prefs.setString('user_image', userData['image'] ?? '');
          await prefs.setString('user_type', userData['type'] ?? '');
          await prefs.setString('user_address', userData['address'] ?? '');
          await prefs.setString('user_status', userData['status'] ?? '');

          String userType = userData['type'] ?? '';

           ref.read(authProvider.notifier).state = true;
          ref.read(userTypeProvider.notifier).state = userType;

            setState(() {
              _isLoading = false;
            });

            ref.read(authProvider.notifier).state = true;
            ref.read(userTypeProvider.notifier).state = userType;

            // Routing based on user type
            if (userType == 'Admin') {
              context.go('/admin/dashboard');
            } else {
              context.go('/employee/dashboard');
            }
          } else {
            showErrorMessage("Login failed: Access Token not found in Cookie header.");
          }
        } else {
          showErrorMessage("Login failed: No Cookie header found.");
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        showErrorMessage(data['message'] ?? 'Invalid credentials.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      showErrorMessage('Network Error: Please try again.');
    }
  }

  void showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(milliseconds: 1500),
      ),
    );
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
              Image.network(
                "https://www.pockethrms.com/wp-content/uploads/2022/01/Happy-Workforce.jpg",
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
                      const Text("Email", style: TextStyle(fontWeight: FontWeight.bold)),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Password", style: TextStyle(fontWeight: FontWeight.bold)),
                          GestureDetector(
                            onTap: () {},
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
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
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            await loginUser(); // Ensure loginUser() is called
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("Login", style: TextStyle(fontSize: 18, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
