import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminModel {
  Future<List<Map<String, String>>> fetchAdmins() async {
    try {
      print("🔍 [DEBUG] AdminModel: Starting fetchAdmins");
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      print("🔍 [DEBUG] AdminModel: Retrieved Token: ${token != null ? 'Token exists' : 'Token is null'}");

      if (token == null || token.isEmpty) {
        print("❌ [DEBUG] AdminModel: No valid token found! Redirecting to login.");
        throw Exception("Authentication required. Please login again.");
      }

      const String apiUrl = "https://192.168.1.5:5500/api/admin/admins";
      print("🔍 [DEBUG] AdminModel: Calling API: $apiUrl");

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Cookie': 'accessToken=$token',
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print("❌ [DEBUG] AdminModel: API call timed out");
          throw Exception("Connection timeout. Please check your internet connection.");
        },
      );

      print("🔍 [DEBUG] AdminModel: Response Status Code: ${response.statusCode}");
      print("🔍 [DEBUG] AdminModel: Response Body Length: ${response.body.length}");
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        print("🔍 [DEBUG] AdminModel: Response decoded successfully");
        
        if (responseBody['success'] == true &&
            responseBody.containsKey('data') &&
            responseBody['data'] is List) {
          List<Map<String, String>> adminList = (responseBody['data'] as List)
              .map((admin) => {
                    "id": admin["_id"].toString(),
                    "image": admin["image"]?.toString() ?? "",
                    "name": admin["name"]?.toString() ?? "No Name",
                    "email": admin["email"]?.toString() ?? "No Email",
                  })
              .toList();

          print("🔍 [DEBUG] AdminModel: Admins Data Fetched: ${adminList.length} admins");
          return adminList;
        } else {
          print("❌ [DEBUG] AdminModel: Invalid API response format: ${responseBody['success']}");
          throw Exception("Invalid API response format");
        }
      } else if (response.statusCode == 401) {
        print("❌ [DEBUG] AdminModel: Authentication Error: 401 Unauthorized");
        throw Exception("Authentication failed. Please login again.");
      } else {
        print("❌ [DEBUG] AdminModel: API Error: ${response.statusCode} - ${response.reasonPhrase}");
        throw Exception("API Error: ${response.statusCode} - ${response.reasonPhrase}");
      }
    } catch (e) {
      print("❌ [DEBUG] AdminModel: Error fetching admin data: $e");
      rethrow; // Re-throw to let the ViewModel handle it
    }
  }
}