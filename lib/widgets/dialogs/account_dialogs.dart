// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeley_frontend/commons/decoration.dart';
import 'package:yeley_frontend/providers/users.dart';
import 'package:yeley_frontend/services/local_storage.dart';

/// Classe utilitaire pour gérer les dialogues liés au compte utilisateur
class AccountDialogs {
  /// Affiche un dialogue de confirmation de déconnexion
  static Future<void> showLogoutDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Se déconnecter',
            style: kBold22.copyWith(color: Colors.black),
          ),
          content: Text(
            'Êtes-vous sûr de vouloir vous déconnecter ?',
            style: kRegular16.copyWith(color: Colors.black),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Se déconnecter',
                style: kRegular16.copyWith(color: kMainGreen),
              ),
              onPressed: () async {
                await context.read<UsersProvider>().logout(context);
              },
            ),
            TextButton(
              child: Text(
                'Annuler',
                style: kRegular16.copyWith(color: Colors.black),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  /// Affiche un dialogue de confirmation de suppression de compte
  static Future<void> showDeleteAccountDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Supprimer le compte',
            style: kBold22.copyWith(color: Colors.black),
          ),
          content: Text(
            'Votre compte sera supprimé définitivement.',
            style: kRegular16.copyWith(color: Colors.black),
          ),
          actions: context.watch<UsersProvider>().isDeleting
              ? [
                  const Center(
                      child: CircularProgressIndicator(
                    color: kMainGreen,
                  ))
                ]
              : <Widget>[
                  TextButton(
                    child: Text(
                      'Supprimer',
                      style: kRegular16.copyWith(color: Colors.red),
                    ),
                    onPressed: () async {
                      await context.read<UsersProvider>().deleteAccount(context);
                    },
                  ),
                  TextButton(
                    child: Text(
                      'Annuler',
                      style: kRegular16.copyWith(color: Colors.black),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
        );
      },
    );
  }

  /// Affiche un dialogue indiquant qu'un email de confirmation a été envoyé
  static Future<void> showEmailConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // L'utilisateur doit cliquer sur un bouton pour fermer
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Confirmation requise',
            style: kBold22.copyWith(color: Colors.black),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Un email de confirmation a été envoyé à votre adresse email.',
                  style: kRegular16.copyWith(color: Colors.black),
                ),
                const SizedBox(height: 16),
                Text(
                  'Vérifiez votre boîte de réception et vos spams, puis cliquez sur le lien de confirmation pour activer votre compte.',
                  style: kRegular16.copyWith(color: Colors.black),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Se connecter',
                style: kRegular16.copyWith(color: kMainGreen),
              ),
              onPressed: () async {
                Navigator.pop(context); // Ferme le dialogue
                
                // Récupère l'email temporairement stocké
                final email = await LocalStorageService().getString("temp_email") ?? "";
                
                // Redirige vers la page de connexion
                Navigator.pushNamedAndRemoveUntil(
                  context, 
                  '/login', 
                  (route) => false,
                  arguments: {'email': email}, // Passage de l'email en argument
                );
              },
            ),
          ],
        );
      },
    );
  }
  
  /// Affiche un dialogue indiquant qu'un email de réinitialisation de mot de passe a été envoyé
  static Future<void> showPasswordResetEmailSentDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // L'utilisateur doit cliquer sur un bouton pour fermer
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Email envoyé',
            style: kBold22.copyWith(color: Colors.black),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Un email de réinitialisation de mot de passe a été envoyé à votre adresse email.',
                  style: kRegular16.copyWith(color: Colors.black),
                ),
                const SizedBox(height: 16),
                Text(
                  'Vérifiez votre boîte de réception et vos spams, puis cliquez sur le lien pour réinitialiser votre mot de passe.',
                  style: kRegular16.copyWith(color: Colors.black),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Retour à la connexion',
                style: kRegular16.copyWith(color: kMainGreen),
              ),
              onPressed: () async {
                Navigator.pop(context); // Ferme le dialogue
                
                // Récupère l'email temporairement stocké
                final email = await LocalStorageService().getString("temp_email") ?? "";
                
                // Redirige vers la page de connexion
                Navigator.pushNamedAndRemoveUntil(
                  context, 
                  '/login', 
                  (route) => false,
                  arguments: {'email': email}, // Passage de l'email en argument
                );
              },
            ),
          ],
        );
      },
    );
  }
  
  /// Affiche un dialogue indiquant que le mot de passe a été réinitialisé avec succès
  static Future<void> showPasswordResetSuccessDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // L'utilisateur doit cliquer sur un bouton pour fermer
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Mot de passe réinitialisé',
            style: kBold22.copyWith(color: Colors.black),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Votre mot de passe a été réinitialisé avec succès.',
                  style: kRegular16.copyWith(color: Colors.black),
                ),
                const SizedBox(height: 16),
                Text(
                  'Vous pouvez maintenant vous connecter avec votre nouveau mot de passe.',
                  style: kRegular16.copyWith(color: Colors.black),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Se connecter',
                style: kRegular16.copyWith(color: kMainGreen),
              ),
              onPressed: () async {
                Navigator.pop(context); // Ferme le dialogue
                
                // Récupère l'email temporairement stocké
                final email = await LocalStorageService().getString("temp_email") ?? "";
                
                // Redirige vers la page de connexion
                Navigator.pushNamedAndRemoveUntil(
                  context, 
                  '/login', 
                  (route) => false,
                  arguments: {'email': email}, // Passage de l'email en argument
                );
              },
            ),
          ],
        );
      },
    );
  }
}