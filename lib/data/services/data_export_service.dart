import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DataExportService {
  // Common Logic to build the Excel file to avoid repeating code
  Future<List<int>?> _generateExcelBytes(List<Map<String, dynamic>> attendanceLogs) async {
    var excel = Excel.createExcel();
    String sheetName = "MIT_Attendance_Report";
    Sheet sheetObject = excel[sheetName];
    excel.delete('Sheet1');

    CellStyle headerStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString("#00796B"),
      fontColorHex: ExcelColor.fromHexString("#FFFFFF"),
      fontFamily: getFontFamily(FontFamily.Calibri),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    CellStyle dataStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      fontFamily: getFontFamily(FontFamily.Calibri),
    );

    // Set Column Widths (Name column set to 70 for Telegram/Mobile visibility)
    sheetObject.setColumnWidth(0, 15.0); // ID
    sheetObject.setColumnWidth(1, 70.0); // Name
    sheetObject.setColumnWidth(2, 25.0); // Date
    sheetObject.setColumnWidth(3, 15.0); // Status

    // Header Row
    List<CellValue> headers = [
      TextCellValue("Student ID"),
      TextCellValue("Full Name"),
      TextCellValue("Date & Time"),
      TextCellValue("Status")
    ];

    for (int i = 0; i < headers.length; i++) {
      var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headers[i];
      cell.cellStyle = headerStyle;
    }

    // Data Rows
    for (int i = 0; i < attendanceLogs.length; i++) {
      var log = attendanceLogs[i];
      List<CellValue> rowValues = [
        TextCellValue(log['studentId']?.toString() ?? 'N/A'),
        TextCellValue(log['name']?.toString() ?? 'N/A'),
        TextCellValue(log['timestamp']?.toString() ?? 'N/A'),
        TextCellValue(log['status']?.toString() ?? 'Present'),
      ];

      for (int colIndex = 0; colIndex < rowValues.length; colIndex++) {
        var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: i + 1));
        cell.value = rowValues[colIndex];
        cell.cellStyle = dataStyle;
      }
    }
    return excel.save();
  }

  // METHOD 1: Share (Opens Telegram, Email, etc.)
  Future<void> shareExcel(List<Map<String, dynamic>> attendanceLogs) async {
    final bytes = await _generateExcelBytes(attendanceLogs);
    if (bytes == null) return;

    final directory = await getTemporaryDirectory();
    final path = "${directory.path}/MIT_Attendance_Share.xlsx";
    await File(path).writeAsBytes(bytes);
    await Share.shareXFiles([XFile(path)], text: 'MIT Attendance Report');
  }

  // METHOD 2: Download (Fixed for Modern Android Scoped Storage)
  Future<String?> downloadExcel(List<Map<String, dynamic>> attendanceLogs) async {
    try {
      final bytes = await _generateExcelBytes(attendanceLogs);
      if (bytes == null) return null;

      // FIX: Use getExternalStorageDirectory() to find a safe path on the phone
      // This avoids the permission errors caused by hardcoded strings
      final directory = await getExternalStorageDirectory();
      if (directory == null) return null;

      final String fileName = "MIT_Attendance_${DateTime.now().millisecondsSinceEpoch}.xlsx";
      final String path = "${directory.path}/$fileName";
      
      final file = File(path);
      await file.writeAsBytes(bytes);
      return path;
    } catch (e) {
      print("Download Error: $e");
      return null;
    }
  }
}