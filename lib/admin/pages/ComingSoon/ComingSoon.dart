import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:new_hrms/admin/widgets/admindrawer.dart'; // Import CustomDrawer
import 'package:new_hrms/admin/widgets/admin_header.dart'; // Import CustomHeader


class ComingSoonPage extends StatefulWidget {
  const ComingSoonPage({Key? key}) : super(key: key);

   @override
  _ComingSoonPageState createState() => _ComingSoonPageState();
}

  class _ComingSoonPageState extends State<ComingSoonPage> {
  DateTime? _lastBackPressed;


  @override
  Widget build(BuildContext context) {
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
      appBar: const CustomHeader(title: ""),
      drawer: CustomDrawer(selectedScreen: "Coming Soon", userName: "User"),
      body: Center(
        child: const Text(
          "This feature is coming soon!",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      ),
    );
  }
}
