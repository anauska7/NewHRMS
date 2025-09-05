import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_background_service_ios/flutter_background_service_ios.dart';
import 'package:intl/intl.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:new_hrms/employee/pages/attendance/attendance_model.dart';
import 'package:new_hrms/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

const double OFFICE_LATITUDE = 19.0443696;
const double OFFICE_LONGITUDE = 73.0731067;
const double OFFICE_RADIUS = 100.0; // meters

class AttendanceViewModel extends StateNotifier<AttendanceState> {
  final String? selectedYear;
  final String? selectedMonth;
  final String? selectedDay;

  AttendanceViewModel({
    this.selectedYear,
    this.selectedMonth,
    this.selectedDay,
  }) : super(AttendanceState.initial()) {
    debugPrint('🏗️ [CONSTRUCTOR] AttendanceViewModel constructor called');
    debugPrint('🏗️ [CONSTRUCTOR] Initial filters - Year: $selectedYear, Month: $selectedMonth, Day: $selectedDay');
    debugPrint('🏗️ [CONSTRUCTOR] Office coordinates: LAT=$OFFICE_LATITUDE, LNG=$OFFICE_LONGITUDE, RADIUS=${OFFICE_RADIUS}m');
    _initializeServices();
    fetchAttendanceRecords();
    debugPrint('🏗️ [CONSTRUCTOR] Constructor completed');
  }

