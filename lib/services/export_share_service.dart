import 'dart:io';

import 'package:share_plus/share_plus.dart';

String _fileName(File file) {
  final p = file.path.replaceAll('\\', '/');
  final i = p.lastIndexOf('/');
  return i >= 0 ? p.substring(i + 1) : p;
}

/// Partage un fichier (PDF, CSV, etc.) via la feuille système Android / iOS.
class ExportShareService {
  static Future<void> sharePdf(File file, {String subject = 'CreditTrak'}) async {
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf', name: _fileName(file))],
      subject: subject,
    );
  }

  static Future<void> shareCsv(File file, {String subject = 'CreditTrak'}) async {
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv', name: _fileName(file))],
      subject: subject,
    );
  }
}
