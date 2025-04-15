// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:yeley_frontend/commons/exception.dart';
import 'package:yeley_frontend/services/api.dart';
import 'package:yeley_frontend/services/local_storage.dart';

class AuthProvider extends ChangeNotifier {
  bool isLogging = false;
  bool isRegistering = false;

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
      String jwt = await Api.login(email, password);
      await LocalStorageService().setString("JWT", jwt);
      Api.jwt = jwt;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (Route<dynamic> route) => false,
      );
    } catch (exception) {
      await ExceptionHelper.handle(context: context, exception: exception);
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
      String jwt = await Api.signup(email, password);
      await LocalStorageService().setString("JWT", jwt);
      Api.jwt = jwt;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (Route<dynamic> route) => false,
      );
    } catch (exception) {
      await ExceptionHelper.handle(context: context, exception: exception);
    } finally {
      isRegistering = false;
      notifyListeners();
    }
  }
}
