import 'package:flutter/material.dart';
import '../../core/tokens.dart';
import '../../core/user_feedback.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/ui/ui.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _businessController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authController = AuthController();
  bool _isLoading = false;

  String? _businessError;
  String? _emailError;
  String? _passwordError;

  Future<void> _handleSignUp() async {
    final business = _businessController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _businessError = business.isEmpty ? "Nom du commerce requis" : null;
      _emailError = email.isEmpty ? "Email requis" : null;
      _passwordError = password.isEmpty ? "Mot de passe requis" : null;
    });

    if (_businessError != null || _emailError != null || _passwordError != null) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authController.signUp(
        email,
        password,
        business,
        ownerName: _nameController.text.trim(),
      );

      if (!mounted) return;
      UserFeedback.showSuccessToast(context, "Compte créé avec succès !");
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      if (!mounted) return;
      UserFeedback.showErrorToast(context, e, title: "Erreur d'inscription");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _businessController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ResponsiveContainer(
              maxWidth: 480,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: FadeInUp(
                duration: const Duration(milliseconds: 350),
                child: AppCard(
                  variant: AppCardVariant.elevated,
                  padding: const EdgeInsets.all(AppTokens.space24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Créer un compte",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Gérez vos opérations et visualisez vos profits en temps réel.",
                        style: TextStyle(
                          color: isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: AppTokens.space24),
                      AppInput(
                        controller: _businessController,
                        label: "Nom du Commerce",
                        hintText: "ex: Toure Multi-Services",
                        isRequired: true,
                        prefixIcon: Icons.storefront_rounded,
                        textInputAction: TextInputAction.next,
                        errorText: _businessError,
                        onChanged: (_) {
                          if (_businessError != null) setState(() => _businessError = null);
                        },
                      ),
                      const SizedBox(height: AppTokens.space16),
                      AppInput(
                        controller: _nameController,
                        label: "Votre Nom Complet",
                        hintText: "ex: Aly Toure",
                        prefixIcon: Icons.person_outline_rounded,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppTokens.space16),
                      AppInput(
                        controller: _emailController,
                        label: "Email Professionnel",
                        hintText: "nom@exemple.com",
                        isRequired: true,
                        prefixIcon: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        errorText: _emailError,
                        onChanged: (_) {
                          if (_emailError != null) setState(() => _emailError = null);
                        },
                      ),
                      const SizedBox(height: AppTokens.space16),
                      AppInput(
                        controller: _passwordController,
                        label: "Mot de passe",
                        hintText: "••••••••",
                        isRequired: true,
                        isPassword: true,
                        prefixIcon: Icons.lock_outline_rounded,
                        textInputAction: TextInputAction.done,
                        errorText: _passwordError,
                        onSubmitted: (_) => _handleSignUp(),
                        onChanged: (_) {
                          if (_passwordError != null) setState(() => _passwordError = null);
                        },
                      ),
                      const SizedBox(height: AppTokens.space28),
                      AppButton(
                        label: "Commencer maintenant",
                        icon: Icons.rocket_launch_rounded,
                        isFullWidth: true,
                        size: AppButtonSize.lg,
                        isLoading: _isLoading,
                        onPressed: _handleSignUp,
                      ),
                      const SizedBox(height: AppTokens.space20),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Déjà un compte ? ",
                              style: TextStyle(
                                color: isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary,
                                fontSize: 13.5,
                              ),
                            ),
                            InkWell(
                              onTap: () => Navigator.pop(context),
                              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Text(
                                  "Se connecter",
                                  style: TextStyle(
                                    color: isDark ? AppTokens.primary300 : AppTokens.primary600,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
