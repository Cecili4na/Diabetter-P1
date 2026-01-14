// lib/services/export_service_io.dart
// Mobile/Desktop implementation - uses file system

import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Save PDF to temporary directory
Future<String> savePdf(Uint8List bytes, String fileName) async {
  final output = await getTemporaryDirectory();
  final filePath = '${output.path}/$fileName';
  final file = File(filePath);
  await file.writeAsBytes(bytes);
  return filePath;
}

/// Share PDF using native share dialog
Future<void> sharePdf(String filePath) async {
  await Share.shareXFiles(
    [XFile(filePath)],
    subject: 'Relatório Diabetter',
    text: 'Aqui está meu relatório do Diabetter.',
  );
}
