import 'package:flutter/material.dart';
import 'package:new_hrms/admin/widgets/admindrawer.dart';
import 'package:new_hrms/admin/widgets/admin_header.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: const CustomHeader(title: "Dashboard"), 
     drawer: CustomDrawer(selectedScreen: "Dashboard"), 
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDashboardCard("Total Employee", "47"),
            _buildDashboardCard("Total Leader", "5"),
            _buildDashboardCard("Total Admin", "5"),
            _buildDashboardCard("Total Team", "1"),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(String title, String count) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: SizedBox(
        height: 110,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Row(
            children: [
              // Green Icon Box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 36),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(height: 6),

                    Text(
                      count,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
