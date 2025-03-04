import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:new_hrms/admin/adminDashboard/screen/admindashboard.dart';

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

  String url = 'http://192.168.1.20:5500/api/auth/login';
  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  };
  Map<String, dynamic> body = {
    'email': _emailController.text.trim(),
    'password': _passwordController.text.trim(),
  };

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);

    print("Response Code: ${response.statusCode}");
    print("Response Body: ${response.body}");

    if (response.statusCode == 200 && data.containsKey('token') && data['token'] != null) {
      String token = data['token'].toString();

      await _storage.write(key: 'auth_token', value: token);

      print("Stored JWT Token: $token");

      setState(() {
        _isLoading = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Login failed. Please try again.')),
      );
    }
  } catch (e) {
    setState(() {
      _isLoading = false; 
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
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

              // Login Card
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

                      // Email Field
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

                      // Password Field 
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Password",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          GestureDetector(
                            onTap: () {},
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

                      // Login Button
                     SizedBox(
                     width: double.infinity,
                     height: 50,
                     child: ElevatedButton(
                         onPressed: () {
                              Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const DashboardScreen()),
                                );
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

              const SizedBox(height: 30),

              // Footer Section
              Column(
                children: [
                  const Text(
                    "Developed by Neophyte Team",
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: SvgPicture.asset(
                          "assets/github.svg",
                          height: 30,
                        ),
                      ),

                      IconButton(
                        onPressed: () {
                        },
                        icon: SvgPicture.asset(
                          "assets/linkedin.svg",
                          height: 30,
                        ),
                      ),

                      IconButton(
                        onPressed: () {
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


