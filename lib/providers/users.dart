// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:yeley_frontend/commons/constants.dart';
import 'package:yeley_frontend/commons/exception.dart';
import 'package:yeley_frontend/models/address.dart';
import 'package:yeley_frontend/models/establishment.dart';
import 'package:yeley_frontend/models/tag.dart';
import 'package:yeley_frontend/services/api.dart';
import 'package:yeley_frontend/services/local_storage.dart';

class UsersProvider extends ChangeNotifier {
  UsersProvider({
    this.address,
  });

  bool isDeleting = false;
  bool isSettingAddress = false;
  bool isTagsLoading = false;
  bool isNearbyEstablishmentsLoading = false;
  bool isCardSwiped = false;

  /// The current displayed page.
  /// Default value is home.
  BottomNavigation navigationIndex = BottomNavigation.home;

  /// Establishent displayed depend on the type selected (restaurant/activity).
  EstablishmentType establishmentType = EstablishmentType.restaurant;

  /// User address
  Address? address;

  /// Range to get nearby establishments in a circle, expressed in KM.
  /// Default value is 5.
  int range = 30;

  /// Tags from the database
  List<Tag>? restaurantsTags;
  List<Tag>? activitiesTags;

  bool isFavoritesEmptyForCurrentType() {
    if (establishmentType == EstablishmentType.restaurant) {
      return favoriteRestaurants != null && favoriteRestaurants!.isEmpty;
    } else if (establishmentType == EstablishmentType.activity) {
      return favoriteActivities != null && favoriteActivities!.isEmpty;
    }
    return true; // Default case, should never reach here
  }


  Future<void> onEstablishmentTypeSwitched(
    BuildContext context,
  ) async {
    if (establishmentType == EstablishmentType.restaurant) {
      establishmentType = EstablishmentType.activity;
      displayedTags = activitiesTags;
    } else {
      establishmentType = EstablishmentType.restaurant;
      displayedTags = restaurantsTags;
    }
    selectedTags = [];
    notifyListeners();
    await getNearbyEstablishments(context);
  }

  Future<void> getTags(
    BuildContext context,
  ) async {
    try {
      isTagsLoading = true;
      notifyListeners();
      final List<Tag> tags = await Api.getTags();

      restaurantsTags = [];
      activitiesTags = [];
      for (Tag tag in tags) {
        if (tag.type == EstablishmentType.restaurant) {
          restaurantsTags!.add(tag);
        } else {
          activitiesTags!.add(tag);
        }
      }
      displayedTags = restaurantsTags;
    } catch (exception) {
      String message;
      if (exception is ClientException) {
        message = 'Erreur de connexion (${exception.message})';
      } else {
        message = 'Erreur lors de la récupération des tags';
      }
      await ExceptionHelper.handle(
        context: context,
        exception: Message(message),
      );
    } finally {
      isTagsLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout(
    BuildContext context,
  ) async {
    try {
      // Clear the local storage
      await LocalStorageService().setString("JWT", "");
      await LocalStorageService().setString("user_email", "");
      await LocalStorageService().setString("user_created_at", "");
    } catch (e) {
      await ExceptionHelper.handle(
        context: context,
        exception: Message('Erreur de déconnexion (${e.toString()})'),
      );
    }

    Api.jwt = null;
    // The user is redirected on the signup page.
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/signup',
      (Route<dynamic> route) => false,
    );
  }

  // Address will be saved in the secure storage.
  Future<void> setAddress(
      String addressInput,
    BuildContext context,
    String postalCode,
    String city,
      List<Location> locationsInput
  ) async {
    try {
      isSettingAddress = true;
      notifyListeners();

      final String fullAddress = "$address, $postalCode $city, France";
      List<Location> locations = locationsInput;

      if (locations.isEmpty) {
        throw Error();
      }

      final List<double> coordinates = [locations.first.longitude, locations.first.latitude];
      address = Address(
        address: addressInput,
        city: city,
        postalCode: postalCode,
        fullAddress: fullAddress,
        coordinates: coordinates,
      );

      // User address is saved stringify and saved in local storage.
      await LocalStorageService().setString("address", jsonEncode(address!.toJson()));

      Navigator.pop(context);
    } catch (e) {
      await ExceptionHelper.handle(
        context: context,
        exception: Message('Aucune adresse ne correspond (${e.toString()})'),
      );
    } finally {
      isSettingAddress = false;
      notifyListeners();
    }
  }

  Future<void> getPhonePosition(BuildContext context) async {
    try {
      isSettingAddress = true;
      notifyListeners();

      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Error();
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Error();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Error();
      }

      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      address = Address(
        address: placemarks.first.street ?? "",
        city: placemarks.first.name ?? "",
        postalCode: placemarks.first.postalCode ?? "",
        fullAddress:
            "${placemarks.first.street ?? ""}, ${placemarks.first.postalCode ?? ""} ${placemarks.first.name ?? ""}, France",
        coordinates: [
          position.longitude,
          position.latitude,
        ],
      );

      // User address is saved stringify and saved in local storage.
      await LocalStorageService().setString("address", jsonEncode(address!.toJson()));
    } catch (e) {
      await ExceptionHelper.handle(
        context: context,
        exception: Message('Accès à la position du téléphone impossible (${e.toString()})'),
      );
    } finally {
      isSettingAddress = false;
      notifyListeners();
      Navigator.pop(context);
    }
  }

