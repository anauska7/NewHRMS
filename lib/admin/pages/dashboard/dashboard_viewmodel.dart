import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DashboardModel {
  // Fetch data for total count (employees, leaders, admins, etc.)
  Future<int> fetchCount(String apiUrl) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      
      if (token == null || token.isEmpty) {
        throw Exception("Authentication token is missing.");
      }

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Cookie': 'accessToken=$token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data.containsKey("data")) {
          if (data["data"] is List) {
            return (data["data"] as List).length;
          } else if (data["data"] is Map) {
            return data["data"].values.fold(0, (sum, value) => sum + (value is List ? value.length : 0));
          }
        }
      }
    } catch (e) {
      throw Exception("Failed to fetch count from API: $e");
    }
    return 0;
  }
}
