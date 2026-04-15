import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/attendance_viewmodel.dart';
import '../../data/services/data_export_service.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  // Initialize the export service
  final DataExportService _exportService = DataExportService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AttendanceViewModel>(context, listen: false).loadAttendance();
    });
  }

  /// Maps the student models to the format expected by the DataExportService
  List<Map<String, dynamic>> _prepareExportData(List records) {
    return records.map((student) {
      return {
        'studentId': student.studentId,
        'name': student.name,
        'timestamp': student.timestamp ?? "N/A",
        'status': "Present", // As per your UI requirements
        'location': student.location ?? "No data",
      };
    }).toList();
  }

  /// Handles the Share functionality (opens Android share sheet)
  void _handleShare(List records) async {
    if (records.isEmpty) {
      _showSnackBar("No records available to share", isError: true);
      return;
    }

    _showSnackBar("Preparing report for sharing...");
    final exportData = _prepareExportData(records);
    await _exportService.shareExcel(exportData);
  }

  /// Handles the Direct Download functionality (saves to /Download folder)
  void _handleDownload(List records) async {
    if (records.isEmpty) {
      _showSnackBar("No records available to download", isError: true);
      return;
    }

    _showSnackBar("Downloading Excel Report...");
    final exportData = _prepareExportData(records);
    String? path = await _exportService.downloadExcel(exportData);

    if (path != null && mounted) {
      _showSnackBar("Saved to Downloads: $path", isSuccess: true);
    } else if (mounted) {
      _showSnackBar("Download failed. Check storage permissions.", isError: true);
    }
  }

  /// Helper to show SnackBars for user feedback
  void _showSnackBar(String message, {bool isError = false, bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : (isSuccess ? Colors.green : null),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance Logs"),
        backgroundColor: const Color(0xFF00796B), // MIT Professional Teal
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // 1. DIRECT DOWNLOAD BUTTON (Saves to phone storage)
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: "Download to Phone",
            onPressed: () {
              final viewModel = Provider.of<AttendanceViewModel>(context, listen: false);
              _handleDownload(viewModel.records);
            },
          ),

          // 2. SHARE BUTTON (Opens Telegram, Email, etc.)
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: "Share Report",
            onPressed: () {
              final viewModel = Provider.of<AttendanceViewModel>(context, listen: false);
              _handleShare(viewModel.records);
            },
          ),

          // REFRESH BUTTON
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
                    columnSpacing: 20,
                    columns: const [
                      DataColumn(label: Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Location', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
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