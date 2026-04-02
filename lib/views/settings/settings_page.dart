import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/theme_mode_controller.dart';
import '../../models/business_settings_model.dart';
import '../../models/profile_model.dart';
import '../../widgets/profile_avatar.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _settingsController = SettingsController();
  final _authController = AuthController();
  late Future<ProfileModel?> _profileFuture;
  late Future<BusinessSettingsModel> _settingsFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _settingsController.getProfile();
    _settingsFuture = _settingsController.getBusinessSettings();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeModeController.instance,
      builder: (context, _) {
        return FutureBuilder<ProfileModel?>(
          future: _profileFuture,
          builder: (context, profileSnapshot) {
            return FutureBuilder<BusinessSettingsModel>(
              future: _settingsFuture,
              builder: (context, settingsSnapshot) {
                final profile = profileSnapshot.data;
                final settings = settingsSnapshot.data ?? BusinessSettingsModel.empty;
                return Scaffold(
              appBar: AppBar(
                title: const Text("Paramètres", style: TextStyle(fontWeight: FontWeight.bold)),
                centerTitle: true,
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildProfileSection(profile),
                    const SizedBox(height: 32),
                    _buildSettingsSection(
                      context,
                      "Commerce",
                      [
                        _SettingsTile(
                          icon: Icons.storefront_rounded,
                          title: "Profil du commerce",
                          value: profile?.businessName ?? "-",
                          onTap: () => Navigator.pushNamed(context, '/settings-business'),
                        ),
                        _SettingsTile(
                          icon: Icons.phone_android_rounded,
                          title: "Téléphone",
                          value: profile?.phoneNumber ?? "-",
                          onTap: () => Navigator.pushNamed(context, '/settings-business'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSettingsSection(
                      context,
                      "Imprimante & Bluetooth",
                      [
                        _SettingsTile(
                          icon: Icons.print_rounded,
                          title: "Format & Appareil",
                          value: settings.autoPrintReceipt ? "Impression auto activée" : "Impression auto désactivée",
                          onTap: () => Navigator.pushNamed(context, '/settings-printer'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSettingsSection(
                      context,
                      "Préférences",
                      [
                        _SettingsTile(
                          icon: Icons.language_rounded,
                          title: "Langue",
                          value: settings.language == 'fr' ? "Français" : settings.language.toUpperCase(),
                          onTap: () {},
                        ),
                        SwitchListTile(
                          secondary: Icon(Icons.dark_mode_rounded, color: AppColors.primary),
                          title: const Text("Mode sombre", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          value: ThemeModeController.instance.isDark,
                          onChanged: (v) async {
                            await ThemeModeController.instance.setDarkMode(v);
                            try {
                              await _settingsController.updateBusinessSettings(
                                darkMode: v,
                                language: settings.language,
                                autoPrintReceipt: settings.autoPrintReceipt,
                              );
                            } catch (_) {
                              await ThemeModeController.instance.setDarkMode(!v);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Impossible de sauvegarder le thème sur le serveur.")),
                                );
                              }
                            }
                          },
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    _buildLogoutButton(context),
                  ],
                ),
              ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildProfileSection(ProfileModel? profile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          ProfileAvatar(profile: profile, radius: 35, lightStyle: true),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.ownerName ?? profile?.businessName ?? "Utilisateur",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Propriétaire", 
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10)],
          ),
          child: Column(children: tiles),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () async {
        await _authController.signOut();
        if (!context.mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
      },
      icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
      label: const Text("Déconnexion", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _SettingsTile({required this.icon, required this.title, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
          ),
          Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}
