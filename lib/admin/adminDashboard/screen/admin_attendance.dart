import 'package:flutter/material.dart';
import 'package:new_hrms/admin/adminDashboard/widgets/admin_header.dart';
import 'package:new_hrms/admin/adminDashboard/widgets/admindrawer.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: const CustomHeader(title: "Attendance"),
       drawer: CustomDrawer(selectedScreen: "Attendance"), 
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Attendance",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Handle CSV download
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    child: const Text(
                      "Download CSV",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Dropdown Filters
            const CustomDropdown(label: "Employees"),
            const CustomDropdown(label: "Year"),
            const CustomDropdown(label: "Month"),
            const CustomDropdown(label: "Day"),

            const SizedBox(height: 16),

            // Search Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Perform search
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  "Search",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Attendance Table
            const SectionTitle(title: "Attendance Records"),
            const SizedBox(height: 8),
            AttendanceTable(),
          ],
        ),
      ),
    );
  }
}

// Custom Dropdown Widget
class CustomDropdown extends StatelessWidget {
  final String label;
  const CustomDropdown({required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              isExpanded: true,
              underline: const SizedBox(),
              hint: Text("-- Select $label --"),
              items: <String>['Option 1', 'Option 2', 'Option 3'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {},
            ),
          ),
        ],
      ),
    );
  }
}

// Section Title Widget
class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}

// Attendance Data Table Widget
class AttendanceTable extends StatelessWidget {
  final List<Map<String, String>> attendanceData = [
    {
      "id": "1",
      "name": "Tushar Sabat",
      "email": "sabattushar40@gmail.com",
      "date": "1-3-2025",
      "day": "Saturday",
      "status": "Present",
      "checkIn": "08:58:07",
      "checkOut": "18:00:00"
    },
    {
      "id": "2",
      "name": "Saraansh Sharma",
      "email": "saraansh.sharma@gmail.com",
      "date": "1-3-2025",
      "day": "Saturday",
      "status": "Present",
      "checkIn": "08:58:13",
      "checkOut": "18:05:00"
    },
    {
      "id": "3",
      "name": "Dillip Kumar Sahu",
      "email": "dillip.math@gmail.com",
      "date": "1-3-2025",
      "day": "Saturday",
      "status": "Absent",
      "checkIn": "--",
      "checkOut": "--"
    },
    {
      "id": "4",
      "name": "Ujjwal Dash",
      "email": "ujjwal.dash@gmail.com",
      "date": "1-3-2025",
      "day": "Saturday",
      "status": "Present",
      "checkIn": "08:58:26",
      "checkOut": "17:50:00"
    },
    {
      "id": "5",
      "name": "Rudra Madhab Mahanty",
      "email": "rudramadhab@gmail.com",
      "date": "1-3-2025",
      "day": "Saturday",
      "status": "Present",
      "checkIn": "08:58:32",
      "checkOut": "17:55:00"
    },
  ];

  AttendanceTable({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        border: TableBorder.all(color: Colors.grey.shade300),
        columns: const [
          DataColumn(label: Text("#", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Name", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Email", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Date", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Day", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("CheckIn Time", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("CheckOut Time", style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: attendanceData.map((data) {
          return DataRow(cells: [
            DataCell(Text(data["id"] ?? "")),
            DataCell(Text(data["name"] ?? "")),
            DataCell(Text(data["email"] ?? "")),
            DataCell(Text(data["date"] ?? "")),
            DataCell(Text(data["day"] ?? "")),
            DataCell(Text(data["status"] ?? "")),
            DataCell(Text(data["checkIn"] ?? "")),
            DataCell(Text(data["checkOut"] ?? "")),
          ]);
        }).toList(),
      ),
    );
  }
}