// lib/services/export_service_web.dart
// Web-specific implementation - triggers browser download

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

/// Save PDF by triggering browser download
Future<String> savePdf(Uint8List bytes, String fileName) async {
  // Create a blob from the PDF bytes
  final blob = html.Blob([bytes], 'application/pdf');
  
  // Create a download URL
  final url = html.Url.createObjectUrlFromBlob(blob);
  
  // Create an anchor element and trigger download
  final anchor = html.AnchorElement()
    ..href = url
    ..download = fileName
    ..style.display = 'none';
  
  html.document.body?.children.add(anchor);
  anchor.click();
  
  // Cleanup
  html.document.body?.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
  
  return fileName; // Return filename as confirmation
}

/// Share is not supported on web - no-op
Future<void> sharePdf(String filePath) async {
  // Web doesn't support native share in the same way
  // The file was already downloaded via browser
}
