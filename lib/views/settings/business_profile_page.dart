import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/user_feedback.dart';
import '../../controllers/operation_phone_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../models/profile_model.dart';

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
  bool _isSaving = false;
  bool _loaded = false;

  @override
  void dispose() {
    _businessController.dispose();
    _ownerController.dispose();
    _phoneController.dispose();
    _opPhone1Controller.dispose();
    _opPhone2Controller.dispose();
    _opPhone3Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProfileModel?>(
      future: _settingsController.getProfile(),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        if (!_loaded && profile != null) {
          _businessController.text = profile.businessName;
          _ownerController.text = profile.ownerName ?? "";
          _phoneController.text = profile.phoneNumber ?? "";
          final ops = profile.operationPhones;
          _opPhone1Controller.text = ops.isNotEmpty ? ops[0] : "";
          _opPhone2Controller.text = ops.length > 1 ? ops[1] : "";
          _opPhone3Controller.text = ops.length > 2 ? ops[2] : "";
          _loaded = true;
        }

        return Scaffold(
          appBar: AppBar(title: const Text("Profil Commerce")),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildField("Nom du Commerce", _businessController),
                const SizedBox(height: 20),
                _buildField("Propriétaire", _ownerController),
                const SizedBox(height: 20),
                _buildField("Téléphone", _phoneController),
                const SizedBox(height: 24),
                Text(
                  "Numéros d'opération (max. 3)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  "Ces numéros servent à filtrer l'historique et les statistiques, et à les associer à chaque opération.",
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withOpacity(0.9)),
                ),
                const SizedBox(height: 12),
                _buildField("Numéro d'opération 1", _opPhone1Controller),
                const SizedBox(height: 16),
                _buildField("Numéro d'opération 2 (optionnel)", _opPhone2Controller),
                const SizedBox(height: 16),
                _buildField("Numéro d'opération 3 (optionnel)", _opPhone3Controller),
                const SizedBox(height: 48),
                _buildSaveButton(context),
              ],
            ),
          ),
        );
      },
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
                  final opPhones = [
                    _opPhone1Controller.text.trim(),
                    _opPhone2Controller.text.trim(),
                    _opPhone3Controller.text.trim(),
                  ].where((p) => p.isNotEmpty).take(3).toList();
                  await _settingsController.updateProfile(
                    businessName: _businessController.text.trim(),
                    ownerName: _ownerController.text.trim(),
                    phoneNumber: _phoneController.text.trim(),
                    operationPhones: opPhones,
                  );
                  if (!context.mounted) return;
                  await OperationPhoneController.instance.syncFromProfile(opPhones);
                  if (!context.mounted) return;
                  await UserFeedback.showSuccessModal(context, "Profil mis à jour avec succès.");
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
            : const Text("Enregistrer les modifications", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
