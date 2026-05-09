import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controllers/settings_controller.dart';
import '../../core/theme.dart';
import '../../core/user_feedback.dart';
import '../../models/commission_rates_model.dart';

class CommissionRatesPage extends StatefulWidget {
  const CommissionRatesPage({super.key});

  @override
  State<CommissionRatesPage> createState() => _CommissionRatesPageState();
}

class _CommissionRatesPageState extends State<CommissionRatesPage> {
  final _formKey = GlobalKey<FormState>();
  final _settingsController = SettingsController();
  final _depotCtrl = TextEditingController();
  final _retraitCtrl = TextEditingController();
  final _nafamaCtrl = TextEditingController();
  final _forfaitCtrl = TextEditingController();
  final _sewaCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s = await _settingsController.getBusinessSettings();
      if (!mounted) return;
      _applyRatesToFields(s.commissionRates);
    } catch (e) {
      if (mounted) {
        await UserFeedback.showErrorModal(context, e);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyRatesToFields(CommissionRates r) {
    _depotCtrl.text = _multiplierToPercentString(r.depot);
    _retraitCtrl.text = _multiplierToPercentString(r.retrait);
    _nafamaCtrl.text = _multiplierToPercentString(r.nafama);
    _forfaitCtrl.text = _multiplierToPercentString(r.forfait);
    _sewaCtrl.text = _multiplierToPercentString(r.sewa);
  }

  /// Affiche le pourcentage équivalent (multiplicateur × 100).
  static String _multiplierToPercentString(double m) {
    final p = m * 100;
    if ((p - p.round()).abs() < 1e-6) return p.round().toString();
    final s = p.toStringAsFixed(6);
    return s.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  static double? _parsePercentInput(String raw) {
    final t = raw.trim().replaceAll(',', '.').replaceAll(' ', '');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  CommissionRates? _ratesFromForm() {
    final d = _parsePercentInput(_depotCtrl.text);
    final r = _parsePercentInput(_retraitCtrl.text);
    final n = _parsePercentInput(_nafamaCtrl.text);
    final f = _parsePercentInput(_forfaitCtrl.text);
    final s = _parsePercentInput(_sewaCtrl.text);
    if (d == null || r == null || n == null || f == null || s == null) return null;
    if (d < 0 || r < 0 || n < 0 || f < 0 || s < 0) return null;
    if (d > 100 || r > 100 || n > 100 || f > 100 || s > 100) return null;
    return CommissionRates.fromPercentages(
      depotPct: d,
      retraitPct: r,
      nafamaPct: n,
      forfaitPct: f,
      sewaPct: s,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final rates = _ratesFromForm();
    if (rates == null) {
      await UserFeedback.showErrorModal(
        context,
        Exception('Vérifie les taux : nombres entre 0 et 100 % (virgule ou point décimal).'),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _settingsController.updateCommissionRates(rates);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Taux enregistrés. Ils s’appliquent aux nouvelles transactions.')),
      );
    } catch (e) {
      if (!mounted) return;
      await UserFeedback.showErrorModal(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _resetDefaults() {
    _applyRatesToFields(CommissionRates.defaults);
    setState(() {});
  }

  @override
  void dispose() {
    _depotCtrl.dispose();
    _retraitCtrl.dispose();
    _nafamaCtrl.dispose();
    _forfaitCtrl.dispose();
    _sewaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Taux de commission', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Saisis les pourcentages appliqués au montant de chaque opération. '
                      'Ex. dépôt historique : 0,14 signifie 0,14 %.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    _pctField(
                      label: 'Dépôt (UV)',
                      controller: _depotCtrl,
                    ),
                    const SizedBox(height: 16),
                    _pctField(
                      label: 'Retrait (UV)',
                      controller: _retraitCtrl,
                    ),
                    const SizedBox(height: 16),
                    _pctField(
                      label: 'Nafama (UV)',
                      controller: _nafamaCtrl,
                    ),
                    const SizedBox(height: 16),
                    _pctField(
                      label: 'Forfait (crédit)',
                      controller: _forfaitCtrl,
                    ),
                    const SizedBox(height: 16),
                    _pctField(
                      label: 'Sewa (crédit)',
                      controller: _sewaCtrl,
                    ),
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Enregistrer'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _saving ? null : _resetDefaults,
                      child: const Text('Réinitialiser les valeurs par défaut'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _pctField({
    required String label,
    required TextEditingController controller,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: '$label (%)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      validator: (v) {
        final p = _parsePercentInput(v ?? '');
        if (p == null) return 'Nombre requis';
        if (p < 0 || p > 100) return 'Entre 0 et 100';
        return null;
      },
    );
  }
}
