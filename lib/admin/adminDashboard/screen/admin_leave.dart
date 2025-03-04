import 'package:flutter/material.dart';
import 'package:new_hrms/admin/adminDashboard/widgets/admin_header.dart';
import 'package:new_hrms/admin/adminDashboard/widgets/admindrawer.dart';

class LeaveApplicationsPage extends StatelessWidget {
  const LeaveApplicationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> leaveApplications = [
      {"id": "1", "name": "Saraansh Sharma", "email": "saraansh.sharma@example.com"},
      {"id": "2", "name": "Chitrarth Rai", "email": "chitrarthrai10@example.com"},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomHeader(title: "Leaves"),
       drawer: CustomDrawer(selectedScreen: "Leaves"), 
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                "Leave Applications",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // *Dropdowns & Date Picker*
            _buildDropdown("Employees"),
            const SizedBox(height: 10),
            _buildDropdown("Select"),
            const SizedBox(height: 10),
            _buildDropdown("Select"),
            const SizedBox(height: 10),
            _buildDatePicker(context),

            const SizedBox(height: 20),

            // *Search Button*
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  // TODO: Implement search functionality
                },
                child: const Text(
                  "Search",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // *Table Header*
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: Colors.green.shade50,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("#", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("Name", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("Email", style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            // *Table Data*
            Column(
              children: leaveApplications.map((app) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(app["id"]!),
                      Text(app["name"]!),
                      Text(app["email"]!),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // *Dropdown Builder*
  Widget _buildDropdown(String label) {
    return DropdownButtonFormField<String>(
      decoration: _inputDecoration(label),
      items: ["Option 1", "Option 2", "Option 3"]
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (value) {},
    );
  }

  // *Date Picker Field*
  Widget _buildDatePicker(BuildContext context) {
    return TextField(
      readOnly: true,
      decoration: InputDecoration(
        hintText: "Select Date",
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
            );
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // *Custom Input Decoration*
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}