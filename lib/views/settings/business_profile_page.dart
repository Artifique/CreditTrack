import 'package:flutter/material.dart';
import '../../core/tokens.dart';
import '../../core/user_feedback.dart';
import '../../controllers/operation_phone_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/sim_card_controller.dart';
import '../../widgets/ui/ui.dart';

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

  final List<TextEditingController> _nameControllers = [];
  final List<TextEditingController> _opPhoneControllers = [];
  final List<TextEditingController> _uvBalControllers = [];
  final List<TextEditingController> _crBalControllers = [];

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

        final sims = await SimCardController.instance.loadSimCards();
        if (!mounted) return;
        _disposeSlotControllers();

        for (final sim in sims) {
          _addSlot(
            initialName: sim.name,
            initialPhone: sim.phone,
            initialUv: sim.soldeUv,
            initialCredit: sim.soldeCredit,
          );
        }

        if (_opPhoneControllers.isEmpty) {
          _addSlot();
        }
      }
    } catch (e) {
      if (mounted) setState(() => _loadError = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addSlot({
    String initialName = '',
    String initialPhone = '',
    double initialUv = 0,
    double initialCredit = 0,
  }) {
    _nameControllers.add(TextEditingController(text: initialName));
    _opPhoneControllers.add(TextEditingController(text: initialPhone));
    _uvBalControllers.add(TextEditingController(text: initialUv.toStringAsFixed(0)));
    _crBalControllers.add(TextEditingController(text: initialCredit.toStringAsFixed(0)));
  }

  void _removeSlot(int index) {
    if (index >= 0 && index < _opPhoneControllers.length) {
      _nameControllers[index].dispose();
      _opPhoneControllers[index].dispose();
      _uvBalControllers[index].dispose();
      _crBalControllers[index].dispose();
      setState(() {
        _nameControllers.removeAt(index);
        _opPhoneControllers.removeAt(index);
        _uvBalControllers.removeAt(index);
        _crBalControllers.removeAt(index);
      });
    }
  }

  void _disposeSlotControllers() {
    for (final c in _nameControllers) {
      c.dispose();
    }
    for (final c in _opPhoneControllers) {
      c.dispose();
    }
    for (final c in _uvBalControllers) {
      c.dispose();
    }
    for (final c in _crBalControllers) {
      c.dispose();
    }
    _nameControllers.clear();
    _opPhoneControllers.clear();
    _uvBalControllers.clear();
    _crBalControllers.clear();
  }

  @override
  void dispose() {
    _businessController.dispose();
    _ownerController.dispose();
    _phoneController.dispose();
    _disposeSlotControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil & Comptes SIM', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        actions: [
          if (!_loading)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _load,
              tooltip: "Rafraîchir",
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(child: Text(_loadError!, textAlign: TextAlign.center))
              : SingleChildScrollView(
                  child: ResponsiveContainer(
                    maxWidth: 720,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppCard(
                          variant: AppCardVariant.elevated,
                          padding: const EdgeInsets.all(AppTokens.space20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Informations du Commerce",
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              AppInput(
                                controller: _businessController,
                                label: "Nom du Commerce",
                                hintText: "ex: ALY TOURE SERVICE",
                                prefixIcon: Icons.storefront_rounded,
                              ),
                              const SizedBox(height: 14),
                              AppInput(
                                controller: _ownerController,
                                label: "Nom du Gérant / Propriétaire",
                                hintText: "ex: Aly Toure",
                                prefixIcon: Icons.person_outline_rounded,
                              ),
                              const SizedBox(height: 14),
                              AppInput(
                                controller: _phoneController,
                                label: "Téléphone Principal",
                                hintText: "ex: 77 00 00 00",
                                keyboardType: TextInputType.phone,
                                prefixIcon: Icons.phone_rounded,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTokens.space24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Comptes SIM de Travail (Illimités)",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => _openAddSimModal(context, isDark),
                              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                              label: const Text("+ Ajouter une SIM", style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Chaque SIM enregistrée dispose de son propre solde UV et Crédit.",
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        for (var i = 0; i < _opPhoneControllers.length; i++) ...[
                          _buildOperationSlot(i, isDark),
                          const SizedBox(height: 12),
                        ],
                        const SizedBox(height: AppTokens.space24),
                        AppButton(
                          label: "Enregistrer les modifications",
                          icon: Icons.check_circle_rounded,
                          size: AppButtonSize.lg,
                          isLoading: _isSaving,
                          onPressed: _save,
                        ),
                        const SizedBox(height: AppTokens.space40),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildOperationSlot(int index, bool isDark) {
    final titleText = _nameControllers[index].text.trim().isNotEmpty
        ? _nameControllers[index].text.trim()
        : "Compte SIM ${index + 1}";

    return AppCard(
      variant: AppCardVariant.elevated,
      padding: const EdgeInsets.all(AppTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0x336366F1) : AppTokens.primary50,
                      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                    ),
                    child: Icon(Icons.sim_card_rounded, size: 18, color: isDark ? AppTokens.primary300 : AppTokens.primary600),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    titleText,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              if (_opPhoneControllers.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppTokens.error),
                  onPressed: () => _removeSlot(index),
                  tooltip: "Supprimer cette SIM",
                ),
            ],
          ),
          const SizedBox(height: 12),
          AppInput(
            controller: _nameControllers[index],
            label: "Nom personnalisé de la SIM",
            hintText: "ex: Orange Money Caisse 01",
            prefixIcon: Icons.badge_outlined,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          AppInput(
            controller: _opPhoneControllers[index],
            label: "Numéro de la ligne",
            hintText: "Ex. 77 123 45 67",
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_android_rounded,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppInput(
                  controller: _uvBalControllers[index],
                  label: "Solde UV (FCFA)",
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppInput(
                  controller: _crBalControllers[index],
                  label: "Stock Crédit (FCFA)",
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openAddSimModal(BuildContext context, bool isDark) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final uvCtrl = TextEditingController(text: "0");
    final crCtrl = TextEditingController(text: "0");
    bool isAdding = false;
    final parentContext = context;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTokens.darkSurface : AppTokens.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radius2Xl)),
      ),
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
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
                        "+ Ajouter un Compte SIM",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AppInput(
                    controller: nameCtrl,
                    label: "Nom personnalisé de la SIM",
                    hintText: "ex: Orange Money 01 ou Moov Caisse",
                    isRequired: true,
                    prefixIcon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 12),
                  AppInput(
                    controller: phoneCtrl,
                    label: "Numéro de la SIM / Agent",
                    hintText: "ex: 77 123 45 67",
                    isRequired: true,
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_rounded,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppInput(
                          controller: uvCtrl,
                          label: "Solde UV Initial",
                          hintText: "0",
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.account_balance_wallet_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppInput(
                          controller: crCtrl,
                          label: "Solde Crédit Initial",
                          hintText: "0",
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.phone_android_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    label: "ENREGISTRER LA SIM",
                    icon: Icons.check_circle_rounded,
                    isFullWidth: true,
                    size: AppButtonSize.lg,
                    isLoading: isAdding,
                    onPressed: () async {
                      final p = phoneCtrl.text.trim();
                      final n = nameCtrl.text.trim();
                      if (p.isEmpty) {
                        UserFeedback.showToast(ctx, "Le numéro est obligatoire.", type: AppToastType.warning);
                        return;
                      }
                      setModalState(() => isAdding = true);
                      try {
                        final uv = double.tryParse(uvCtrl.text.trim().replaceAll(' ', '')) ?? 0.0;
                        final cr = double.tryParse(crCtrl.text.trim().replaceAll(' ', '')) ?? 0.0;
                        final created = await SimCardController.instance.addSimCard(
                          phone: p,
                          name: n,
                          initialUv: uv,
                          initialCredit: cr,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (parentContext.mounted) {
                          UserFeedback.showSuccessToast(parentContext, "SIM « ${created.displayName} » ajoutée avec succès !");
                        }
                        await _load();
                      } catch (e) {
                        if (ctx.mounted) {
                          setModalState(() => isAdding = false);
                          UserFeedback.showErrorModal(ctx, e);
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final slots = _opPhoneControllers.map((c) => c.text.trim().replaceAll(' ', '')).toList();
      final opPhones = slots.where((p) => p.isNotEmpty).toList();

      await _settingsController.updateProfile(
        businessName: _businessController.text.trim(),
        ownerName: _ownerController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        operationPhones: opPhones,
      );

      for (var i = 0; i < _opPhoneControllers.length; i++) {
        final phone = slots[i];
        if (phone.isEmpty) continue;
        final name = _nameControllers[i].text.trim();
        final uv = double.tryParse(_uvBalControllers[i].text.trim().replaceAll(' ', '')) ?? 0;
        final cr = double.tryParse(_crBalControllers[i].text.trim().replaceAll(' ', '')) ?? 0;
        if (uv < 0 || cr < 0) {
          throw Exception('Les soldes du numéro $phone ne peuvent pas être négatifs.');
        }

        await SimCardController.instance.updateSimCard(
          phone: phone,
          newName: name.isNotEmpty ? name : "SIM $phone",
          soldeUv: uv,
          soldeCredit: cr,
        );
      }

      await OperationPhoneController.instance.syncFromProfile(opPhones);
      await SimCardController.instance.loadSimCards();

      if (!mounted) return;
      UserFeedback.showSuccessToast(context, 'Profil et comptes SIM enregistrés.');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      await UserFeedback.showErrorModal(context, e);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
