import 'package:flutter/material.dart';
import 'package:new_hrms/employee/widgets/employee_drawer.dart';
import 'package:new_hrms/employee/widgets/employee_header.dart';

class LeaveListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomHeader(title: "Apply Leave"),
      drawer: CustomDrawer(selectedScreen: "Apply Leave"),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel("Leave Type"),
            _buildDropdown("Select Leave Type"),

            _buildLabel("Status"),
            _buildDropdown("Select Status"),

            _buildLabel("Applied Date"),
            _buildTextField("Select Applied Date", Icons.calendar_today),

            const SizedBox(height: 10),

            ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // Green color
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  "Search",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),

            const SizedBox(height: 20),

            Table(
              border: TableBorder.all(),
              children: [
                TableRow(
                  children: [
                    _buildTableCell("#"),
                    _buildTableCell("Type"),
                    _buildTableCell("Title"),
                  ],
                ),
              ],
            ),
          ],
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

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold))),
    );
  }
}
