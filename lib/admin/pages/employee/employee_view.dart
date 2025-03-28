import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'employee_model.dart';
import 'package:new_hrms/admin/widgets/admindrawer.dart';
import 'package:new_hrms/admin/widgets/admin_header.dart';

class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});

  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen> {
  DateTime? _lastBackPressed;

  @override
  Widget build(BuildContext context) {
    // Watch the employee data state from the view model
    final employeeState = ref.watch(employeeViewModelProvider);

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
          context.go('/admin/dashboard');
        }
      },
      child: Scaffold(
        appBar: const CustomHeader(title: "Employees"),
        drawer: CustomDrawer(
          selectedScreen: "Employees",
          userName: "Admin",
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            // Trigger a refresh
            ref.read(employeeViewModelProvider.notifier).fetchEmployees();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (employeeState.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 100.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                if (employeeState.errorMessage.isNotEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 50.0),
                      child: Column(
                        children: [
                          Text(
                            employeeState.errorMessage,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              ref.read(employeeViewModelProvider.notifier).retryFetch();
                            },
                            child: const Text("Retry"),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!employeeState.isLoading && employeeState.employeeData.isNotEmpty)
                  _EmployeeTable(employeeData: employeeState.employeeData),
                
                if (!employeeState.isLoading && employeeState.employeeData.isEmpty && employeeState.errorMessage.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 100.0),
                      child: Text("No employees found"),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmployeeTable extends StatelessWidget {
  final List<Map<String, String>> employeeData;

  const _EmployeeTable({super.key, required this.employeeData});

  @override
  Widget build(BuildContext context) {
    print("Building Employee Table with ${employeeData.length} employees");

    // Get screen width for responsive layout
    double screenWidth = MediaQuery.of(context).size.width;

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
            child: Text(
              "All Employees (${employeeData.length})",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Table with Horizontal Scrolling
          SingleChildScrollView(
            scrollDirection: Axis.horizontal, 
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: screenWidth), // Ensure table takes full width
              child: DataTable(
                columnSpacing: 20,
                headingRowColor: MaterialStateProperty.all(Colors.green.shade50),
                columns: const [
                  DataColumn(label: Text("#", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Image", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Name", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Email", style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: employeeData.asMap().entries.map((entry) {
                  int index = entry.key + 1; 
                  Map<String, String> employee = entry.value;
                  return DataRow(
                    cells: [
                      DataCell(Text(index.toString())), 
                      DataCell(
                        employee["image"] != null && employee["image"]!.isNotEmpty
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(employee["image"]!),
                                radius: 18,
                              )
                            : const CircleAvatar(
                                backgroundColor: Colors.grey,
                                radius: 18,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                      ),
                      DataCell(Text(employee["name"] ?? "No Name")),
                      DataCell(Text(employee["email"] ?? "No Email")),
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
