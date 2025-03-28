// model/attendance_model.dart
import 'package:intl/intl.dart';

class Attendance {
  final String id;
  final int date;
  final String day;
  final String status;
  final DateTime checkInTime;
  final DateTime? checkOutTime;

  Attendance({
    required this.id,
    required this.date,
    required this.day,
    required this.status,
    required this.checkInTime,
    this.checkOutTime,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    // Attempt to parse the check-in and check-out times. Use tryParse to avoid exceptions
    DateTime parseDate(String dateStr) {
      DateTime? parsedDate = DateTime.tryParse(dateStr);
      return parsedDate ?? DateTime(1970); // If parsing fails, return a default date
    }
    return Attendance(
      id: json['id'] ?? '',
      date: json['date'] ?? 0,
      day: json['day'] ?? 'Unknown',
      status: json['status'] ?? 'Unknown',
      checkInTime: parseDate(json['checkInTime'] ?? ''),
      checkOutTime: json['checkOutTime'] != null ? parseDate(json['checkOutTime']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'day': day,
      'status': status,
      'check_in_time': checkInTime.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
    };
  }

  // Method to return the formatted date in dd-MM-yyyy format
  String get formattedDate {
    return DateFormat('dd-MM-yyyy').format(checkInTime);
  }
}



// State class for managing attendance data
class AttendanceState {
  final bool isLoading;
  final String successMessage;
  final String errorMessage;
  final List<Attendance> attendanceList;
  final String? selectedYear;
  final String? selectedMonth;
  final String? selectedDay;

  AttendanceState({
    required this.isLoading,
    required this.successMessage,
    required this.errorMessage,
    required this.attendanceList,
    this.selectedYear,
    this.selectedMonth,
    this.selectedDay,
  });

  factory AttendanceState.initial() {
    return AttendanceState(
      isLoading: false,
      successMessage: '',
      errorMessage: '',
      attendanceList: [],
      selectedYear: null,
      selectedMonth: null,
      selectedDay: null,
    );
  }

  AttendanceState copyWith({
    bool? isLoading,
    String? successMessage,
    String? errorMessage,
    List<Attendance>? attendanceList, List<Map<String, String>>? attendanceRecords,
    String? selectedYear,
    String? selectedMonth,
    String? selectedDay,
  }) {
    return AttendanceState(
      isLoading: isLoading ?? this.isLoading,
      successMessage: successMessage ?? this.successMessage,
      errorMessage: errorMessage ?? this.errorMessage,
      attendanceList: attendanceList ?? this.attendanceList,
       selectedYear: selectedYear ?? this.selectedYear,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedDay: selectedDay ?? this.selectedDay,
    );
  }
}
