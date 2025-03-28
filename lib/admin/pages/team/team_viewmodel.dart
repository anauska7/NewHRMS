import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TeamsModel {
  Future<List<Map<String, String>>> fetchTeams() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      const String apiUrl = "https://neoe2e.neophyte.live/hrms-api/api/admin/teams"; // Example API endpoint

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
        if (data.containsKey("data") && data["data"] is List) {
          return (data["data"] as List).map((team) {
            return {
              "id": team["_id"].toString(),
              "name": team["name"]?.toString() ?? "No Name",
              "leader": team["leader"]?.toString() ?? "No Leader",
              "status": team["status"]?.toString() ?? "No Status",
              "image": team["image"]?.toString() ?? "",
            };
          }).toList();
        }
      }
      return [];
    } catch (e) {
      print("❌ Error fetching teams data: $e");
      return [];
    }
  }
}
