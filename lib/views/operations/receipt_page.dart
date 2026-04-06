import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../core/theme.dart';
import '../../models/transaction_model.dart';
import '../../services/bluetooth_service.dart';
import '../../services/export_share_service.dart';
import '../../services/pdf_service.dart';

class ReceiptPage extends StatelessWidget {
  final TransactionModel transaction;
  final String businessName;

  const ReceiptPage({
    super.key,
    required this.transaction,
    required this.businessName,
  });

  Future<void> _sharePdf(BuildContext context) async {
    final file = await PdfService().generateReceipt(transaction, businessName);
    await ExportShareService.sharePdf(file);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF prêt — enregistre-le via Partager (Fichiers, Drive…).')),
      );
    }
  }

  Future<void> _printSystem(BuildContext context) async {
    final file = await PdfService().generateReceipt(transaction, businessName);
    final bytes = await file.readAsBytes();
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<void> _printThermal(BuildContext context) async {
    final svc = BluetoothPrinterService();
    try {
      await svc.printReceipt(transaction, businessName);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Envoyé à l’imprimante Bluetooth (si connectée).')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impression Bluetooth : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy HH:mm').format(transaction.createdAt);
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final variant = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(title: const Text('Reçu')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        businessName.toUpperCase(),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: onSurface),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(color: variant.withOpacity(0.3)),
                    if (transaction.journalSeq != null)
                      _line(context, 'N° journal', '#${transaction.journalSeq}'),
                    _line(context, 'Type', TransactionModel.typeDisplayName(transaction.type)),
                    _line(context, 'Catégorie', transaction.category.name),
                    _line(context, 'Téléphone', transaction.clientPhone),
                    _line(context, 'Montant', '${transaction.amount.toStringAsFixed(0)} CFA'),
                    _line(context, 'Commission', '${transaction.commission.toStringAsFixed(0)} CFA'),
                    _line(context, 'Date', date),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _sharePdf(context),
                    icon: const Icon(Icons.share_rounded, size: 20),
                    label: const Text('Partager PDF'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _printSystem(context),
                    icon: const Icon(Icons.print_rounded, size: 20),
                    label: const Text('Imprimer'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _printThermal(context),
                icon: const Icon(Icons.bluetooth_rounded, size: 20),
                label: const Text('Imprimante thermique'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Terminer', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(BuildContext context, String label, String value) {
    final variant = Theme.of(context).colorScheme.onSurfaceVariant;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: variant)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: onSurface)),
        ],
      ),
    );
  }
}
