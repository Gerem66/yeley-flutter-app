import 'package:yeley_frontend/commons/constants.dart';
import 'package:yeley_frontend/models/tag.dart';

class Establishment {
  final String id;
  final String name;
  final String fullAddress;
  final List<Tag> tags;
  // Long lat
  final List<double> coordinates;
  final List<String> picturesPaths;
  final int likes;
  final String phone;
  final EstablishmentType type;
  final String price;
  final String capacity;
  final String about;
  final String schedules;
  final String strongPoint;
  final String goodToKnow;
  final String forbiddenOnSite;

  const Establishment({
    required this.name,
    required this.id,
    required this.fullAddress,
    required this.tags,
    required this.coordinates,
    required this.picturesPaths,
    required this.likes,
    required this.phone,
    required this.type,
    required this.price,
    required this.capacity,
    required this.about,
    required this.schedules,
    required this.strongPoint,
    required this.goodToKnow,
    required this.forbiddenOnSite,
  });

  factory Establishment.fromJson(Map<String, dynamic> json) {
    return Establishment(
      id: json['id'],
      name: json['name'],
      fullAddress: json['fullAddress'],
      tags: Tag.fromJsons(json['tags']),
      coordinates: List<double>.from(json['coordinates']),
      picturesPaths: List<String>.from(json['picturesPaths']),
      likes: json['likes'],
      phone: json['phone'],
      type: EstablishmentType.values.byName(json["type"]),
      price: json['price'],
      capacity: json['capacity'],
      about: json['about'],
      schedules: json['schedules'],
      strongPoint: json['strongPoint'],
      goodToKnow: json['goodToKnow'],
      forbiddenOnSite: json['forbiddenOnSite'],
    );
  }

  static Future<List<Establishment>> fromJsons(List<dynamic> jsons) async {
    final List<Establishment> establishments = [];
    for (Map<String, dynamic> json in jsons) {
      establishments.add(Establishment.fromJson(json));
    }
    return establishments;
  }
}
