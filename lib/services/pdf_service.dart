import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../models/transaction_model.dart';
import 'package:intl/intl.dart';

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
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Type:"),
                  pw.Text(transaction.type.name.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
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

  // Générer un rapport complet de transactions (Liste)
  Future<File> generateReport(List<TransactionModel> transactions, String title) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(level: 0, child: pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['Date', 'Type', 'Client', 'N° op.', 'Montant', 'Solde'],
            data: transactions.map((t) => [
              DateFormat('dd/MM/yy').format(t.createdAt),
              t.type.name,
              t.clientName,
              t.merchantPhone ?? '—',
              "${t.amount} F",
              "${t.soldeApres} F"
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );

    return _saveDocument(name: 'rapport_credit_trak.pdf', pdf: pdf);
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
