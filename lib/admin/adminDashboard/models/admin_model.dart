import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String apiUrl = "https://est.neophyte.live/api/admins"; 

  static Future<List<dynamic>> getAdmins() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to load data");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }
}