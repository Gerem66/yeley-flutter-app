// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:yeley_frontend/commons/decoration.dart';
import 'package:yeley_frontend/services/local_storage.dart';
import 'package:yeley_frontend/commons/extensions/translate.dart';

abstract class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  Future<void> handle(BuildContext context);

  @override
  String toString() => message;
}

class SessionExpired extends ApiException {
  SessionExpired() : super('Session expirée, veuillez vous reconnecter.');

  @override
  Future<void> handle(BuildContext context) async {
    await LocalStorageService().setString('JWT', '');
    Navigator.pushNamed(context, '/signup');
  }
}

class EmailNotConfirmed extends ApiException {
  EmailNotConfirmed() : super("security:email:not_confirmed".translate());

  @override
  Future<void> handle(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(
          message,
          style: kRegular16.copyWith(
            color: Colors.white,
          ),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}

class Message extends ApiException {
  Message(String message) : super(message);

  @override
  Future<void> handle(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(
          message,
          style: kRegular16.copyWith(
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  String toString() => message;
}

class ExceptionHelper {
  /// Throw exception [ApiException], from the Api service, based on status codes.
  static void fromResponse(Response response) {
    Map<String, dynamic> body = jsonDecode(response.body);
    String? message;
    String? id;

    // Extraction du message d'erreur et de l'identifiant
    if (body.containsKey('id')) {
      id = body["id"] as String;
      message = id.translate();
    } else if (body.containsKey('message')) {
      message = body["message"];
    }

    // Traitement spécifique selon le type d'erreur
    if (id == "security:email:not_confirmed") {
      throw EmailNotConfirmed();
    } else if (response.statusCode == 401) {
      throw SessionExpired();
    } else {
      throw Message(message ?? "internal:generic".translate());
    }
  }

  static Future<void> handle({required BuildContext context, required Object exception}) async {
    if (exception is ApiException) {
      await exception.handle(context);
    } else {
      final String message;

      if (exception is String) {
        message = exception;
      } else if (exception is Exception) {
        message = exception.toString().replaceFirst('Exception: ', '');
      } else {
        if (kDebugMode) {
          print('Exception: $exception');
        }
        message = 'Une erreur inconnue est survenue. (${exception.runtimeType})';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            message,
            style: kRegular16.copyWith(color: Colors.white),
          ),
        ),
      );
    }
  }
}
