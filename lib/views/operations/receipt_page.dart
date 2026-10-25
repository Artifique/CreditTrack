import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../core/app_logger.dart';
import '../../core/tokens.dart';
import '../../models/transaction_model.dart';
import '../../services/bluetooth_service.dart';
import '../../services/export_share_service.dart';
import '../../services/pdf_service.dart';
import 'widgets/receipt_info_line.dart';

/// Page d'affichage et d'impression du reçu transactionnel.
class ReceiptPage extends StatelessWidget {
  final TransactionModel transaction;
  final String businessName;

  const ReceiptPage({
    super.key,
    required this.transaction,
    required this.businessName,
  });

  Future<void> _sharePdf(BuildContext context) async {
    try {
      final file = await PdfService().generateReceipt(transaction, businessName);
      await ExportShareService.sharePdf(file);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF prêt pour le partage.')),
        );
      }
    } catch (e, st) {
      AppLogger.error('Erreur partage PDF reçu', e, st);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur PDF : $e')),
        );
      }
    }
  }

  Future<void> _printSystem(BuildContext context) async {
    try {
      final file = await PdfService().generateReceipt(transaction, businessName);
      final bytes = await file.readAsBytes();
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e, st) {
      AppLogger.error('Erreur impression système', e, st);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur impression : $e')),
        );
      }
    }
  }

  Future<void> _printThermal(BuildContext context) async {
    final svc = BluetoothPrinterService();
    try {
      await svc.printReceipt(transaction, businessName);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Envoyé à l’imprimante Bluetooth.')),
        );
      }
    } catch (e, st) {
      AppLogger.error('Erreur impression thermique', e, st);
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
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final variant = theme.colorScheme.onSurfaceVariant;

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
                  boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 8)],
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
                    Divider(color: variant.withValues(alpha: 0.3)),
                    if (transaction.journalSeq != null)
                      ReceiptInfoLine(label: 'N° journal', value: '#${transaction.journalSeq}'),
                    ReceiptInfoLine(label: 'Type', value: TransactionModel.typeDisplayName(transaction.type)),
                    ReceiptInfoLine(label: 'Catégorie', value: transaction.category.name),
                    ReceiptInfoLine(label: 'Téléphone', value: transaction.clientPhone),
                    ReceiptInfoLine(
                      label: 'Montant',
                      value: '${transaction.amount.toStringAsFixed(0)} CFA',
                      valueColor: transaction.type.amountDisplayColor(onSurface),
                      isBold: true,
                    ),
                    ReceiptInfoLine(label: 'Commission', value: '${transaction.commission.toStringAsFixed(0)} CFA'),
                    ReceiptInfoLine(label: 'Date', value: date),
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
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTokens.primary500,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Terminer', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
