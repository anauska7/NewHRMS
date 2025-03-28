import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TeamModel {
  // API call to Add Team
  Future<Map<String, dynamic>> addTeam(Map<String, String> teamData) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      const String apiUrl = "https://neoe2e.neophyte.live/hrms-api/api/admin/team";
      
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Cookie': 'accessToken=$token',
        },
        body: jsonEncode(teamData),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        return responseBody;
      } else {
        throw Exception("Failed to add team. ${response.reasonPhrase}");
      }
    } catch (e) {
      throw Exception("Network error: $e");
    }
  }
}
