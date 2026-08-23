import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/transaction_model.dart';

/// Métadonnées des filtres Historique à imprimer en en-tête du PDF.
class HistoryReportFilters {
  const HistoryReportFilters({
    required this.periodLabel,
    required this.categoryLabel,
    required this.typeLabel,
    this.searchQuery = '',
    this.merchantPhone,
  });

  final String periodLabel;
  final String categoryLabel;
  final String typeLabel;
  final String searchQuery;
  final String? merchantPhone;
}

class PdfService {
  // Générer un reçu de transaction unique
  Future<File> generateReceipt(TransactionModel transaction, String businessName) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(transaction.createdAt);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Format thermique 80mm
        margin: const pw.EdgeInsets.all(10),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(businessName.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              pw.SizedBox(height: 5),
              pw.Text("---------------------------------"),
              pw.SizedBox(height: 10),
                  if (transaction.journalSeq != null) ...[
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("N° journal:"),
                        pw.Text("#${transaction.journalSeq}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                  pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Type:"),
                  pw.Text(TransactionModel.typeDisplayName(transaction.type).toUpperCase(),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Client:"),
                  pw.Text(transaction.clientName),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Tel:"),
                  pw.Text(transaction.clientPhone),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Text("---------------------------------"),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("MONTANT:", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Text("${transaction.amount} CFA", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Commission:"),
                  pw.Text("${transaction.commission} CFA", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Text("---------------------------------"),
              pw.SizedBox(height: 10),
              pw.Text("Date: $dateStr", style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 20),
              pw.Text("Merci de votre confiance !", style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 10)),
            ],
          );
        },
      ),
    );

    return _saveDocument(name: 'recu_${transaction.id}.pdf', pdf: pdf);
  }

  /// Construit le PDF historique en mémoire (web + mobile, sans path_provider).
  Future<({Uint8List bytes, String filename})> buildHistoryPdf({
    required List<TransactionModel> transactions,
    required HistoryReportFilters filters,
  }) async {
    final fileStamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final pdf = _historyDocument(transactions, filters);
    return (
      bytes: await pdf.save(),
      filename: 'historique_credittrak_$fileStamp.pdf',
    );
  }

  /// Rapport historique enregistré sur disque (mobile / desktop uniquement).
  Future<File> generateHistoryReport({
    required List<TransactionModel> transactions,
    required HistoryReportFilters filters,
  }) async {
    final built = await buildHistoryPdf(transactions: transactions, filters: filters);
    if (kIsWeb) {
      throw UnsupportedError('Enregistrement fichier indisponible sur le web. Utilise buildHistoryPdf.');
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${built.filename}');
    await file.writeAsBytes(built.bytes);
    return file;
  }

  pw.Document _historyDocument(
    List<TransactionModel> transactions,
    HistoryReportFilters filters,
  ) {
    final pdf = pw.Document();
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final amountFmt = NumberFormat('#,##0');

    final count = transactions.length;
    final totalAmount = transactions.fold<double>(0, (s, t) => s + t.amount);
    final totalCommission = transactions.fold<double>(0, (s, t) => s + t.commission);

    String money(double v) => '${amountFmt.format(v.round())} F';

    final filterLines = <String>[
      'Période : ${filters.periodLabel}',
      'Catégorie : ${filters.categoryLabel}',
      'Type : ${filters.typeLabel}',
    ];
    if (filters.searchQuery.trim().isNotEmpty) {
      filterLines.add('Recherche : ${filters.searchQuery.trim()}');
    }
    if (filters.merchantPhone != null && filters.merchantPhone!.trim().isNotEmpty) {
      filterLines.add('N° transfert : ${filters.merchantPhone}');
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          pw.Text(
            'Historique des transactions',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          ...filterLines.map((l) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Text(l, style: const pw.TextStyle(fontSize: 10)),
              )),
          pw.SizedBox(height: 12),
          pw.Text(
            '$count opération${count > 1 ? 's' : ''}  ·  Montant ${money(totalAmount)}  ·  Commissions ${money(totalCommission)}',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Date et heure', 'Type', 'Client / tél.', 'N° transfert', 'Montant', 'Commission'],
            data: transactions
                .map((t) {
                  final phone = t.clientPhone.trim();
                  final client = phone.isEmpty ? t.clientName : '${t.clientName}  $phone';
                  return [
                    dateFmt.format(t.createdAt),
                    TransactionModel.typeDisplayName(t.type),
                    client,
                    t.merchantPhone ?? '—',
                    money(t.amount),
                    money(t.commission),
                  ];
                })
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          ),
        ],
      ),
    );
    return pdf;
  }

  // Enregistrer le fichier dans le stockage local
  Future<File> _saveDocument({required String name, required pw.Document pdf}) async {
    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes);
    return file;
  }
}
