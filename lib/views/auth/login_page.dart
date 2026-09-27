import 'package:flutter/material.dart';
import '../../core/tokens.dart';
import '../../core/user_feedback.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/ui/ui.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authController = AuthController();
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;

  void _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _emailError = email.isEmpty ? "Email requis" : null;
      _passwordError = password.isEmpty ? "Mot de passe requis" : null;
    });

    if (_emailError != null || _passwordError != null) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authController.signIn(email, password);
      if (!mounted) return;
      UserFeedback.showSuccessToast(context, "Bienvenue sur CreditTrak !");
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      if (!mounted) return;
      UserFeedback.showErrorToast(context, e, title: "Échec de connexion");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ResponsiveContainer(
              maxWidth: 440,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: FadeInUp(
                duration: const Duration(milliseconds: 400),
                child: AppCard(
                  variant: AppCardVariant.elevated,
                  padding: const EdgeInsets.all(AppTokens.space32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLogo(isDark),
                      const SizedBox(height: AppTokens.space24),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                        child: Image.asset(
                          'assets/images/login.jpg',
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: AppTokens.space32),
                      AppInput(
                        controller: _emailController,
                        label: "Adresse Email",
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
                      const SizedBox(height: AppTokens.space20),
                      AppInput(
                        controller: _passwordController,
                        label: "Mot de passe",
                        hintText: "••••••••",
                        isRequired: true,
                        isPassword: true,
                        prefixIcon: Icons.lock_outline_rounded,
                        textInputAction: TextInputAction.done,
                        errorText: _passwordError,
                        onSubmitted: (_) => _handleSignIn(),
                        onChanged: (_) {
                          if (_passwordError != null) setState(() => _passwordError = null);
                        },
                      ),
                      const SizedBox(height: AppTokens.space32),
                      AppButton(
                        label: "Se Connecter",
                        icon: Icons.login_rounded,
                        isFullWidth: true,
                        size: AppButtonSize.lg,
                        isLoading: _isLoading,
                        onPressed: _handleSignIn,
                      ),
                      const SizedBox(height: AppTokens.space24),
                      _buildSignUpText(isDark),
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

  Widget _buildLogo(bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: AppTokens.shadowGlow(AppTokens.primary500),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              'CreditTrak.png',
              width: 80,
              height: 80,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: AppTokens.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 44),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppTokens.space16),
        Text(
          "CreditTrak",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Gérez vos transferts & crédits avec sérénité",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary,
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpText(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Nouveau sur la plateforme ? ",
          style: TextStyle(
            color: isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary,
            fontSize: 13.5,
          ),
        ),
        InkWell(
          onTap: () => Navigator.pushNamed(context, '/signup'),
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              "Créer un compte",
              style: TextStyle(
                color: isDark ? AppTokens.primary300 : AppTokens.primary600,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
