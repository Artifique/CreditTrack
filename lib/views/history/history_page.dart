import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme.dart';
import '../../core/user_feedback.dart';
import '../../controllers/operation_phone_controller.dart';
import '../../controllers/transaction_controller.dart';
import '../../models/transaction_model.dart';
import '../../services/export_share_service.dart';
import '../../widgets/operation_phone_selector.dart';
import '../operations/transaction_detail_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _transactionController = TransactionController();
  final _searchController = TextEditingController();
  String _categoryFilter = "Tout";
  String _businessName = 'Mon Commerce';
  DateTime? _filterFrom;
  DateTime? _filterTo;

  @override
  void initState() {
    super.initState();
    _transactionController.getProfileData().then((p) {
      if (p != null && mounted) {
        OperationPhoneController.instance.syncFromProfile(p.operationPhones);
        setState(() => _businessName = p.businessName);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historique", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range_rounded),
            tooltip: 'Filtrer par date',
            onPressed: _pickDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.table_rows_rounded),
            tooltip: 'Exporter CSV',
            onPressed: _exportCsv,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const OperationPhoneSelector(),
                if (_filterFrom != null || _filterTo != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        _dateFilterLabel(),
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          _filterFrom = null;
                          _filterTo = null;
                        }),
                        child: const Text('Réinitialiser dates'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(
            child: ListenableBuilder(
              listenable: OperationPhoneController.instance,
              builder: (context, _) {
                return StreamBuilder<List<TransactionModel>>(
                  stream: _transactionController.watchTransactions(
                    merchantPhone: OperationPhoneController.instance.selectedForFilter,
                  ),
                  builder: (context, snapshot) {
                    final list = _applyFilters(snapshot.data ?? []);
                    return _buildTransactionList(list);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: "Rechercher un client ou un numéro...",
          prefixIcon: const Icon(Icons.search_rounded),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _FilterChip(label: "Tout", isSelected: _categoryFilter == "Tout", onTap: () => setState(() => _categoryFilter = "Tout")),
          _FilterChip(label: "UV", isSelected: _categoryFilter == "UV", onTap: () => setState(() => _categoryFilter = "UV")),
          _FilterChip(label: "CREDIT", isSelected: _categoryFilter == "CREDIT", onTap: () => setState(() => _categoryFilter = "CREDIT")),
        ],
      ),
    );
  }

  bool _inDateRange(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    if (_filterFrom != null) {
      final from = DateTime(_filterFrom!.year, _filterFrom!.month, _filterFrom!.day);
      if (day.isBefore(from)) return false;
    }
    if (_filterTo != null) {
      final to = DateTime(_filterTo!.year, _filterTo!.month, _filterTo!.day);
      if (day.isAfter(to)) return false;
    }
    return true;
  }

  bool _matchesFilters(TransactionModel tx) {
    final q = _searchController.text.trim().toLowerCase();
    final bySearch = q.isEmpty ||
        tx.clientName.toLowerCase().contains(q) ||
        tx.clientPhone.contains(_searchController.text.trim()) ||
        (tx.merchantPhone ?? '').contains(_searchController.text.trim());
    final byCategory = _categoryFilter == 'Tout' || tx.category.name == _categoryFilter;
    return bySearch && byCategory && _inDateRange(tx.createdAt);
  }

  List<TransactionModel> _applyFilters(List<TransactionModel> transactions) {
    return transactions.where(_matchesFilters).toList();
  }

  String _dateFilterLabel() {
    final df = DateFormat('dd/MM/yyyy');
    if (_filterFrom != null && _filterTo != null) {
      return 'Du ${df.format(_filterFrom!)} au ${df.format(_filterTo!)}';
    }
    if (_filterFrom != null) return 'À partir du ${df.format(_filterFrom!)}';
    if (_filterTo != null) return 'Jusqu’au ${df.format(_filterTo!)}';
    return '';
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _filterFrom != null && _filterTo != null
          ? DateTimeRange(start: _filterFrom!, end: _filterTo!)
          : null,
    );
    if (range == null) return;
    setState(() {
      _filterFrom = range.start;
      _filterTo = range.end;
    });
  }

  Future<void> _exportCsv() async {
    try {
      final phone = OperationPhoneController.instance.selectedForFilter;
      final txs = await _transactionController.getTransactions(merchantPhone: phone, limit: 5000);
      final filtered = txs.where(_matchesFilters).toList();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/credittrak_historique.csv');
      String esc(Object? v) {
        final s = v?.toString() ?? '';
        if (s.contains(';') || s.contains('"') || s.contains('\n')) {
          return '"${s.replaceAll('"', '""')}"';
        }
        return s;
      }
      final lines = <String>[
        'journal_seq;date_utc;type;category;montant;commission;client_tel;numero_operation;id',
      ];
      for (final t in filtered) {
        lines.add([
          t.journalSeq?.toString() ?? '',
          t.createdAt.toIso8601String(),
          TransactionModel.typeToApi(t.type),
          t.category.name,
          t.amount.toStringAsFixed(2),
          t.commission.toStringAsFixed(2),
          esc(t.clientPhone),
          esc(t.merchantPhone),
          esc(t.id),
        ].join(';'));
      }
      await file.writeAsString(lines.join('\n'), encoding: utf8);
      if (!mounted) return;
      await ExportShareService.shareCsv(file, subject: 'CreditTrak — export CSV');
    } catch (e) {
      if (!mounted) return;
      await UserFeedback.showErrorModal(context, e);
    }
  }

  Widget _buildTransactionList(List<TransactionModel> transactions) {
    if (transactions.isEmpty) {
      return const Center(child: Text("Aucune transaction trouvée."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        return _TransactionHistoryItem(
          transaction: tx,
          onOpenDetail: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => TransactionDetailPage(transaction: tx, businessName: _businessName),
              ),
            );
          },
          onEdit: () => _openEditDialog(tx),
          onDelete: () => _confirmDelete(tx),
        );
      },
    );
  }

  Future<void> _confirmDelete(TransactionModel tx) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Supprimer la transaction"),
            content: const Text("Cette action va annuler son impact sur le solde. Continuer ?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Supprimer")),
            ],
          ),
        ) ??
        false;

    if (!ok) return;
    try {
      await _transactionController.deleteTransaction(tx.id!);
      if (!mounted) return;
      await UserFeedback.showSuccessModal(context, "Transaction supprimée.");
    } catch (e) {
      if (!mounted) return;
      await UserFeedback.showErrorModal(context, e);
    }
  }

  Future<void> _openEditDialog(TransactionModel tx) async {
    final phoneCtrl = TextEditingController(text: tx.clientPhone);
    final amountCtrl = TextEditingController(text: tx.amount.toStringAsFixed(0));
    TransactionCategory selectedCategory =
        tx.type == TransactionType.transfertProfitUv ? TransactionCategory.UV : tx.category;
    TransactionType selectedType = tx.type;

    List<TransactionType> typesFor(TransactionCategory c) => c == TransactionCategory.UV
        ? [
            TransactionType.depot,
            TransactionType.retrait,
            TransactionType.nafama,
            TransactionType.transfertUv,
            TransactionType.transfertC2c,
            TransactionType.transfertProfitUv,
          ]
        : [TransactionType.achat, TransactionType.forfait, TransactionType.sewa];

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) {
          final allowed = typesFor(selectedCategory);
          if (!allowed.contains(selectedType)) {
            selectedType = allowed.first;
          }
          final lockCategory = selectedType == TransactionType.transfertProfitUv;
          return AlertDialog(
            title: const Text("Modifier la transaction"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<TransactionCategory>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: "Catégorie"),
                    items: const [
                      DropdownMenuItem(value: TransactionCategory.UV, child: Text("UV")),
                      DropdownMenuItem(value: TransactionCategory.CREDIT, child: Text("CREDIT")),
                    ],
                    onChanged: lockCategory
                        ? null
                        : (v) {
                            if (v == null) return;
                            setLocalState(() {
                              selectedCategory = v;
                            });
                          },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TransactionType>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: "Type"),
                    items: allowed
                        .map(
                          (e) => DropdownMenuItem<TransactionType>(
                            value: e,
                            child: Text(TransactionModel.typeDisplayName(e)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setLocalState(() {
                        selectedType = v;
                        if (v == TransactionType.transfertProfitUv) {
                          selectedCategory = TransactionCategory.UV;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  if (selectedType == TransactionType.transfertProfitUv)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Numéro d’opération : ${tx.merchantPhone ?? "—"}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    )
                  else
                    TextField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(labelText: "Téléphone client"),
                      keyboardType: TextInputType.phone,
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    decoration: const InputDecoration(labelText: "Montant"),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Enregistrer")),
            ],
          );
        },
      ),
    );

    if (saved != true) return;

    final amount = double.tryParse(amountCtrl.text.trim().replaceAll(' ', '')) ?? 0;
    if (amount <= 0) {
      await UserFeedback.showErrorModal(context, Exception('Montant strictement positif requis.'));
      return;
    }
    if (selectedType != TransactionType.transfertProfitUv) {
      final digits = phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
      if (phoneCtrl.text.trim().isEmpty || digits.length < 8) {
        await UserFeedback.showErrorModal(context, Exception('Téléphone client invalide (au moins 8 chiffres).'));
        return;
      }
    }

    try {
      final updated = TransactionModel(
        id: tx.id,
        userId: tx.userId,
        type: selectedType,
        category: selectedCategory,
        clientName: selectedType == TransactionType.transfertProfitUv ? 'Transfert interne' : tx.clientName,
        clientPhone: selectedType == TransactionType.transfertProfitUv
            ? (tx.merchantPhone ?? tx.clientPhone)
            : phoneCtrl.text.trim(),
        merchantPhone: tx.merchantPhone,
        amount: amount,
        commission: TransactionModel.calculateCommission(selectedType, amount),
        soldeApres: tx.soldeApres,
        note: tx.note,
        createdAt: tx.createdAt,
      );
      await _transactionController.updateTransaction(updated);
      if (!mounted) return;
      await UserFeedback.showSuccessModal(context, "Transaction modifiée.");
    } catch (e) {
      if (!mounted) return;
      await UserFeedback.showErrorModal(context, e);
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) => onTap(),
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedColor: AppColors.primary.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        showCheckmark: false,
      ),
    );
  }
}

