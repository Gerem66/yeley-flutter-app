import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeley_frontend/commons/decoration.dart';
import 'package:yeley_frontend/commons/validators.dart';
import 'package:yeley_frontend/providers/auth.dart';
import 'package:yeley_frontend/widgets/custom_button.dart';
import 'package:yeley_frontend/widgets/text_with_link.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _errorText = '';

  @override
  void initState() {
    super.initState();
    // Récupérer l'email depuis les arguments si disponible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('email')) {
        _emailController.text = args['email'] as String;
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
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
            'Mot de passe oublié',
            style: kSemiBold20.copyWith(color: Colors.black),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Réinitialiser votre mot de passe',
                style: kSemiBold24.copyWith(color: Colors.black),
              ),
              const SizedBox(height: 16),
              const Text(
                'Entrez votre adresse email et nous vous enverrons un lien pour réinitialiser votre mot de passe.',
                style: kRegular16,
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
              
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Votre adresse email',
                  prefixIcon: const Icon(Icons.email, color: kMainGreen),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: Validator.email,
              ),
              const SizedBox(height: 32),
              
              Consumer<AuthProvider>(
                builder: (context, auth, child) {
                return CustomButton(
                  text: 'Envoyer le lien de réinitialisation',
                  isLoading: auth.isSendingResetEmail,
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      await auth.forgotPassword(
                        context,
                        _emailController.text,
                      );
                    }
                  },
                );
              }),
              
              const SizedBox(height: 24),
              
              Center(
                child: TextWithLink(
                  normalText: 'Retour à ',
                  linkText: 'la page de connexion',
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}