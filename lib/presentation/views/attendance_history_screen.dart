import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/attendance_viewmodel.dart';
import '../../data/models/student_model.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AttendanceViewModel>(context, listen: false).loadAttendance();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance Logs"),
        backgroundColor: const Color(0xFF263238),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => Provider.of<AttendanceViewModel>(context, listen: false).loadAttendance(),
          )
        ],
      ),
      body: Consumer<AttendanceViewModel>(
        builder: (context, viewModel, child) {
          final history = viewModel.records;

          if (history.isEmpty) {
            return const Center(child: Text("No records found in database."));
          }

          return RefreshIndicator(
            onRefresh: () => viewModel.loadAttendance(),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
                    border: TableBorder.all(color: Colors.grey[300]!, width: 1),
                    columnSpacing: 20, // Reduced slightly to fit more columns
                    columns: const [
                      DataColumn(label: Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Location', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))), // New Header
                    ],
                    rows: history.map((student) {
                      return DataRow(cells: [
                        DataCell(Text(student.name)),
                        DataCell(Text(student.studentId)),
                        DataCell(Text(student.timestamp ?? "N/A")),
                        DataCell(
                          Container(
                            constraints: const BoxConstraints(maxWidth: 180),
                            child: Text(
                              student.location ?? "No data",
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        // New DataCell for Status
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.check_circle, color: Colors.green, size: 18),
                              SizedBox(width: 4),
                              Text(
                                "Present",
                                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}