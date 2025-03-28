import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:new_hrms/employee/pages/attendance/attendance_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceViewModel extends StateNotifier<AttendanceState> {
  final String? selectedYear;
  final String? selectedMonth;
  final String? selectedDay;

  AttendanceViewModel({
    this.selectedYear,
    this.selectedMonth,
    this.selectedDay,
  }) : super(AttendanceState.initial());

  // Check-in method
  Future<void> checkIn() async {
    state = state.copyWith(isLoading: true, errorMessage: '', successMessage: '');

    try {
      // Location permission check
      LocationPermission permission = await _checkLocationPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          isLoading: false, 
          errorMessage: 'Location permission is required to check-in'
        );
        return;
      }

      // Get current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final decodedToken = JwtDecoder.decode(token!);

      final requestBody = {
        "employeeID": decodedToken['_id'],
        "latitude": position.latitude.toString(),
        "longitude": position.longitude.toString(),
        "camera": "false"
      };

      if (kDebugMode) {
        print('Check-In Request Body: $requestBody');
      }

      final response = await http.post(
        Uri.parse('https://neoe2e.neophyte.live/hrms-api/api/employee/mark-employee-checkin'),
        body: jsonEncode(requestBody),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': 'accessToken=$token',
        },
      );

      if (kDebugMode) {
        print('Check-In Response Status: ${response.statusCode}');
        print('Check-In Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        state = state.copyWith(
          isLoading: false, 
          successMessage: 'Successfully checked in'
        );
      } else {
        final errorMessage = jsonDecode(response.body)['message'] ?? 'Failed to check-in';
        state = state.copyWith(
          isLoading: false, 
          errorMessage: errorMessage
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Check-In Error: $e');
      }
      
      state = state.copyWith(
        isLoading: false, 
        errorMessage: 'Network error: ${e.toString()}'
      );
    }
  }

  // Fetch attendance records method
  Future<void> fetchAttendanceRecords() async {
    state = state.copyWith(isLoading: true, errorMessage: '', successMessage: '');

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Authentication token not found'
        );
        return;
      }

      final decodedToken = JwtDecoder.decode(token);
      final employeeID = decodedToken['_id'];

      final response = await http.post(
        Uri.parse('https://neoe2e.neophyte.live/hrms-api/api/employee/view-employee-attendance'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': 'accessToken=$token',
        },
        body: jsonEncode({'employeeID': employeeID}),
      );

      if (kDebugMode) {
        print('Fetch Attendance Response Status: ${response.statusCode}');
        print('Fetch Attendance Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
           List<dynamic> data = responseData['data']; // Corrected line

          if (data != null && data.isNotEmpty) {
            List<Attendance> attendanceRecords = 
                data.map((record) => Attendance.fromJson(record)).toList();

                // Apply filtering based on selected year, month, and day
            if (state.selectedYear != null) {
              attendanceRecords = attendanceRecords
                  .where((attendance) => attendance.checkInTime.year.toString() == state.selectedYear)
                  .toList();
            }

            if (state.selectedMonth != null) {
              attendanceRecords = attendanceRecords
                  .where((attendance) => DateFormat('MMMM').format(attendance.checkInTime).toLowerCase() == 
                      state.selectedMonth!.toLowerCase())
                  .toList();
            }

            if (state.selectedDay != null) {
              attendanceRecords = attendanceRecords
                  .where((attendance) => attendance.checkInTime.day.toString() == state.selectedDay)
                  .toList();
            }
                

            state = state.copyWith(
              isLoading: false,
              attendanceList: attendanceRecords, // Update attendanceList in state
              successMessage: 'Attendance records fetched successfully'
            );
          } else {
            state = state.copyWith(
              isLoading: false,
              errorMessage: 'No attendance records found'
            );
          }
        } else {
          state = state.copyWith(
            isLoading: false,
            errorMessage: responseData['message'] ?? 'Failed to fetch attendance records',
          );
        }
      } else {
        final errorMessage = jsonDecode(response.body)['message'] ?? 'Failed to fetch attendance records';
        state = state.copyWith(
          isLoading: false,
          errorMessage: errorMessage
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Network error: ${e.toString()}'
      );
    }
  }

   // Set filters
  void setSelectedYear(String? year) {
    state = state.copyWith(selectedYear: year);
  }

  void setSelectedMonth(String? month) {
    state = state.copyWith(selectedMonth: month);
  }

  void setSelectedDay(String? day) {
    state = state.copyWith(selectedDay: day);
  }


  // Check-out method
  Future<void> checkOut() async {
    state = state.copyWith(isLoading: true, errorMessage: '', successMessage: '');

    try {
      // First, check and request location permissions
      LocationPermission permission = await _checkLocationPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          isLoading: false, 
          errorMessage: 'Location permission is required to check-out'
        );
        return;
      }

      // Get current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final decodedToken = JwtDecoder.decode(token!); // Add this

      if (token == null) {
        state = state.copyWith(
          isLoading: false, 
          errorMessage: 'Authentication token not found'
        );
        return;
      }

      final response = await http.post(
        Uri.parse('https://neoe2e.neophyte.live/hrms-api/api/employee/mark-employee-checkout'),
        body: jsonEncode({
          'latitude': position.latitude,
          'longitude': position.longitude,
          "employeeID": decodedToken['_id'], // Add employeeID
        }),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': 'accessToken=$token',
        },
      );

      if (kDebugMode) {
        print('Check-Out Response Status: ${response.statusCode}');
        print('Check-Out Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        state = state.copyWith(
          isLoading: false, 
          successMessage: 'Successfully checked out'
        );
      } else {
        final errorMessage = jsonDecode(response.body)['message'] ?? 'Failed to check-out';
        state = state.copyWith(
          isLoading: false, 
          errorMessage: errorMessage
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false, 
        errorMessage: 'Network error: ${e.toString()}'
      );
    }
  }

  // Location permission check and request
  Future<LocationPermission> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission;
  }
}

// Provider for the ViewModel
final attendanceViewModelProvider = StateNotifierProvider<AttendanceViewModel, AttendanceState>((ref) {
  return AttendanceViewModel();
});