  Future<void> _initializeServices() async {
    debugPrint('🔧 [INIT_SERVICES] Starting service initialization');
    debugPrint('🔧 [INIT_SERVICES] Current time: ${DateTime.now()}');
    try {
      debugPrint('🔧 [INIT_SERVICES] Step 1: Initializing notification service...');
      await NotificationService.initialize();
      debugPrint('✅ [INIT_SERVICES] Notification service initialized successfully');
      
      debugPrint('🔧 [INIT_SERVICES] Step 2: Requesting initial location permission...');
      await _requestInitialLocationPermission();
      debugPrint('✅ [INIT_SERVICES] Location permission request completed');
      
      debugPrint('🔧 [INIT_SERVICES] Step 3: Initializing background service...');
      await initializeBackgroundService();
      debugPrint('✅ [INIT_SERVICES] Background service initialization completed');
      
      debugPrint('🎉 [INIT_SERVICES] All services initialized successfully');
    } catch (e) {
      debugPrint('❌ [INIT_SERVICES] Error during service initialization: $e');
      debugPrint('❌ [INIT_SERVICES] Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _requestInitialLocationPermission() async {
    debugPrint('🌍 [LOCATION_PERM] _requestInitialLocationPermission() START');
    try {
      debugPrint('🌍 [LOCATION_PERM] Checking if location services are enabled...');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('🌍 [LOCATION_PERM] Location services enabled: $serviceEnabled');
      
      if (!serviceEnabled) {
        debugPrint('⚠️ [LOCATION_PERM] Location services not enabled, saving to preferences');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('location_services_enabled', false);
        debugPrint('💾 [LOCATION_PERM] Saved location_services_enabled: false');
        return;
      }

      debugPrint('🌍 [LOCATION_PERM] Checking current location permission...');
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('🌍 [LOCATION_PERM] Current location permission: $permission');
      
      if (permission == LocationPermission.denied) {
        debugPrint('🌍 [LOCATION_PERM] Permission denied, requesting permission...');
        permission = await Geolocator.requestPermission();
        debugPrint('🌍 [LOCATION_PERM] Permission request result: $permission');
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('location_permission', permission.toString());
        debugPrint('💾 [LOCATION_PERM] Saved location_permission to preferences: $permission');
      } else {
        debugPrint('✅ [LOCATION_PERM] Permission already granted: $permission');
      }

      debugPrint('🎉 [LOCATION_PERM] _requestInitialLocationPermission() completed successfully');
    } catch (e) {
      debugPrint('❌ [LOCATION_PERM] Error requesting initial location permission: $e');
      debugPrint('❌ [LOCATION_PERM] Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> initializeBackgroundService() async {
    debugPrint('🔧 [BG_SERVICE] initializeBackgroundService() START');
    final service = FlutterBackgroundService();
    try {
      debugPrint('🔧 [BG_SERVICE] Getting FlutterBackgroundService instance');
      bool isRunning = await service.isRunning();
      debugPrint('🔧 [BG_SERVICE] Background service running status: $isRunning');
      
      if (!isRunning) {
        debugPrint('🔧 [BG_SERVICE] Service not running, configuring service...');
        await service.configure(
          androidConfiguration: AndroidConfiguration(
            onStart: onStart,
            isForegroundMode: true,
            autoStart: true,
            notificationChannelId: 'attendance_channel',
            initialNotificationTitle: "Attendance Tracking",
            initialNotificationContent: "Tracking your office presence",
            foregroundServiceNotificationId: NotificationIds.attendance,
          ),
          iosConfiguration: IosConfiguration(
            autoStart: true,
            onForeground: onStart,
            onBackground: onIosBackground,
          ),
        );
        debugPrint('✅ [BG_SERVICE] Service configuration completed');
        
        debugPrint('🔧 [BG_SERVICE] Starting background service...');
        await service.startService();
        debugPrint('🎉 [BG_SERVICE] Background service started successfully');
      } else {
        debugPrint('ℹ️ [BG_SERVICE] Background service already running, skipping initialization');
      }
    } catch (e) {
      debugPrint('❌ [BG_SERVICE] Error initializing background service: $e');
      debugPrint('❌ [BG_SERVICE] Stack trace: ${StackTrace.current}');
    }
  }

  static Future<bool> onIosBackground(ServiceInstance service) async {
    debugPrint('🍎 [IOS_BG] onIosBackground() called');
    debugPrint('🍎 [IOS_BG] Service instance: ${service.toString()}');
    try {
      await NotificationService.initialize();
      debugPrint('✅ [IOS_BG] Notification service initialized in iOS background');
      return true;
    } catch (e) {
      debugPrint('❌ [IOS_BG] Error in iOS background: $e');
      return false;
    }
  }

  static void onStart(ServiceInstance service) async {
    debugPrint('🚀 [BG_START] onStart() START');
    debugPrint('🚀 [BG_START] Service instance type: ${service.runtimeType}');
    debugPrint('🚀 [BG_START] Current time: ${DateTime.now()}');
    
    try {
      debugPrint('🚀 [BG_START] Initializing notification service in background isolate...');
      await NotificationService.initialize();
      debugPrint('✅ [BG_START] Notification service initialized in background');

      if (service is AndroidServiceInstance) {
        debugPrint('🤖 [BG_START] Service is AndroidServiceInstance');
        debugPrint('🤖 [BG_START] Setting as foreground service...');
        service.setAsForegroundService();
        service.setForegroundNotificationInfo(
          title: "Attendance Tracker",
          content: "Running in background",
        );
        debugPrint('✅ [BG_START] Initial notification set');

        debugPrint('🤖 [BG_START] Setting up event listeners...');
        service.on('setAsForeground').listen((event) {
          debugPrint('📢 [BG_EVENT] setAsForeground event received: $event');
          service.setAsForegroundService();
          service.setForegroundNotificationInfo(
            title: "Attendance Tracker",
            content: "Running in foreground",
          );
        });

        service.on('setAsBackground').listen((event) {
          debugPrint('📢 [BG_EVENT] setAsBackground event received: $event');
          service.setAsBackgroundService();
        });
        debugPrint('✅ [BG_START] Event listeners configured');
      } else {
        debugPrint('🍎 [BG_START] Service is not AndroidServiceInstance (likely iOS)');
      }

      service.on('stopService').listen((event) {
        debugPrint('🛑 [BG_EVENT] stopService event received: $event');
        service.stopSelf();
      });

      debugPrint('🚀 [BG_START] Running initial location check...');
      await backgroundLocationCheck(service);
      debugPrint('✅ [BG_START] Initial location check completed');

      debugPrint('🚀 [BG_START] Setting up periodic timer (5 minutes)...');
      Timer.periodic(const Duration(minutes: 5), (timer) async {
        debugPrint('⏰ [TIMER] Timer tick: ${DateTime.now()}');
        await backgroundLocationCheck(service);
        
        if (service is AndroidServiceInstance) {
          debugPrint('⏰ [TIMER] Updating Android notification with productivity...');
          final prefs = await SharedPreferences.getInstance();
          final int totalMinutes = prefs.getInt('daily_productivity_minutes') ?? 0;
          final int hours = totalMinutes ~/ 60;
          final int minutes = totalMinutes % 60;
          final String productivityString = '${hours}h ${minutes}m';
          debugPrint('⏰ [TIMER] Current productivity: $productivityString');

          service.setForegroundNotificationInfo(
            title: "Attendance Tracker",
            content: "Productivity today: $productivityString",
          );
        }
      });

      debugPrint('🎉 [BG_START] Background service onStart() completed successfully');
    } catch (e) {
      debugPrint('❌ [BG_START] Error in onStart(): $e');
      debugPrint('❌ [BG_START] Stack trace: ${StackTrace.current}');
    }
  }

  static Future<void> backgroundLocationCheck(ServiceInstance service) async {
    debugPrint('🌍 [BG_LOCATION] backgroundLocationCheck() START');
    debugPrint('🌍 [BG_LOCATION] Service instance: ${service.toString()}');
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        debugPrint('❌ [BG_LOCATION] No auth token found, skipping location check');
        return;
      }

      final now = DateTime.now();
      final currentHour = now.hour;
      final formattedTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📍 [LOCATION CHECK] $formattedTime');
      debugPrint('⏰ [BG_LOCATION] Current hour: $currentHour');

      if (currentHour < 9 || currentHour >= 19) {
        debugPrint('⏰ [BG_LOCATION] Outside working hours (9 AM - 7 PM), skipping check');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return;
      }

      debugPrint('✅ [BG_LOCATION] Within working hours (9 AM - 7 PM), proceeding with check');

      final decodedToken = JwtDecoder.decode(token);
      final employeeId = decodedToken['_id'];
      final today = DateFormat('yyyy-MM-dd').format(now);

      debugPrint('📅 [BG_LOCATION] Today\'s date: $today');

      String? lastCheckinDate = prefs.getString('last_checkin_date');
      debugPrint('📅 [BG_LOCATION] Last check-in date from prefs: $lastCheckinDate');

      // **FIXED: Use local check-in status instead of server status for first-time check**
      bool hasManuallyCheckedInToday = lastCheckinDate == today;
      debugPrint('📅 [BG_LOCATION] Has manually checked in today (from prefs): $hasManuallyCheckedInToday');

      // Only fetch server status if we think they've checked in
      Map<String, dynamic>? attendanceStatus;
      bool isCurrentlyCheckedIn = false;
      
      if (hasManuallyCheckedInToday) {
        attendanceStatus = await _fetchTodayAttendanceStatusWithMultipleEntries(token, employeeId, today);
        isCurrentlyCheckedIn = _isCurrentlyCheckedIn(attendanceStatus['entries'] ?? []);
        debugPrint('📊 [BG_LOCATION] Server check-in status: $isCurrentlyCheckedIn');
      } else {
        debugPrint('📊 [BG_LOCATION] No manual check-in detected, skipping server check');
      }

      Position position = await _getCurrentPosition();
      if (position.latitude == 0 && position.longitude == 0) {
        debugPrint('❌ [BG_LOCATION] Invalid position received, skipping check');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return;
      }

      double distanceInMeters = Geolocator.distanceBetween(
        OFFICE_LATITUDE,
        OFFICE_LONGITUDE,
        position.latitude,
        position.longitude,
      );

      debugPrint('🏢 [BG_LOCATION] Distance to office: ${distanceInMeters.toStringAsFixed(2)} meters');

      if (distanceInMeters <= OFFICE_RADIUS) {
        debugPrint('✅ [BG_LOCATION] Employee is WITHIN office radius');

        // **FIXED: If no manual check-in today, skip automatic check-in**
        if (!hasManuallyCheckedInToday) {
          debugPrint('🚪 [BG_LOCATION] No manual check-in today, skipping automatic check-in');
          await _initializeProductivityTracking(prefs, today);
          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          return;
        }

        if (!isCurrentlyCheckedIn) {
          debugPrint('🚪 [BG_LOCATION] Employee is not checked in, attempting auto check-in...');
          await _performAutomaticCheckIn(token, employeeId, position, today, prefs);
        } else {
          debugPrint('📊 [BG_LOCATION] Employee is checked in, updating productivity...');
          await _updateProductivity(prefs, today);
        }
      } else {
        debugPrint('❌ [BG_LOCATION] Employee is OUTSIDE office radius');
        if (hasManuallyCheckedInToday && isCurrentlyCheckedIn) {
          debugPrint('🚪 [BG_LOCATION] Employee is checked in but outside office, attempting auto check-out...');
          await _performAutomaticCheckOut(token, employeeId, position, today, prefs);
        } else {
          debugPrint('ℹ️ [BG_LOCATION] Employee is outside office and not checked in, no action needed');
        }
      }

      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      debugPrint('❌ [BG_LOCATION] Error in background location check: $e');
      debugPrint('❌ [BG_LOCATION] Stack trace: ${StackTrace.current}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }

  // **FIXED: Enhanced with better error handling and retries**
  static Future<Map<String, dynamic>> _fetchTodayAttendanceStatusWithMultipleEntries(String token, String employeeId, String today) async {
    debugPrint('🔍 [FETCH_STATUS] _fetchTodayAttendanceStatusWithMultipleEntries() START');
    debugPrint('🔍 [FETCH_STATUS] Employee ID: $employeeId');
    debugPrint('🔍 [FETCH_STATUS] Date: $today');

    // **FIXED: Add retry mechanism for immediate post-check-in fetch**
    int maxRetries = 3;
    int retryDelay = 2; // seconds

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      debugPrint('🔍 [FETCH_STATUS] Attempt $attempt of $maxRetries');
      
      try {
        final response = await http.post(
          Uri.parse('http://192.168.1.5:5500/api/employee/view-employee-attendance'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Cookie': 'accessToken=$token',
          },
          body: jsonEncode({'employeeID': employeeId}),
        ).timeout(const Duration(seconds: 15));

        debugPrint('🔍 [FETCH_STATUS] Response status: ${response.statusCode}');
        debugPrint('🔍 [FETCH_STATUS] Response body length: ${response.body.length}');

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          debugPrint('🔍 [FETCH_STATUS] Response success: ${responseData['success']}');
          
          if (responseData['success'] == true) {
            List<dynamic> attendanceData = responseData['data'];
            debugPrint('🔍 [FETCH_STATUS] Found ${attendanceData.length} total records');

            // Sort by date descending to get today's record first
            attendanceData.sort((a, b) {
              try {
                DateTime dateA = DateTime.parse(a['checkInTime'] ?? '1970-01-01');
                DateTime dateB = DateTime.parse(b['checkInTime'] ?? '1970-01-01');
                return dateB.compareTo(dateA);
              } catch (e) {
                return 0;
              }
            });
            
            for (int i = 0; i < attendanceData.length; i++) {
              var record = attendanceData[i];
              debugPrint('🔍 [FETCH_STATUS] Checking record $i: ${record['checkInTime']}');
              
              if (record['checkInTime'] != null && record['checkInTime'] != 'null') {
                try {
                  DateTime checkInTime = DateTime.parse(record['checkInTime']);
                  if (checkInTime.isUtc) {
                    checkInTime = checkInTime.toLocal();
                  }
                  
                  if (checkInTime.year <= 1970) {
                    debugPrint('🔍 [FETCH_STATUS] Skipping 1970 date');
                    continue;
                  }
                  
                  String recordDate = DateFormat('yyyy-MM-dd').format(checkInTime);
                  debugPrint('🔍 [FETCH_STATUS] Record date: $recordDate vs Target: $today');
                  
                  if (recordDate == today) {
                    debugPrint('✅ [FETCH_STATUS] Found today\'s record on attempt $attempt!');
                    
                    List<Map<String, dynamic>> entries = [];
                    
                    if (record['multipleEntries'] != null) {
                      entries = List<Map<String, dynamic>>.from(record['multipleEntries']);
                      debugPrint('🔍 [FETCH_STATUS] Using multipleEntries: ${entries.length}');
                    } else if (record['entries'] != null) {
                      entries = List<Map<String, dynamic>>.from(record['entries']);
                      debugPrint('🔍 [FETCH_STATUS] Using entries: ${entries.length}');
                    } else {
                      entries.add({'timestamp': record['checkInTime'], 'type': 'IN'});
                      if (record['checkOutTime'] != null && record['checkOutTime'] != 'null') {
                        entries.add({'timestamp': record['checkOutTime'], 'type': 'OUT'});
                      }
                      debugPrint('🔍 [FETCH_STATUS] Created entries from check-in/out: ${entries.length}');
                    }
                    
                    final result = {
                      'hasAttendance': true,
                      'entries': entries,
                      'totalWorkingHours': record['totalWorkingHours'] ?? 0.0,
                    };
                    
                    debugPrint('🔍 [FETCH_STATUS] Returning successful result: $result');
                    return result;
                  }
                } catch (e) {
                  debugPrint('❌ [FETCH_STATUS] Error parsing record $i: $e');
                  continue;
                }
              }
            }
            
            debugPrint('ℹ️ [FETCH_STATUS] No today\'s record found on attempt $attempt');
          } else {
            debugPrint('❌ [FETCH_STATUS] API returned success: false');
          }
        } else {
          debugPrint('❌ [FETCH_STATUS] HTTP error: ${response.statusCode}');
        }
        
        // **FIXED: Retry logic for failed attempts**
        if (attempt < maxRetries) {
          debugPrint('🔄 [FETCH_STATUS] Retrying in ${retryDelay}s... (attempt $attempt/$maxRetries)');
          await Future.delayed(Duration(seconds: retryDelay));
          retryDelay *= 2; // Exponential backoff
        }
        
      } catch (e) {
        debugPrint('❌ [FETCH_STATUS] Network error on attempt $attempt: $e');
        if (attempt < maxRetries) {
          debugPrint('🔄 [FETCH_STATUS] Retrying in ${retryDelay}s... (attempt $attempt/$maxRetries)');
          await Future.delayed(Duration(seconds: retryDelay));
          retryDelay *= 2;
        }
      }
    }
    
    debugPrint('❌ [FETCH_STATUS] All retry attempts failed');
    
    // Return cached status if available
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStatus = prefs.getString('today_attendance_status');
      if (cachedStatus != null) {
        debugPrint('🔄 [FETCH_STATUS] Returning cached status');
        return jsonDecode(cachedStatus) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('❌ [FETCH_STATUS] Error parsing cached status: $e');
    }
    
    return {
      'hasAttendance': false,
      'entries': <Map<String, dynamic>>[],
      'totalWorkingHours': 0.0,
    };
  }

  static bool _isCurrentlyCheckedIn(List<Map<String, dynamic>> entries) {
    debugPrint('🔍 [CHECK_STATUS] _isCurrentlyCheckedIn() START');
    debugPrint('🔍 [CHECK_STATUS] Number of entries: ${entries.length}');
    
    if (entries.isEmpty) {
      debugPrint('🔍 [CHECK_STATUS] No entries, returning false');
      return false;
    }
    
    // Sort entries by timestamp (most recent first)
    entries.sort((a, b) {
      DateTime timeA = DateTime.parse(a['timestamp']);
      DateTime timeB = DateTime.parse(b['timestamp']);
      return timeB.compareTo(timeA);
    });
    
    String lastEntryType = entries.first['type'] ?? 'OUT';
    bool isCheckedIn = lastEntryType == 'IN';
    debugPrint('🔍 [CHECK_STATUS] Last entry type: $lastEntryType, checked in: $isCheckedIn');
    return isCheckedIn;
  }

  static Future<Position> _getCurrentPosition() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      return position;
    } catch (e) {
      return Position(
        latitude: 0,
        longitude: 0,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }
  }

  static Future<void> _performAutomaticCheckIn(String token, String employeeId, Position position, String today, SharedPreferences prefs) async {
    debugPrint('🚪 [AUTO_CHECKIN] _performAutomaticCheckIn() START');
    
    final dailyProductivityMinutes = prefs.getInt('daily_productivity_minutes') ?? 0;
    
    final requestBody = {
      "employeeID": employeeId,
      "latitude": position.latitude.toString(),
      "longitude": position.longitude.toString(),
      "productivity": dailyProductivityMinutes,
      "isMobile": true,
    };

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.5:5500/api/employee/mark-employee-checkin'),
        body: jsonEncode(requestBody),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': 'accessToken=$token',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        debugPrint('✅ [AUTO_CHECKIN] Auto check-in successful');
        await prefs.setString('last_checkin_date', today);
        await prefs.setString('last_entry_type', 'IN');
        await prefs.setInt('last_entry_time', DateTime.now().millisecondsSinceEpoch);
        
        await _refreshAttendanceStatus(prefs, today);
        await _initializeProductivityTracking(prefs, today);
        
        // **FIXED: Safe notification call**
        try {
          await NotificationService.showAttendanceNotification(
            id: NotificationIds.checkIn,
            title: 'Auto Check-in Successful',
            body: 'You have been automatically checked in. You need to work 9 hours to be marked Present!',
          );
        } catch (e) {
          debugPrint('❌ [AUTO_CHECKIN] Notification error: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ [AUTO_CHECKIN] Error: $e');
    }
  }

  static Future<void> _performAutomaticCheckOut(String token, String employeeId, Position position, String today, SharedPreferences prefs) async {
    debugPrint('🚪 [AUTO_CHECKOUT] _performAutomaticCheckOut() START');
    
    int dailyProductivityMinutes = prefs.getInt('daily_productivity_minutes') ?? 0;
    double workingHours = dailyProductivityMinutes / 60.0;
    
    String attendanceStatus;
    if (workingHours >= 9.0) {
      attendanceStatus = "Present";
    } else if (workingHours > 0.0) {
      attendanceStatus = "Half Day";
    } else {
      attendanceStatus = "Absent";
    }

    final requestBody = {
      "employeeID": employeeId,
      "latitude": position.latitude.toString(),
      "longitude": position.longitude.toString(),
      "productivity": dailyProductivityMinutes,
      "isMobile": true,
    };

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.5:5500/api/employee/mark-employee-checkout'),
        body: jsonEncode(requestBody),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': 'accessToken=$token',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        debugPrint('✅ [AUTO_CHECKOUT] Auto check-out successful');
        await prefs.setString('last_entry_type', 'OUT');
        await prefs.setInt('last_entry_time', DateTime.now().millisecondsSinceEpoch);
        
        await _refreshAttendanceStatus(prefs, today);
        
        String hoursText = "${workingHours.floor()}h ${(workingHours % 1 * 60).round()}m";
        String notificationBody = attendanceStatus == "Present" 
          ? '✅ Auto check-out complete! Status: Present ($hoursText)'
          : attendanceStatus == "Half Day" 
            ? '⚠️ Auto check-out complete. Status: Half Day ($hoursText)'
            : '❌ Auto check-out complete. Status: Absent ($hoursText)';
        
        // **FIXED: Safe notification call**
        try {
          await NotificationService.showAttendanceNotification(
            id: NotificationIds.checkOut,
            title: 'Auto Check-out Complete',
            body: notificationBody,
          );
        } catch (e) {
          debugPrint('❌ [AUTO_CHECKOUT] Notification error: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ [AUTO_CHECKOUT] Error: $e');
    }
  }

  // **FIXED: Enhanced refresh with better timing**
  static Future<void> _refreshAttendanceStatus(SharedPreferences prefs, String today) async {
    debugPrint('🔄 [REFRESH_STATUS] Refreshing attendance status for today: $today');
    
    final token = prefs.getString('auth_token');
    if (token == null) return;
    
    final decodedToken = JwtDecoder.decode(token);
    final employeeId = decodedToken['_id'];
    
    // **FIXED: Add delay before fetching to allow server processing**
    await Future.delayed(const Duration(seconds: 2));
    
    // Force fetch the latest attendance status
    final attendanceStatus = await _fetchTodayAttendanceStatusWithMultipleEntries(token, employeeId, today);
    
    // Store the attendance status for immediate use
    await prefs.setString('today_attendance_status', jsonEncode(attendanceStatus));
    
    debugPrint('🔄 [REFRESH_STATUS] Status refreshed: ${attendanceStatus['hasAttendance']}');
  }

  static Future<void> _initializeProductivityTracking(SharedPreferences prefs, String today) async {
    debugPrint('📊 [PRODUCTIVITY] _initializeProductivityTracking() START');
    
    String? storedProductivityDate = prefs.getString('last_productivity_date');
    
    if (storedProductivityDate != today) {
      debugPrint('🔄 [PRODUCTIVITY] New day detected, resetting productivity...');
      await prefs.setInt('daily_productivity_minutes', 5);
      await prefs.setString('last_productivity_date', today);
      debugPrint('✅ [PRODUCTIVITY] Productivity reset to 5 minutes for new day');
    } else {
      debugPrint('📊 [PRODUCTIVITY] Same day, adding 5 minutes...');
      int currentMinutes = prefs.getInt('daily_productivity_minutes') ?? 0;
      int newMinutes = currentMinutes + 5;
      await prefs.setInt('daily_productivity_minutes', newMinutes);
      debugPrint('✅ [PRODUCTIVITY] Added 5 minutes: $currentMinutes → $newMinutes');
    }
  }

  static Future<void> _updateProductivity(SharedPreferences prefs, String today) async {
    debugPrint('📊 [PRODUCTIVITY] _updateProductivity() START');
    
    String? storedProductivityDate = prefs.getString('last_productivity_date');
    
    if (storedProductivityDate != today) {
      debugPrint('🔄 [PRODUCTIVITY] New day detected, resetting productivity...');
      await prefs.setInt('daily_productivity_minutes', 5);
      await prefs.setString('last_productivity_date', today);
      debugPrint('✅ [PRODUCTIVITY] Productivity reset to 5 minutes for new day');
      return;
    }

    int dailyProductivityMinutes = prefs.getInt('daily_productivity_minutes') ?? 0;
    int newMinutes = dailyProductivityMinutes + 5;
    await prefs.setInt('daily_productivity_minutes', newMinutes);

    final int hours = newMinutes ~/ 60;
    final int minutes = newMinutes % 60;
    final String productivityString = '${hours}h ${minutes}m';
    debugPrint('📊 [PRODUCTIVITY] Updated: $dailyProductivityMinutes → $newMinutes minutes');

    if (newMinutes >= 540 && newMinutes % 30 == 0) {
      try {
        await NotificationService.showBasicNotification(
          id: NotificationIds.attendance + 200,
          title: 'Minimum Hours Completed! 🎉',
          body: 'You\'ve worked $productivityString today. You\'ll be marked Present!',
        );
      } catch (e) {
        debugPrint('❌ [PRODUCTIVITY] Notification error: $e');
      }
    } else if (newMinutes > 0 && newMinutes % 60 == 0) {
      String status = newMinutes >= 540 ? "Present" : "Half Day";
      try {
        await NotificationService.showBasicNotification(
          id: NotificationIds.attendance + 100,
          title: 'Working Hours Update',
          body: 'Current: $productivityString - Status: $status',
        );
      } catch (e) {
        debugPrint('❌ [PRODUCTIVITY] Notification error: $e');
      }
    }
  }

  Future<String> getDailyProductivity() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final storedProductivityDate = prefs.getString('last_productivity_date');

    if (storedProductivityDate != today) {
      return '0h 0m';
    }

    final totalMinutes = prefs.getInt('daily_productivity_minutes') ?? 0;
    final int hours = totalMinutes ~/ 60;
    final int minutes = totalMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  Future<String?> _uploadImage(String imagePath) async {
    debugPrint('📷 [UPLOAD_IMAGE] _uploadImage() START');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final decodedToken = JwtDecoder.decode(token);
      final employeeId = decodedToken['_id'];

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://192.168.1.5:5500/api/employee/upload-attendance-photo'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Cookie': 'accessToken=$token',
      });

      request.fields['employeeID'] = employeeId;

      File imageFile = File(imagePath);
      if (await imageFile.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'photo',
            imagePath,
            filename: 'attendance_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );
      } else {
        throw Exception('Image file not found');
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          String? photoUrl = responseData['data']['photoUrl'] ?? responseData['data']['photo_url'];
          debugPrint('✅ [UPLOAD_IMAGE] Upload successful');
          return photoUrl;
        } else {
          throw Exception(responseData['message'] ?? 'Failed to upload image');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [UPLOAD_IMAGE] Error: $e');
      return null;
    }
  }

