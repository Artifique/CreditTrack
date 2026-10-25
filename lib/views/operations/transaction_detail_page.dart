import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../core/app_logger.dart';
import '../../core/tokens.dart';
import '../../core/user_feedback.dart';
import '../../models/transaction_model.dart';
import '../../services/bluetooth_service.dart';
import '../../services/export_share_service.dart';
import '../../services/pdf_service.dart';
import '../../widgets/ui/app_button.dart';
import '../../widgets/ui/fade_in_up.dart';
import 'widgets/transaction_detail_ticket.dart';

/// Détail d'une transaction : consultation complète, impact des soldes, impression & export PDF.
class TransactionDetailPage extends StatefulWidget {
  final TransactionModel transaction;
  final String businessName;

  const TransactionDetailPage({
    super.key,
    required this.transaction,
    required this.businessName,
  });

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  bool _isGeneratingPdf = false;
  bool _isPrintingThermal = false;
  bool _isPrintingSystem = false;

  final _moneyFormat = NumberFormat('#,##0', 'fr_FR');

  Future<void> _downloadPdf() async {
    if (_isGeneratingPdf) return;
    setState(() => _isGeneratingPdf = true);

    try {
      final file = await PdfService().generateReceipt(widget.transaction, widget.businessName);
      await ExportShareService.sharePdf(file, subject: 'Reçu CreditTrack - #${widget.transaction.journalSeq ?? ''}');
      if (mounted) {
        UserFeedback.showSuccessToast(context, 'PDF prêt pour le partage');
      }
    } catch (e, st) {
      AppLogger.error('Erreur génération PDF détail', e, st);
      if (mounted) {
        UserFeedback.showErrorToast(context, 'Erreur génération PDF: $e');
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _printSystem() async {
    if (_isPrintingSystem) return;
    setState(() => _isPrintingSystem = true);

    try {
      final file = await PdfService().generateReceipt(widget.transaction, widget.businessName);
      final bytes = await file.readAsBytes();
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e, st) {
      AppLogger.error('Erreur impression système détail', e, st);
      if (mounted) {
        UserFeedback.showErrorToast(context, 'Erreur impression système: $e');
      }
    } finally {
      if (mounted) setState(() => _isPrintingSystem = false);
    }
  }

  Future<void> _printThermal() async {
    if (_isPrintingThermal) return;
    setState(() => _isPrintingThermal = true);

    try {
      await BluetoothPrinterService().printReceipt(widget.transaction, widget.businessName);
      if (mounted) {
        UserFeedback.showSuccessToast(context, 'Ticket envoyé à l’imprimante Bluetooth');
      }
    } catch (e, st) {
      AppLogger.error('Erreur impression thermique détail', e, st);
      if (mounted) {
        UserFeedback.showErrorModal(context, e);
      }
    } finally {
      if (mounted) setState(() => _isPrintingThermal = false);
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    UserFeedback.showToast(context, '$label copié dans le presse-papiers');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tx = widget.transaction;

    final dateFormatted = DateFormat("dd/MM/yyyy 'à' HH:mm").format(tx.createdAt);
    final amountFormatted = '${_moneyFormat.format(tx.amount)} F';
    final soldeAvantFormatted = '${_moneyFormat.format(tx.soldeAvant)} F';
    final soldeApresFormatted = '${_moneyFormat.format(tx.soldeApres)} F';
    final commissionFormatted = '${_moneyFormat.format(tx.commission)} F';

    final isDepositOrDebit = [
      TransactionType.depot,
      TransactionType.nafama,
      TransactionType.transfertC2c,
      TransactionType.forfait,
      TransactionType.sewa,
      TransactionType.transfertCredit,
    ].contains(tx.type);

    final amountColor = isDepositOrDebit ? AppTokens.error : AppTokens.success;

    return Scaffold(
      backgroundColor: isDark ? AppTokens.darkBg : AppTokens.lightBg,
      appBar: AppBar(
        title: const Text(
          'Détail de l’opération',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 21),
            tooltip: 'Partager / Exporter',
            onPressed: _downloadPdf,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        child: FadeInUp(
          child: Column(
            children: [
              TransactionDetailTicket(
                transaction: tx,
                businessName: widget.businessName,
                dateFormatted: dateFormatted,
                amountFormatted: amountFormatted,
                soldeAvantFormatted: soldeAvantFormatted,
                soldeApresFormatted: soldeApresFormatted,
                commissionFormatted: commissionFormatted,
                amountColor: amountColor,
                isDark: isDark,
                onCopy: _copyToClipboard,
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Imprimer Ticket (Système)',
                icon: Icons.print_rounded,
                size: AppButtonSize.lg,
                isFullWidth: true,
                isLoading: _isPrintingSystem,
                onPressed: _printSystem,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Partager PDF',
                      icon: Icons.picture_as_pdf_rounded,
                      variant: AppButtonVariant.outline,
                      size: AppButtonSize.md,
                      isLoading: _isGeneratingPdf,
                      onPressed: _downloadPdf,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Thermique',
                      icon: Icons.bluetooth_rounded,
                      variant: AppButtonVariant.outline,
                      size: AppButtonSize.md,
                      isLoading: _isPrintingThermal,
                      onPressed: _printThermal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
