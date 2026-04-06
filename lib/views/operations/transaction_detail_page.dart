import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../core/theme.dart';
import '../../models/transaction_model.dart';
import '../../services/bluetooth_service.dart';
import '../../services/export_share_service.dart';
import '../../services/pdf_service.dart';

/// Détail d’une transaction : consultation, impression, export PDF.
class TransactionDetailPage extends StatelessWidget {
  final TransactionModel transaction;
  final String businessName;

  const TransactionDetailPage({
    super.key,
    required this.transaction,
    required this.businessName,
  });

  Future<void> _downloadPdf(BuildContext context) async {
    final file = await PdfService().generateReceipt(transaction, businessName);
    await ExportShareService.sharePdf(file, subject: 'Reçu CreditTrak');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choisis « Enregistrer » ou une appli (Fichiers, Drive…) pour télécharger le PDF.'),
        ),
      );
    }
  }

  Future<void> _printSystem(BuildContext context) async {
    final file = await PdfService().generateReceipt(transaction, businessName);
    final bytes = await file.readAsBytes();
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<void> _printThermal(BuildContext context) async {
    try {
      await BluetoothPrinterService().printReceipt(transaction, businessName);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Envoyé à l’imprimante Bluetooth (si connectée).')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy à HH:mm').format(transaction.createdAt);
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final variant = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(title: const Text('Détail de l’opération')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  businessName.toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: onSurface),
                ),
                const SizedBox(height: 16),
                if (transaction.journalSeq != null)
                  _row('N° journal', '#${transaction.journalSeq}', variant, onSurface),
                _row('Type', TransactionModel.typeDisplayName(transaction.type), variant, onSurface),
                _row('Catégorie', transaction.category.name, variant, onSurface),
                _row('Client', transaction.clientName, variant, onSurface),
                _row('Téléphone', transaction.clientPhone, variant, onSurface),
                if (transaction.merchantPhone != null && transaction.merchantPhone!.isNotEmpty)
                  _row('N° opération', transaction.merchantPhone!, variant, onSurface),
                _row('Montant', '${NumberFormat('#,##0', 'fr_FR').format(transaction.amount)} CFA', variant, onSurface),
                _row('Commission', '${NumberFormat('#,##0', 'fr_FR').format(transaction.commission)} CFA', variant, onSurface),
                _row('Solde après', '${NumberFormat('#,##0', 'fr_FR').format(transaction.soldeApres)} CFA', variant, onSurface),
                if (transaction.note != null && transaction.note!.trim().isNotEmpty)
                  _row('Note', transaction.note!, variant, onSurface),
                const Divider(height: 28),
                Text(date, style: TextStyle(fontSize: 13, color: variant)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _printSystem(context),
            icon: const Icon(Icons.print_rounded),
            label: const Text('Imprimer le reçu'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 52),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _downloadPdf(context),
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: const Text('Télécharger / partager le PDF'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _printThermal(context),
            icon: const Icon(Icons.bluetooth_rounded),
            label: const Text('Imprimante thermique'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color variant, Color onSurface) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(color: variant, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: onSurface, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