  Future<void> checkIn({String? imagePath}) async {
    debugPrint('🚪 [MANUAL_CHECKIN] checkIn() START');
    
    state = state.copyWith(isLoading: true, errorMessage: '', successMessage: '');

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Location services are disabled. Please enable them to check in.'
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'Location permission is required to check-in'
          );
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      double distanceInMeters = Geolocator.distanceBetween(
        OFFICE_LATITUDE,
        OFFICE_LONGITUDE,
        position.latitude,
        position.longitude
      );

      if (distanceInMeters > OFFICE_RADIUS) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'You are not within the office area. Please move closer to mark attendance.'
        );
        return;
      }

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

      String? photoUrl;
      if (imagePath != null) {
        photoUrl = await _uploadImage(imagePath);
      }

      final dailyProductivityMinutes = prefs.getInt('daily_productivity_minutes') ?? 0;

      final requestBody = {
        "employeeID": decodedToken['_id'],
        "latitude": position.latitude.toString(),
        "longitude": position.longitude.toString(),
        "productivity": dailyProductivityMinutes,
        "isMobile": true,
        "camera": imagePath != null ? "true" : "false",
      };

      if (photoUrl != null) {
        requestBody["photoUrl"] = photoUrl;
      }

      final response = await http.post(
        Uri.parse('http://192.168.1.5:5500/api/employee/mark-employee-checkin'),
        body: jsonEncode(requestBody),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': 'accessToken=$token',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [MANUAL_CHECKIN] Check-in successful');
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        await prefs.setString('last_checkin_date', today);
        await prefs.setString('last_entry_type', 'IN');
        await prefs.setInt('last_entry_time', DateTime.now().millisecondsSinceEpoch);

        // **FIXED: Set manual check-in flag immediately**
        await prefs.setBool('has_manual_checkin_today', true);

        // Force refresh the attendance status after successful check-in
        await _refreshAttendanceStatus(prefs, today);
        await _initializeProductivityTracking(prefs, today);

        state = state.copyWith(
          isLoading: false,
          successMessage: imagePath != null 
            ? 'Successfully checked in with photo' 
            : 'Successfully checked in'
        );

        await fetchAttendanceRecords();

        // **FIXED: Safe notification call**
        try {
          await NotificationService.showAttendanceNotification(
            id: NotificationIds.checkIn,
            title: 'Successfully Checked In',
            body: imagePath != null 
              ? 'You have successfully checked in with photo. You need to work 9 hours to be marked Present!'
              : 'You have successfully checked in. You need to work 9 hours to be marked Present!',
          );
        } catch (e) {
          debugPrint('❌ [MANUAL_CHECKIN] Notification error: $e');
        }
      } else {
        final errorMessage = jsonDecode(response.body)['message'] ?? 'Failed to check-in';
        state = state.copyWith(
          isLoading: false,
          errorMessage: errorMessage
        );
      }
    } catch (e) {
      debugPrint('❌ [MANUAL_CHECKIN] Error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Network error: ${e.toString()}'
      );
    }
  }

  Future<void> checkOut({String? imagePath}) async {
    debugPrint('🚪 [MANUAL_CHECKOUT] checkOut() START');
    
    state = state.copyWith(isLoading: true, errorMessage: '', successMessage: '');

    try {
      // **FIXED: Use local preference check first, then verify with server**
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      // Check local preference first
      final lastCheckinDate = prefs.getString('last_checkin_date');
      final lastEntryType = prefs.getString('last_entry_type');
      
      debugPrint('🔍 [MANUAL_CHECKOUT] Local check - last checkin: $lastCheckinDate, last entry: $lastEntryType');
      
      if (lastCheckinDate != today || lastEntryType != 'IN') {
        debugPrint('❌ [MANUAL_CHECKOUT] Local check shows not checked in');
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'You are not currently checked in. Please check in first.'
        );
        return;
      }
      
      // **FIXED: Optional server verification with timeout**
      if (token != null) {
        try {
          final decodedToken = JwtDecoder.decode(token);
          final employeeId = decodedToken['_id'];
          
          // Use shorter timeout for server verification
          final attendanceStatus = await _fetchTodayAttendanceStatusWithMultipleEntries(token, employeeId, today);
          bool serverCheckedIn = _isCurrentlyCheckedIn(attendanceStatus['entries'] ?? []);
          
          debugPrint('🔍 [MANUAL_CHECKOUT] Server verification: $serverCheckedIn');
          
          // If server says not checked in but local says checked in, trust local for now
          if (!serverCheckedIn && attendanceStatus['hasAttendance'] == false) {
            debugPrint('⚠️ [MANUAL_CHECKOUT] Server/local mismatch, but proceeding with local state');
          }
        } catch (e) {
          debugPrint('⚠️ [MANUAL_CHECKOUT] Server verification failed, using local state: $e');
        }
      }

      LocationPermission permission = await _checkLocationPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Location permission is required to check-out'
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      double distanceInMeters = Geolocator.distanceBetween(
        OFFICE_LATITUDE,
        OFFICE_LONGITUDE,
        position.latitude,
        position.longitude
      );

      if (distanceInMeters > OFFICE_RADIUS) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'You are not within the office area. Please move closer to mark check-out.'
        );
        return;
      }

      if (token == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Authentication token not found'
        );
        return;
      }

      final decodedToken = JwtDecoder.decode(token);

      String? photoUrl;
      if (imagePath != null) {
        photoUrl = await _uploadImage(imagePath);
      }

      final dailyProductivityMinutes = prefs.getInt('daily_productivity_minutes') ?? 0;
      final double workingHours = dailyProductivityMinutes / 60.0;

      String attendanceStatus;
      if (workingHours >= 9.0) {
        attendanceStatus = "Present";
      } else if (workingHours > 0.0) {
        attendanceStatus = "Half Day";
      } else {
        attendanceStatus = "Absent";
      }

      final requestBody = {
        'employeeID': decodedToken['_id'],
        'latitude': position.latitude.toString(),
        'longitude': position.longitude.toString(),
        'productivity': dailyProductivityMinutes,
        'isMobile': true,
      };

      if (photoUrl != null) {
        requestBody["photoUrl"] = photoUrl;
      }

      final response = await http.post(
        Uri.parse('http://192.168.1.5:5500/api/employee/mark-employee-checkout'),
        body: jsonEncode(requestBody),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': 'accessToken=$token',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [MANUAL_CHECKOUT] Check-out successful');
        await prefs.setString('last_entry_type', 'OUT');
        await prefs.setInt('last_entry_time', DateTime.now().millisecondsSinceEpoch);

        // Force refresh the attendance status after successful check-out
        await _refreshAttendanceStatus(prefs, today);

        final finalProductivity = await getDailyProductivity();

        state = state.copyWith(
          isLoading: false,
          successMessage: imagePath != null 
            ? 'Successfully checked out with photo'
            : 'Successfully checked out'
        );

        await fetchAttendanceRecords();

        String notificationBody = attendanceStatus == "Present" 
          ? 'You have successfully checked out. Status: Present ($finalProductivity)'
          : attendanceStatus == "Half Day" 
            ? 'You have successfully checked out. Status: Half Day ($finalProductivity)'
            : 'You have successfully checked out. Status: Absent ($finalProductivity)';

        // **FIXED: Safe notification call**
        try {
          await NotificationService.showAttendanceNotification(
            id: NotificationIds.checkOut,
            title: 'Successfully Checked Out',
            body: notificationBody,
          );
        } catch (e) {
          debugPrint('❌ [MANUAL_CHECKOUT] Notification error: $e');
        }
      } else {
        final errorMessage = jsonDecode(response.body)['message'] ?? 'Failed to check-out';
        state = state.copyWith(
          isLoading: false,
          errorMessage: errorMessage
        );
      }
    } catch (e) {
      debugPrint('❌ [MANUAL_CHECKOUT] Error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Network error: ${e.toString()}'
      );
    }
  }

  Future<void> debugAttendanceStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    if (token != null) {
      final decodedToken = JwtDecoder.decode(token);
      final employeeId = decodedToken['_id'];
      
      debugPrint('🔍 [DEBUG] Checking attendance status for today: $today');
      debugPrint('🔍 [DEBUG] Employee ID: $employeeId');
      debugPrint('🔍 [DEBUG] Last check-in date: ${prefs.getString('last_checkin_date')}');
      debugPrint('🔍 [DEBUG] Last entry type: ${prefs.getString('last_entry_type')}');
      
      final status = await _fetchTodayAttendanceStatusWithMultipleEntries(token, employeeId, today);
      debugPrint('🔍 [DEBUG] Server status: $status');
      
      bool isCheckedIn = _isCurrentlyCheckedIn(status['entries'] ?? []);
      debugPrint('🔍 [DEBUG] Currently checked in: $isCheckedIn');
    }
  }

  Future<void> resetFiltersAndFetchAttendance() async {
    debugPrint('🔄 [RESET_FILTERS] resetFiltersAndFetchAttendance() START');
    state = state.copyWith(
      selectedYear: null,
      selectedMonth: null,
      selectedDay: null,
      isLoading: true,
      errorMessage: '',
      successMessage: '',
    );
    await fetchAttendanceRecordsWithFilters(year: null, month: null, day: null);
  }

  Future<void> fetchAttendanceRecordsWithFilters({String? year, String? month, String? day}) async {
    debugPrint('📋 [FETCH_RECORDS] fetchAttendanceRecordsWithFilters() START');
    
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
        Uri.parse('http://192.168.1.5:5500/api/employee/view-employee-attendance'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': 'accessToken=$token',
        },
        body: jsonEncode({'employeeID': employeeID}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          List<dynamic> data = responseData['data'];
          List<Attendance> attendanceRecords =
              data.map((record) => Attendance.fromJson(record)).toList();

          List<Attendance> validRecords = attendanceRecords
              .where((attendance) => attendance.isValidRecord)
              .toList();

          if (year != null) {
            validRecords = validRecords.where((attendance) =>
                attendance.firstCheckInTime != null &&
                attendance.firstCheckInTime!.year.toString() == year
            ).toList();
          }

          if (month != null) {
            validRecords = validRecords.where((attendance) {
              if (attendance.firstCheckInTime == null) return false;
              String monthStr = DateFormat('MMMM').format(attendance.firstCheckInTime!);
              return monthStr.toLowerCase() == month.toLowerCase();
            }).toList();
          }

          if (day != null) {
            validRecords = validRecords.where((attendance) =>
                attendance.firstCheckInTime != null &&
                attendance.firstCheckInTime!.day.toString() == day
            ).toList();
          }

          state = state.copyWith(
            isLoading: false,
            attendanceList: validRecords,
            successMessage: 'Attendance records fetched successfully'
          );
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

  Future<void> fetchAttendanceRecords() async {
    debugPrint('📋 [FETCH_RECORDS] fetchAttendanceRecords() START');
    
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
        Uri.parse('http://192.168.1.5:5500/api/employee/view-employee-attendance'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': 'accessToken=$token',
        },
        body: jsonEncode({'employeeID': employeeID}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          List<dynamic> data = responseData['data'];
          
          if (data.isNotEmpty) {
            List<Attendance> attendanceRecords =
                data.map((record) => Attendance.fromJson(record)).toList();

            List<Attendance> validRecords = attendanceRecords
                .where((attendance) => attendance.isValidRecord)
                .toList();

            // Apply filters based on state
            if (state.selectedYear != null) {
              validRecords = validRecords
                  .where((attendance) => attendance.firstCheckInTime != null &&
                      attendance.firstCheckInTime!.year.toString() == state.selectedYear)
                  .toList();
            }

            if (state.selectedMonth != null) {
              validRecords = validRecords
                  .where((attendance) {
                    if (attendance.firstCheckInTime == null) return false;
                    String month = DateFormat('MMMM').format(attendance.firstCheckInTime!);
                    return month.toLowerCase() == state.selectedMonth!.toLowerCase();
                  })
                  .toList();
            }

            if (state.selectedDay != null) {
              validRecords = validRecords
                  .where((attendance) => attendance.firstCheckInTime != null &&
                      attendance.firstCheckInTime!.day.toString() == state.selectedDay)
                  .toList();
            }

            state = state.copyWith(
              isLoading: false,
              attendanceList: validRecords,
              successMessage: 'Attendance records fetched successfully'
            );
          } else {
            state = state.copyWith(
              isLoading: false,
              attendanceList: [],
              successMessage: 'No attendance records found'
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

  void setSelectedYear(String? year) {
    debugPrint('🔧 [SET_FILTER] setSelectedYear() called with: $year');
    state = state.copyWith(selectedYear: year);
  }

  void setSelectedMonth(String? month) {
    debugPrint('🔧 [SET_FILTER] setSelectedMonth() called with: $month');
    state = state.copyWith(selectedMonth: month);
  }

  void setSelectedDay(String? day) {
    debugPrint('🔧 [SET_FILTER] setSelectedDay() called with: $day');
    state = state.copyWith(selectedDay: day);
  }

  Future<LocationPermission> _checkLocationPermission() async {
    debugPrint('🌍 [CHECK_PERMISSION] _checkLocationPermission() START');
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      return permission;
    } catch (e) {
      debugPrint('❌ [CHECK_PERMISSION] Error: $e');
      rethrow;
    }
  }
}

// Provider for the ViewModel
final attendanceViewModelProvider = StateNotifierProvider<AttendanceViewModel, AttendanceState>((ref) {
  debugPrint('🏭 [PROVIDER] Creating AttendanceViewModel provider');
  return AttendanceViewModel();
});
