import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/input_field.dart';
import '../../../shared/navigation/app_routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _nameErrorText;
  String? _businessNameErrorText;
  String? _emailErrorText;
  String? _passwordErrorText;

  @override
  void dispose() {
    _nameController.dispose();
    _businessNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleRegister(AuthProvider authProvider) async {
    setState(() {
      _nameErrorText = null;
      _businessNameErrorText = null;
      _emailErrorText = null;
      _passwordErrorText = null;
    });
    if (_formKey.currentState!.validate()) {
      final success = await authProvider.register(
        _nameController.text.trim(),
        _businessNameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      if (success) {
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      } else {
        final error = authProvider.errorMessage ?? '';
        final errorLower = error.toLowerCase();
        bool shown = false;
        if (errorLower.contains('name')) {
          setState(() { _nameErrorText = error; });
          shown = true;
        }
        if (errorLower.contains('businessname') || errorLower.contains('entreprise')) {
          setState(() { _businessNameErrorText = error; });
          shown = true;
        }
        if (errorLower.contains('email')) {
          setState(() { _emailErrorText = error; });
          shown = true;
        }
        if (errorLower.contains('password') || errorLower.contains('mot de passe')) {
          setState(() { _passwordErrorText = error; });
          shown = true;
        }
        if (!shown) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.isNotEmpty ? error : 'Erreur inconnue')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un compte'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              InputField(
                controller: _nameController,
                label: 'Nom complet',
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (val) => val == null || val.isEmpty ? 'Champ requis' : null,
                errorText: _nameErrorText,
              ),
              const SizedBox(height: 16),
              InputField(
                controller: _businessNameController,
                label: 'Nom de l\'entreprise',
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (val) => val == null || val.isEmpty ? 'Champ requis' : null,
                errorText: _businessNameErrorText,
              ),
              const SizedBox(height: 16),
              InputField(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (val) =>
                  val != null && val.contains('@') ? null : 'Email invalide',
                errorText: _emailErrorText,
              ),
              const SizedBox(height: 16),
              InputField(
                controller: _passwordController,
                label: 'Mot de passe',
                obscureText: true,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (val) =>
                  val != null && val.length >= 6 ? null : '6 caractères minimum',
                errorText: _passwordErrorText,
              ),
              const SizedBox(height: 30),
              authProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : CustomButton(
                      text: 'S\'inscrire',
                      onPressed: () => _handleRegister(authProvider),
                    ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                },
                child: const Text("Déjà un compte ? Se connecter"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
