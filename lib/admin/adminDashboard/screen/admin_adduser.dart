import 'package:flutter/material.dart';
import 'package:new_hrms/admin/adminDashboard/widgets/admin_header.dart';
import 'package:new_hrms/admin/adminDashboard/widgets/admindrawer.dart';

class AddUserScreen extends StatelessWidget {
  const AddUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomHeader(title: "Add User"),
      drawer: CustomDrawer(selectedScreen: "Add User"), 
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/user_icon.png'), // Replace with actual image
            ),
            const SizedBox(height: 20),
            customTextField(hintText: "Enter Name", icon: Icons.person),
            customTextField(hintText: "Enter Email", icon: Icons.email),
            customTextField(hintText: "Enter Mobile Number", icon: Icons.phone),
            customTextField(hintText: "Enter Password", icon: Icons.lock),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {},
                child: const Text("Add User", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget customTextField({required String hintText, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey),
          hintText: hintText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        ),
      ),
    );
  }
}
