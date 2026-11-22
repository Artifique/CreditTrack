import 'package:flutter/material.dart';
import '../controllers/sim_card_controller.dart';
import '../core/tokens.dart';
import '../core/user_feedback.dart';
import '../models/sim_card_model.dart';
import 'ui/app_button.dart';
import 'ui/app_input.dart';

/// Modal unique et réutilisable pour ajouter ou modifier un compte SIM
/// avec libération garantie des contrôleurs dans [dispose].
class SimCardEditorSheet extends StatefulWidget {
  final SimCardModel? existingSim;
  final bool isDark;
  final VoidCallback onSaved;

  const SimCardEditorSheet({
    super.key,
    this.existingSim,
    required this.isDark,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    SimCardModel? existingSim,
    required bool isDark,
    required VoidCallback onSaved,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTokens.darkSurface : AppTokens.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTokens.radius2Xl)),
      ),
      builder: (_) => SimCardEditorSheet(
        existingSim: existingSim,
        isDark: isDark,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<SimCardEditorSheet> createState() => _SimCardEditorSheetState();
}

class _SimCardEditorSheetState extends State<SimCardEditorSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _uvCtrl;
  late final TextEditingController _crCtrl;
  bool _isSaving = false;

  bool get _isEditing => widget.existingSim != null;

  @override
  void initState() {
    super.initState();
    final sim = widget.existingSim;
    _nameCtrl = TextEditingController(text: sim?.name ?? '');
    _phoneCtrl = TextEditingController(text: sim?.phone ?? '');
    _uvCtrl = TextEditingController(
      text: sim != null ? sim.soldeUv.toStringAsFixed(0) : '0',
    );
    _crCtrl = TextEditingController(
      text: sim != null ? sim.soldeCredit.toStringAsFixed(0) : '0',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _uvCtrl.dispose();
    _crCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final phone = _phoneCtrl.text.trim().replaceAll(' ', '');
    final name = _nameCtrl.text.trim();

    if (phone.isEmpty) {
      UserFeedback.showErrorToast(
          context, 'Veuillez saisir un numéro de téléphone.');
      return;
    }
    if (phone.length < 8) {
      UserFeedback.showErrorToast(
          context, 'Numéro invalide (au moins 8 chiffres).');
      return;
    }

    final uv = double.tryParse(_uvCtrl.text.trim().replaceAll(' ', '')) ?? 0.0;
    final cr = double.tryParse(_crCtrl.text.trim().replaceAll(' ', '')) ?? 0.0;

    setState(() => _isSaving = true);

    try {
      if (_isEditing) {
        await SimCardController.instance.updateSimCard(
          phone: widget.existingSim!.phone,
          newName: name,
          soldeUv: uv,
          soldeCredit: cr,
        );
      } else {
        await SimCardController.instance.addSimCard(
          phone: phone,
          name: name,
          initialUv: uv,
          initialCredit: cr,
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();
      UserFeedback.showSuccessToast(
        context,
        _isEditing
            ? 'Compte SIM mis à jour !'
            : 'Compte SIM ajouté avec succès !',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      UserFeedback.showErrorToast(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEditing
                      ? 'Modifier le Compte SIM'
                      : '+ Ajouter un Compte SIM',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppTokens.darkTextPrimary
                        : AppTokens.lightTextPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppInput(
              controller: _nameCtrl,
              label: 'Nom personnalisé de la SIM',
              hintText: 'ex: Orange Money 01 ou Moov Caisse',
              prefixIcon: Icons.badge_outlined,
            ),
            const SizedBox(height: 12),
            AppInput(
              controller: _phoneCtrl,
              label: 'Numéro de la SIM / Agent',
              hintText: 'ex: 77 123 45 67',
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_android_rounded,
              enabled: !_isEditing,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppInput(
                    controller: _uvCtrl,
                    label: _isEditing ? 'Solde UV (FCFA)' : 'Solde UV Initial',
                    hintText: '0',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.account_balance_wallet_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppInput(
                    controller: _crCtrl,
                    label: _isEditing
                        ? 'Solde Crédit (FCFA)'
                        : 'Solde Crédit Initial',
                    hintText: '0',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.phone_android_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: _isEditing ? 'METTRE À JOUR' : 'ENREGISTRER LA SIM',
                icon: Icons.check_circle_rounded,
                isFullWidth: true,
                size: AppButtonSize.lg,
                isLoading: _isSaving,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
