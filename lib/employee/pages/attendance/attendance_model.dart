import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class Attendance {
  final String id;
  final int date;
  final String day;
  final String status;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final List<AttendanceEntry>? multipleEntries; // NEW: Support multiple entries

  Attendance({
    required this.id,
    required this.date,
    required this.day,
    required this.status,
    this.checkInTime,
    this.checkOutTime,
    this.multipleEntries,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    // **FIXED: Better date parsing with timezone handling**
    DateTime? parseDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty || dateStr == 'null') {
        return null;
      }
      
      try {
        DateTime? parsedDate = DateTime.tryParse(dateStr);
        if (parsedDate != null && parsedDate.year > 1970) {
          // **FIXED: Handle timezone properly - convert UTC to local**
          if (parsedDate.isUtc) {
            return parsedDate.toLocal();
          }
          return parsedDate;
        }
        return null;
      } catch (e) {
        debugPrint('Date parsing error for "$dateStr": $e');
        return null;
      }
    }

    // Parse multiple entries if available
    List<AttendanceEntry>? entries;
    if (json['multipleEntries'] != null) {
      entries = (json['multipleEntries'] as List)
          .map((entry) => AttendanceEntry.fromJson(entry))
          .toList();
    } else if (json['entries'] != null) {
      entries = (json['entries'] as List)
          .map((entry) => AttendanceEntry.fromJson(entry))
          .toList();
    }

    return Attendance(
      id: json['id'] ?? '',
      date: json['date'] ?? 0,
      day: json['day'] ?? 'Unknown',
      status: json['status'] ?? 'Unknown',
      checkInTime: parseDate(json['checkInTime']),
      checkOutTime: parseDate(json['checkOutTime']),
      multipleEntries: entries,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'day': day,
      'status': status,
      'check_in_time': checkInTime?.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'multiple_entries': multipleEntries?.map((e) => e.toJson()).toList(),
    };
  }

  // **NEW: Get first check-in time from multiple entries**
  DateTime? get firstCheckInTime {
    if (multipleEntries == null || multipleEntries!.isEmpty) {
      return checkInTime;
    }

    // Filter consecutive duplicates and get cleaned entries
    List<AttendanceEntry> cleanedEntries = _removeConsecutiveDuplicates(multipleEntries!);
    
    // Find the first 'IN' entry after cleaning
    for (var entry in cleanedEntries) {
      if (entry.type == 'IN') {
        return entry.timestamp;
      }
    }
    
    return checkInTime;
  }

  // **NEW: Get latest check-out time from multiple entries**
  DateTime? get latestCheckOutTime {
    if (multipleEntries == null || multipleEntries!.isEmpty) {
      return checkOutTime;
    }

    // Filter consecutive duplicates and get cleaned entries
    List<AttendanceEntry> cleanedEntries = _removeConsecutiveDuplicates(multipleEntries!);
    
    // Find the last 'OUT' entry after cleaning (iterate backwards)
    for (int i = cleanedEntries.length - 1; i >= 0; i--) {
      if (cleanedEntries[i].type == 'OUT') {
        return cleanedEntries[i].timestamp;
      }
    }
    
    return checkOutTime;
  }

  // **NEW: Remove consecutive duplicate entries, keeping the latest one**
  List<AttendanceEntry> _removeConsecutiveDuplicates(List<AttendanceEntry> entries) {
    if (entries.isEmpty) return [];

    // Sort entries by timestamp first
    List<AttendanceEntry> sortedEntries = List.from(entries);
    sortedEntries.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    List<AttendanceEntry> cleaned = [];
    String? lastType;

    for (var entry in sortedEntries) {
      if (entry.type == lastType) {
        // Remove the previous duplicate and add the current (latest) one
        if (cleaned.isNotEmpty) cleaned.removeLast();
      }
      cleaned.add(entry);
      lastType = entry.type;
    }

    return cleaned;
  }

  // **UPDATED: Calculate working hours from cleaned entries**
  double get workingHours {
    if (multipleEntries != null && multipleEntries!.isNotEmpty) {
      return _calculateWorkingHoursFromEntries(_removeConsecutiveDuplicates(multipleEntries!));
    }
    
    // Fallback to single entry calculation
    if (checkInTime == null || checkOutTime == null) {
      return 0.0;
    }
    
    Duration workDuration = checkOutTime!.difference(checkInTime!);
    return workDuration.inMinutes / 60.0;
  }

  // **UPDATED: Calculate working hours from cleaned multiple entries**
  double _calculateWorkingHoursFromEntries(List<AttendanceEntry> cleanedEntries) {
    double totalHours = 0.0;
    DateTime? lastCheckIn;

    for (var entry in cleanedEntries) {
      if (entry.type == 'IN') {
        lastCheckIn = entry.timestamp;
      } else if (entry.type == 'OUT' && lastCheckIn != null) {
        Duration workPeriod = entry.timestamp.difference(lastCheckIn);
        totalHours += workPeriod.inMinutes / 60.0;
        lastCheckIn = null; // Reset for next check-in
      }
    }

    // If there's an unclosed check-in, calculate up to now or end of work day
    if (lastCheckIn != null) {
      DateTime now = DateTime.now();
      DateTime endOfWorkDay = DateTime(now.year, now.month, now.day, 19, 0); // 7 PM
      DateTime endTime = now.isBefore(endOfWorkDay) ? now : endOfWorkDay;
      
      if (endTime.isAfter(lastCheckIn)) {
        Duration workPeriod = endTime.difference(lastCheckIn);
        totalHours += workPeriod.inMinutes / 60.0;
      }
    }

    return totalHours;
  }

  String get formattedWorkingHours {
    double hours = workingHours;
    if (hours == 0.0) return "0h 0m";
    
    int wholeHours = hours.floor();
    int minutes = ((hours - wholeHours) * 60).round();
    return "${wholeHours}h ${minutes}m";
  }

  String get calculatedAttendanceStatus {
    if (firstCheckInTime == null) {
      return "Absent";
    }
    
    double hours = workingHours;
    
    if (hours >= 9.0) {
      return "Present";
    } else if (hours > 0.0) {
      return "Half Day";
    } else {
      return "Absent";
    }
  }

  bool get isValidRecord {
    return firstCheckInTime != null;
  }

  String get checkInOutCount {
    if (multipleEntries == null || multipleEntries!.isEmpty) {
      return "1/1";
    }

    List<AttendanceEntry> cleaned = _removeConsecutiveDuplicates(multipleEntries!);
    int inCount = cleaned.where((e) => e.type == 'IN').length;
    int outCount = cleaned.where((e) => e.type == 'OUT').length;
    
    return "$inCount/$outCount";
  }

  // **FIXED: Format times without problematic timezone conversion**
  String get formattedFirstCheckIn {
    DateTime? firstIn = firstCheckInTime;
    if (firstIn == null) return "N/A";
    return DateFormat('hh:mm a').format(firstIn);
  }

  String get formattedLatestCheckOut {
    DateTime? latestOut = latestCheckOutTime;
    if (latestOut == null) return "N/A";
    return DateFormat('hh:mm a').format(latestOut);
  }

  String get formattedDate {
    if (firstCheckInTime == null) {
      return 'N/A';
    }
    return DateFormat('dd-MM-yyyy').format(firstCheckInTime!);
  }
}

// **NEW: Class to represent individual check-in/check-out entries**
class AttendanceEntry {
  final DateTime timestamp;
  final String type; // 'IN' or 'OUT'
  final double? latitude;
  final double? longitude;

  AttendanceEntry({
    required this.timestamp,
    required this.type,
    this.latitude,
    this.longitude,
  });

  factory AttendanceEntry.fromJson(Map<String, dynamic> json) {
    DateTime parsedTime = DateTime.parse(json['timestamp']);
    // **FIXED: Convert to local time if UTC**
    if (parsedTime.isUtc) {
      parsedTime = parsedTime.toLocal();
    }
    
    return AttendanceEntry(
      timestamp: parsedTime,
      type: json['type'] ?? 'IN',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

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
    List<Attendance>? attendanceList,
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
