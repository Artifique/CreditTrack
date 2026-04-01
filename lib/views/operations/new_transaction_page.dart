import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/user_feedback.dart';
import '../../controllers/transaction_controller.dart';
import '../../models/transaction_model.dart';
import '../../services/pdf_service.dart';
import 'receipt_page.dart';

class NewTransactionPage extends StatefulWidget {
  const NewTransactionPage({super.key});

  @override
  State<NewTransactionPage> createState() => _NewTransactionPageState();
}

class _NewTransactionPageState extends State<NewTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _clientPhoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _transactionController = TransactionController();
  String _selectedCategory = 'UV';
  TransactionType _selectedType = TransactionType.depot;
  double _estimatedCommission = 0;
  bool _isSubmitting = false;
  TransactionModel? _createdTransaction;
  String _businessName = "Mon Commerce";

  @override
  void initState() {
    super.initState() ;
    _amountController.addListener(_updateCommission);
  }

  @override
  void dispose() {
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

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (_clientPhoneController.text.trim().isEmpty || amount <= 0) {
      UserFeedback.showErrorModal(context, Exception("Complète les champs requis."));
      return;
    }

    final transaction = TransactionModel(
      userId: userId,
      type: _selectedType,
      category: _selectedCategory == 'UV' ? TransactionCategory.UV : TransactionCategory.CREDIT,
      clientName: "Client",
      clientPhone: _clientPhoneController.text.trim(),
      amount: amount,
      commission: _estimatedCommission,
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
    final amount = double.tryParse(_amountController.text) ?? 0;
    setState(() {
      _estimatedCommission = TransactionModel.calculateCommission(_selectedType, amount);
    });
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
              _buildCategorySelector(),
              const SizedBox(height: 32),
              _buildTypeSelector(),
              const SizedBox(height: 32),
              _buildInputField(
                label: "Numéro de Téléphone",
                hint: "77 000 00 00",
                icon: Icons.phone_android_rounded,
                keyboardType: TextInputType.phone,
                controller: _clientPhoneController,
              ),
              const SizedBox(height: 20),
              _buildInputField(
                label: "Montant (CFA)",
                hint: "0",
                icon: Icons.payments_outlined,
                keyboardType: TextInputType.number,
                isAmount: true,
                controller: _amountController,
              ),
              const SizedBox(height: 24),
              _buildCommissionPreview(), // NOUVEAU v1.1
              const SizedBox(height: 48),
              _buildSubmitButton(),
            ],
          ),
        ),
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

  Widget _buildCategorySelector() {
    return Row(
      children: [
        _CategoryChip(
          label: "Mobile Money (UV)",
          isSelected: _selectedCategory == 'UV',
          onTap: () => setState(() {
            _selectedCategory = 'UV';
            _selectedType = TransactionType.depot;
            _updateCommission();
          }),
        ),
        const SizedBox(width: 12),
        _CategoryChip(
          label: "Crédit",
          isSelected: _selectedCategory == 'CREDIT',
          onTap: () => setState(() {
            _selectedCategory = 'CREDIT';
            _selectedType = TransactionType.achat;
            _updateCommission();
          }),
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    final types = _selectedCategory == 'UV' 
        ? [TransactionType.depot, TransactionType.retrait, TransactionType.nafama] 
        : [TransactionType.achat, TransactionType.forfait, TransactionType.sewa];

    return Wrap(
      spacing: 12,
      children: types.map((type) => ChoiceChip(
        label: Text(type.name.toUpperCase()),
        selected: _selectedType == type,
        onSelected: (val) => setState(() {
          _selectedType = type;
          _updateCommission();
        }),
        selectedColor: AppColors.primary.withOpacity(0.2),
        labelStyle: TextStyle(
          color: _selectedType == type ? AppColors.primary : AppColors.textSecondary,
          fontWeight: FontWeight.bold,
        ),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      )).toList(),
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
            fillColor: Colors.white,
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
            Text(
              "Commission générée : ${_estimatedCommission.toStringAsFixed(0)} F",
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

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: isSelected ? null : Border.all(color: Colors.grey.shade300),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
