import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class LeaveModel {
  // Fetch Employee Names for Dropdown or Leave Applications
  Future<List<String>> fetchEmployeeNames() async {
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
        final List<dynamic> data = jsonDecode(response.body)['data'];
        // Debug: Print the full employee data
        // Use a Set to ensure unique names
        final Set<String> uniqueNames = data
            .map<String>((emp) => emp["name"]?.toString() ?? "Unknown")
            .toSet();

        // Convert back to a list and sort
        return uniqueNames.toList()..sort();
      }
      return [];
    } catch (e) {
      print("❌ [DEBUG] Employee Fetch Error: $e");
      return [];
    }
  }

  

  // Fetch Leave Applications and integrate employee names from the second API
  Future<List<Map<String, String>>> fetchLeaveApplications() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      const String leaveApiUrl = "https://neoe2e.neophyte.live/hrms-api/api/admin/view-leave-applications";
      const String employeeApiUrl = "https://neoe2e.neophyte.live/hrms-api/api/admin/employees";

      // Step 1: Fetch leave applications
      final leaveResponse = await http.post(
        Uri.parse(leaveApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Cookie': 'accessToken=$token',
        },
      );

      if (leaveResponse.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(leaveResponse.body);

        if (responseBody['success'] == true && responseBody.containsKey('data') && responseBody['data'] is List) {
          
          // Step 2: Fetch employee data
          final employeeResponse = await http.get(
            Uri.parse(employeeApiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
              'Cookie': 'accessToken=$token',
            },
          );

          Map<String, String> employeeMap = {};
          if (employeeResponse.statusCode == 200) {
            final employeeData = jsonDecode(employeeResponse.body);
            if (employeeData['success'] == true && employeeData.containsKey('data')) {
              employeeMap = Map.fromIterable(
                employeeData['data'],
                key: (employee) => employee["id"]?.toString()?.trim() ?? "Unknown",
                value: (employee) => employee["name"]?.toString()?.trim() ?? "Unknown",
              );
            }
          }

          // Step 3: Combine leave data with employee names
          List<Map<String, String>> leaveList = (responseBody['data'] as List).map((leave) {
            String userId = leave["applicantID"]?.toString()?.trim() ?? "Unknown";
            String employeeName = employeeMap[userId] ?? "Unknown";

            return {
              "id": leave["_id"].toString(),
              "employeename": employeeName,
              "type": leave["type"]?.toString() ?? "N/A",
              "startDate": formatDate(leave["startDate"]?.toString() ?? "N/A"),
              "endDate": formatDate(leave["endDate"]?.toString() ?? "N/A"),
              "status": leave["adminResponse"]?.toString() ?? "Pending",
            };
          }).toList();

          return leaveList;
        }
      }

      return [];
    } catch (e) {
      print("❌ [DEBUG] Network Error: $e");
      return [];
    }
  }

  String formatDate(String date) {
    try {
      if (date != "N/A") {
        DateTime parsedDate = DateTime.parse(date);
        return DateFormat('dd-MM-yyyy').format(parsedDate);
      }
      return "N/A";
    } catch (e) {
      return "N/A";
    }
  }
}
