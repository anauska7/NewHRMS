// applyleave_model.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ViewLeave {
  final String id;
  final String applicantID;
  final String title;
  final String type;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime appliedDate;
  final int period;
  final String reason;
  final String adminResponse;

  ViewLeave({
    required this.id,
    required this.applicantID,
    required this.title,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.appliedDate,
    required this.period,
    required this.reason,
    required this.adminResponse,
  });

  factory ViewLeave.fromJson(Map<String, dynamic> json) {
    return ViewLeave(
      id: json['_id'] ?? '',
      applicantID: json['applicantID'] ?? '',
      title: json['title'] ?? '',
      type: json['type'] ?? '',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : DateTime.now(),
      appliedDate: json['appliedDate'] != null
          ? DateTime.parse(json['appliedDate'])
          : DateTime.now(),
      period: json['period'] ?? 0,
      reason: json['reason'] ?? '',
      adminResponse: json['adminResponse'] ?? '',
    );
  }

  String get formattedStartDate => DateFormat('dd-MM-yyyy').format(startDate);

  String get formattedEndDate => DateFormat('dd-MM-yyyy').format(endDate);

  String get formattedAppliedDate =>
      DateFormat('dd-MM-yyyy').format(appliedDate);
}

class ViewLeaveModel {
  Future<List<ViewLeave>> fetchLeaveRecords(String token) async {
    const String apiUrl =
        "https://neoe2e.neophyte.live/hrms-api/api/employee/view-leave-applications";

    // Debug: Log the token and API URL being used
    print('API URL: $apiUrl');
    print('Auth Token: $token');

    // Validate if the token is valid
    if (token.isEmpty) {
      throw Exception("Token is empty. Please login again.");
    }

    // Assuming we decode the token and retrieve the applicantID from it
    String applicantID = _getApplicantIDFromToken(token);

    if (applicantID.isEmpty) {
      throw Exception("Applicant ID is empty. Unable to fetch leave records.");
    }

    // Debug: Log the applicantID
    print('Applicant ID: $applicantID');

    // API request body including the applicant ID
    final requestBody = {
      'applicantID': applicantID, // Send the applicantID in the body
    };

    // Start of API call
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Use token for authentication
        'Cookie': 'accessToken=$token',
      },
      body: jsonEncode(requestBody), // Removed extra set of curly braces
    );

    // Debug: Log the status code and the response body
    print('Response Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        // Debug: Log the parsed response
        print('Parsed Response: ${responseBody}');

        if (responseBody['success'] == true && responseBody['data'] is List) {
          List<dynamic> data = responseBody['data'];
          return data
              .map((leaveJson) => ViewLeave.fromJson(leaveJson))
              .toList();
        } else {
          // Log failure when response format is invalid
          throw Exception(
              "Invalid response format: ${responseBody['message'] ?? 'Unknown error'}");
        }
      } catch (e) {
        // Log error if parsing fails
        print('Error parsing response: $e');
        throw Exception("Error parsing response: $e");
      }
    } else {
      // Log error response code
      print('API Call failed with status: ${response.statusCode}');
      throw Exception(
          "Failed to fetch leave records with status code ${response.statusCode}");
    }
  }
}

// Corrected function to decode the token and retrieve applicantID
  String _getApplicantIDFromToken(String token) {
    // Check if token is null or empty
    if (token.isEmpty) {
      return '';
    }

    try {
      // Assuming JWT format
      var parts = token.split('.');
      if (parts.length == 3) {
        var payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
        var decodedPayload = jsonDecode(payload);

        // Debug log the decoded payload
        print('Decoded Payload: $decodedPayload');

        // Assuming 'user.id' or '_id' contains the applicantID
        return decodedPayload['_id'] ?? ''; // Corrected to use '_id' instead of 'user.id'
      }
    } catch (e) {
      // Log any decoding issues
      print('Error decoding token: $e');
    }

    return ''; // Return empty if token decoding fails or format is incorrect
  }
