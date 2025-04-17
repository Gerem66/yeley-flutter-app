import 'dart:convert';
import 'package:http/http.dart';
import 'package:yeley_frontend/commons/exception.dart';
import 'package:yeley_frontend/commons/constants.dart';
import 'package:yeley_frontend/models/establishment.dart';
import 'package:yeley_frontend/models/tag.dart';

class Api {
  Api._(); // Singleton

  static String? jwt;

  static Future<String> signup(
    String email,
    String password,
  ) async {
    Response response = await post(
      Uri.parse('$kApiUrl/auth/signup'),
      headers: {
        'Content-type': 'application/json',
      },
      body: jsonEncode(
        {
          "email": email.toLowerCase(),
          "password": password,
        },
      ),
    );

    if (response.statusCode < 200 || response.statusCode > 299) {
      ExceptionHelper.fromResponse(response);
    }
    return jsonDecode(response.body)["accessToken"];
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    Response response = await post(
      Uri.parse('$kApiUrl/auth/login'),
      headers: {
        'Content-type': 'application/json',
      },
      body: jsonEncode(
        {
          "email": email.toLowerCase(),
          "password": password,
        },
      ),
    );

    if (response.statusCode < 200 || response.statusCode > 299) {
      ExceptionHelper.fromResponse(response);
    }

    final responseData = jsonDecode(response.body);
    return {
      "accessToken": responseData["accessToken"],
      "createdAt": responseData["createdAt"],
    };
  }

  static Future<bool> checkServerConnection() async {
    try {
      Response response = await get(
        Uri.parse('$kApiUrl/ping'),
        headers: {
          'Content-type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      return false;
    }
  }

  static Future<void> deleteUserAccount() async {
    Response response = await delete(
      Uri.parse('$kApiUrl/users'),
      headers: {
        'Authorization': 'Bearer $jwt',
      },
    );
    if (response.statusCode < 200 || response.statusCode > 299) {
      ExceptionHelper.fromResponse(response);
    }
  }

  static Future<List<Tag>> getTags() async {
    Response response = await get(
      Uri.parse('$kApiUrl/tags/all'),
      headers: {
        'Authorization': 'Bearer $jwt',
      },
    );
    if (response.statusCode < 200 || response.statusCode > 299) {
      ExceptionHelper.fromResponse(response);
    }
    final Map<String, dynamic> body = jsonDecode(response.body);
    return Tag.fromJsons(body["tags"]);
  }

  static Future<List<Establishment>> getNearbyEstablishments(
    int range,
    List<double> coordinates,
    EstablishmentType type,
    List<Tag> tags, {
    bool favorite = false,
  }) async {
    Response response = await post(
      Uri.parse('$kApiUrl/users/nearby/establishments${favorite ? "?liked=true" : ""}'),
      headers: {
        'Authorization': 'Bearer $jwt',
        'Content-type': 'application/json',
      },
      body: jsonEncode(
        {
          "range": range,
          'coordinates': coordinates,
          "type": type.name,
          "tags": Tag.getIds(tags),
        },
      ),
    );

    if (response.statusCode < 200 || response.statusCode > 299) {
      ExceptionHelper.fromResponse(response);
    }
    final Map<String, dynamic> body = jsonDecode(response.body);
    return Establishment.fromJsons(body["nearbyEstablishments"]);
  }

  static Future<void> like(Establishment establishment) async {
    Response response = await get(
      Uri.parse('$kApiUrl/users/like/establishment/${establishment.id}'),
      headers: {
        'Authorization': 'Bearer $jwt',
      },
    );
    if (response.statusCode < 200 || response.statusCode > 299) {
      ExceptionHelper.fromResponse(response);
    }
  }

  static Future<void> unlike(Establishment establishment) async {
    Response response = await get(
      Uri.parse('$kApiUrl/users/unlike/establishment/${establishment.id}'),
      headers: {
        'Authorization': 'Bearer $jwt',
      },
    );
    if (response.statusCode < 200 || response.statusCode > 299) {
      ExceptionHelper.fromResponse(response);
    }
  }
}
