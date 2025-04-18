import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeley_frontend/commons/decoration.dart';
import 'package:yeley_frontend/providers/auth.dart';
import 'package:yeley_frontend/widgets/custom_button.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({Key? key}) : super(key: key);

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String _token = '';
  String _errorText = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('token')) {
        setState(() {
          _token = args['token'] as String;
        });
      } else {
        setState(() {
          _errorText = 'Le jeton de réinitialisation est manquant. Veuillez réessayer.';
        });
      }
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validatePasswords() {
    if (_passwordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      setState(() {
        _errorText = 'Veuillez remplir tous les champs.';
      });
      return false;
    }
    
    if (_passwordController.text.length < 8) {
      setState(() {
        _errorText = 'Le mot de passe doit contenir au moins 8 caractères.';
      });
      return false;
    }
    
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorText = 'Les mots de passe ne correspondent pas.';
      });
      return false;
    }
    
    setState(() {
      _errorText = '';
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'Réinitialiser le mot de passe',
            style: kSemiBold20.copyWith(color: Colors.black),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'Créer un nouveau mot de passe',
              style: kSemiBold24.copyWith(color: Colors.black),
            ),
            const SizedBox(height: 16),
            Text(
              'Veuillez saisir votre nouveau mot de passe ci-dessous.',
              style: kRegular16.copyWith(color: Colors.black),
            ),
            const SizedBox(height: 32),
            
            if (_errorText.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDEDED),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorText,
                  style: kRegular14.copyWith(color: Colors.red),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Nouveau mot de passe',
                hintText: '********',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirmer le mot de passe',
                hintText: '********',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 32),
            Consumer<AuthProvider>(
              builder: (context, auth, child) {
                return CustomButton(
                  text: 'Réinitialiser le mot de passe',
                  isLoading: auth.isResettingPassword,
                  onPressed: _token.isEmpty ? null : () async {
                    if (_validatePasswords()) {
                      await auth.resetPassword(
                        context, 
                        _token,
                        _passwordController.text,
                      );
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}