import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../controllers/auth_controller.dart';

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

  Future<void> _handleSignUp() async {
    if (_businessController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nom commerce, email et mot de passe sont requis."), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authController.signUp(
        _emailController.text.trim(),
        _passwordController.text,
        _businessController.text.trim(),
        ownerName: _nameController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Compte créé avec succès."), backgroundColor: Colors.green),
      );
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Créer un compte", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 8),
            const Text("Commencez à gérer votre business intelligemment.", style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 40),
            _buildInputField(label: "Nom du Commerce", hint: "ex: Toure Multi-Services", icon: Icons.storefront_rounded, controller: _businessController),
            const SizedBox(height: 20),
            _buildInputField(label: "Votre Nom Complet", hint: "ex: Aly Toure", icon: Icons.person_outline_rounded, controller: _nameController),
            const SizedBox(height: 20),
            _buildInputField(label: "Email Professionnel", hint: "nom@exemple.com", icon: Icons.alternate_email_rounded, controller: _emailController),
            const SizedBox(height: 20),
            _buildInputField(label: "Mot de passe", hint: "••••••••", icon: Icons.lock_outline_rounded, isPassword: true, controller: _passwordController),
            const SizedBox(height: 40),
            _buildSignUpButton(),
            const SizedBox(height: 24),
            _buildLoginText(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({required String label, required String hint, required IconData icon, required TextEditingController controller, bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primary),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(20),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignUp,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("Créer mon compte", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildLoginText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Déjà un compte ?"),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Se connecter", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
