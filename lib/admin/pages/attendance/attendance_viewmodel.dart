import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceModel {
  // Fetch Attendance Records from API
  Future<Map<String, dynamic>> fetchAttendanceData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        print("❌ [DEBUG] No valid token found! Redirecting to login.");
        throw Exception("Authentication required. Please login again.");
      }

      const String attendanceApiUrl = "https://neoe2e.neophyte.live/hrms-api/api/admin/view-employee-attendance";
      const String employeeApiUrl = "https://neoe2e.neophyte.live/hrms-api/api/admin/employees";

      // Fetch Employees first to map employeeID to names
      final employeeResponse = await http.get(
        Uri.parse(employeeApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Cookie': 'accessToken=$token',
        },
      );

      Map<String, String> employeeIdToName = {};
      if (employeeResponse.statusCode == 200) {
        final employeeData = jsonDecode(employeeResponse.body);
        print("🔍 Employee API Full Response: $employeeData");
        
        if (employeeData['success'] == true && employeeData.containsKey('data')) {
          for (var employee in employeeData['data']) {
            // Try different approaches to get employee ID
            String? employeeId = 
              employee["_id"] ?? 
              employee["id"] ?? 
              employee["employeeId"] ?? 
              employee["employeeID"];
            
            String employeeName = 
              employee["name"] ?? 
              employee["fullName"] ?? 
              "Unknown";
            
            if (employeeId != null) {
              print("🔍 Mapping Employee: ID = $employeeId, Name = $employeeName");
              employeeIdToName[employeeId] = employeeName;
            } else {
              print("❌ Skipping employee due to missing ID: $employee");
            }
          }
        } else {
          print("❌ No employee data found in the response");
        }
      } else {
        print("❌ Failed to fetch employees. Status code: ${employeeResponse.statusCode}");
        print("❌ Response body: ${employeeResponse.body}");
      }

      // Fetch Attendance Data
      final response = await http.post(
        Uri.parse(attendanceApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Cookie': 'accessToken=$token',
        },
        body: jsonEncode({}) // Empty body as per your description
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print("❌ [DEBUG] API call timed out");
          throw Exception("Connection timeout. Please check your internet connection.");
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        print("🔍 Attendance API Response: $responseBody");
        
        if (responseBody['success'] == true &&
            responseBody.containsKey('data') &&
            responseBody['data'] is List) {

          List<Map<String, String>> attendanceList = (responseBody['data'] as List).map((entry) {
            String employeeId = entry["employeeID"].toString();
            String employeeName = employeeIdToName[employeeId] ?? "Unknown (ID: $employeeId)";
            
            print("🔍 Attendance Entry: EmployeeID = $employeeId, Mapped Name = $employeeName");

            String status = "Absent"; // Default to Absent if checkIn and checkOut are missing

  // Check if check-in and check-out times are valid
  if (entry["checkInTime"] != null && entry["checkOutTime"] != null) {
    status = entry["present"] == true ? "Present" : "Absent";
  }

            return {
              "id": entry["_id"].toString(),
              "employeeId": employeeId,
              "employeeName": employeeName,
              "date": "${entry["date"]}-${entry["month"]}-${entry["year"]}",
              "day": entry["day"]?.toString() ?? "N/A",
              "status": entry["present"] == true ? "Present" : "Absent",
              "checkIn": formatDate(entry["checkInTime"]?.toString() ?? "--"),
              "checkOut": formatDate(entry["checkOutTime"]?.toString() ?? "--"),
              "withinRange": entry["withinRange"].toString(),
              "latitude": entry["latitude"].toString(),
              "longitude": entry["longitude"].toString(),
            };
          }).toList();

          // Create list of employee names
          List<String> employeeNames = employeeIdToName.values.toList();

          print("🔍 Total Attendance Entries: ${attendanceList.length}");
          print("🔍 Total Employee Names: ${employeeNames.length}");

          return {
            'attendanceData': attendanceList,
            'employeeNames': employeeNames,
          };
        } else {
          print("❌ [DEBUG] Invalid API response format: ${responseBody['success']}");
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
      print("❌ [DEBUG] Error fetching attendance data: $e");
      rethrow;
    }
  }

  String formatDate(String timestamp) {
    try {
      if (timestamp != "--") {
        DateTime dateTime = DateTime.parse(timestamp);
        DateTime istTime = dateTime.toUtc().add(const Duration(hours: 5, minutes: 30));
        return DateFormat('HH:mm:ss').format(istTime);
      }
      return "--";
    } catch (e) {
      return "--";
    }
  }
}