import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:new_hrms/employee/pages/leaveapplication/leaveapplication_model.dart';
import 'package:new_hrms/employee/widgets/employee_drawer.dart';
import 'package:new_hrms/employee/widgets/employee_header.dart';

class LeaveApplicationPage extends ConsumerStatefulWidget {
  const LeaveApplicationPage({super.key});

  @override
  ConsumerState<LeaveApplicationPage> createState() => _LeaveApplicationPageState();
}

class _LeaveApplicationPageState extends ConsumerState<LeaveApplicationPage> {
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _periodController = TextEditingController();
  String? leaveType;
  DateTime? startDate;
  DateTime? endDate;

  DateTime? _lastBackPressed;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listen(leaveViewModelProvider, (previous, next) {
        if (previous?.isLoading == true && next.isLoading == false) {
          if (next.errorMessage.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Leave application submitted successfully'),
                backgroundColor: Colors.green,
              ),
            );

            _clearForm();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(next.errorMessage),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      });
    });
  }

  void _clearForm() {
    setState(() {
      _titleController.clear();
      _periodController.clear();
      _reasonController.clear();
      leaveType = null;
      startDate = null;
      endDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final leaveState = ref.watch(leaveViewModelProvider);
    double screenWidth = MediaQuery.of(context).size.width;

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
          context.go('/employee/dashboard');
        }
      },

      child: Scaffold(
        appBar: const CustomHeader(title: "Leaves"),
        drawer: CustomDrawer(selectedScreen: "Leave Applications", userName: ''),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel("Enter Title"),
                _buildTextField("Enter Title", Icons.edit, _titleController),

                _buildLabel("Leave Type"),
                _buildDropdown(),

                _buildLabel("Enter Period"),
                _buildTextField("Enter Period", Icons.edit, _periodController),

                _buildLabel("Start Date"),
                _buildDateField("Select Start Date", Icons.calendar_today, isStartDate: true),

                _buildLabel("End Date"),
                _buildDateField("Select End Date", Icons.calendar_today, isStartDate: false),

                _buildLabel("Enter Reason"),
                _buildTextField("Enter Reason", Icons.note, _reasonController),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: leaveState.isLoading
                      ? null
                      : () {
                          if (_validateInputs()) {
                            ref.read(leaveViewModelProvider.notifier).applyLeave(
                              _titleController.text,
                              leaveType ?? "",
                              _periodController.text,
                              _formatDate(startDate),
                              _formatDate(endDate),
                              _reasonController.text,
                            );
                          }
                        },  
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    minimumSize: screenWidth < 600 ? const Size(double.infinity, 50) : const Size(300, 50),
                  ),
                  child: leaveState.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Apply Leave",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _validateInputs() {
    if (_titleController.text.isEmpty) {
      _showSnackBar("Please enter a title");
      return false;
    }
    if (leaveType == null) {
      _showSnackBar("Please select a leave type");
      return false;
    }
    if (startDate == null) {
      _showSnackBar("Please select a start date");
      return false;
    }
    if (endDate == null) {
      _showSnackBar("Please select an end date");
      return false;
    }
    if (_reasonController.text.isEmpty) {
      _showSnackBar("Please enter a reason");
      return false;
    }
    return true;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String _formatDate(DateTime? date) {
    return date != null 
      ? DateFormat('dd-MM-yyyy').format(date) 
      : "";
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 5),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTextField(String hint, IconData icon, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildDateField(String hint, IconData icon, {required bool isStartDate}) {
    return TextField(
      readOnly: true,
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
        );
        if (selectedDate != null) {
          setState(() {
            if (isStartDate) {
              startDate = selectedDate;
            } else {
              endDate = selectedDate;
            }
          });
        }
      },
      controller: TextEditingController(
        text: isStartDate 
          ? (startDate != null ? DateFormat('dd-MM-yyyy').format(startDate!) : '')
          : (endDate != null ? DateFormat('dd-MM-yyyy').format(endDate!) : '')
      ),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: leaveType,
      hint: const Text("Select Leave Type"),
      items: ["Sick Leave", "Casual Leave", "Emergency Leave"]
          .map((leave) => DropdownMenuItem(value: leave, child: Text(leave)))
          .toList(),
      onChanged: (val) {
        setState(() {
          leaveType = val;
        });
      },
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
