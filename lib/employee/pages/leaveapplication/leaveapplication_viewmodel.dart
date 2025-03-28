import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class LeaveModel {
  // Apply leave API
  Future<bool> applyLeave(
      String title, String leaveType, String period, String startDate, String endDate, String reason) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      String? applicantId = prefs.getString('user_id'); // Assuming you store user ID during login
      
      if (token == null) {
        print("❌ [DEBUG] No authentication token found");
        return false;
      }

      if (applicantId == null) {
        print("❌ [DEBUG] No applicant ID found");
        return false;
      }

      const String apiUrl = "https://neoe2e.neophyte.live/hrms-api/api/employee/apply-leave-application";
      
      // Use a more robust date parsing method
      DateTime startDateTime;
      DateTime endDateTime;
      
      try {
        // Define formats explicitly
        final List<DateFormat> formats = [
          DateFormat('dd-MM-yyyy'),   // Match the format used in view
          DateFormat('yyyy-MM-dd'),   // ISO format
          DateFormat('MM/dd/yyyy'),   // US format
        ];

        startDateTime = _parseDate(startDate, formats);
        endDateTime = _parseDate(endDate, formats);
      } catch (e) {
        print("❌ [DEBUG] Invalid date format: $e");
        print("Start Date: $startDate, End Date: $endDate");
        return false;  // Invalid date format
      }

      // Always format to 'yyyy-MM-dd' for API
      final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
      final formattedStartDate = dateFormat.format(startDateTime);
      final formattedEndDate = dateFormat.format(endDateTime);
      final appliedDate = dateFormat.format(DateTime.now()); // Current date as applied date

      // Prepare request body with detailed logging
      final requestBody = {
        'title': title,
        'type': leaveType,
        'period': period,
        'startDate': formattedStartDate,
        'endDate': formattedEndDate,
        'reason': reason,
        'applicantID': applicantId, // Add applicant ID
        'appliedDate': appliedDate, // Add applied date
      };

      print("🚀 [DEBUG] Request Body: ${jsonEncode(requestBody)}");
      print("🔑 [DEBUG] Token: $token");

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Cookie': 'accessToken=$token',
        },
        body: jsonEncode(requestBody),
      );

      // Comprehensive response logging
      print("📡 [DEBUG] Response Status Code: ${response.statusCode}");
      print("📄 [DEBUG] Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("✅ [DEBUG] Response Data: $data");
        return data['success'] == true;
      } else {
        print("❌ [DEBUG] Failed to apply leave: ${response.statusCode} - ${response.reasonPhrase}");
        print("❌ [DEBUG] Response Body: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ [DEBUG] Unexpected error in applyLeave: $e");
      return false;
    }
  }

  // Helper method to parse date with multiple formats
  DateTime _parseDate(String dateString, List<DateFormat> formats) {
    for (var format in formats) {
      try {
        return format.parse(dateString);
      } catch (_) {
        // Continue to next format if parsing fails
        continue;
      }
    }
    // If no format works, throw an exception
    throw FormatException("Unable to parse date: $dateString");
  }
}