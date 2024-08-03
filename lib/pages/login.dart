import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeley_frontend/commons/decoration.dart';
import 'package:yeley_frontend/commons/validators.dart';
import 'package:yeley_frontend/providers/auth.dart';

import '../widgets/CustomBackground.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomBackground(
      child: Container(
        color: Colors.transparent,  // Change kScaffoldBackground to Colors.transparent
        child: SafeArea(
          child: Scaffold(
            backgroundColor: Colors.transparent,  // Change kScaffoldBackground to Colors.transparent
            body: SingleChildScrollView(
              child: SizedBox(
                height: MediaQuery.of(context).size.height -
                    (MediaQuery.of(context).padding.top + MediaQuery.of(context).padding.bottom),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      Align(
                        alignment: Alignment.center,
                        child: Image.asset(
                          'assets/splash.png',
                          height: 95,
                          width: 95,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Align(
                          alignment: Alignment.center,
                          child: Text(
                            "YELEY",
                            style: kBold24,
                          )
                      ),
                      const SizedBox(height: 10),
                      const Align(
                        alignment: Alignment.center,
                        child: Text(
                          "Connectez-vous",
                          style: kBold22,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 70),
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            "Pour accéder à vos restaurants et activités favorites !",
                            style: kRegular14,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 150,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 13),
                              child: Text(
                                "Se connecter",
                                style: kBold18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 4,
                              decoration: const BoxDecoration(
                                color: kMainGreen,
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(100),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        child: Text("Email", style: kBold14),
                      ),
                      const SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: TextFormField(
                          textCapitalization: TextCapitalization.none,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.email, color: kMainGreen),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                                borderSide: BorderSide.none
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
                            hintText: 'Quel est votre email ?',
                            hintStyle: kRegular16,
                          ),
                          controller: _emailController,
                          validator: Validator.email,
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        child: Text("Mot de passe", style: kBold14),
                      ),
                      const SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: TextFormField(
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                                borderSide: BorderSide.none
                            ),
                            hintText: 'Quel est votre mot de passe',
                            hintStyle: kRegular16,
                            filled: true,
                            fillColor: Colors.grey[200],
                            prefixIcon: const Icon(Icons.lock, color: kMainGreen),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: _togglePasswordVisibility,
                            ),
                          ),
                          controller: _passwordController,
                          validator: Validator.password,
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: SizedBox(
                          height: 50,
                          width: double.infinity,
                          child: context.watch<AuthProvider>().isLogin
                              ? const Center(
                            child: CircularProgressIndicator(
                              color: kMainGreen,
                            ),
                          )
                              : ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: kMainGreen),
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                await context
                                    .read<AuthProvider>()
                                    .login(context, _emailController.text, _passwordController.text);
                              }
                            },
                            child: Text("Se connecter", style: kBold16.copyWith(color: Colors.white)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                              fontFamily: "Lato",
                            ),
                            children: [
                              TextSpan(
                                text: 'Vous n\'avez pas de compte ? ',
                                style: kRegular16.copyWith(color: Colors.black),
                              ),
                              TextSpan(
                                style: kRegular16.copyWith(color: kMainGreen),
                                text: 'Inscrivez-vous.',
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.pushNamed(context, '/signup');
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
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
