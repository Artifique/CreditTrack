import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_formatters.dart';
import '../../core/tokens.dart';
import '../../core/user_feedback.dart';
import '../../controllers/operation_phone_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/transaction_controller.dart';
import '../../models/commission_rates_model.dart';
import '../../models/transaction_model.dart';
import '../../services/export_share_service.dart';
import '../../services/pdf_service.dart';
import '../../widgets/operation_phone_selector.dart';
import '../../widgets/ui/ui.dart';
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
  TransactionType? _typeFilter;
  String _businessName = 'Mon Commerce';
  DateTime? _filterFrom;
  DateTime? _filterTo;
  bool _exportingPdf = false;
  List<TransactionModel> _lastFiltered = const [];
  CommissionRates _commissionRates = CommissionRates.defaults;

  static const _uvTypes = [
    TransactionType.depot,
    TransactionType.retrait,
    TransactionType.nafama,
    TransactionType.transfertUv,
    TransactionType.transfertC2c,
    TransactionType.transfertProfitUv,
  ];
  static const _creditTypes = [
    TransactionType.achat,
    TransactionType.forfait,
    TransactionType.sewa,
    TransactionType.transfertCredit,
  ];

  @override
  void initState() {
    super.initState();
    _transactionController.getProfileData().then((p) {
      if (p != null && mounted) {
        OperationPhoneController.instance.syncFromProfile(p.operationPhones);
        setState(() => _businessName = p.businessName);
      }
    });
    SettingsController().getBusinessSettings().then((s) {
      if (!mounted) return;
      setState(() => _commissionRates = s.commissionRates);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Historique des Opérations",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Exporter en PDF',
            onPressed: _exportingPdf ? null : _exportPdfFromStream,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ResponsiveContainer(
        maxWidth: 1040,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const OperationPhoneSelector(),
                  const SizedBox(height: 12),
                  _buildPeriodRow(isDark),
                ],
              ),
            ),
            _buildSearchBar(isDark),
            _buildCategoryChips(),
            const SizedBox(height: 6),
            _buildTypeChips(),
            const SizedBox(height: 8),
            Expanded(
              child: ListenableBuilder(
                listenable: OperationPhoneController.instance,
                builder: (context, _) {
                  return StreamBuilder<List<TransactionModel>>(
                    stream: _transactionController.watchTransactions(
                      merchantPhone:
                          OperationPhoneController.instance.selectedForFilter,
                    ),
                    builder: (context, snapshot) {
                      final list = _applyFilters(snapshot.data ?? []);
                      _lastFiltered = list;
                      return Column(
                        children: [
                          _buildSummaryBar(list, isDark),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                            child: AppButton(
                              label: _exportingPdf
                                  ? 'Exportation en cours…'
                                  : 'Exporter la sélection en PDF',
                              icon: Icons.picture_as_pdf_rounded,
                              variant: AppButtonVariant.outline,
                              isFullWidth: true,
                              isLoading: _exportingPdf,
                              onPressed: () => _exportPdf(list),
                            ),
                          ),
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh:
                                  _transactionController.refreshTransactions,
                              child: _buildTransactionList(list, isDark),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: AppInput(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        hintText: "Rechercher par client, téléphone ou N°...",
        prefixIcon: Icons.search_rounded,
        suffix: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
              )
            : null,
      ),
    );
  }

  Widget _buildPeriodRow(bool isDark) {
    final df = DateFormat('dd/MM/yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _DateReadOnlyField(
                label: 'Du',
                value: _filterFrom != null ? df.format(_filterFrom!) : '—',
                onTap: _pickDateRange,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DateReadOnlyField(
                label: 'Au',
                value: _filterTo != null ? df.format(_filterTo!) : '—',
                onTap: _pickDateRange,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            AppButton(
              label: 'Choisir une période',
              icon: Icons.date_range_rounded,
              variant: AppButtonVariant.ghost,
              size: AppButtonSize.sm,
              onPressed: _pickDateRange,
            ),
            if (_filterFrom != null || _filterTo != null) ...[
              const SizedBox(width: 6),
              AppButton(
                label: 'Réinitialiser',
                variant: AppButtonVariant.ghost,
                size: AppButtonSize.sm,
                onPressed: () => setState(() {
                  _filterFrom = null;
                  _filterTo = null;
                }),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _FilterChip(
              label: "Tout",
              isSelected: _categoryFilter == "Tout",
              onTap: () => _setCategory("Tout")),
          _FilterChip(
              label: "UV",
              isSelected: _categoryFilter == "UV",
              onTap: () => _setCategory("UV")),
          _FilterChip(
              label: "Crédit",
              isSelected: _categoryFilter == "CREDIT",
              onTap: () => _setCategory("CREDIT")),
        ],
      ),
    );
  }

  Widget _buildTypeChips() {
    final types = _typesForCategory(_categoryFilter);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _FilterChip(
            label: "Tous les types",
            isSelected: _typeFilter == null,
            onTap: () => setState(() => _typeFilter = null),
          ),
          ...types.map(
            (t) => _FilterChip(
              label: TransactionModel.typeDisplayName(t),
              isSelected: _typeFilter == t,
              onTap: () => setState(() => _typeFilter = t),
            ),
          ),
        ],
      ),
    );
  }

  List<TransactionType> _typesForCategory(String category) {
    if (category == 'UV') return _uvTypes;
    if (category == 'CREDIT') return _creditTypes;
    return [..._uvTypes, ..._creditTypes];
  }

  void _setCategory(String category) {
    setState(() {
      _categoryFilter = category;
      if (_typeFilter != null &&
          !_typesForCategory(category).contains(_typeFilter)) {
        _typeFilter = null;
      }
    });
  }

  String _categoryLabel() {
    if (_categoryFilter == 'CREDIT') return 'Crédit';
    return _categoryFilter;
  }

  String _periodLabel() {
    final df = DateFormat('dd/MM/yyyy');
    if (_filterFrom != null && _filterTo != null) {
      return 'Du ${df.format(_filterFrom!)} au ${df.format(_filterTo!)}';
    }
    if (_filterFrom != null) return 'À partir du ${df.format(_filterFrom!)}';
    if (_filterTo != null) return 'Jusqu’au ${df.format(_filterTo!)}';
    return 'Toutes les dates';
  }

  bool _inDateRange(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    if (_filterFrom != null) {
      final from =
          DateTime(_filterFrom!.year, _filterFrom!.month, _filterFrom!.day);
      if (day.isBefore(from)) return false;
    }
    if (_filterTo != null) {
      final to = DateTime(_filterTo!.year, _filterTo!.month, _filterTo!.day);
      if (day.isAfter(to)) return false;
    }
    return true;
  }

  bool _matchesFilters(TransactionModel tx) {
    final q = _searchController.text.trim();
    final qLower = q.toLowerCase();
    final qDigits = q.replaceAll(' ', '');
    final bySearch = q.isEmpty ||
        tx.clientName.toLowerCase().contains(qLower) ||
        tx.clientPhone.replaceAll(' ', '').contains(qDigits) ||
        (tx.merchantPhone ?? '').replaceAll(' ', '').contains(qDigits) ||
        (tx.journalSeq?.toString() ?? '').contains(q);
    final byCategory =
        _categoryFilter == 'Tout' || tx.category.name == _categoryFilter;
    final byType = _typeFilter == null || tx.type == _typeFilter;
    return bySearch && byCategory && byType && _inDateRange(tx.createdAt);
  }

  List<TransactionModel> _applyFilters(List<TransactionModel> transactions) {
    return transactions.where(_matchesFilters).toList();
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

  Widget _buildSummaryBar(List<TransactionModel> txs, bool isDark) {
    final count = txs.length;
    final totalAmount = txs.fold<double>(0, (s, t) => s + t.amount);
    final totalCommission = txs.fold<double>(0, (s, t) => s + t.commission);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: AppCard(
        variant: AppCardVariant.elevated,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _SummaryStat(label: 'Opérations', value: '$count', isDark: isDark),
            Container(
                height: 28,
                width: 1,
                color: isDark ? AppTokens.darkBorder : AppTokens.lightBorder),
            _SummaryStat(
                label: 'Volume',
                value: AppFormatters.formatMoneyShort(totalAmount.round()),
                isDark: isDark),
            Container(
                height: 28,
                width: 1,
                color: isDark ? AppTokens.darkBorder : AppTokens.lightBorder),
            _SummaryStat(
              label: 'Commissions',
              value:
                  '+${AppFormatters.formatMoneyShort(totalCommission.round())}',
              isHighlight: true,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPdfFromStream() => _exportPdf(_lastFiltered);

  Future<void> _exportPdf(List<TransactionModel> filtered) async {
    if (filtered.isEmpty) {
      if (!mounted) return;
      UserFeedback.showToast(context, 'Aucune transaction à exporter.',
          type: AppToastType.warning);
      return;
    }
    setState(() => _exportingPdf = true);
    try {
      final built = await PdfService().buildHistoryPdf(
        transactions: filtered,
        filters: HistoryReportFilters(
          periodLabel: _periodLabel(),
          categoryLabel: _categoryLabel(),
          typeLabel: _typeFilter == null
              ? 'Tous les types'
              : TransactionModel.typeDisplayName(_typeFilter!),
          searchQuery: _searchController.text,
          merchantPhone: OperationPhoneController.instance.selectedForFilter,
        ),
      );
      if (!mounted) return;
      await ExportShareService.sharePdfBytes(
        built.bytes,
        filename: built.filename,
      );
      if (!mounted) return;
      UserFeedback.showSuccessToast(context, 'PDF exporté avec succès !');
    } catch (e) {
      if (!mounted) return;
      await UserFeedback.showErrorModal(context, e);
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  Widget _buildTransactionList(
      List<TransactionModel> transactions, bool isDark) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color:
                    isDark ? AppTokens.darkBgSubtle : AppTokens.lightBgSubtle,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 40,
                color: isDark
                    ? AppTokens.darkTextTertiary
                    : AppTokens.lightTextTertiary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Aucune transaction trouvée",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: isDark
                    ? AppTokens.darkTextPrimary
                    : AppTokens.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Essayez de modifier vos filtres ou la période sélectionnée.",
              style: TextStyle(
                fontSize: 12.5,
                color: isDark
                    ? AppTokens.darkTextTertiary
                    : AppTokens.lightTextTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        return _TransactionHistoryItem(
          transaction: tx,
          onOpenDetail: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => TransactionDetailPage(
                    transaction: tx, businessName: _businessName),
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
            content: const Text(
                "Cette action va annuler son impact sur le solde. Continuer ?"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Annuler")),
              AppButton(
                label: "Supprimer",
                variant: AppButtonVariant.danger,
                size: AppButtonSize.sm,
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok) return;

    try {
      if (tx.id != null) {
        await _transactionController.deleteTransaction(tx.id!);
      }
      if (!mounted) return;
      UserFeedback.showSuccessToast(context, "Transaction supprimée.");
    } catch (e) {
      if (!mounted) return;
      await UserFeedback.showErrorModal(context, e);
    }
  }

  Future<void> _openEditDialog(TransactionModel tx) async {
    final amountCtrl =
        TextEditingController(text: tx.amount.toStringAsFixed(0));
    final phoneCtrl = TextEditingController(text: tx.clientPhone);
    var selectedCategory = tx.category;
    var selectedType = tx.type;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setModalState) {
          final types = selectedCategory == TransactionCategory.CREDIT
              ? _creditTypes
              : _uvTypes;
          final isProfitTransfer =
              selectedType == TransactionType.transfertProfitUv;

          return AlertDialog(
            title: const Text("Modifier la transaction",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<TransactionCategory>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(labelText: "Catégorie"),
                    items: const [
                      DropdownMenuItem(
                          value: TransactionCategory.UV, child: Text("UV")),
                      DropdownMenuItem(
                          value: TransactionCategory.CREDIT,
                          child: Text("Crédit")),
                    ],
                    onChanged: (cat) {
                      if (cat == null) return;
                      setModalState(() {
                        selectedCategory = cat;
                        selectedType = cat == TransactionCategory.CREDIT
                            ? _creditTypes.first
                            : _uvTypes.first;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TransactionType>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(labelText: "Type"),
                    items: types
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(TransactionModel.typeDisplayName(t)),
                          ),
                        )
                        .toList(),
                    onChanged: (t) {
                      if (t == null) return;
                      setModalState(() => selectedType = t);
                    },
                  ),
                  const SizedBox(height: 12),
                  if (!isProfitTransfer) ...[
                    TextField(
                      controller: phoneCtrl,
                      decoration:
                          const InputDecoration(labelText: "Téléphone client"),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: amountCtrl,
                    decoration:
                        const InputDecoration(labelText: "Montant (CFA)"),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogCtx, false),
                  child: const Text("Annuler")),
              AppButton(
                label: "Enregistrer",
                size: AppButtonSize.sm,
                onPressed: () => Navigator.pop(dialogCtx, true),
              ),
            ],
          );
        },
      ),
    );

    final rawAmountText = amountCtrl.text.trim().replaceAll(' ', '');
    final rawPhoneText = phoneCtrl.text.trim();
    amountCtrl.dispose();
    phoneCtrl.dispose();

    if (saved != true || !mounted) return;

    final amount = double.tryParse(rawAmountText) ?? 0;
    if (amount <= 0) {
      await UserFeedback.showErrorModal(
          context, Exception('Montant strictement positif requis.'));
      return;
    }
    if (selectedType != TransactionType.transfertProfitUv) {
      final digits = rawPhoneText.replaceAll(RegExp(r'\D'), '');
      if (rawPhoneText.isEmpty || digits.length < 8) {
        await UserFeedback.showErrorModal(context,
            Exception('Téléphone client invalide (au moins 8 chiffres).'));
        return;
      }
    }

    try {
      final updated = TransactionModel(
        id: tx.id,
        userId: tx.userId,
        type: selectedType,
        category: selectedCategory,
        clientName: selectedType == TransactionType.transfertProfitUv
            ? 'Transfert interne'
            : tx.clientName,
        clientPhone: selectedType == TransactionType.transfertProfitUv
            ? (tx.merchantPhone ?? tx.clientPhone)
            : rawPhoneText,
        merchantPhone: tx.merchantPhone,
        amount: amount,
        commission: TransactionModel.calculateCommission(selectedType, amount,
            rates: _commissionRates),
        soldeApres: tx.soldeApres,
        note: tx.note,
        createdAt: tx.createdAt,
      );
      await _transactionController.updateTransaction(updated);
      if (!mounted) return;
      UserFeedback.showSuccessToast(context, "Transaction modifiée.");
    } catch (e) {
      if (!mounted) return;
      await UserFeedback.showErrorModal(context, e);
    }
  }
}

class _DateReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool isDark;

  const _DateReadOnlyField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppTokens.darkBgSubtle : AppTokens.lightSurface,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(
            color: isDark ? AppTokens.darkBorder : AppTokens.lightBorder,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppTokens.darkTextTertiary
                        : AppTokens.lightTextTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: isDark
                        ? AppTokens.darkTextPrimary
                        : AppTokens.lightTextPrimary,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: isDark
                  ? AppTokens.darkTextTertiary
                  : AppTokens.lightTextTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;
  final bool isDark;

  const _SummaryStat({
    required this.label,
    required this.value,
    this.isHighlight = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppTokens.darkTextSecondary
                  : AppTokens.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
              color: isHighlight
                  ? (isDark ? AppTokens.secondary300 : AppTokens.secondary600)
                  : (isDark
                      ? AppTokens.darkTextPrimary
                      : AppTokens.lightTextPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        child: AnimatedContainer(
          duration: AppTokens.durationFast,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0x336366F1) : AppTokens.primary50)
                : (isDark ? AppTokens.darkBgSubtle : AppTokens.lightSurface),
            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
            border: Border.all(
              color: isSelected
                  ? (isDark ? AppTokens.primary400 : AppTokens.primary500)
                  : (isDark ? AppTokens.darkBorder : AppTokens.lightBorder),
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? (isDark ? AppTokens.primary300 : AppTokens.primary600)
                  : (isDark
                      ? AppTokens.darkTextSecondary
                      : AppTokens.lightTextSecondary),
            ),
          ),
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = transaction.type;
    final isDepot = t == TransactionType.depot;
    final isRetrait = t == TransactionType.retrait;

    late final Color iconBg;
    late final Color iconFg;
    late final IconData iconData;
    late final Color amountColor;

    if (isRetrait) {
      iconBg = const Color(0xFFE6F9EE);
      iconFg = const Color(0xFF22C55E);
      iconData = Icons.arrow_upward_rounded;
      amountColor = const Color(0xFF22C55E);
    } else if (isDepot) {
      iconBg = const Color(0xFFFEE2E2);
      iconFg = const Color(0xFFEF4444);
      iconData = Icons.arrow_downward_rounded;
      amountColor = const Color(0xFFEF4444);
    } else {
      iconBg = const Color(0xFFEEF2FF);
      iconFg = const Color(0xFF6366F1);
      iconData = Icons.sync_alt_rounded;
      amountColor = const Color(0xFF38BDF8);
    }

    final dateStr =
        DateFormat('dd/MM/yyyy HH:mm').format(transaction.createdAt);

    final txNumber =
        'N°${transaction.journalSeq ?? (transaction.id != null && transaction.id!.length >= 4 ? transaction.id!.substring(0, 4) : (transaction.createdAt.millisecondsSinceEpoch % 9000 + 1000))}';

    final lineInfo = (transaction.merchantPhone != null &&
            transaction.merchantPhone!.trim().isNotEmpty)
        ? 'Transfert ${transaction.merchantPhone!.trim()}'
        : 'Transfert ${transaction.category.name}';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141C2B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF232F45) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onOpenDetail,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Squircle Badge
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(iconData, color: iconFg, size: 28),
                  ),
                ),
                const SizedBox(width: 14),
                // Middle details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.clientName.trim().isNotEmpty
                            ? transaction.clientName.trim()
                            : "Client direct",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16.5,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        TransactionModel.typeDisplayName(transaction.type),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF818CF8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        transaction.clientPhone.trim().isNotEmpty
                            ? transaction.clientPhone.trim()
                            : "Non renseigné",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        txNumber,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lineInfo,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF818CF8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F2922)
                              : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF065F46)
                                : const Color(0xFFA7F3D0),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.payments_rounded,
                              size: 13,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "Espèce : ",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? const Color(0xFF6EE7B7)
                                    : const Color(0xFF047857),
                              ),
                            ),
                            Text(
                              "${AppFormatters.formatAmount(transaction.soldeEspeceAvant)} F",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 11,
                                color: isDark
                                    ? const Color(0xFF6EE7B7)
                                    : const Color(0xFF047857),
                              ),
                            ),
                            Text(
                              "${AppFormatters.formatAmount(transaction.soldeEspeceApres)} F",
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF065F46),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      GestureDetector(
                        onTap: onOpenDetail,
                        behavior: HitTestBehavior.opaque,
                        child: const Text(
                          "Détail & reçu",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF60A5FA),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Right details
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        Icons.more_vert_rounded,
                        size: 22,
                        color: isDark
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF64748B),
                      ),
                      onSelected: (v) {
                        if (v == 'edit') onEdit();
                        if (v == 'delete') onDelete();
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text("Modifier")),
                        PopupMenuItem(
                            value: 'delete', child: Text("Supprimer")),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${AppFormatters.formatAmount(transaction.amount)} F",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: amountColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Commission ${AppFormatters.formatAmount(transaction.commission)} F",
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      transaction.category.name,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    if (transaction.category == TransactionCategory.UV) ...[
                      const SizedBox(height: 3),
                      Text(
                        isRetrait
                            ? "Espèce -${AppFormatters.formatAmount(transaction.amount)} F"
                            : (isDepot ||
                                    t == TransactionType.nafama ||
                                    t == TransactionType.transfertC2c
                                ? "Espèce +${AppFormatters.formatAmount(transaction.amount)} F"
                                : (t == TransactionType.transfertUv
                                    ? "Espèce -${AppFormatters.formatAmount(transaction.amount)} F"
                                    : "")),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isRetrait || t == TransactionType.transfertUv
                              ? const Color(0xFFF87171)
                              : const Color(0xFF4ADE80),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF94A3B8),
                      size: 22,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
