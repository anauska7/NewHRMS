import 'package:flutter/material.dart';
import 'package:new_hrms/admin/widgets/admin_header.dart';
import 'package:new_hrms/admin/widgets/admindrawer.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  _EmployeesScreenState createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  late Future<List<Map<String, String>>> _employeeData;

  @override
  // void initState() {
  //   super.initState();
  //   _employeeData = EmployeesApi.fetchEmployees(); 
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomHeader(title: "Employees"),
      drawer: CustomDrawer(selectedScreen: "Employees"), 
      body: FutureBuilder<List<Map<String, String>>>(
        future: _employeeData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); 
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}")); 
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No employees found")); 
          } else {
            return _EmployeeTable(title: "All Employees", data: snapshot.data!); 
          }
        },
      ),
    );
  }
}

class _EmployeeTable extends StatelessWidget {
  final String title;
  final List<Map<String, String>> data;

  const _EmployeeTable({super.key, required this.title, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                "All Employees",
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
                rows: data.map((employee) {
                  return DataRow(
                    cells: [
                      DataCell(Text(employee["id"] ?? "")),
                      DataCell(CircleAvatar(
                        backgroundImage: NetworkImage(employee["image"] ?? ""),
                        backgroundColor: Colors.grey[300],
                        radius: 18,
                      )),
                      DataCell(Text(employee["name"] ?? "")),
                      DataCell(Text(employee["email"] ?? "")),
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
