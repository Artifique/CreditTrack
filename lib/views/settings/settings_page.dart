import 'package:flutter/material.dart';
import '../../core/tokens.dart';
import '../../core/user_feedback.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/theme_mode_controller.dart';
import '../../models/business_settings_model.dart';
import '../../models/profile_model.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/ui/ui.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                    title: const Text("Paramètres", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                    centerTitle: true,
                  ),
                  body: SingleChildScrollView(
                    child: ResponsiveContainer(
                      maxWidth: 760,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        children: [
                          FadeInUp(
                            delay: const Duration(milliseconds: 50),
                            child: _buildProfileSection(profile),
                          ),
                          const SizedBox(height: AppTokens.space28),
                          FadeInUp(
                            delay: const Duration(milliseconds: 100),
                            child: _buildSettingsSection(
                              context,
                              "Commerce & Numéros",
                              [
                                _SettingsTile(
                                  icon: Icons.storefront_rounded,
                                  title: "Profil du commerce",
                                  value: profile?.businessName ?? "-",
                                  onTap: () => Navigator.pushNamed(context, '/settings-business'),
                                ),
                                _SettingsTile(
                                  icon: Icons.sim_card_rounded,
                                  title: "Gestion des cartes SIM",
                                  value: "${profile?.operationPhones.length ?? 0} SIM(s) configurée(s)",
                                  onTap: () async {
                                    await Navigator.pushNamed(context, '/settings-sims');
                                    if (mounted) {
                                      setState(() {
                                        _profileFuture = _settingsController.getProfile();
                                      });
                                    }
                                  },
                                ),
                                _SettingsTile(
                                  icon: Icons.phone_android_rounded,
                                  title: "Téléphone principal",
                                  value: profile?.phoneNumber ?? "-",
                                  onTap: () => Navigator.pushNamed(context, '/settings-business'),
                                ),
                                _SettingsTile(
                                  icon: Icons.percent_rounded,
                                  title: "Taux de commission",
                                  value: "Dépôt, retrait, forfait, UV...",
                                  onTap: () => Navigator.pushNamed(context, '/settings-commission-rates'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTokens.space24),
                          FadeInUp(
                            delay: const Duration(milliseconds: 150),
                            child: _buildSettingsSection(
                              context,
                              "Matériel & Impression",
                              [
                                _SettingsTile(
                                  icon: Icons.print_rounded,
                                  title: "Imprimante thermique",
                                  value: settings.autoPrintReceipt ? "Auto activée" : "Manuelle",
                                  onTap: () => Navigator.pushNamed(context, '/settings-printer'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTokens.space24),
                          FadeInUp(
                            delay: const Duration(milliseconds: 200),
                            child: _buildSettingsSection(
                              context,
                              "Préférences & Affichage",
                              [
                                SwitchListTile(
                                  secondary: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0x33FBBF24) : AppTokens.primary50,
                                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                                    ),
                                    child: Icon(
                                      isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                      color: isDark ? const Color(0xFFFBBF24) : AppTokens.primary500,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    "Mode sombre",
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "Palette sombre reposante pour les yeux",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary,
                                    ),
                                  ),
                                  value: ThemeModeController.instance.isDark,
                                  activeThumbColor: AppTokens.primary400,
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
                                        UserFeedback.showToast(
                                          context,
                                          "Impossible de synchroniser avec le serveur.",
                                          type: AppToastType.warning,
                                        );
                                      }
                                    }
                                  },
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTokens.space24),
                          FadeInUp(
                            delay: const Duration(milliseconds: 250),
                            child: _buildSettingsSection(
                              context,
                              "Zone de Danger",
                              [
                                ListTile(
                                  onTap: () => _confirmClearAllData(context),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppTokens.darkErrorBg : AppTokens.errorBg,
                                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                                    ),
                                    child: const Icon(Icons.delete_forever_rounded, color: AppTokens.error, size: 20),
                                  ),
                                  title: const Text(
                                    "Effacer toutes les transactions",
                                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppTokens.error),
                                  ),
                                  subtitle: Text(
                                    "Remise à zéro des soldes & historique",
                                    style: TextStyle(fontSize: 12, color: isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary),
                                  ),
                                  trailing: const Icon(Icons.chevron_right_rounded, color: AppTokens.error, size: 20),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTokens.space32),
                          FadeInUp(
                            delay: const Duration(milliseconds: 300),
                            child: AppButton(
                              label: "Déconnexion",
                              icon: Icons.logout_rounded,
                              variant: AppButtonVariant.ghost,
                              isFullWidth: true,
                              onPressed: () async {
                                await _authController.signOut();
                                if (!context.mounted) return;
                                Navigator.pushReplacementNamed(context, '/login');
                              },
                            ),
                          ),
                          const SizedBox(height: AppTokens.space40),
                        ],
                      ),
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
      padding: const EdgeInsets.all(AppTokens.space24),
      decoration: BoxDecoration(
        gradient: AppTokens.primaryGradient,
        borderRadius: BorderRadius.circular(AppTokens.radius2Xl),
        boxShadow: [
          BoxShadow(
            color: AppTokens.primary500.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          ProfileAvatar(profile: profile, radius: 32, lightStyle: true),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.ownerName ?? profile?.businessName ?? "Commerçant",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile?.phoneNumber ?? "Gestionnaire",
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  ),
                  child: const Text(
                    "Propriétaire Vérifié",
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary,
              letterSpacing: 0.2,
            ),
          ),
        ),
        AppCard(
          variant: AppCardVariant.elevated,
          padding: EdgeInsets.zero,
          child: Column(
            children: List.generate(tiles.length, (index) {
              final tile = tiles[index];
              final isLast = index == tiles.length - 1;
              return Column(
                children: [
                  tile,
                  if (!isLast)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 56,
                      color: isDark ? AppTokens.darkBorder : AppTokens.lightBorder,
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmClearAllData(BuildContext context) async {
    final confirmCtrl = TextEditingController();
    final ok = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              final isMatch = confirmCtrl.text.trim() == 'SUPPRIMER';
              return AlertDialog(
                title: const Text("Effacer toutes les données", style: TextStyle(fontWeight: FontWeight.w700)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Cette action supprime définitivement toutes les transactions et remet tous les soldes à zéro. "
                      "Le profil et vos numéros enregistrés restent inchangés. Cette action est irréversible.",
                      style: TextStyle(fontSize: 13.5, height: 1.45),
                    ),
                    const SizedBox(height: 16),
                    const Text("Tapez SUPPRIMER pour confirmer :", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 8),
                    AppInput(
                      controller: confirmCtrl,
                      hintText: 'SUPPRIMER',
                      onChanged: (_) => setDialogState(() {}),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text("Annuler"),
                  ),
                  AppButton(
                    label: "Effacer tout",
                    variant: AppButtonVariant.danger,
                    size: AppButtonSize.sm,
                    onPressed: isMatch ? () => Navigator.pop(dialogContext, true) : null,
                  ),
                ],
              );
            },
          ),
        ) ??
        false;

    confirmCtrl.dispose();
    if (!ok) return;

    try {
      await _settingsController.clearAllData();
      if (!mounted) return;
      UserFeedback.showSuccessToast(context, "Toutes les données ont été effacées.");
      if (!mounted) return;
      setState(() {
        _profileFuture = _settingsController.getProfile();
        _settingsFuture = _settingsController.getBusinessSettings();
      });
    } catch (e) {
      if (!mounted) return;
      await UserFeedback.showErrorModal(context, e);
    }
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0x336366F1) : AppTokens.primary50,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        ),
        child: Icon(icon, color: isDark ? AppTokens.primary300 : AppTokens.primary500, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              value,
              style: TextStyle(
                color: isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextSecondary,
                fontSize: 12.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary,
          ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
