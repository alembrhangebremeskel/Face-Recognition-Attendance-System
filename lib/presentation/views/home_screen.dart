import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/attendance_viewmodel.dart';
import 'camera_screen.dart';
// If you have a separate screen for viewing records, import it here. 
// Otherwise, we will use CameraScreen for the scan button.

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.read<AttendanceViewModel>().loadAttendance();

    return Scaffold(
      appBar: AppBar(
        title: const Text("MIT Attendance System"),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
      ),
      body: Consumer<AttendanceViewModel>(
        builder: (context, vm, child) {
          return vm.records.isEmpty
              ? const Center(child: Text("No records yet. Press the camera to start."))
              : ListView.builder(
                  itemCount: vm.records.length,
                  itemBuilder: (context, index) {
                    final record = vm.records[index];
                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(record.name),
                      subtitle: Text("ID: ${record.studentId}"),
                      trailing: Text(record.timestamp),
                    );
                  },
                );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CameraScreen()), // FIXED: Removed 'const' if needed and fixed name
          );
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}