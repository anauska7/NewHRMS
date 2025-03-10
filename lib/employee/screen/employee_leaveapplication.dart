import 'package:flutter/material.dart';
import 'package:new_hrms/employee/widgets/employee_drawer.dart';
import 'package:new_hrms/employee/widgets/employee_header.dart';

class LeaveApplicationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomHeader(title: "Leave Application"),
      drawer: CustomDrawer(selectedScreen: "Leave Application"),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel("Enter Title"),
              _buildTextField("Enter Title", Icons.edit),

              _buildLabel("Leave Type"),
              _buildDropdown("Select Leave Type"),

              _buildLabel("Enter Period"),
              _buildTextField("Enter Period", Icons.edit),

              _buildLabel("Start Date"),
              _buildTextField("Select Start Date", Icons.calendar_today),

              _buildLabel("End Date"),
              _buildTextField("Select End Date", Icons.calendar_today),

              _buildLabel("Enter Reason"),
              _buildTextField("Enter Reason", Icons.note),

              const SizedBox(height: 20),

              // Green Apply Leave Button
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // Green color
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  "Apply Leave",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Label Widget
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 5),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Text Field Widget
  Widget _buildTextField(String hint, IconData icon) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Dropdown Widget
  Widget _buildDropdown(String hint) {
    return DropdownButtonFormField(
      items: [],
      onChanged: (val) {},
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
