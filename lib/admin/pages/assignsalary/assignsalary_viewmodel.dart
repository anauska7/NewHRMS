import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SalaryModel {
  // Fetch employees for dropdown
  Future<List<String>> fetchEmployees() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      const String apiUrl = "https://neoe2e.neophyte.live/hrms-api/api/admin/employees";
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
        final responseBody = jsonDecode(response.body);
        if (responseBody['success'] == true && responseBody.containsKey('data')) {
          List<String> employeeNames = (responseBody['data'] as List)
              .map<String>((emp) => emp["name"].toString())
              .toList();
          return employeeNames;
        }
      }
      return [];
    } catch (e) {
      print("❌ [DEBUG] Employee Fetch Error: $e");
      return [];
    }
  }
}
