import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:new_hrms/admin/pages/team/team_view.dart';
import 'leave_model.dart';
import 'package:intl/intl.dart';
import 'package:new_hrms/admin/widgets/admin_header.dart';
import 'package:new_hrms/admin/widgets/admindrawer.dart';

class LeaveApplicationsPage extends ConsumerStatefulWidget {
  const LeaveApplicationsPage({super.key});

  @override
  ConsumerState<LeaveApplicationsPage> createState() => _LeaveApplicationsPageState();
}

class _LeaveApplicationsPageState extends ConsumerState<LeaveApplicationsPage> {
  DateTime? _lastBackPressed;

  @override
  Widget build(BuildContext context) {
    final leaveState = ref.watch(leaveViewModelProvider);
    final leaveViewModel = ref.read(leaveViewModelProvider.notifier);

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
        appBar: const CustomHeader(title: "Leaves"),
        drawer: CustomDrawer(
          selectedScreen: "Leaves",
          userName: "Admin",
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            // Fetch leave applications, which will reset filters
            await leaveViewModel.fetchLeaveApplications();
            await leaveViewModel.fetchEmployeeNames();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (leaveState.isLoading) const Center(child: CircularProgressIndicator()),
                if (leaveState.errorMessage.isNotEmpty)
                  Center(child: Text("Error: ${leaveState.errorMessage}")),
                _LeaveUI(
                  leaveApplications: leaveState.filteredLeaveApplications,
                  employees: leaveState.employeeNames,
                  selectedEmployee: leaveState.selectedEmployee,
                  onEmployeeChanged: (value) => leaveViewModel.setSelectedEmployee(value),
                  onSearchPressed: () => leaveViewModel.filterLeaveApplications(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// SectionTitle Widget for displaying section titles
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

class _LeaveUI extends StatelessWidget {
  final List<Map<String, String>> leaveApplications;
  final List<String> employees;
  final String? selectedEmployee;
  final ValueChanged<String?> onEmployeeChanged;
  final VoidCallback onSearchPressed;

  const _LeaveUI({
    super.key,
    required this.leaveApplications,
    required this.employees,
    required this.selectedEmployee,
    required this.onEmployeeChanged,
    required this.onSearchPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: "Filter Leave Applications"),
        CustomDropdown(
          label: "Employee Name",
          items: employees,
          value: selectedEmployee,
          onChanged: onEmployeeChanged,
          dropdownWidth: MediaQuery.of(context).size.width - 32, // adjust as needed
        ),

        const SizedBox(height: 18),
        // Search Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onSearchPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text("Search", style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 16),
        // Leave Applications Table
        LeaveApplicationsTable(leaveApplications: leaveApplications),
      ],
    );
  }
}

class LeaveApplicationsTable extends StatelessWidget {
  final List<Map<String, String>> leaveApplications;

  const LeaveApplicationsTable({super.key, required this.leaveApplications});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        border: TableBorder.all(color: Colors.grey.shade300),
        columns: const [
          DataColumn(label: Text("Employee Name", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Leave Type", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Start Date", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("End Date", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: leaveApplications.map((leave) {
          return DataRow(cells: [
            DataCell(Text(leave["employeename"] ?? "")),
            DataCell(Text(leave["type"] ?? "")),
            DataCell(Text(leave["startDate"] ?? "")),
            DataCell(Text(leave["endDate"] ?? "")),
            DataCell(Text(leave["status"] ?? "")),
          ]);
        }).toList(),
      ),
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
    super.key
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
              menuMaxHeight: 3 * 48.0, // Limit to 3 options
              itemHeight: 48.0,
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