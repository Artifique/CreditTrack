import 'dart:io';
import 'dart:typed_data';

import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

String _fileName(File file) {
  final p = file.path.replaceAll('\\', '/');
  final i = p.lastIndexOf('/');
  return i >= 0 ? p.substring(i + 1) : p;
}

/// Partage un fichier (PDF, etc.) via la feuille système Android / iOS / web.
class ExportShareService {
  /// Web : télécharge le PDF. Mobile : ouvre Enregistrer / Partager / Envoyer.
  static Future<void> sharePdfBytes(
    Uint8List bytes, {
    required String filename,
  }) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  static Future<void> sharePdf(File file, {String subject = 'CreditTrak'}) async {
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf', name: _fileName(file))],
      subject: subject,
    );
  }
}
