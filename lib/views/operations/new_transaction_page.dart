import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/user_feedback.dart';
import '../../controllers/operation_phone_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/transaction_controller.dart';
import '../../models/commission_rates_model.dart';
import '../../models/new_transaction_route_args.dart';
import '../../models/transaction_model.dart';
import '../../services/export_share_service.dart';
import '../../services/pdf_service.dart';
import 'receipt_page.dart';

class NewTransactionPage extends StatefulWidget {
  final NewTransactionRouteArgs? routeArgs;

  const NewTransactionPage({super.key, this.routeArgs});

  @override
  State<NewTransactionPage> createState() => _NewTransactionPageState();
}

class _NewTransactionPageState extends State<NewTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _clientPhoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _transactionController = TransactionController();
  String? _selectedCategory;
  TransactionType? _selectedType;
  double _estimatedCommission = 0;
  CommissionRates _commissionRates = CommissionRates.defaults;
  bool _isSubmitting = false;
  TransactionModel? _createdTransaction;
  String _businessName = "Mon Commerce";
  List<String> _operationPhones = [];
  String? _selectedMerchantPhone;
  List<String> _recentPhones = [];

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
  static const _quickAmounts = [1000, 2000, 3000, 4000, 5000, 10000];

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_updateCommission);
    _loadOperationPhones();
    _loadRecentPhones();
    SettingsController().getBusinessSettings().then((s) {
      if (!mounted) return;
      setState(() => _commissionRates = s.commissionRates);
      _updateCommission();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final a = widget.routeArgs;
      if (a?.initialType == null || !mounted) return;
      setState(() {
        _selectedCategory = 'UV';
        _selectedType = a!.initialType!;
        final hint = a.suggestedProfitUvAmount;
        if (hint != null && hint > 0) {
          _amountController.text = hint.floor().toString();
        }
      });
      _updateCommission();
    });
  }

  bool get _isProfitTransfer => _selectedType == TransactionType.transfertProfitUv;

  bool get _canShowTypes => _selectedCategory != null;

  bool get _canShowAgent => _selectedCategory != null && _selectedType != null;

  bool get _canShowForm =>
      _canShowAgent && (_operationPhones.isEmpty || (_selectedMerchantPhone?.trim().isNotEmpty ?? false));

  List<TransactionType> get _typesForSelectedCategory =>
      _selectedCategory == 'CREDIT' ? _creditTypes : _uvTypes;

  bool _isValidPhoneDigits(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 8;
  }

  Future<void> _loadOperationPhones() async {
    final p = await _transactionController.getProfileData();
    if (!mounted) return;
    final phones = p?.operationPhones ?? [];
    final sel = OperationPhoneController.instance.selectedForFilter;
    setState(() {
      _operationPhones = phones;
      if (phones.isEmpty) {
        _selectedMerchantPhone = null;
      } else if (sel != null && phones.contains(sel)) {
        _selectedMerchantPhone = sel;
      } else {
        _selectedMerchantPhone = phones.first;
      }
    });
  }

  Future<void> _loadRecentPhones() async {
    final phones = await _transactionController.getRecentClientPhones();
    if (!mounted) return;
    setState(() => _recentPhones = phones);
  }

  @override
  void dispose() {
    _amountController.removeListener(_updateCommission);
    _clientPhoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitTransaction() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      UserFeedback.showErrorModal(context, Exception("Session expirée. Reconnecte-toi."));
      return;
    }
    final category = _selectedCategory;
    final type = _selectedType;
    if (category == null || type == null) {
      UserFeedback.showErrorModal(context, Exception("Choisis d’abord le type d’opération."));
      return;
    }

    final amount = double.tryParse(_amountController.text.trim().replaceAll(' ', '')) ?? 0;
    if (amount <= 0) {
      UserFeedback.showErrorModal(context, Exception('Indique un montant strictement positif.'));
      return;
    }
    if (!_isProfitTransfer) {
      if (_clientPhoneController.text.trim().isEmpty || !_isValidPhoneDigits(_clientPhoneController.text)) {
        UserFeedback.showErrorModal(
          context,
          Exception('Numéro client invalide (au moins 8 chiffres).'),
        );
        return;
      }
    }
    if (_operationPhones.isNotEmpty &&
        (_selectedMerchantPhone == null || _selectedMerchantPhone!.trim().isEmpty)) {
      UserFeedback.showErrorModal(
        context,
        Exception("Choisis le numéro de transfert utilisé pour cette transaction."),
      );
      return;
    }

    final clientPhone = _isProfitTransfer
        ? (_selectedMerchantPhone?.trim().isNotEmpty == true ? _selectedMerchantPhone!.trim() : 'Profit UV')
        : _clientPhoneController.text.trim();

    final transaction = TransactionModel(
      userId: userId,
      type: type,
      category: category == 'UV' ? TransactionCategory.UV : TransactionCategory.CREDIT,
      clientName: _isProfitTransfer ? 'Transfert interne' : 'Client',
      clientPhone: clientPhone,
      merchantPhone: _selectedMerchantPhone?.trim().isNotEmpty == true
          ? _selectedMerchantPhone!.trim()
          : null,
      amount: amount,
      commission: 0,
      soldeApres: 0,
      note: null,
      createdAt: DateTime.now(),
    );

    setState(() => _isSubmitting = true);
    try {
      final insertedTransaction = await _transactionController.addTransaction(transaction);
      final profile = await _transactionController.getProfileData();
      _createdTransaction = insertedTransaction;
      _businessName = profile?.businessName ?? "Mon Commerce";
      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      await UserFeedback.showErrorModal(context, e);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _updateCommission() {
    final amount = double.tryParse(_amountController.text.trim().replaceAll(' ', '')) ?? 0;
    final type = _selectedType;
    setState(() {
      _estimatedCommission = type == null
          ? 0
          : TransactionModel.calculateCommission(type, amount, rates: _commissionRates);
    });
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      if (_selectedType != null && !_typesForSelectedCategory.contains(_selectedType)) {
        _selectedType = null;
      }
    });
    _updateCommission();
  }

  void _selectType(TransactionType type) {
    setState(() => _selectedType = type);
    _updateCommission();
  }

  void _selectQuickAmount(int amount) {
    _amountController.text = amount.toString();
    _updateCommission();
  }

  int? get _enteredAmount {
    return int.tryParse(_amountController.text.trim().replaceAll(' ', ''));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nouvelle Opération", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle("Type d’opération"),
              const SizedBox(height: 12),
              _buildCategorySelector(),
              if (_canShowTypes) ...[
                const SizedBox(height: 24),
                _buildTypeSelector(),
              ],
              if (_canShowAgent) ...[
                const SizedBox(height: 28),
                _sectionTitle("Compte agent"),
                const SizedBox(height: 12),
                if (_operationPhones.isNotEmpty)
                  _buildMerchantPhoneSelector()
                else
                  Text(
                    "Enregistre au moins un numéro de transfert et ses soldes dans Profil commerce : "
                    "il est obligatoire pour chaque transaction.",
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withOpacity(0.95)),
                  ),
              ],
              if (_canShowForm) ...[
                const SizedBox(height: 28),
                _sectionTitle("Informations de l’opération"),
                const SizedBox(height: 12),
                if (!_isProfitTransfer) ...[
                  _buildClientPhoneField(),
                  const SizedBox(height: 20),
                ],
                _buildInputField(
                  label: "Montant (CFA)",
                  hint: "0",
                  icon: Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                  isAmount: true,
                  controller: _amountController,
                ),
                const SizedBox(height: 16),
                _buildQuickAmounts(),
                const SizedBox(height: 24),
                if (_isProfitTransfer) _buildProfitTransferHint() else _buildCommissionPreview(),
                const SizedBox(height: 36),
                _buildSubmitButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16));
  }

  Widget _buildCategorySelector() {
    return Row(
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: _SquareTile(
              label: "Mobile Money (UV)",
              icon: Icons.account_balance_wallet_rounded,
              isSelected: _selectedCategory == 'UV',
              onTap: () => _selectCategory('UV'),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: _SquareTile(
              label: "Crédit",
              icon: Icons.sim_card_rounded,
              isSelected: _selectedCategory == 'CREDIT',
              onTap: () => _selectCategory('CREDIT'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return _squareGrid(
      itemCount: _typesForSelectedCategory.length,
      crossAxisCount: 3,
      itemBuilder: (index) {
        final type = _typesForSelectedCategory[index];
        return _SquareTile(
          label: TransactionModel.typeDisplayName(type),
          icon: _iconForType(type),
          isSelected: _selectedType == type,
          onTap: () => _selectType(type),
        );
      },
    );
  }

  Widget _buildMerchantPhoneSelector() {
    return _squareGrid(
      itemCount: _operationPhones.length,
      crossAxisCount: _operationPhones.length == 1 ? 2 : 3,
      itemBuilder: (index) {
        final phone = _operationPhones[index];
        return _SquareTile(
          label: phone,
          icon: Icons.sim_card_outlined,
          isSelected: _selectedMerchantPhone == phone,
          onTap: () => setState(() => _selectedMerchantPhone = phone),
        );
      },
    );
  }

  Widget _buildQuickAmounts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Montants rapides", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        _squareGrid(
          itemCount: _quickAmounts.length,
          crossAxisCount: 3,
          itemBuilder: (index) {
            final amount = _quickAmounts[index];
            return _SquareTile(
              label: "${_formatQuick(amount)} FCFA",
              icon: Icons.payments_outlined,
              isSelected: _enteredAmount == amount,
              onTap: () => _selectQuickAmount(amount),
            );
          },
        ),
      ],
    );
  }

  String _formatQuick(int amount) {
    if (amount >= 1000) {
      final thousands = amount ~/ 1000;
      return '$thousands 000';
    }
    return '$amount';
  }

  Widget _squareGrid({
    required int itemCount,
    required int crossAxisCount,
    required Widget Function(int index) itemBuilder,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) => itemBuilder(index),
    );
  }

  IconData _iconForType(TransactionType type) {
    switch (type) {
      case TransactionType.depot:
        return Icons.arrow_downward_rounded;
      case TransactionType.retrait:
        return Icons.arrow_upward_rounded;
      case TransactionType.nafama:
        return Icons.savings_outlined;
      case TransactionType.transfertUv:
        return Icons.swap_horiz_rounded;
      case TransactionType.transfertC2c:
        return Icons.people_alt_outlined;
      case TransactionType.transfertProfitUv:
        return Icons.trending_up_rounded;
      case TransactionType.achat:
        return Icons.add_card_rounded;
      case TransactionType.forfait:
        return Icons.wifi_rounded;
      case TransactionType.sewa:
        return Icons.phonelink_ring_rounded;
      case TransactionType.transfertCredit:
        return Icons.mobile_screen_share_rounded;
    }
  }

  Widget _buildProfitTransferHint() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.teal.withOpacity(0.25)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transfert profit UV',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          SizedBox(height: 8),
          Text(
            'Le montant est ajouté à ton solde UV sur le numéro de transfert choisi et déduit de ton bénéfice UV. '
            'Aucune commission sur cette opération.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionPreview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Commission estimée", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text("Calculée automatiquement", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          Text(
            "+ ${_estimatedCommission.toStringAsFixed(0)} F",
            style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildClientPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Numéro client', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Autocomplete<String>(
          optionsBuilder: (textEditingValue) {
            final q = textEditingValue.text.trim();
            if (q.isEmpty) return const Iterable<String>.empty();
            final qNorm = q.replaceAll(' ', '');
            return _recentPhones.where((p) => p.replaceAll(' ', '').contains(qNorm)).take(5);
          },
          onSelected: (v) => _clientPhoneController.text = v,
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            if (controller.text != _clientPhoneController.text) {
              controller.text = _clientPhoneController.text;
            }
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.phone,
              onChanged: (v) => _clientPhoneController.text = v,
              decoration: InputDecoration(
                hintText: '77 000 00 00',
                prefixIcon: Icon(Icons.phone_android_rounded, color: AppColors.primary),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(20),
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(16),
                color: Theme.of(context).colorScheme.surface,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        dense: true,
                        leading: Icon(Icons.history_rounded, color: AppColors.textSecondary),
                        title: Text(option),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool isAmount = false,
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: isAmount ? 24 : 16,
            fontWeight: isAmount ? FontWeight.bold : FontWeight.normal,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primary),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(20),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitTransaction,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "Valider l'Opération",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.secondary, size: 80),
            const SizedBox(height: 24),
            const Text("Opération Réussie !", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_createdTransaction?.type == TransactionType.transfertProfitUv)
              Text(
                'Montant versé sur le solde UV : ${(_createdTransaction?.amount ?? 0).toStringAsFixed(0)} F',
                style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              )
            else
              Text(
                "Commission générée : + ${_estimatedCommission.toStringAsFixed(0)} F",
                style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 12),
            const Text("La transaction a été enregistrée avec succès.", textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            _buildDialogButton(
              "Voir / Imprimer le Reçu",
              AppColors.primary,
              true,
              () async {
                final tx = _createdTransaction;
                if (tx == null) return;
                await PdfService().generateReceipt(tx, _businessName);
                if (!context.mounted) return;
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReceiptPage(transaction: tx, businessName: _businessName),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildDialogButton(
              "Partager le PDF",
              Colors.blue.shade50,
              false,
              () async {
                final tx = _createdTransaction;
                if (tx == null) return;
                final file = await PdfService().generateReceipt(tx, _businessName);
                await ExportShareService.sharePdf(file);
              },
            ),
            const SizedBox(height: 12),
            _buildDialogButton(
              "Terminer",
              Colors.grey.shade200,
              false,
              () => Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogButton(String label, Color color, bool isPrimary, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: TextStyle(color: isPrimary ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _SquareTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SquareTile({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: isSelected ? AppColors.primary : scheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? AppColors.primary : scheme.outlineVariant.withOpacity(0.6),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isSelected ? 0.08 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: isSelected ? Colors.white : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
