
import 'dart:typed_data';

Future<String> savePdf(Uint8List bytes, String fileName) async {
  throw UnsupportedError('Cannot save PDF without platform support');
}

Future<void> sharePdf(String filePath) async {
  throw UnsupportedError('Cannot share PDF without platform support');
}
