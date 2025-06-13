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
import 'package:flutter_background_service_platform_interface/flutter_background_service_platform_interface.dart';
import 'package:intl/intl.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:new_hrms/employee/pages/attendance/attendance_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:awesome_notifications/awesome_notifications.dart';

// Define office location constants
const double OFFICE_LATITUDE = 19.0443696;
const double OFFICE_LONGITUDE = 73.0731067;
const double OFFICE_RADIUS = 100.0; // meters

// Channel IDs for notifications
const String NOTIFICATION_CHANNEL_ID = 'attendance_channel';
const int NOTIFICATION_ID = 888;

class AttendanceViewModel extends StateNotifier<AttendanceState> {
  final String? selectedYear;
  final String? selectedMonth;
  final String? selectedDay;

  AttendanceViewModel({
    this.selectedYear,
    this.selectedMonth,
    this.selectedDay,
  }) : super(AttendanceState.initial()) {
      debugPrint('[DEBUG] AttendanceViewModel constructor called');
    _requestInitialLocationPermission().then((_) {
      debugPrint('[DEBUG] Finished initial location permission request');
      initializeBackgroundService();
    });
    // Fetch attendance records on initialization
    fetchAttendanceRecords();
  }

  // Request initial location permission from the UI thread
  Future<void> _requestInitialLocationPermission() async {
    debugPrint('[DEBUG] _requestInitialLocationPermission() START');
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('[DEBUG] Location services enabled: $serviceEnabled');
      if (!serviceEnabled) {
        // We can't enable location services programmatically, but we can store this state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('location_services_enabled', false);
        debugPrint('[DEBUG] Location services not enabled, returning early');
        debugPrint('[DEBUG] _requestInitialLocationPermission() END');
        return;
      }

      // Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('[DEBUG] Location permission: $permission');
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint('[DEBUG] Requested location permission, result: $permission');
        // Store the permission result
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('location_permission', permission.toString());
      }
    } catch (e) {
      print("Error requesting initial location permission: $e");
    }
  }

  // Initialize background service
  Future<void> initializeBackgroundService() async {
    debugPrint('[DEBUG] initializeBackgroundService() START');
    final service = FlutterBackgroundService();
    
    try {
      bool isRunning = await service.isRunning();
      debugPrint('[DEBUG] Background service running: $isRunning');
      if (!isRunning) {
        await service.configure(
          androidConfiguration: AndroidConfiguration(
            onStart: onStart,
            isForegroundMode: true,
            autoStart: true,
            notificationChannelId: NOTIFICATION_CHANNEL_ID,
            initialNotificationTitle: "Attendance Tracking",
            initialNotificationContent: "Tracking your office presence",
            foregroundServiceNotificationId: NOTIFICATION_ID,
          ),
          iosConfiguration: IosConfiguration(
            autoStart: true,
            onForeground: onStart,
            onBackground: onIosBackground,
          ),
        );
        await service.startService();
        debugPrint('[DEBUG] Background service configured and started');
      }
    } catch (e) {
      print("Error initializing background service: $e");
    }
  }

  // iOS background handling
  static Future<bool> onIosBackground(ServiceInstance service) async {
    debugPrint('[DEBUG] onIosBackground() called');
    return true;
  }

  // Background service entry point
  static void onStart(ServiceInstance service) async {
    debugPrint('[DEBUG] onStart() START');
    // REMOVED DartPluginRegistrant.ensureInitialized() as it causes issues in background isolate

    // For Android, make sure to create a valid notification
    if (service is AndroidServiceInstance) {
      debugPrint('[DEBUG] Service is AndroidServiceInstance');
      service.setAsForegroundService();
      
      // Make sure to update the notification periodically
      service.setForegroundNotificationInfo(
        title: "Attendance Tracker",
        content: "Running in background",
      );
      
      service.on('setAsForeground').listen((event) {
        debugPrint('[DEBUG] setAsForeground event received');
        service.setAsForegroundService();
        service.setForegroundNotificationInfo(
          title: "Attendance Tracker",
          content: "Running in foreground",
        );
      });

      service.on('setAsBackground').listen((event) {
        debugPrint('[DEBUG] setAsBackground event received');
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      debugPrint('[DEBUG] stopService event received');
      service.stopSelf();
    });

    // Run the location check right away
    await backgroundLocationCheck(service);

    // Set up periodic location checks and notification updates
    Timer.periodic(const Duration(minutes: 5), (timer) async {
      debugPrint('[DEBUG] Timer tick: running backgroundLocationCheck');
      await backgroundLocationCheck(service);
      
      if (service is AndroidServiceInstance) {
        // Update notification to keep it fresh and prevent ANR
        service.setForegroundNotificationInfo(
          title: "Attendance Tracker",
          content: "Checking location: ${DateFormat('HH:mm').format(DateTime.now())}",
        );
      }
    });
  }

  // Background location check method
  static Future<void> backgroundLocationCheck(ServiceInstance service) async {
    debugPrint('[DEBUG] backgroundLocationCheck() START'); 
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        print('[LOCATION DEBUG] ${DateTime.now()}: No auth token found, skipping location check');
        return;
      }

      // Get current time
      final now = DateTime.now();
      final currentHour = now.hour;
      final formattedTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📍 [LOCATION CHECK] $formattedTime');
      
      // Only proceed during working hours (e.g., 8 AM to 6 PM)
      if (currentHour < 9 || currentHour > 18) {
        print('⏰ [LOCATION DEBUG] Outside working hours (current hour: $currentHour), skipping check');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return;
      }

      // Check if already checked in today
      final lastCheckInDate = prefs.getString('last_checkin_date');
      final today = DateFormat('yyyy-MM-dd').format(now);
      final isCheckedIn = lastCheckInDate == today;
      final isCheckedOut = prefs.getBool('checked_out_today') ?? false;

      print('📆 [LOCATION DEBUG] Today: $today');
      print('📆 [LOCATION DEBUG] Last check-in date: ${lastCheckInDate ?? "None"}');
      print('📆 [LOCATION DEBUG] Check-in status: ${isCheckedIn ? "Checked in" : "Not checked in"}');
      print('📆 [LOCATION DEBUG] Check-out status: ${isCheckedOut ? "Checked out" : "Not checked out"}');
      
      // Check location permission - IMPROVED HANDLING
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Try to request permission from background
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || 
            permission == LocationPermission.deniedForever) {
          print('⚠️ [LOCATION DEBUG] Location permission denied: $permission');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          
          // Create notification to prompt user to enable permissions
          AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: NOTIFICATION_ID + 2,
              channelKey: NOTIFICATION_CHANNEL_ID,
              title: 'Location Permission Required',
              body: 'Please enable location permissions for automatic attendance tracking',
            ),
          );
          return;
        }
      }

      // Request location service if not enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('⚠️ [LOCATION DEBUG] Location services disabled');
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: "Attendance Tracker",
            content: "Location services disabled. Please enable for automatic check-in.",
          );
        }
        
        // Create notification to prompt user to enable location services
        AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: NOTIFICATION_ID + 3,
            channelKey: NOTIFICATION_CHANNEL_ID,
            title: 'Location Services Disabled',
            body: 'Please enable location services for automatic attendance tracking',
          ),
        );
        
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return;
      }

      print('🔄 [LOCATION DEBUG] Trying to get current position...');

      // Get current location with timeout to prevent hanging
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10)
      ).catchError((e) {
        print("Error getting location: $e");
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
          headingAccuracy: 0
        );
      });

      // If invalid position (error occurred), return
      if (position.latitude == 0 && position.longitude == 0) {
        print('❌ [LOCATION DEBUG] Invalid position received, skipping check');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return;
      }

      // Log location data every time it's checked (every 5 minutes)
      print('📍 [LOCATION DEBUG] Position details:');
      print('   Latitude: ${position.latitude.toStringAsFixed(6)}');
      print('   Longitude: ${position.longitude.toStringAsFixed(6)}');
      print('   Accuracy: ${position.accuracy.toStringAsFixed(2)} meters');
      print('   Altitude: ${position.altitude.toStringAsFixed(2)} meters');
      print('   Timestamp: ${position.timestamp}');

      // Check if within office radius
      double distanceInMeters = Geolocator.distanceBetween(
        OFFICE_LATITUDE, 
        OFFICE_LONGITUDE, 
        position.latitude, 
        position.longitude
      );

      print('🏢 [LOCATION DEBUG] Office distance: ${distanceInMeters.toStringAsFixed(2)} meters');
      print('🏢 [LOCATION DEBUG] Office radius limit: $OFFICE_RADIUS meters');

      if (distanceInMeters <= OFFICE_RADIUS) {
        print('✅ [LOCATION DEBUG] Employee is WITHIN office radius');
      } else {
        print('❌ [LOCATION DEBUG] Employee is OUTSIDE office radius');
      }

      // Get decoded token
      final decodedToken = JwtDecoder.decode(token);
      final employeeId = decodedToken['_id'];
      print('👤 [LOCATION DEBUG] Employee ID: $employeeId');

      // Check if user is checked in but not yet checked out
      if (isCheckedIn && !isCheckedOut) {
        // If user is outside office radius and already checked in but not checked out
        if (distanceInMeters > OFFICE_RADIUS) {
          print('🔄 [LOCATION DEBUG] Attempting auto check-out...');
          // Perform auto check-out
          final response = await http.post(
            Uri.parse('https://neoe2e.neophyte.live/hrms-api/api/employee/mark-employee-checkout'),
            body: jsonEncode({
              'employeeID': employeeId,
              'latitude': position.latitude.toString(),
              'longitude': position.longitude.toString(),
            }),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Cookie': 'accessToken=$token',
            },
          ).timeout(const Duration(seconds: 30), onTimeout: () {
            print('⚠️ [LOCATION DEBUG] Check-out API request timed out');
            return http.Response('{"error": "timeout"}', 408);
          });

          print('📡 [LOCATION DEBUG] Check-out API response status: ${response.statusCode}');

          if (response.statusCode == 200) {
            // Mark as checked out
            print('✅ [LOCATION DEBUG] Auto check-out successful');
            await prefs.setBool('checked_out_today', true);
            
            // Trigger notification for automatic check-out
            AwesomeNotifications().createNotification(
              content: NotificationContent(
                id: NOTIFICATION_ID + 1,
                channelKey: NOTIFICATION_CHANNEL_ID,
                title: 'Auto Check-out',
                body: 'You have been automatically checked out as you left the office area.',
              ),
            );
          }
        }
      } else if (!isCheckedIn && distanceInMeters <= OFFICE_RADIUS) {
        // If user is within office radius and not checked in yet, mark attendance
        print('🔄 [LOCATION DEBUG] Attempting auto check-in...');
        final requestBody = {
          "employeeID": employeeId,
          "latitude": position.latitude.toString(),
          "longitude": position.longitude.toString(),
          "camera": "false",
        };

        final response = await http.post(
          Uri.parse('https://neoe2e.neophyte.live/hrms-api/api/employee/mark-employee-checkin'),
          body: jsonEncode(requestBody),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Cookie': 'accessToken=$token',
          },
        ).timeout(const Duration(seconds: 30), onTimeout: () {
          print('⚠️ [LOCATION DEBUG] Check-in API request timed out');
          return http.Response('{"error": "timeout"}', 408);
        });

        print('📡 [LOCATION DEBUG] Check-in API response status: ${response.statusCode}');

        if (response.statusCode == 200) {
          // Save successful check-in date
          await prefs.setString('last_checkin_date', today);
          await prefs.setBool('checked_out_today', false);
          await prefs.setBool('attendanceMarked', true);

          // Trigger Awesome Notification
          AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: NOTIFICATION_ID,
              channelKey: NOTIFICATION_CHANNEL_ID,
              title: 'Attendance Marked',
              body: 'You have been automatically checked in',
            ),
          );
        }
      }
    } catch (e) {
      print('Error in background location check: $e');
    }
  }

  // Method to check-in a user manually
  Future<void> checkIn() async {
    state = state.copyWith(isLoading: true, errorMessage: '', successMessage: '');

    try {
      // Improved location permission handling
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
      
      // Check if within office radius
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

      final requestBody = {
        "employeeID": decodedToken['_id'],
        "latitude": position.latitude.toString(),
        "longitude": position.longitude.toString(),
        "camera": "false"
      };

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

      if (response.statusCode == 200) {
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        await prefs.setString('last_checkin_date', today);
        await prefs.setBool('checked_out_today', false);
        
        state = state.copyWith(
          isLoading: false, 
          successMessage: 'Successfully checked in'
        );
        
        // Refresh the attendance list after check-in
        await fetchAttendanceRecords();

        // Trigger Awesome Notification for check-in
        AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: NOTIFICATION_ID,
            channelKey: NOTIFICATION_CHANNEL_ID,
            title: 'Successfully Checked In',
            body: 'You have successfully checked in.',
          ),
        );
      } else {
        final errorMessage = jsonDecode(response.body)['message'] ?? 'Failed to check-in';
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

  // Check-out method
  Future<void> checkOut() async {
    state = state.copyWith(isLoading: true, errorMessage: '', successMessage: '');

    try {
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
      
      // Check if within office radius
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

      final response = await http.post(
        Uri.parse('https://neoe2e.neophyte.live/hrms-api/api/employee/mark-employee-checkout'),
        body: jsonEncode({
          'employeeID': decodedToken['_id'],
          'latitude': position.latitude.toString(),
          'longitude': position.longitude.toString(),
        }),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': 'accessToken=$token',
        },
      );

      if (response.statusCode == 200) {
        await prefs.setBool('checked_out_today', true);
        
        state = state.copyWith(
          isLoading: false, 
          successMessage: 'Successfully checked out'
        );
        
        // Refresh the attendance list after check-out
        await fetchAttendanceRecords();

        // Trigger Awesome Notification for check-out
        AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: NOTIFICATION_ID,
            channelKey: NOTIFICATION_CHANNEL_ID,
            title: 'Successfully Checked Out',
            body: 'You have successfully checked out.',
          ),
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

  // Method to reset filters and fetch all attendance records
Future<void> resetFiltersAndFetchAttendance() async {
  // Reset selected filters
  state = state.copyWith(
    selectedYear: null,
    selectedMonth: null,
    selectedDay: null,
    isLoading: true, // Set loading to true while fetching data
    errorMessage: '',
    successMessage: '',
  );

  // Fetch all attendance records without applying any filters
  await fetchAttendanceRecords();
}


  // Fetch attendance records
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

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          List<dynamic> data = responseData['data'];

          if (data.isNotEmpty) {
            List<Attendance> attendanceRecords = 
                data.map((record) => Attendance.fromJson(record)).toList();

            // Apply filters
            if (state.selectedYear != null) {
              attendanceRecords = attendanceRecords
                  .where((attendance) => attendance.checkInTime.year.toString() == state.selectedYear)
                  .toList();
            }

            if (state.selectedMonth != null) {
              attendanceRecords = attendanceRecords
                  .where((attendance) {
                    String month = DateFormat('MMMM').format(attendance.checkInTime);
                    return month.toLowerCase() == state.selectedMonth!.toLowerCase();
                  })
                  .toList();
            }

            if (state.selectedDay != null) {
              attendanceRecords = attendanceRecords
                  .where((attendance) => attendance.checkInTime.day.toString() == state.selectedDay)
                  .toList();
            }

            state = state.copyWith(
              isLoading: false,
              attendanceList: attendanceRecords,
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

  // Location permission check and request
  Future<LocationPermission> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
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