  void updateNavigationIndex(BottomNavigation index) {
    navigationIndex = index;
    notifyListeners();
  }

  Future<void> onBottomNavigationUpdated(BuildContext context, int index) async {
    final selectedNavigation = BottomNavigation.values[index];

    if (selectedNavigation == BottomNavigation.favorites) {
      navigationIndex = BottomNavigation.favorites;
      notifyListeners();

      if (address == null) {
        return;
      }

      await Future.wait([
        getNearbyFavoriteRestaurants(context),
        getNearbyFavoriteActivities(context),
      ]);

      if (favoriteActivities!.isNotEmpty || favoriteRestaurants!.isNotEmpty) {
        hasInitialyFavorites = true;
        notifyListeners();
      }
    } else if (selectedNavigation == BottomNavigation.home) {
      // Si on retourne à la page d'accueil, on rafraîchit toujours la liste
      navigationIndex = selectedNavigation;
      notifyListeners();

      if (address != null) {
        // Rafraîchir les établissements pour s'assurer d'exclure les établissements récemment likés/dislikés
        await getNearbyEstablishments(context);
      }
    } else {
      navigationIndex = selectedNavigation;
      notifyListeners();
    }
  }

  Future<void> deleteAccount(
    BuildContext context,
  ) async {
    try {
      isDeleting = true;
      notifyListeners();
      await Api.deleteUserAccount();
      // JWT is removed.
      await LocalStorageService().setString("JWT", "");
      // The user is redirected on the signup page.
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/signup',
        (Route<dynamic> route) => false,
      );
    } catch (exception) {
      await ExceptionHelper.handle(context: context, exception: exception);
    } finally {
      isDeleting = false;
      notifyListeners();
    }
  }

  Future<void> onRangeUpdated(BuildContext context, int newRange) async {
    range = newRange;
    notifyListeners();

    if (navigationIndex == BottomNavigation.home) {
      await getNearbyEstablishments(context);
    } else {
      await Future.wait([
        getNearbyFavoriteRestaurants(context),
        getNearbyFavoriteActivities(context),
      ]);
    }
  }

  /// --- Home ---

  /// The selected tags, default restaurant ones.
  List<Tag>? displayedTags;

  /// Tags selected by the user.
  List<Tag> selectedTags = [];

  /// Displayed establishment
  List<Establishment>? displayedEstablishments;

  /// Use for the front card animation
  Offset frontCardPosition = Offset.zero;

  /// Define int the init state.
  /// Used for the front card animation
  Size screenSize = Size.zero;

  double angle = 0;

  void onUpdatePosition(DragUpdateDetails details) {
    frontCardPosition += details.delta;

    double x = frontCardPosition.dx;
    angle = 45 * x / screenSize.width;

    notifyListeners();
  }

  void onEndPosition(BuildContext context, DragEndDetails details) async {
    isCardSwiped = true;
    if (frontCardPosition.dx >= 100) {
      angle = 20;
      onCardButtonSwiped(context, EstablishmentSwiped.liked);
    } else if (frontCardPosition.dx <= -100) {
      angle = -20;
      onCardButtonSwiped(context, EstablishmentSwiped.disliked);
    } else {
      frontCardPosition = Offset.zero;
      angle = 0;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 200));
      isCardSwiped = false;
    }
  }

  Future<void> onCardButtonSwiped(
    BuildContext context,
    EstablishmentSwiped status,
  ) async {
    if (displayedEstablishments == null || displayedEstablishments!.isEmpty) {
      return;
    }

    /// Récupérer l'établissement actuel avant de continuer
    final currentEstablishment = displayedEstablishments!.first;

    /// Used for the animation time.
    isCardSwiped = true;

    /// Set the end position of the animation.
    frontCardPosition += status == EstablishmentSwiped.liked
        ? Offset(2 * screenSize.width, 2 * screenSize.width)
        : Offset(-2 * screenSize.width, 2 * screenSize.width);
    notifyListeners();

    try {
      if (status == EstablishmentSwiped.liked) {
        await Api.like(currentEstablishment);

        // Force une requête pour rafraîchir les favoris si nous sommes sur la page des favoris
        if (navigationIndex == BottomNavigation.favorites) {
          if (establishmentType == EstablishmentType.restaurant) {
            await getNearbyFavoriteRestaurants(context);
          } else {
            await getNearbyFavoriteActivities(context);
          }
        }
      } else {
        // Pour les swipes gauche, on utilise dislike() pour ajouter l'établissement à unlikedEstablishments
        await Api.dislike(currentEstablishment);
      }
    } catch (e) {
      // En cas d'erreur, on affiche un message mais on continue l'animation
      await ExceptionHelper.handle(
        context: context,
        exception: Message('Erreur lors de l\'action: ${e.toString()}'),
      );
    }

    /// Wait for the animation to complete
    await Future.delayed(const Duration(milliseconds: 200));

    // Supprimer l'établissement de la liste locale seulement s'il est encore le premier
    if (displayedEstablishments != null && 
        displayedEstablishments!.isNotEmpty && 
        displayedEstablishments!.first.id == currentEstablishment.id) {
      displayedEstablishments!.removeAt(0);
    }

    /// Reset the position for the next card.
    frontCardPosition = Offset.zero;
    isCardSwiped = false;
    angle = 0;
    notifyListeners();
  }

  Future<void> onHomeTagTap(BuildContext context, Tag tag, bool isSelected) async {
    if (isSelected) {
      selectedTags.add(tag);
    } else {
      selectedTags.remove(tag);
    }
    notifyListeners();
    await getNearbyEstablishments(context);
  }

  Future<void> getNearbyEstablishments(
    BuildContext context,
  ) async {
    try {
      // Since the function is call during the init state, the address might be null at this moment (if first time using app).
      if (address == null) {
        return;
      }
      isNearbyEstablishmentsLoading = true;
      notifyListeners();
      displayedEstablishments = await Api.getNearbyEstablishments(
        range,
        address!.coordinates,
        establishmentType,
        selectedTags,
      );
    } catch (exception) {
      await ExceptionHelper.handle(context: context, exception: exception);
    } finally {
      isNearbyEstablishmentsLoading = false;
      notifyListeners();
    }
  }

  /// --- Favorites ---
  bool isNearbyFavoriteRestaurantsLoading = false;
  bool isNearbyFavoriteActivitiesLoading = false;

  /// Selected tags
  List<Tag> favoriteSelectedRestaurantsTags = [];
  List<Tag> favoriteSelectedActivitiesTags = [];

  List<Establishment>? favoriteRestaurants;
  List<Establishment>? favoriteActivities;

  /// Prevent error displayed "not favorites" if you select a tag and the search return a empty list.
  bool hasInitialyFavorites = false;

  bool isFavoritesNull() {
    return favoriteRestaurants == null || favoriteActivities == null;
  }

  bool isFavoritesEmpty() {
    /// Mean that the favorites were already loaded once.
    if (hasInitialyFavorites) {
      return false;
    }

    return favoriteRestaurants!.isEmpty || favoriteActivities!.isEmpty;
  }

  Future<void> onFavoriteTagTap(BuildContext context, Tag tag, bool isSelected) async {
    if (isSelected) {
      if (tag.type == EstablishmentType.restaurant) {
        favoriteSelectedRestaurantsTags.add(tag);
      } else {
        favoriteSelectedActivitiesTags.add(tag);
      }
    } else {
      if (tag.type == EstablishmentType.restaurant) {
        favoriteSelectedRestaurantsTags.remove(tag);
      } else {
        favoriteSelectedActivitiesTags.remove(tag);
      }
    }
    notifyListeners();
    if (tag.type == EstablishmentType.restaurant) {
      await getNearbyFavoriteRestaurants(context);
    } else {
      await getNearbyFavoriteActivities(context);
    }
  }

  Future<void> getNearbyFavoriteRestaurants(context) async {
    try {
      if (address == null) {
        return;
      }
      isNearbyFavoriteRestaurantsLoading = true;
      notifyListeners();
      favoriteRestaurants = await Api.getNearbyEstablishments(
        range,
        address!.coordinates,
        EstablishmentType.restaurant,
        favoriteSelectedRestaurantsTags,
        favorite: true,
      );
    } catch (exception) {
      await ExceptionHelper.handle(context: context, exception: exception);
    } finally {
      isNearbyFavoriteRestaurantsLoading = false;
      notifyListeners();
    }
  }

  Future<void> getNearbyFavoriteActivities(context) async {
    try {
      if (address == null) {
        return;
      }
      isNearbyFavoriteActivitiesLoading = true;
      notifyListeners();
      favoriteActivities = await Api.getNearbyEstablishments(
        range,
        address!.coordinates,
        EstablishmentType.activity,
        favoriteSelectedActivitiesTags,
        favorite: true,
      );
    } catch (exception) {
      await ExceptionHelper.handle(context: context, exception: exception);
    } finally {
      isNearbyFavoriteActivitiesLoading = false;
      notifyListeners();
    }
  }
}
