import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:new_hrms/admin/pages/leave/leave_view.dart';
import 'package:new_hrms/admin/widgets/admin_header.dart';
import 'package:new_hrms/admin/widgets/admindrawer.dart';
import 'attendance_model.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  String? selectedEmployee;
  DateTime? selectedDate;
  DateTime? _lastBackPressed;

  // Method to reset filters
  void _resetFilters() {
    setState(() {
      selectedEmployee = null;
      selectedDate = null;
    });
  }

  // Refresh method
  Future<void> _refreshAttendanceData() async {
    // Reset filters
    _resetFilters();

    // Trigger data fetch
    await ref.read(attendanceViewModelProvider.notifier).fetchAttendanceData();
  }

  @override
  Widget build(BuildContext context) {
    final attendanceState = ref.watch(attendanceViewModelProvider);

    // Sort employee names alphabetically
    final sortedEmployeeNames =
        List<String>.from(attendanceState.employeeNames);
    sortedEmployeeNames.sort((a, b) => a.compareTo(b));

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
          context.go('/admin/dashboard');
        }
      },
      child: Scaffold(
        appBar: const CustomHeader(title: "Attendance"),
        drawer: CustomDrawer(
          selectedScreen: "Attendance",
          userName: '',
        ),
        body: RefreshIndicator(
          onRefresh: _refreshAttendanceData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Loading Indicator
                if (attendanceState.isLoading)
                  const Center(child: CircularProgressIndicator()),

                // Error Message
                if (attendanceState.errorMessage.isNotEmpty)
                  Center(child: Text("Error: ${attendanceState.errorMessage}")),

                // Filters Section
                const SectionTitle(title: "Filter Attendance Records"),

                // Reset Filters Button
                if (selectedEmployee != null || selectedDate != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ElevatedButton(
                      onPressed: _resetFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text("Reset Filters"),
                    ),
                  ),

                // Employee Dropdown
                CustomDropdown(
                  label: "Employee Name",
                  items: sortedEmployeeNames,
                  value: selectedEmployee,
                  onChanged: (value) {
                    setState(() {
                      selectedEmployee = value;
                    });
                  },
                  dropdownWidth: MediaQuery.of(context).size.width - 32,
                ),
                const SizedBox(height: 10),

                // Date Picker
                Row(
                  children: [
                    const Text("Select Date",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () async {
                        final DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2010),
                          lastDate: DateTime(2070),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            selectedDate = pickedDate;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          selectedDate != null
                              ? DateFormat('yyyy-MM-dd').format(selectedDate!)
                              : "Choose Date",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Attendance Records Title
                const SectionTitle(title: "Attendance Records"),
                // Filtered Attendance Table
                ..._buildFilteredAttendanceTable(
                    attendanceState.attendanceData),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Method for building filtered attendance table
  List<Widget> _buildFilteredAttendanceTable(
      List<Map<String, String>> attendanceData) {
    var filteredData = attendanceData;

    // Apply filters
    if (selectedEmployee != null) {
      filteredData = filteredData
          .where((entry) => entry['employeeName'] == selectedEmployee)
          .toList();
    }

    // Filter by date
    if (selectedDate != null) {
      filteredData = filteredData
          .where((entry) {
            try {
              var entryDate =
                  DateFormat('dd-MM-yyyy').parse(entry['date'] ?? '');
              return isSameDay(entryDate, selectedDate!);
            } catch (e) {
              return false;
            }
          })
          .toList();
    }

    return [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          border: TableBorder.all(color: Colors.grey.shade300),
          columns: const [
            DataColumn(
                label: Text("Employee Name",
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text("Date", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text("Day", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text("CheckIn Time",
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text("CheckOut Time",
                    style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: filteredData.map((data) {
            return DataRow(cells: [
              DataCell(Text(data["employeeName"] ?? "")),
              DataCell(Text(data["date"] ?? "")),
              DataCell(Text(data["day"] ?? "")),
              DataCell(Text(data["status"] ?? "")),
              DataCell(Text(data["checkIn"] ?? "")),
              DataCell(Text(data["checkOut"] ?? "")),
            ]);
          }).toList(),
        ),
      ),
    ];
  }

  // Helper method to check if two dates are the same day
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}

// SectionTitle Widget remains the same
class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
    );
  }
}

class CustomDropdown extends StatelessWidget {
  final String label;
  final List<String> items;
  final String? value;
  final ValueChanged<String?> onChanged;
  final double? dropdownWidth;

  const CustomDropdown({
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
    this.dropdownWidth,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        DropdownButtonHideUnderline(
          child: Container(
            width: dropdownWidth,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(5),
            ),
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              hint: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0),
                child: Text('Select Employee', style: TextStyle(fontSize: 14)),
              ),
              icon: const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: Icon(Icons.arrow_drop_down),
              ),
              iconSize: 24,
              elevation: 1,
              style: const TextStyle(color: Colors.black, fontSize: 16),
              onChanged: onChanged,
              dropdownColor: Colors.white,
              menuMaxHeight: 200, // Set a maximum height for the dropdown menu
              itemHeight: 48.0, // Set the height for each item
              items: items.map<DropdownMenuItem<String>>((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}