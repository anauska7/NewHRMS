import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:new_hrms/employee/pages/attendance/attendance_viewmodel.dart';
import 'package:new_hrms/employee/pages/attendance/attendance_model.dart';
import 'package:new_hrms/employee/widgets/employee_drawer.dart';
import 'package:new_hrms/employee/widgets/employee_header.dart';

class AttendancePage extends ConsumerStatefulWidget {
  const AttendancePage({Key? key});

  @override
  ConsumerState<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage> {
  // Dropdown value holders
  String? selectedYear;
  String? selectedMonth;
  String? selectedDay;

  DateTime? _lastBackPressed;

  // Sample dropdown lists
  final List<String> years = ['2023', '2024', '2025'];
  final List<String> months = [
    'January', 'February', 'March', 'April',
    'May', 'June', 'July', 'August',
    'September', 'October', 'November', 'December'
  ];
  final List<String> days = List.generate(31, (index) => (index + 1).toString());

  @override
  Widget build(BuildContext context) {
    final attendanceState = ref.watch(attendanceViewModelProvider);
    double screenWidth = MediaQuery.of(context).size.width;

    // Show error or success snackbar
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
        
        // If this is the first back button press or too much time has passed
        if (_lastBackPressed == null || 
            now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
          // Show snackbar to indicate first back press
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to go to dashboard'),
              duration: Duration(seconds: 2),
            ),
          );
          
          // Update last back pressed time
          _lastBackPressed = now;
          
          return;
        }
        
        // If back is pressed twice in quick succession
        if (now.difference(_lastBackPressed!) <= const Duration(seconds: 2)) {
          // Use GoRouter to go to dashboard
          context.go('/employee/dashboard');
        }
      },

      child: Scaffold(
        appBar: const CustomHeader(title: "Attendance"),
        drawer: CustomDrawer(selectedScreen: "Attendance", userName: '',),
        body: SingleChildScrollView(  // Wrap the body in a SingleChildScrollView to make it scrollable
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Check-In and Check-Out Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAttendanceButton('Check-In', Colors.green, () async {
                    // Check location services before attempting check-in
                    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                    if (!serviceEnabled) {
                      _showLocationServiceAlert();
                      return;
                    }

                    ref.read(attendanceViewModelProvider.notifier).checkIn();
                  }),
                  const SizedBox(width: 10),
                  _buildAttendanceButton('Check-Out', Colors.red, () async {
                    // Check location services before attempting check-out
                    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                    if (!serviceEnabled) {
                      _showLocationServiceAlert();
                      return;
                    }

                    ref.read(attendanceViewModelProvider.notifier).checkOut();
                  }),
                ],
              ),
              const SizedBox(height: 20),

              // Filters - Vertical Layout
              _buildDropdown('Year', years, (value) {
                setState(() {
                  selectedYear = value;
                });
                ref.read(attendanceViewModelProvider.notifier).setSelectedYear(value);
              },screenWidth*0.8),
              const SizedBox(height: 10),
              _buildDropdown('Month', months, (value) {
                setState(() {
                  selectedMonth = value;
                });
                ref.read(attendanceViewModelProvider.notifier).setSelectedMonth(value);
              },screenWidth*0.8),
              const SizedBox(height: 10),
              _buildDropdown('Day', days, (value) {
                setState(() {
                  selectedDay = value;
                });
                ref.read(attendanceViewModelProvider.notifier).setSelectedDay(value);
              },screenWidth*0.8),
              const SizedBox(height: 10),

              // Search Button
              Center(
                child: ElevatedButton(
                    onPressed: _performSearch, child: const Text("Search")),
              ),
              const SizedBox(height: 20),

              // Loading indicator
              if (attendanceState.isLoading)
                const Center(child: CircularProgressIndicator()),

              // Attendance table
              _buildAttendanceTable(attendanceState.attendanceList), // Pass attendanceList here!
            ],
          ),
        ),
      ),
    );
  }

  // Show alert when location services are disabled
  void _showLocationServiceAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Services Disabled'),
          content: const Text('Please enable location services to check-in/check-out'),
          actions: <Widget>[
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
  return Container(
    width: double.infinity, // Set the width for the dropdown container
     padding: const EdgeInsets.only(left: 13.0, right: 20.0),
     decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey),
    ),
    child: DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label, 
        border: InputBorder.none, // Remove the default border
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      isExpanded: true, // Ensure the dropdown box takes the full width of the container
      items: items.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Container(
            width: dropdownWidth, // Set the width of the dropdown options list
             child: Text(value),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      dropdownColor: Colors.white,
      menuMaxHeight: 200, // Adjust the maximum height for the dropdown list
      alignment: Alignment.center, // Align dropdown content to the left
    ),
  );
}






  void _performSearch() {
    ref.read(attendanceViewModelProvider.notifier).fetchAttendanceRecords();  // Fetch data on search!
  }

  Widget _buildTableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildAttendanceTable(List<Attendance>? attendanceList) {
    if (attendanceList == null || attendanceList.isEmpty) {
      return const Center(child: Text('No attendance records found.'));
    }

    return Table(
      border: TableBorder.all(),
      columnWidths: const {
        0: FlexColumnWidth(0.5),
        1: FlexColumnWidth(1.2),
        2: FlexColumnWidth(1.2),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(1.5),
        5: FlexColumnWidth(1.5),
      },
      children: [
        // Table Header Row
        TableRow(
          decoration: BoxDecoration(color: Colors.green[200]),
          children: [
            _buildTableHeaderCell("#"),
            _buildTableHeaderCell("Date"),
            _buildTableHeaderCell("Day"),
            _buildTableHeaderCell("Status"),
            _buildTableHeaderCell("Check-In Time"),
            _buildTableHeaderCell("Check-Out Time"),
          ],
        ),
        // Data Rows
        for (int i = 0; i < attendanceList.length; i++)
          TableRow(
            children: [
              _buildTableCell((i + 1).toString()),
              _buildTableCell(attendanceList[i].formattedDate),
              _buildTableCell(attendanceList[i].day),
              _buildTableCell(_determineAttendanceStatus(attendanceList[i])),
              _buildTableCell(_getCheckInTime(attendanceList[i])),
              _buildTableCell(_getCheckOutTime(attendanceList[i])),
            ],
          ),
      ],
    );
  }

  // Helper method to determine attendance status
  String _determineAttendanceStatus(Attendance attendance) {
    // Check if check-in or check-out is missing or at default time
    if (attendance.checkInTime.year == 1970 || 
        attendance.checkOutTime == null || 
        attendance.checkOutTime?.year == 1970) {
      return "Absent";
    }
    return "Present";
  }

  // Helper method to get check-in time
  String _getCheckInTime(Attendance attendance) {
    // If check-in is at default time, return "N/A"
    if (attendance.checkInTime.year == 1970) {
      return "N/A";
    }
    return _convertToIST(attendance.checkInTime);
  }

  // Helper method to get check-out time
  String _getCheckOutTime(Attendance attendance) {
    // If check-out is null or at default time, return "N/A"
    if (attendance.checkOutTime == null || attendance.checkOutTime?.year == 1970) {
      return "N/A";
    }
    return _convertToIST(attendance.checkOutTime!);
  }

  // Helper method to convert to IST
  String _convertToIST(DateTime dateTime) {
    // Convert to IST (UTC+5:30)
    DateTime istTime = dateTime.toUtc().add(const Duration(hours: 5, minutes: 30));
    return DateFormat('hh:mm a').format(istTime);
  }
}
