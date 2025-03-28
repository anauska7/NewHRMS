import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:new_hrms/employee/pages/viewleave/viewleave_model.dart';
import 'package:new_hrms/employee/pages/viewleave/viewleave_viewmodel.dart';
import 'package:new_hrms/employee/widgets/employee_drawer.dart';
import 'package:new_hrms/employee/widgets/employee_header.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ViewLeavePage extends ConsumerStatefulWidget {
  const ViewLeavePage({Key? key}) : super(key: key);

  @override
  ConsumerState createState() => _LeavePageState();
}

class _LeavePageState extends ConsumerState {
  String? token;
  DateTime? _lastBackPressed;

  @override
  void initState() {
    super.initState();
    _getTokenAndFetchLeaves();
  }

  Future<void> _getTokenAndFetchLeaves() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('auth_token');
    });
    if (token != null) {
      ref.read(ViewleaveViewModelProvider.notifier).fetchLeaveRecords(token!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final leaveState = ref.watch(ViewleaveViewModelProvider);
    double screenWidth = MediaQuery.of(context).size.width;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (leaveState.errorMessage.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(leaveState.errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }

      if (leaveState.leaveRecords.isNotEmpty && leaveState.errorMessage.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Leaves fetched successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        final DateTime now = DateTime.now();
        if (_lastBackPressed == null ||
            now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to go to dashboard'),
              duration: Duration(seconds: 2),
            ),
          );
          _lastBackPressed = now;
          return;
        }

        if (now.difference(_lastBackPressed!) <= const Duration(seconds: 2)) {
          context.go('/employee/dashboard');
        }
      },
      child: Scaffold(
        appBar: const CustomHeader(title: "View Leaves"),
        drawer: const CustomDrawer(
          selectedScreen: "View Leaves",
          userName: '',
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (token == null)
                const CircularProgressIndicator()
              else if (leaveState.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (leaveState.errorMessage.isNotEmpty)
                Center(
                  child: Text(
                    leaveState.errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              else if (leaveState.leaveRecords.isEmpty)
                const Center(child: Text('You have not applied for leaves'))
              else
                _buildLeaveRecordsTable(leaveState.leaveRecords, screenWidth),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaveRecordsTable(List leaveRecords, double screenWidth) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: screenWidth < 600 ? 10 : 20,
        columns: const [
          DataColumn(
              label: Text('Leave Type', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Title', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(
              label: Text('From Date', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('To Date', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(
              label: Text('Applied Date', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Reason', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: leaveRecords.map((leave) {
          return DataRow(cells: [
            DataCell(Text(leave.type)),
            DataCell(Text(leave.title)),
            DataCell(Text(leave.formattedStartDate)),
            DataCell(Text(leave.formattedEndDate)),
            DataCell(Text(leave.formattedAppliedDate)),
            DataCell(Text(leave.adminResponse)),
            DataCell(Text(leave.reason)),
          ]);
        }).toList(),
      ),
    );
  }
}
