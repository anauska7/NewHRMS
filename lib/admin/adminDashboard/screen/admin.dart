import 'package:flutter/material.dart';
import 'package:new_hrms/admin/adminDashboard/widgets/admin_header.dart';
import 'package:new_hrms/admin/adminDashboard/widgets/admindrawer.dart';

class AdminsScreen extends StatefulWidget {
  const AdminsScreen({super.key});

  @override
  _AdminsScreenState createState() => _AdminsScreenState();
}

class _AdminsScreenState extends State<AdminsScreen> {
  late Future<List<Map<String, String>>> _adminData;

  @override
  void initState() {
    super.initState();
    _adminData = fetchAdmins();
  }

  Future<List<Map<String, String>>> fetchAdmins() async {
    await Future.delayed(const Duration(seconds: 2)); // Simulated API delay
    return [
      {
        "id": "1",
        "name": "Admin One",
        "email": "admin1@example.com",
        "image": "https://via.placeholder.com/50",
      },
      {
        "id": "2",
        "name": "Admin Two",
        "email": "admin2@example.com",
        "image": "https://via.placeholder.com/50",
      },
      {
        "id": "3",
        "name": "Admin Three",
        "email": "admin3@example.com",
        "image": "https://via.placeholder.com/50",
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomHeader(title: "Admins"),
      drawer: const CustomDrawer(selectedScreen: "Admins"),
      body: FutureBuilder<List<Map<String, String>>>(
        future: _adminData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No admins found"));
          } else {
            return _AdminTable(title: "All Admins", data: snapshot.data!);
          }
        },
      ),
    );
  }
}

class _AdminTable extends StatelessWidget {
  final String title;
  final List<Map<String, String>> data;

  const _AdminTable({super.key, required this.title, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Card
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
                "All Admins",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          const SizedBox(height: 10),

          // Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: DataTable(
                columnSpacing: 15,
                headingRowColor: MaterialStateProperty.all(Colors.green.shade50),
                columns: const [
                  DataColumn(label: Text("#", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Image", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Name", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Email", style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: data.map((admin) {
                  return DataRow(
                    cells: [
                      DataCell(Text(admin["id"] ?? "")),
                      DataCell(CircleAvatar(
                        backgroundImage: NetworkImage(admin["image"] ?? ""),
                        backgroundColor: Colors.grey[300],
                        radius: 18,
                      )),
                      DataCell(Text(admin["name"] ?? "")),
                      DataCell(Text(admin["email"] ?? "")),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}