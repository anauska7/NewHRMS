import 'package:flutter/material.dart';
import 'package:new_hrms/employee/widgets/employee_drawer.dart';
import 'package:new_hrms/employee/widgets/employee_header.dart';

class AttendancePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomHeader(title: "Attendance"),
      drawer: CustomDrawer(selectedScreen: "Attendance"),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Check-In and Check-Out Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildButton("Check-In", Colors.green),
                const SizedBox(width: 10),
                _buildButton("Check-Out", Colors.red),
              ],
            ),
            const SizedBox(height: 20),

            // Filters: Year, Month, Day
            _buildDropdown("Year"),
            _buildDropdown("Month"),
            _buildDropdown("Day"),
            const SizedBox(height: 10),

            // Search Button
            ElevatedButton(onPressed: () {}, child: const Text("Search")),
            const SizedBox(height: 20),

            // Attendance Table
            _buildAttendanceTable(),
          ],
        ),
      ),
    );
  }

  // Button Widget
  Widget _buildButton(String text, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      onPressed: () {},
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16)),
    );
  }

  // Dropdown Widget
  Widget _buildDropdown(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: DropdownButtonFormField(
        items: [], 
        onChanged: (val) {}, 
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  // Attendance Table Widget
  Widget _buildAttendanceTable() {
    return Table(
      border: TableBorder.all(),
      columnWidths: const {
        0: FlexColumnWidth(0.5), // SL No
        1: FlexColumnWidth(1.2), // Date
        2: FlexColumnWidth(1.2), // Day
        3: FlexColumnWidth(1), // Status
        4: FlexColumnWidth(1.5), // Check-In Time
        5: FlexColumnWidth(1.5), // Check-Out Time
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

        // Table Data Row (Example Data)
        TableRow(
          children: [
            _buildTableCell("1"),
            _buildTableCell("8-3-2025"),
            _buildTableCell("Saturday"),
            _buildTableCell("Present"),
            _buildTableCell("09:00 AM"),
            _buildTableCell("06:00 PM"),
          ],
        ),
      ],
    );
  }

  // Table Header Cell
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

  // Table Data Cell
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
}
