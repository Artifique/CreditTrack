import 'package:flutter/material.dart';
import '../../core/theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Paramètres", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfileSection(),
            const SizedBox(height: 32),
            _buildSettingsSection(
              "Commerce",
              [
                _SettingsTile(
                  icon: Icons.storefront_rounded, 
                  title: "Profil du commerce", 
                  value: "Toure Registre",
                  onTap: () => Navigator.pushNamed(context, '/settings-business'),
                ),
                _SettingsTile(
                  icon: Icons.phone_android_rounded, 
                  title: "Téléphone", 
                  value: "+221 77 123 45 67",
                  onTap: () => Navigator.pushNamed(context, '/settings-business'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSettingsSection(
              "Imprimante & Bluetooth",
              [
                _SettingsTile(
                  icon: Icons.print_rounded, 
                  title: "Format & Appareil", 
                  value: "MPT-II (58mm)",
                  onTap: () => Navigator.pushNamed(context, '/settings-printer'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSettingsSection(
              "Préférences",
              [
                _SettingsTile(icon: Icons.language_rounded, title: "Langue", value: "Français", onTap: () {}),
                _SettingsTile(icon: Icons.dark_mode_rounded, title: "Mode Sombre", value: "Désactivé", onTap: () {}),
              ],
            ),
            const SizedBox(height: 40),
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 35,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Aly Toure",
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

  Widget _buildSettingsSection(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
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
      onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
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
          Text(value, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}
