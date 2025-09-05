import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:new_hrms/employee/pages/attendance/attendance_viewmodel.dart';
import 'package:new_hrms/employee/pages/attendance/attendance_model.dart';
import 'package:new_hrms/employee/pages/attendance/camera_screen.dart';
import 'package:new_hrms/employee/pages/attendance/camera_service.dart';
import 'package:new_hrms/employee/widgets/employee_drawer.dart';
import 'package:new_hrms/employee/widgets/employee_header.dart';

class AttendancePage extends ConsumerStatefulWidget {
  const AttendancePage({Key? key}) : super(key: key);

  @override
  ConsumerState createState() => _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage> {
  String? selectedYear;
  String? selectedMonth;
  String? selectedDay;
  DateTime? _lastBackPressed;
  String? _capturedImagePath;

  final List<String> years = ['2023', '2024', '2025'];
  final List<String> months = [
    'January', 'February', 'March', 'April',
    'May', 'June', 'July', 'August',
    'September', 'October', 'November', 'December'
  ];
  final List<String> days = List.generate(31, (index) => (index + 1).toString());

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future _initializeCamera() async {
    await CameraService.initializeCameras();
  }

  @override
  Widget build(BuildContext context) {
    final attendanceState = ref.watch(attendanceViewModelProvider);
    double screenWidth = MediaQuery.of(context).size.width;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (attendanceState.errorMessage.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(attendanceState.errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
      if (attendanceState.successMessage.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(attendanceState.successMessage),
            backgroundColor: Colors.green,
          ),
        );
      }
    });

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        final DateTime now = DateTime.now();
        if (_lastBackPressed == null ||
            now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to go to dashboard'),
              duration: Duration(seconds: 2),
            ),
          );
          _lastBackPressed = now;
          return;
        }
        if (now.difference(_lastBackPressed!) <= const Duration(seconds: 2)) {
          context.go('/employee/dashboard');
        }
      },
      child: Scaffold(
        appBar: const CustomHeader(title: "Attendance"),
        drawer: CustomDrawer(selectedScreen: "Attendance", userName: ''),
        body: RefreshIndicator(
          onRefresh: () async {
            await ref.read(attendanceViewModelProvider.notifier).resetFiltersAndFetchAttendance();
            setState(() {
              selectedYear = null;
              selectedMonth = null;
              selectedDay = null;
            });
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCameraSection(),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAttendanceButton('Check-In', Colors.green, () async {
                      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                      if (!serviceEnabled) {
                        _showLocationServiceAlert();
                        return;
                      }
                      ref.read(attendanceViewModelProvider.notifier).checkIn(
                        imagePath: _capturedImagePath
                      );
                    }),
                    const SizedBox(width: 10),
                    _buildAttendanceButton('Check-Out', Colors.red, () async {
                      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                      if (!serviceEnabled) {
                        _showLocationServiceAlert();
                        return;
                      }
                      ref.read(attendanceViewModelProvider.notifier).checkOut(
                        imagePath: _capturedImagePath
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 20),
                _buildDropdown('Year', years, (value) {
                  setState(() {
                    selectedYear = value;
                  });
                  ref.read(attendanceViewModelProvider.notifier).setSelectedYear(value);
                }, screenWidth * 0.8),
                const SizedBox(height: 10),
                _buildDropdown('Month', months, (value) {
                  setState(() {
                    selectedMonth = value;
                  });
                  ref.read(attendanceViewModelProvider.notifier).setSelectedMonth(value);
                }, screenWidth * 0.8),
                const SizedBox(height: 10),
                _buildDropdown('Day', days, (value) {
                  setState(() {
                    selectedDay = value;
                  });
                  ref.read(attendanceViewModelProvider.notifier).setSelectedDay(value);
                }, screenWidth * 0.8),
                const SizedBox(height: 10),
                Center(
                  child: ElevatedButton(
                    onPressed: _performSearch,
                    child: const Text("Search"),
                  ),
                ),
                const SizedBox(height: 20),
                if (attendanceState.isLoading)
                  const Center(child: CircularProgressIndicator()),
                _buildAttendanceTable(attendanceState.attendanceList),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance Photo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade50,
              ),
              child: _capturedImagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_capturedImagePath!),
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No photo taken',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openCamera,
                    icon: const Icon(Icons.camera_front),
                    label: const Text('Take Photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (_capturedImagePath != null) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _clearPhoto,
                    icon: const Icon(Icons.delete),
                    label: const Text('Clear'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future _openCamera() async {
    try {
      bool hasPermission = await _requestCameraPermission();
      if (!hasPermission) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CameraScreen(
            onImageCaptured: (String imagePath) {
              setState(() {
                _capturedImagePath = imagePath;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Photo captured successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            useFrontCamera: true,
          ),
        ),
      );
    } catch (e) {
      _showErrorDialog('Failed to open camera: ${e.toString()}');
    }
  }

  Future<bool> _requestCameraPermission() async {
    try {
      await CameraService.initializeCameras();
      final frontCamera = CameraService.getFrontCamera();
      if (frontCamera == null) {
        _showPermissionDialog();
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('Camera permission error: $e');
      _showPermissionDialog();
      return false;
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Camera Permission Required'),
          content: const Text('This app needs camera permission to take attendance photos. Please grant camera permission in your device settings.'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                _openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  void _openAppSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please go to Settings > Apps > Your App > Permissions and enable Camera'),
        duration: Duration(seconds: 5),
      ),
    );
  }

  void _clearPhoto() {
    setState(() {
      _capturedImagePath = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Photo cleared'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showLocationServiceAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Services Disabled'),
          content: const Text('Please enable location services to check-in/check-out'),
          actions: [
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                Geolocator.openLocationSettings();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAttendanceButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 16)
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, Function(String?) onChanged, double dropdownWidth) {
    String? value;
    if (label == 'Year') value = selectedYear;
    if (label == 'Month') value = selectedMonth;
    if (label == 'Day') value = selectedDay;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 13.0, right: 20.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey),
      ),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        isExpanded: true,
        value: value,
        items: items.map((String value) {
          return DropdownMenuItem(
            value: value,
            child: Container(
              width: dropdownWidth,
              child: Text(value),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        dropdownColor: Colors.white,
        menuMaxHeight: 200,
        alignment: Alignment.center,
      ),
    );
  }

  void _performSearch() {
    ref.read(attendanceViewModelProvider.notifier).fetchAttendanceRecords();
  }

  Widget _buildTableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildAttendanceTable(List? attendanceList) {
    if (attendanceList == null || attendanceList.isEmpty) {
      return const Center(child: Text('No attendance records found.'));
    }

    List validRecords = attendanceList
        .where((attendance) => attendance.isValidRecord)
        .toList();
    if (validRecords.isEmpty) {
      return const Center(child: Text('No valid attendance records found.'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        border: TableBorder.all(),
        columnWidths: const {
          0: FixedColumnWidth(40),
          1: FixedColumnWidth(100),
          2: FixedColumnWidth(70),
          3: FixedColumnWidth(90),
          4: FixedColumnWidth(90),
          5: FixedColumnWidth(90),
          6: FixedColumnWidth(90),
          7: FixedColumnWidth(60),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.green[200]),
            children: [
              _buildTableHeaderCell("#"),
              _buildTableHeaderCell("Date"),
              _buildTableHeaderCell("Day"),
              _buildTableHeaderCell("Status"),
              _buildTableHeaderCell("First In"),
              _buildTableHeaderCell("Last Out"),
              _buildTableHeaderCell("Hours"),
              _buildTableHeaderCell("In/Out"),
            ],
          ),
          for (int i = 0; i < validRecords.length; i++)
            TableRow(
              decoration: BoxDecoration(
                color: _getRowColor(validRecords[i].calculatedAttendanceStatus),
              ),
              children: [
                _buildTableCell((i + 1).toString()),
                _buildTableCell(validRecords[i].formattedDate),
                _buildTableCell(validRecords[i].day),
                _buildStatusCell(validRecords[i].calculatedAttendanceStatus),
                _buildTableCell(validRecords[i].formattedFirstCheckIn),
                _buildTableCell(validRecords[i].formattedLatestCheckOut),
                _buildTableCell(validRecords[i].formattedWorkingHours),
                _buildTableCell(validRecords[i].checkInOutCount),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatusCell(String status) {
    Color textColor;
    Color backgroundColor;
    switch (status) {
      case "Present":
        textColor = Colors.green[800]!;
        backgroundColor = Colors.green[100]!;
        break;
      case "Half Day":
        textColor = Colors.orange[800]!;
        backgroundColor = Colors.orange[100]!;
        break;
      case "Absent":
        textColor = Colors.red[800]!;
        backgroundColor = Colors.red[100]!;
        break;
      default:
        textColor = Colors.black;
        backgroundColor = Colors.grey[100]!;
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: textColor.withOpacity(0.3)),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Color? _getRowColor(String status) {
    switch (status) {
      case "Present":
        return Colors.green[50];
      case "Half Day":
        return Colors.orange[50];
      case "Absent":
        return Colors.red[50];
      default:
        return null;
    }
  }
}
