import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // For navigation
import 'package:new_hrms/employee/widgets/employee_drawer.dart'; // Import CustomDrawer
import 'package:new_hrms/employee/widgets/employee_header.dart'; // Import CustomHeader

class ContactPage extends StatefulWidget {
  const ContactPage({Key? key}) : super(key: key);

  @override
  _ContactPageState createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  // The list of contacts
  final List<Map<String, String>> contacts = [
    {"role": "CEO", "name": "John Smith", "phone": "+1 (555) 123-4567"},
    {"role": "CTO", "name": "Jane Doe", "phone": "+1 (555) 234-5678"},
    {"role": "HR Manager", "name": "Mike Johnson", "phone": "+1 (555) 345-6789"},
  ];

  DateTime? _lastBackPressed;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: false, // Prevent default back button behavior
      onPopInvoked: (didPop) {
        if (didPop) return;

        final DateTime now = DateTime.now();
        
        // If this is the first back button press or too much time has passed
        if (_lastBackPressed == null || now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
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
          context.go('/employee/dashboard');
        }
      },
      child: Scaffold(
        appBar: const CustomHeader(title: "Contact Us"), // CustomHeader used here
        drawer: CustomDrawer(selectedScreen: "Contact Us", userName: "User"), // CustomDrawer used here
        body: Padding(
          padding: EdgeInsets.all(screenWidth < 600 ? 8.0 : 16.0), // Adjust padding for mobile vs larger screens
          child: ListView(
            children: contacts.map((contact) {
              return _buildContactCard(contact, screenWidth);
            }).toList(),
          ),
        ),
      ),
    );
  }

  // Contact Card Widget with Green Top Border
  Widget _buildContactCard(Map<String, String> contact, double screenWidth) {
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
                        style: TextStyle(
                          fontSize: screenWidth < 600 ? 14 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        contact["name"]!,
                        style: TextStyle(
                          fontSize: screenWidth < 600 ? 12 : 14, 
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        contact["phone"]!,
                        style: TextStyle(
                          fontSize: screenWidth < 600 ? 12 : 14,
                          color: Colors.black54,
                        ),
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
