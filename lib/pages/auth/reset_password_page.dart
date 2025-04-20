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
  String _token = '';
  String _errorText = '';
  bool _isPasswordVisible = false;

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
    super.dispose();
  }
  
  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  bool _validatePassword() {
    if (_passwordController.text.isEmpty) {
      setState(() {
        _errorText = 'Veuillez saisir un mot de passe.';
      });
      return false;
    }
    
    if (_passwordController.text.length < 8) {
      setState(() {
        _errorText = 'Le mot de passe doit contenir au moins 8 caractères.';
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
              decoration: InputDecoration(
                labelText: 'Nouveau mot de passe',
                hintText: '********',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: _togglePasswordVisibility,
                ),
              ),
              obscureText: !_isPasswordVisible,
            ),
            const SizedBox(height: 8),
            Text(
              'Le mot de passe doit contenir au moins 8 caractères.',
              style: kRegular14.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Consumer<AuthProvider>(
              builder: (context, auth, child) {
                return CustomButton(
                  text: 'Réinitialiser le mot de passe',
                  isLoading: auth.isResettingPassword,
                  onPressed: _token.isEmpty ? null : () async {
                    if (_validatePassword()) {
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