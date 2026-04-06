import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/user_feedback.dart';
import '../../controllers/operation_phone_controller.dart';
import '../../controllers/settings_controller.dart';
class BusinessProfilePage extends StatefulWidget {
  const BusinessProfilePage({super.key});

  @override
  State<BusinessProfilePage> createState() => _BusinessProfilePageState();
}

class _BusinessProfilePageState extends State<BusinessProfilePage> {
  final _settingsController = SettingsController();
  final _businessController = TextEditingController();
  final _ownerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _opPhone1Controller = TextEditingController();
  final _opPhone2Controller = TextEditingController();
  final _opPhone3Controller = TextEditingController();
  final List<TextEditingController> _uvBalControllers = List.generate(3, (_) => TextEditingController());
  final List<TextEditingController> _crBalControllers = List.generate(3, (_) => TextEditingController());

  bool _isSaving = false;
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final profile = await _settingsController.getProfile();
      if (!mounted) return;
      if (profile != null) {
        _businessController.text = profile.businessName;
        _ownerController.text = profile.ownerName ?? '';
        _phoneController.text = profile.phoneNumber ?? '';
        final ops = profile.operationPhones;
        _opPhone1Controller.text = ops.isNotEmpty ? ops[0] : '';
        _opPhone2Controller.text = ops.length > 1 ? ops[1] : '';
        _opPhone3Controller.text = ops.length > 2 ? ops[2] : '';
        for (var i = 0; i < 3; i++) {
          _uvBalControllers[i].clear();
          _crBalControllers[i].clear();
        }
        for (var i = 0; i < ops.length && i < 3; i++) {
          final w = await _settingsController.getOperationPhoneWallet(ops[i]);
          _uvBalControllers[i].text = (w?.soldeUv ?? 0).toStringAsFixed(0);
          _crBalControllers[i].text = (w?.soldeCredit ?? 0).toStringAsFixed(0);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _loadError = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _businessController.dispose();
    _ownerController.dispose();
    _phoneController.dispose();
    _opPhone1Controller.dispose();
    _opPhone2Controller.dispose();
    _opPhone3Controller.dispose();
    for (final c in _uvBalControllers) {
      c.dispose();
    }
    for (final c in _crBalControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Commerce'),
        actions: [
          if (!_loading)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _load,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(child: Text(_loadError!, textAlign: TextAlign.center))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildField('Nom du Commerce', _businessController),
                      const SizedBox(height: 20),
                      _buildField('Propriétaire', _ownerController),
                      const SizedBox(height: 20),
                      _buildField('Téléphone', _phoneController),
                      const SizedBox(height: 24),
                      Text(
                        'Numéros d’opération (max. 3)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pour chaque numéro, indique le solde UV (float Orange Money) et le stock crédit '
                        'tel que tu constates sur la ligne. Les opérations mettront à jour ces soldes automatiquement.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withOpacity(0.95)),
                      ),
                      const SizedBox(height: 16),
                      _buildOperationSlot(0, 'Numéro d’opération 1', _opPhone1Controller),
                      const SizedBox(height: 20),
                      _buildOperationSlot(1, 'Numéro d’opération 2 (optionnel)', _opPhone2Controller),
                      const SizedBox(height: 20),
                      _buildOperationSlot(2, 'Numéro d’opération 3 (optionnel)', _opPhone3Controller),
                      const SizedBox(height: 48),
                      _buildSaveButton(context),
                    ],
                  ),
                ),
    );
  }

  Widget _buildOperationSlot(int index, String label, TextEditingController phoneCtrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            hintText: 'Ex. 77 …',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSmallAmountField('Solde UV (CFA)', _uvBalControllers[index]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSmallAmountField('Stock crédit (CFA)', _crBalControllers[index]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallAmountField(String label, TextEditingController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isSaving
            ? null
            : () async {
                setState(() => _isSaving = true);
                try {
                  final slots = [
                    _opPhone1Controller.text.trim(),
                    _opPhone2Controller.text.trim(),
                    _opPhone3Controller.text.trim(),
                  ];
                  final opPhones = slots.where((p) => p.isNotEmpty).take(3).toList();

                  await _settingsController.updateProfile(
                    businessName: _businessController.text.trim(),
                    ownerName: _ownerController.text.trim(),
                    phoneNumber: _phoneController.text.trim(),
                    operationPhones: opPhones,
                  );

                  for (var i = 0; i < 3; i++) {
                    final phone = slots[i];
                    if (phone.isEmpty) continue;
                    final uv = double.tryParse(_uvBalControllers[i].text.trim().replaceAll(' ', '')) ?? 0;
                    final cr = double.tryParse(_crBalControllers[i].text.trim().replaceAll(' ', '')) ?? 0;
                    if (uv < 0 || cr < 0) {
                      throw Exception('Les soldes du numéro $phone ne peuvent pas être négatifs.');
                    }
                    await _settingsController.setOperationPhoneBalances(
                      phone: phone,
                      soldeUv: uv,
                      soldeCredit: cr,
                    );
                  }

                  if (!context.mounted) return;
                  await OperationPhoneController.instance.syncFromProfile(opPhones);
                  if (!context.mounted) return;
                  await UserFeedback.showSuccessModal(context, 'Profil et soldes enregistrés.');
                  if (!context.mounted) return;
                  Navigator.pop(context);
                } catch (e) {
                  if (!context.mounted) return;
                  await UserFeedback.showErrorModal(context, e);
                } finally {
                  if (mounted) setState(() => _isSaving = false);
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Enregistrer les modifications',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
