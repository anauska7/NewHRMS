import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_hrms/admin/widgets/admin_header.dart';
import 'package:new_hrms/admin/widgets/admindrawer.dart';
import 'assignsalary_model.dart';

class SalaryAssignmentScreen extends ConsumerWidget {
  const SalaryAssignmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salaryState = ref.watch(salaryViewModelProvider);
    final salaryViewModel = ref.watch(salaryViewModelProvider.notifier);

    return Scaffold(
      appBar: const CustomHeader(title: "Assign Salary"),
      drawer: CustomDrawer(
        selectedScreen: "Assign Salary",
        userName: salaryState.selectedEmployee ?? "Admin",
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Employee",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              isExpanded: true,
              value: salaryState.selectedEmployee,
              items: salaryState.employees
                  .map((employee) => DropdownMenuItem(
                        value: employee,
                        child: Text(employee),
                      ))
                  .toList(),
              onChanged: (newValue) => salaryViewModel.setSelectedEmployee(newValue),
            ),
            const SizedBox(height: 16),

            const Text(
              "Select Salary Type",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              isExpanded: true,
              value: salaryState.selectedSalaryType,
              items: ["Basic", "HRA", "Special Allowance"]
                  .map((salaryType) => DropdownMenuItem(
                        value: salaryType,
                        child: Text(salaryType),
                      ))
                  .toList(),
              onChanged: (newValue) => salaryViewModel.setSelectedSalaryType(newValue),
            ),
            const SizedBox(height: 16),

            const Text(
              "Select Status",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              isExpanded: true,
              value: salaryState.selectedStatus,
              items: ["Active", "Inactive"]
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      ))
                  .toList(),
              onChanged: (newValue) => salaryViewModel.setSelectedStatus(newValue),
            ),
            const SizedBox(height: 16),

            // Total Calculated Salary
            Row(
              children: const [
                Text(
                  "Total Calculated Salary",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Text(
                  "₹ 0",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Salary Input Fields
            const SalaryInputField(label: "Basic Salary"),
            const SalaryInputField(label: "HRA"),
            const SalaryInputField(label: "Medical Allowance"),
            const SalaryInputField(label: "Conveyance Allowance"),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to the next page
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  "→ Continue to Deductions",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SalaryInputField extends StatelessWidget {
  final String label;
  const SalaryInputField({required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            decoration: InputDecoration(
              prefixIcon: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text("₹", style: TextStyle(fontSize: 18)),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 0),
              hintText: "Enter $label amount",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }
}
