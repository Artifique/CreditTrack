import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../controllers/transaction_controller.dart';
import '../../models/transaction_model.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _transactionController = TransactionController();
  final _searchController = TextEditingController();
  String _categoryFilter = "Tout";

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
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(
            child: StreamBuilder<List<TransactionModel>>(
              stream: _transactionController.transactionStream,
              builder: (context, snapshot) {
                final list = _applyFilters(snapshot.data ?? []);
                return _buildTransactionList(list);
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
          fillColor: Colors.white,
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
        return _TransactionHistoryItem(transaction: transactions[index]);
      },
    );
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
        backgroundColor: Colors.white,
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
  const _TransactionHistoryItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isPositive =
        transaction.type == TransactionType.retrait || transaction.type == TransactionType.achat;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
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
                Text(
                  "${transaction.createdAt.day}/${transaction.createdAt.month}/${transaction.createdAt.year}",
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
            ],
          ),
        ],
      ),
    );
  }
}
