import 'package:flutter_dotenv/flutter_dotenv.dart';

final String kApiUrl = dotenv.env['API_URL'] ?? '';

final String kMinioUrl = dotenv.env['MINIO_URL'] ?? '';

final String? kSupportEmail = dotenv.env['SUPPORT_EMAIL'];

enum EstablishmentType { restaurant, activity }

enum EstablishmentSwiped { liked, disliked }

enum BottomNavigation { home, favorites, profile }
