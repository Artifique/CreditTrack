import 'package:flutter/material.dart';
import '../../core/theme.dart';
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
  bool _isSaving = false;
  bool _loaded = false;

  @override
  void dispose() {
    _businessController.dispose();
    _ownerController.dispose();
    _phoneController.dispose();
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
                  await _settingsController.updateProfile(
                    businessName: _businessController.text.trim(),
                    ownerName: _ownerController.text.trim(),
                    phoneNumber: _phoneController.text.trim(),
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                  );
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
