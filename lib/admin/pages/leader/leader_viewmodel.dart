import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LeaderModel {
  Future<List<Map<String, String>>> fetchLeaders() async {
    try {
      print("🔍 [DEBUG] Fetching Leaders...");
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      print("🔍 [DEBUG] Retrieved Token: ${token != null ? 'Token exists' : 'Token is null'}");

      if (token == null || token.isEmpty) {
        print("❌ [DEBUG] No valid token found! Redirecting to login.");
        throw Exception("Authentication required. Please login again.");
      }

      const String apiUrl = "https://neoe2e.neophyte.live/hrms-api/api/admin/leaders";
      
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Cookie': 'accessToken=$token',
        },
      ).timeout(const Duration(seconds: 20), onTimeout: () {  // Reduced timeout from 20000 to 20 seconds
        print("❌ [DEBUG] API call timed out!");
        throw Exception("Connection timed out. Please check your internet connection.");
      });

      print("🔍 [DEBUG] Response Status Code: ${response.statusCode}");
      print("🔍 [DEBUG] Response Body Length: ${response.body.length}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);

        if (responseBody['success'] == true &&
            responseBody.containsKey('data') &&
            responseBody['data'] is List) {
          List<Map<String, String>> leadersList = (responseBody['data'] as List)
              .map((leader) => {
                    "id": leader["_id"].toString(),
                    "image": leader["image"]?.toString() ?? "",
                    "name": leader["name"]?.toString() ?? "No Name",
                    "email": leader["email"]?.toString() ?? "No Email",
                  })
              .toList();

          print("🔍 [DEBUG] Leaders Data Fetched: ${leadersList.length} leaders");
          return leadersList;
        } else {
          print("❌ [DEBUG] Invalid API response format.");
          throw Exception("Invalid API response format");
        }
      } else if (response.statusCode == 401) {
        print("❌ [DEBUG] Authentication Error: 401 Unauthorized");
        throw Exception("Authentication failed. Please login again.");
      } else {
        print("❌ [DEBUG] API Error: ${response.statusCode} - ${response.reasonPhrase}");
        throw Exception("API Error: ${response.statusCode} - ${response.reasonPhrase}");
      }
    } catch (e) {
      print("❌ [DEBUG] Error fetching leader data: $e");
      rethrow; // Re-throw to let the ViewModel handle it
    }
  }
}