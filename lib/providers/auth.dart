// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:yeley_frontend/commons/exception.dart';
import 'package:yeley_frontend/services/api.dart';
import 'package:yeley_frontend/services/local_storage.dart';
import 'package:yeley_frontend/widgets/dialogs/account_dialogs.dart';

class AuthProvider extends ChangeNotifier {
  bool isLogging = false;
  bool isRegistering = false;
  bool isResettingPassword = false;
  bool isSendingResetEmail = false;

  Future<void> login(
    BuildContext context,
    String email,
    String password,
  ) async {
    if (email.isEmpty || password.isEmpty || isLogging) {
      return;
    }
    try {
      isLogging = true;
      notifyListeners();

      final loginResult = await Api.login(email, password);
      final String jwt = loginResult["accessToken"];
      final String formattedEmail = email.toLowerCase();
      final String createdAt = loginResult["createdAt"];

      // Stocker le JWT, l'email et la date d'inscription dans le stockage local
      await LocalStorageService().setString("JWT", jwt);
      await LocalStorageService().setString("user_email", formattedEmail);
      await LocalStorageService().setString("user_created_at", createdAt);

      Api.jwt = jwt;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (Route<dynamic> route) => false,
      );
    } catch (exception) {
      if (exception is ApiException) {
        await ExceptionHelper.handle(context: context, exception: exception);
      } else {
        await ExceptionHelper.handle(context: context, exception: 'Erreur de connexion ($exception)');
      }
    } finally {
      isLogging = false;
      notifyListeners();
    }
  }

  Future<void> signup(
    BuildContext context,
    String email,
    String password,
  ) async {
    if (email.isEmpty || password.isEmpty || isRegistering) {
      return;
    }
    try {
      isRegistering = true;
      notifyListeners();

      // La méthode API.signup retourne maintenant un message au lieu d'un token
      await Api.signup(email, password);

      // Stockage de l'email pour une utilisation ultérieure (connexion)
      await LocalStorageService().setString("temp_email", email.toLowerCase());

      // Afficher le dialogue de confirmation au lieu de rediriger vers la page d'accueil
      await AccountDialogs.showEmailConfirmationDialog(context);

    } catch (exception) {
      if (exception is ApiException) {
        await ExceptionHelper.handle(context: context, exception: exception);
      } else {
        await ExceptionHelper.handle(context: context, exception: 'Erreur d\'inscription (${exception.runtimeType})');
      }
    } finally {
      isRegistering = false;
      notifyListeners();
    }
  }

  Future<void> forgotPassword(
    BuildContext context,
    String email,
  ) async {
    if (email.isEmpty || isSendingResetEmail) {
      return;
    }
    try {
      isSendingResetEmail = true;
      notifyListeners();

      final result = await Api.forgotPassword(email);
      
      // Stockage de l'email pour une utilisation ultérieure (connexion)
      await LocalStorageService().setString("temp_email", email.toLowerCase());
      
      // Afficher le dialogue de confirmation d'envoi d'email
      await AccountDialogs.showPasswordResetEmailSentDialog(context);
      
      // Redirection automatique vers la page de login sans attendre le clic sur le bouton
      Navigator.pushNamedAndRemoveUntil(
        context, 
        '/login', 
        (route) => false,
        arguments: {'email': email}, // Passage de l'email en argument
      );

    } catch (exception) {
      if (exception is ApiException) {
        await ExceptionHelper.handle(context: context, exception: exception);
      } else {
        await ExceptionHelper.handle(context: context, exception: 'Erreur lors de la demande de réinitialisation de mot de passe (${exception.runtimeType})');
      }
    } finally {
      isSendingResetEmail = false;
      notifyListeners();
    }
  }
  
  Future<void> resetPassword(
    BuildContext context,
    String token,
    String newPassword,
  ) async {
    if (newPassword.isEmpty || isResettingPassword) {
      return;
    }
    try {
      isResettingPassword = true;
      notifyListeners();

      final result = await Api.resetPassword(token, newPassword);
      
      // Afficher le dialogue de confirmation
      await AccountDialogs.showPasswordResetSuccessDialog(context);

    } catch (exception) {
      if (exception is ApiException) {
        await ExceptionHelper.handle(context: context, exception: exception);
      } else {
        await ExceptionHelper.handle(context: context, exception: 'Erreur lors de la réinitialisation du mot de passe (${exception.runtimeType})');
      }
    } finally {
      isResettingPassword = false;
      notifyListeners();
    }
  }
}
