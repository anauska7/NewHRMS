import 'package:flutter/material.dart';
import 'package:new_hrms/employee/widgets/employee_drawer.dart';
import 'package:new_hrms/employee/widgets/employee_header.dart';

class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomHeader(title: "Dashboard"),
      drawer: CustomDrawer(selectedScreen: "Dashboard"),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildWelcomeBox(),
              const SizedBox(height: 20),
              _buildDetailsBox(),
            ],
          ),
        ),
      ),
    );
  }

  // Box for Welcome Message
  Widget _buildWelcomeBox() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              "Welcome Amisha Samal",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
            ),
           
          ],
        ),
      ),
    );
  }

  // Box for User Details
  Widget _buildDetailsBox() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircleAvatar(radius: 50, backgroundImage: AssetImage('assets/profile.png')),
            _buildInfoRow("Name", "Amisha Samal"),
            _buildInfoRow("Username", "user662108409"),
            _buildSingleLineRow("Email", "samal.amisha2003@gmail.com"), // Keep email in single line
            _buildInfoRow("Usertype", "Employee"),
            _buildInfoRow("Status", "Active"),
            _buildInfoRow("Mobile", "9777613048"),
            _buildInfoRow("Address", "Shree heights, Kharghar"),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            "$title: ",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Flexible(
            child: Text(value, style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}


 Widget _buildSingleLineRow(String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            "$title: ",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis, // Prevents text from wrapping
              maxLines: 1, // Ensures email remains in a single line
            ),
          ),
        ],
      ),
    );
  }

