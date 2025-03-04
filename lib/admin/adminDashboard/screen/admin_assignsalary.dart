import 'package:flutter/material.dart';
import 'package:new_hrms/admin/adminDashboard/widgets/admin_header.dart';
import 'package:new_hrms/admin/adminDashboard/widgets/admindrawer.dart';

class SalaryAssignmentScreen extends StatelessWidget {
  const SalaryAssignmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: const CustomHeader(title: "Assign Salary"),
       drawer: CustomDrawer(selectedScreen: "Assign Salary"), 
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
                "Salary Structure",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
              const SizedBox(height: 16),

              // Select Employee Dropdown
              const Text(
                "Select Employee",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                  hint: const Text("-- Select Employee --"),
                  items: <String>['Employee 1', 'Employee 2', 'Employee 3']
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {},
                ),
              ),
              const SizedBox(height: 16),

              // Total Salary
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

              // Earnings Components
              const Text(
                "Earnings Components",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Salary Input Fields
              const SalaryInputField(label: "Basic Salary"),
              const SalaryInputField(label: "HRA"),
              const SalaryInputField(label: "Medical Allowance"),
              const SalaryInputField(label: "Conveyance Allowance"),
              const SalaryInputField(label: "Book Allowance"),
              const SalaryInputField(label: "Special Periodic Allowance"),
              const SizedBox(height: 20),

              // Additional Components
              const Text(
                "Additional Components",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Read-only Employer’s PF Contribution Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Employer’s PF Contribution",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "₹ 0.00",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Other Additional Allowances
              const SalaryInputField(label: "PLI"),
              const SalaryInputField(label: "Others"),
              const SizedBox(height: 20),

              // Continue Button
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
      ),
    );
  }
}

// Custom Salary Input Field Widget
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