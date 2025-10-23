import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yeley_frontend/commons/constants.dart';
import 'package:yeley_frontend/commons/decoration.dart';

class NetworkErrorDialog {
  // Variable statique pour suivre si une popup réseau est déjà ouverte
  static bool _isDialogShowing = false;

  /// Affiche une popup élégante pour les erreurs de connexion internet
  /// Ne l'affiche que si une popup similaire n'est pas déjà ouverte
  static Future<void> show(BuildContext context) async {
    // Si une popup est déjà ouverte, ne pas en afficher une nouvelle
    if (_isDialogShowing) {
      return;
    }

    _isDialogShowing = true;

    try {
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icône de connexion perdue
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.wifi_off,
                      size: 64,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Titre
                  const Text(
                    'Pas de connexion',
                    style: kBold22,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  
                  // Message
                  Text(
                    'Impossible de se connecter au serveur.\nVérifiez votre connexion internet et réessayez.',
                    style: kRegular14.copyWith(color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Lien email de contact (affiché uniquement si configuré)
                  if (kSupportEmail != null && kSupportEmail!.isNotEmpty) ...[
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: kRegular14.copyWith(color: Colors.grey[600]),
                        children: [
                          const TextSpan(text: 'Si le problème persiste, contactez-nous :\n'),
                          const WidgetSpan(
                            child: SizedBox(height: 20),
                          ),
                          TextSpan(
                            text: kSupportEmail,
                            style: kRegular16.copyWith(
                              color: kMainGreen,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => _sendSupportEmail(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  if (kSupportEmail == null || kSupportEmail!.isEmpty)
                    const SizedBox(height: 8),
                  
                  // Bouton OK
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kMainGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'J\'ai compris',
                        style: kBold16.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } finally {
      // Réinitialiser le flag quand la popup se ferme
      _isDialogShowing = false;
    }
  }

  /// Ouvre le client email pour contacter le support
  static Future<void> _sendSupportEmail(BuildContext context) async {
    if (kSupportEmail == null || kSupportEmail!.isEmpty) return;
    
    final Uri emailUri = Uri.parse(
      'mailto:$kSupportEmail?subject=Problème de connexion - Yeley',
    );
    
    try {
      await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      // Si ça échoue, afficher un message d'erreur
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir le client email'),
          ),
        );
      }
    }
  }
}
