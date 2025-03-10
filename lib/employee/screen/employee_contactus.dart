import 'package:flutter/material.dart';
import 'package:new_hrms/employee/widgets/employee_drawer.dart';
import 'package:new_hrms/employee/widgets/employee_header.dart';


class ContactPage extends StatelessWidget {
  final List<Map<String, String>> contacts = [
    {"role": "CEO", "name": "John Smith", "phone": "+1 (555) 123-4567"},
    {"role": "CTO", "name": "Jane Doe", "phone": "+1 (555) 234-5678"},
    {"role": "HR Manager", "name": "Mike Johnson", "phone": "+1 (555) 345-6789"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomHeader(title: "Contact Us"),
      drawer: CustomDrawer(selectedScreen: "Contact Us"),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: contacts.map((contact) {
            return _buildContactCard(contact);
          }).toList(),
        ),
      ),
    );
  }

  // Contact Card Widget with Green Top Border
  Widget _buildContactCard(Map<String, String> contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300), // Light grey border
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 4, spreadRadius: 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Green Top Border
          Container(
            height: 5,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
          ),
          
          // Contact Details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.person, size: 40, color: Colors.black54),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact["role"]!,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        contact["name"]!,
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        contact["phone"]!,
                        style: const TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.phone, color: Colors.green),
                  onPressed: () {
                    // Add call functionality here if needed
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
