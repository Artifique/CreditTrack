import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/user_feedback.dart';
import '../../controllers/operation_phone_controller.dart';
import '../../controllers/transaction_controller.dart';
import '../../models/transaction_model.dart';
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
          IconButton(icon: const Icon(Icons.filter_list_rounded), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: OperationPhoneSelector(),
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

  List<TransactionModel> _applyFilters(List<TransactionModel> transactions) {
    return transactions.where((tx) {
      final bySearch = _searchController.text.trim().isEmpty ||
          tx.clientName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          tx.clientPhone.contains(_searchController.text.trim());
      final byCategory = _categoryFilter == "Tout" || tx.category.name == _categoryFilter;
      return bySearch && byCategory;
    }).toList();
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
    TransactionCategory selectedCategory = tx.category;
    TransactionType selectedType = tx.type;

    List<TransactionType> typesFor(TransactionCategory c) => c == TransactionCategory.UV
        ? [
            TransactionType.depot,
            TransactionType.retrait,
            TransactionType.nafama,
            TransactionType.transfertUv,
            TransactionType.transfertC2c,
          ]
        : [TransactionType.achat, TransactionType.forfait, TransactionType.sewa];

    String typeLabel(TransactionType type) {
      switch (type) {
        case TransactionType.depot:
          return "Depot";
        case TransactionType.retrait:
          return "Retrait";
        case TransactionType.nafama:
          return "Nafama";
        case TransactionType.transfertUv:
          return "Transfert UV";
        case TransactionType.transfertC2c:
          return "Transfert C2C";
        case TransactionType.achat:
          return "Achat";
        case TransactionType.forfait:
          return "Forfait";
        case TransactionType.sewa:
          return "Sewa";
      }
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) {
          final allowed = typesFor(selectedCategory);
          if (!allowed.contains(selectedType)) selectedType = allowed.first;
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
                    onChanged: (v) {
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
                        .map((e) => DropdownMenuItem<TransactionType>(value: e, child: Text(typeLabel(e))))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setLocalState(() => selectedType = v);
                    },
                  ),
                  const SizedBox(height: 12),
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

    final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
    if (phoneCtrl.text.trim().isEmpty || amount <= 0) {
      await UserFeedback.showErrorModal(context, Exception("Montant et téléphone sont requis."));
      return;
    }

    try {
      final updated = TransactionModel(
        id: tx.id,
        userId: tx.userId,
        type: selectedType,
        category: selectedCategory,
        clientName: tx.clientName,
        clientPhone: phoneCtrl.text.trim(),
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
    final isPositive =
        transaction.type == TransactionType.retrait || transaction.type == TransactionType.achat;
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
                        color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isPositive ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
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
                            "${transaction.createdAt.day}/${transaction.createdAt.month}/${transaction.createdAt.year}",
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
                          "${isPositive ? '+' : '-'} ${transaction.amount.toStringAsFixed(0)} F",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isPositive ? Colors.green : Colors.red,
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
