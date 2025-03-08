import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:new_hrms/admin/adminDashboard/widgets/admin_header.dart';
import 'package:new_hrms/admin/adminDashboard/widgets/admindrawer.dart';
import 'package:shared_preferences/shared_preferences.dart';


class LeadersScreen extends StatefulWidget {
  const LeadersScreen({super.key});

  @override
  _LeadersScreenState createState() => _LeadersScreenState();
}

class _LeadersScreenState extends State<LeadersScreen> {
  final Type _storage = SharedPreferences;
  List<dynamic> _leaders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLeaders();
  }

Future<void> _fetchLeaders() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      print("🔍 Retrieved Token from SharedPreferences: $token");

      if (token == null || token.isEmpty) {
        print("🚨 No valid token found! Redirecting to login.");
        return;
      }

      const String apiUrl = "http://192.168.1.13:5500/api/admin/leaders";
      print("🔍 Calling API: $apiUrl");
      
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJfaWQiOiI2NGNhMzM3Njg5M2FjOWY3MTllYTVjNGQiLCJlbWFpbCI6ImFkbWluQGFkbWluLmNvbSIsInVzZXJuYW1lIjoiYWRtaW4iLCJ0eXBlIjoiYWRtaW4iLCJpYXQiOjE3NDEwNzc4NzksImV4cCI6MTc0MTA4MTQ3OX0.OPhWSXu-VoyPoPHUgyy6I36yOLXyL2pWApuhMRceOWQ',  // Add the token here
        },
      ).timeout(const Duration(seconds: 10));
      
      print("🔍 Response Status Code: ${response.statusCode}");
      print("🔍 Response Body: ${response.body}");
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        if (responseBody['success'] == true && 
            responseBody.containsKey('data') && 
            responseBody['data'] is List) {
          setState(() {
            _leaders = responseBody['data'];
            _isLoading = false;
          });
        } else {
          throw Exception("Invalid API response format");
        }
      } else if (response.statusCode == 401) {
        setState(() {
          _errorMessage = "Authentication required. Please login again.";
          _isLoading = false;
        });
        print("❌ Authentication Error: 401 Unauthorized");
      } else {
        throw Exception("API Error: ${response.statusCode} - ${response.reasonPhrase}");
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Network Error: Unable to fetch data. Please check your internet connection.";
        _isLoading = false;
      });
      print("❌ Network Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
     appBar: const CustomHeader(title: "Leaders"),
      drawer: CustomDrawer(selectedScreen: "Leaders"), 
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "All Leaders",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 10),

            // ✅ Show loading indicator
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),

            // ✅ Show error message if any
            if (_errorMessage != null)
              Center(
                child: Text(
                  "❌ $_errorMessage",
                  style: const TextStyle(fontSize: 16, color: Colors.red),
                ),
              ),

            // ✅ Show Leaders List if data is available
            if (!_isLoading && _leaders.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _leaders.length,
                  itemBuilder: (context, index) {
                    var leader = _leaders[index];
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[300],
                          backgroundImage: leader['image'] != null && leader['image'].isNotEmpty
                              ? NetworkImage(leader['image'])
                              : null,
                          child: leader['image'] == null || leader['image'].isEmpty
                              ? const Icon(Icons.person, color: Colors.green)
                              : null,
                        ),
                        title: Text(
                          leader['name'] ?? "No Name",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(leader['email'] ?? "No Email"),
                        trailing: Text(
                          "${index + 1}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // ✅ Show message if no leaders found
            if (!_isLoading && _leaders.isEmpty && _errorMessage == null)
              const Center(
                child: Text(
                  "No Leaders Found!",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

extension on Type {
  read({required String key}) {}
}