import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';

class DeepLinkingService {
  static final DeepLinkingService _singleton = DeepLinkingService._internal();
  final AppLinks _appLinks = AppLinks();

  factory DeepLinkingService() {
    return _singleton;
  }

  DeepLinkingService._internal();

  StreamSubscription? _subscription;
  bool _isInitialized = false;

  /// Initialise le service d'écoute des deep links
  Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    if (_isInitialized) return;

    // Gestion des deep links lorsque l'application est fermée
    try {
      final uri = await _appLinks.getInitialAppLink();
      if (uri != null) {
        debugPrint('Initialisation - Deep link trouvé: $uri');
        _handleDeepLink(uri, navigatorKey);
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération du lien initial: $e');
    }

    // Configuration de l'écoute des deep links lorsque l'application est en arrière-plan
    try {
      _subscription = _appLinks.uriLinkStream.listen((uri) {
        debugPrint('Stream - Deep link reçu: $uri');
        // Utiliser un délai pour s'assurer que l'application est prête
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleDeepLink(uri, navigatorKey);
        });
      }, onError: (error) {
        debugPrint('Erreur lors de la gestion des deep links: $error');
      });
      debugPrint('Écoute des deep links configurée avec succès');
    } catch (e) {
      debugPrint('Erreur lors de la configuration de l\'écoute des deep links: $e');
    }

    _isInitialized = true;
    debugPrint('Service DeepLinkingService initialisé');
  }

  /// Gère les deep links reçus
  void _handleDeepLink(Uri uri, GlobalKey<NavigatorState> navigatorKey) {
    debugPrint('Deep link reçu: $uri');
    debugPrint('Schéma: ${uri.scheme}, Hôte: ${uri.host}, Chemin: ${uri.path}');
    
    // Pour les URLs de type yeley://reset-password, host sera "reset-password" et path sera vide
    // Pour les URLs de type https://api.yeley.fr/auth/reset-password, path sera "/auth/reset-password"
    final isResetPasswordLink = 
        uri.host == 'reset-password' || // Pour le format yeley://reset-password
        uri.path.contains('/reset-password') || // Pour le format avec chemin /reset-password
        uri.path.contains('/auth/reset-password'); // Pour le format avec chemin /auth/reset-password
    
    if (isResetPasswordLink) {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        debugPrint('Token de réinitialisation trouvé: $token');
        
        // S'assurer que nous avons un navigateur valide
        if (navigatorKey.currentState == null) {
          debugPrint('NavigatorState null, impossible de naviguer');
          return;
        }
        
        // Utiliser pushNamedAndRemoveUntil pour effacer la pile de navigation
        // et garantir que la page de réinitialisation s'affiche
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigatorKey.currentState!.pushNamedAndRemoveUntil(
            '/reset-password',
            (route) => false,
            arguments: {'token': token},
          );
          debugPrint('Navigation vers /reset-password effectuée');
        });
      } else {
        debugPrint('Token de réinitialisation manquant ou vide');
      }
    } else {
      debugPrint('URL reçue ne correspond pas à un lien de réinitialisation de mot de passe: $uri');
    }
  }

  /// Détruit le service d'écoute des deep links
  void dispose() {
    _subscription?.cancel();
    _isInitialized = false;
    debugPrint('Service DeepLinkingService détruit');
  }
}