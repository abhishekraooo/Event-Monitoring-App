// lib/core/services/export_service.dart

import 'dart:convert';
import 'package:csv/csv.dart';
import 'dart:html' as html; // For web-specific download

class ExportService {
  void exportToCsv(List<List<dynamic>> rows, String fileName) {
    if (rows.length <= 1) {
      // Only headers
      // You can add a snackbar here if you want feedback for no data
      return;
    }

    String csv = const ListToCsvConverter().convert(rows);

    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.Url.revokeObjectUrl(url);
  }
}
