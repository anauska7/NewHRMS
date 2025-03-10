import 'package:flutter/material.dart';
import 'package:new_hrms/employee/widgets/employee_drawer.dart';
import 'package:new_hrms/employee/widgets/employee_header.dart';

class TeamsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomHeader(title: "Teams"),
      drawer: CustomDrawer(selectedScreen: "Teams"),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Table(
          border: TableBorder.all(),
          children: [
            TableRow(
              children: [
                _buildTableCell(" # "),
                _buildTableCell("Image"),
                _buildTableCell("Name"),
              ],
            ),
            TableRow(
              children: [
                _buildTableCell("1"),
                _buildImageCell(),
                _buildTableCell(""),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Center(child: Text(text, style: TextStyle(fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildImageCell() {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Center(
        child: CircleAvatar(radius: 10, backgroundColor: Colors.green),
      ),
    );
  }
}
