import 'package:flutter/material.dart';
import 'package:new_hrms/admin/adminDashboard/widgets/admin_header.dart';
import 'package:new_hrms/admin/adminDashboard/widgets/admindrawer.dart';

class TeamsScreen extends StatelessWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomHeader(title: "Teams"),
       drawer: CustomDrawer(selectedScreen: "Teams"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
             Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1),
                ],
              ),
              child: const Text(
                "All Teams",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // All Teams Title
            const SectionTitle(title: "All Teams"),
            const SizedBox(height: 8),

            // Teams Data Table
            TeamsTable(),
          ],
        ),
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
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
    );
  }
}

// Teams Data Table Widget
class TeamsTable extends StatelessWidget {
  final List<Map<String, String>> teamsData = [
    {
      "id": "1",
      "name": "AI Full-Stack App",
      "leader": "Rajkishore Pradhan",
      "status": "Active",
      "image": "https://via.placeholder.com/40" // Placeholder Image URL
    },
    {
      "id": "2",
      "name": "Web Development Team",
      "leader": "Piyush Sahu",
      "status": "Active",
      "image": "https://via.placeholder.com/40"
    },
    {
      "id": "3",
      "name": "Mobile App Team",
      "leader": "Tushar Sabat",
      "status": "Active",
      "image": "https://via.placeholder.com/40"
    },
  ];

  TeamsTable({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        border: TableBorder.all(color: Colors.grey.shade300),
        columns: const [
          DataColumn(label: Text("#", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Image", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Name", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Leader", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Action", style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: teamsData.map((data) {
          return DataRow(cells: [
            DataCell(Text(data["id"] ?? "")),
            DataCell(CircleAvatar(
              backgroundImage: NetworkImage(data["image"]!),
              radius: 20,
            )),
            DataCell(Text(data["name"] ?? "")),
            DataCell(Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green[700],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                data["leader"] ?? "",
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            )),
            DataCell(Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green[400],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                data["status"] ?? "",
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            )),
            DataCell(ElevatedButton(
              onPressed: () {
                // Navigate to team details page
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[400],
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text("Detail", style: TextStyle(color: Colors.black)),
            )),
          ]);
        }).toList(),
      ),
    );
  }
}