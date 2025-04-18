import 'package:flutter/material.dart';
import 'package:yeley_frontend/pages/address_form.dart';
import 'package:yeley_frontend/pages/auth/forgot_password_page.dart';
import 'package:yeley_frontend/pages/auth/reset_password_page.dart';
import 'package:yeley_frontend/pages/home.dart';
import 'package:yeley_frontend/pages/legal_information.dart';
import 'package:yeley_frontend/pages/login.dart';
import 'package:yeley_frontend/pages/privacy_policy.dart';
import 'package:yeley_frontend/pages/signup.dart';
import 'package:yeley_frontend/pages/terms_of_use.dart';
import 'package:yeley_frontend/services/deep_linking_service.dart';

class YeleyApp extends StatefulWidget {
  final bool isSession;
  const YeleyApp({super.key, required this.isSession});

  @override
  State<YeleyApp> createState() => _YeleyAppState();
}

class _YeleyAppState extends State<YeleyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final DeepLinkingService _deepLinkingService = DeepLinkingService();

  @override
  void initState() {
    super.initState();
    // Initialiser le service de deep linking
    _initDeepLinkingService();
  }

  Future<void> _initDeepLinkingService() async {
    await _deepLinkingService.init(_navigatorKey);
  }

  @override
  void dispose() {
    _deepLinkingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Yeley',
      initialRoute: widget.isSession ? "/home" : "/signup",
      routes: {
        '/': (context) => widget.isSession ? const HomePage() : const SignUpPage(), // Ajout de la route racine
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const HomePage(),
        '/terms-of-use': (context) => const TermsOfUsePage(),
        '/privacy-policy': (context) => const PrivacyPolicyPage(),
        '/address-form': (context) => const AddressFormPage(),
        '/legal-information': (context) => const LegalInformation(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/reset-password': (context) => const ResetPasswordPage(),
      },
      // Gestion des routes inconnues
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => widget.isSession 
            ? const HomePage() 
            : const SignUpPage(),
        );
      },
    );
  }
}