class _TransactionHistoryItem extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback onOpenDetail;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _TransactionHistoryItem({
    required this.transaction,
    required this.onOpenDetail,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = transaction.type;
    final isDepot = t == TransactionType.depot;
    final isRetrait = t == TransactionType.retrait;
    late final Color iconBg;
    late final Color iconFg;
    late final IconData iconData;
    if (isDepot) {
      iconBg = Colors.red.shade50;
      iconFg = Colors.red;
      iconData = Icons.arrow_downward_rounded;
    } else if (isRetrait) {
      iconBg = Colors.green.shade50;
      iconFg = Colors.green;
      iconData = Icons.arrow_upward_rounded;
    } else {
      iconBg = scheme.surfaceContainerHighest;
      iconFg = scheme.primary;
      iconData = Icons.receipt_long_rounded;
    }
    final amountColor = t.amountDisplayColor(scheme.onSurface);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: InkWell(
              onTap: onOpenDetail,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(iconData, color: iconFg),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(transaction.clientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (transaction.merchantPhone != null && transaction.merchantPhone!.isNotEmpty)
                            Text(
                              "Op. ${transaction.merchantPhone}",
                              style: TextStyle(color: AppColors.primary.withOpacity(0.9), fontSize: 11),
                            ),
                          Text(
                            "${transaction.createdAt.day}/${transaction.createdAt.month}/${transaction.createdAt.year}"
                            "${transaction.journalSeq != null ? ' · N°${transaction.journalSeq}' : ''}",
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                          Text(
                            'Détail & reçu',
                            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${transaction.amount.toStringAsFixed(0)} F",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: amountColor,
                            fontSize: 16,
                          ),
                        ),
                        Text(transaction.category.name, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                        Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 4),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text("Modifier")),
                PopupMenuItem(value: 'delete', child: Text("Supprimer")),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
