// ignore_for_file: use_build_context_synchronously

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:yeley_frontend/commons/constants.dart';
import 'package:yeley_frontend/commons/decoration.dart';
import 'package:yeley_frontend/models/establishment.dart';
import 'package:yeley_frontend/models/tag.dart';
import 'package:yeley_frontend/pages/address_form.dart';
import 'package:yeley_frontend/providers/users.dart';
import 'package:yeley_frontend/services/api.dart';
import 'package:yeley_frontend/services/local_storage.dart';
import 'package:yeley_frontend/widgets/custom_background.dart';
import 'package:yeley_frontend/widgets/dialogs/account_dialogs.dart';
import 'package:yeley_frontend/widgets/responsive_navigation_bar.dart';
import 'package:yeley_frontend/widgets/establishment_card.dart';
import 'package:yeley_frontend/widgets/favorite_establishment_card.dart';
import 'package:yeley_frontend/widgets/tag_chip.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isRestaurant = true;
  final _switchController = ValueNotifier<bool>(true);
  final _bottomBarController = ValueNotifier<bool>(true);
  final GlobalKey _kmInkWellKey = GlobalKey();
  int _range = 30;

  // Ajout des variables pour l'animation du header
  late ScrollController _favoritesScrollController;
  bool _isHeaderVisible = true;
  double _headerHeight = 0;
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();

    // Initialisation du ScrollController pour la page des favoris
    _favoritesScrollController = ScrollController();
    _favoritesScrollController.addListener(_scrollListener);

    /// Set listener for the switch button (cf the package).
    _switchController.addListener(() async {
      // Réinitialiser l'affichage du header lors du changement de catégorie
      setState(() {
        isRestaurant = _switchController.value;
        _isHeaderVisible = true;
        _lastScrollOffset = 0;
        if (_favoritesScrollController.hasClients) {
          _favoritesScrollController.jumpTo(0);
        }
      });
      await context.read<UsersProvider>().onEstablishmentTypeSwitched(context);
    });

    _bottomBarController.addListener(() async {
      await context.read<UsersProvider>().onBottomNavigationUpdated(context, 0);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final usersProvider = context.read<UsersProvider>();

      /// Define the screen size.
      usersProvider.screenSize = MediaQuery.of(context).size;

      /// Fetch data
      Future.wait([
        usersProvider.getTags(context),
        usersProvider.getNearbyEstablishments(context),
      ]);
    });
  }

  @override
  void dispose() {
    _favoritesScrollController.removeListener(_scrollListener);
    _favoritesScrollController.dispose();
    super.dispose();
  }

  // Méthode qui gère l'affichage/masquage du header en fonction du défilement
  void _scrollListener() {
    final UsersProvider provider = context.read<UsersProvider>();
    double currentScrollOffset = _favoritesScrollController.offset;

    // Calcul de la hauteur du header si elle n'est pas encore définie
    if (_headerHeight == 0) {
      _headerHeight = 110; // Hauteur approximative du switch + tags
    }

    // Vérifier s'il y a plus de 3 établissements dans la liste actuelle
    bool hasMoreThanThreeEstablishments = false;
    if (isRestaurant && provider.favoriteRestaurants != null) {
      hasMoreThanThreeEstablishments = provider.favoriteRestaurants!.length > 3;
    } else if (!isRestaurant && provider.favoriteActivities != null) {
      hasMoreThanThreeEstablishments = provider.favoriteActivities!.length > 3;
    }

    // Ne pas masquer le header s'il y a 3 établissements ou moins
    if (!hasMoreThanThreeEstablishments) {
      if (!_isHeaderVisible) {
        setState(() {
          _isHeaderVisible = true;
        });
      }
      return;
    }

    // Déterminer si on scrolle vers le bas ou vers le haut
    bool isScrollingDown = currentScrollOffset > _lastScrollOffset;

    // Seuil à partir duquel le header est visible (proche du haut)
    // On va utiliser un seuil de 100 pixels du haut pour afficher le header
    final bool isNearTop = currentScrollOffset < 100;

    // Si on scrolle vers le bas et que le header est visible, on le cache
    if (isScrollingDown && _isHeaderVisible && currentScrollOffset > 20) {
      setState(() {
        _isHeaderVisible = false;
      });
    }

    // On affiche le header uniquement si on est près du haut de la page
    else if (isNearTop && !_isHeaderVisible) {
      setState(() {
        _isHeaderVisible = true;
      });
    }

    // Si on n'est pas près du haut et qu'on scrolle vers le haut, on garde le header caché
    else if (!isNearTop && !isScrollingDown && !_isHeaderVisible) {
      // Ne rien faire - le header reste caché
    }

    _lastScrollOffset = currentScrollOffset;
  }

  Widget _buildTopBar() {
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          const Spacer(),
          if (context.watch<UsersProvider>().navigationIndex == BottomNavigation.home ||
              context.watch<UsersProvider>().navigationIndex == BottomNavigation.favorites)
            Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(
                  Radius.circular(50),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 3,
                    blurRadius: 3,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: AdvancedSwitch(
                controller: _switchController,
                thumb: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    decoration: BoxDecoration(
                      color: kMainGreen.withValues(alpha: 0.2),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(50),
                      ),
                    ),
                    child: Icon(
                      isRestaurant == true ? Icons.sports_basketball_outlined : Icons.fastfood_outlined,
                      color: kMainGreen,
                      size: 25,
                    ),
                  ),
                ),
                activeColor: Colors.white,
                inactiveColor: Colors.white,
                activeChild: Padding(
                  padding: const EdgeInsets.only(left: 7.5, top: 5, right: 5, bottom: 5),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: kMainGreen,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.fastfood_outlined,
                          color: Colors.white,
                          size: 23,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'Restaurants',
                          style: kRegular16.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                inactiveChild: Padding(
                  padding: const EdgeInsets.only(left: 7.5, top: 5, right: 5, bottom: 5),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: kMainGreen,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Activités',
                          style: kRegular16.copyWith(color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.sports_basketball_outlined,
                          color: Colors.white,
                          size: 23,
                        ),
                      ],
                    ),
                  ),
                ),
                borderRadius: const BorderRadius.all(Radius.circular(50)),
                width: 200,
                height: 50,
                enabled: true,
                initialValue: true,
              ),
            ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final UsersProvider userProvider = context.watch<UsersProvider>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(15),
            bottomLeft: Radius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(width: 15),
                  Text(
                    "Adresse",
                    style: kRegular14.copyWith(color: Colors.grey),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_outlined,
                    color: Colors.grey,
                  ),
                ],
              ),
              Row(
                children: [
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.location_on_outlined,
                    color: kMainGreen,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    userProvider.address == null
                        ? ""
                        : (userProvider.address!.address.length > 20
                            ? '${userProvider.address!.address.substring(0, 20)}...'
                            : userProvider.address!.address),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: kRegular16.copyWith(color: Colors.black),
                  ),
                  const SizedBox(width: 5),
                ],
              ),
            ],
          ),
          onTap: () async {
            await showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              ),
              isScrollControlled: true, // Permet de contrôler la hauteur du ModalBottomSheet
              builder: (context) {
                return SizedBox(
                  height: MediaQuery.of(context).size.height * 0.8, // Définit la hauteur à 80% de la hauteur de l'écran
                  child: const AddressFormPage(),
                );
              },
            );

            UsersProvider provider = context.read<UsersProvider>();
            if (provider.navigationIndex == BottomNavigation.home) {
              await provider.getNearbyEstablishments(context);
            } else {
              await Future.wait([
                provider.getNearbyEstablishments(context),
                provider.getNearbyFavoriteRestaurants(context),
                provider.getNearbyFavoriteActivities(context),
              ]);
            }
          },
        ),
        Padding(
          padding: const EdgeInsets.only(right: 15),
          child: InkWell(
            key: _kmInkWellKey,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(15),
              bottomRight: Radius.circular(15),
            ),
            onTap: () async {
              RenderBox box =
                  _kmInkWellKey.currentContext!.findRenderObject() as RenderBox;
              Offset position = box.localToGlobal(Offset.zero);
              await showMenu(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                context: context,
                position: RelativeRect.fromLTRB(position.dx, position.dy + 50, 0, 0),
                items: [
                  PopupMenuItem<int>(
                    value: 5,
                    onTap: () async {
                      setState(() {
                        _range = 5;
                      });
                      await context
                          .read<UsersProvider>()
                          .onRangeUpdated(context, _range);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '5',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                        Divider(color: Colors.grey[300], thickness: 1),
                      ],
                    ),
                  ),
                  PopupMenuItem<int>(
                    value: 10,
                    onTap: () async {
                      setState(() {
                        _range = 10;
                      });
                      await context
                          .read<UsersProvider>()
                          .onRangeUpdated(context, _range);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '10',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                        Divider(color: Colors.grey[300], thickness: 1),
                      ],
                    ),
                  ),
                  PopupMenuItem<int>(
                    value: 20,
                    onTap: () async {
                      setState(() {
                        _range = 20;
                      });
                      await context
                          .read<UsersProvider>()
                          .onRangeUpdated(context, _range);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '20',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                        Divider(color: Colors.grey[300], thickness: 1),
                      ],
                    ),
                  ),
                  PopupMenuItem<int>(
                    padding: const EdgeInsets.only(bottom: 0),
                    value: 30,
                    onTap: () async {
                      setState(() {
                        _range = 30;
                      });
                      await context
                          .read<UsersProvider>()
                          .onRangeUpdated(context, _range);
                    },
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '30',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                        Visibility(
                          visible: true,
                          child: Divider(color: Colors.white, thickness: 1),
                        )
                      ],
                    ),
                  ),
                ],
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "Km",
                      style: kRegular14.copyWith(color: Colors.grey),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_outlined,
                      color: Colors.grey,
                    )
                  ],
                ),
                Text(
                  "$_range Km",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: kRegular16.copyWith(color: Colors.black),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTags() {
    final UsersProvider usersProvider = context.watch<UsersProvider>();
    if (usersProvider.displayedTags == null || usersProvider.isTagsLoading) {
      return const SizedBox(
        height: 50,
        child: Center(
          child: CircularProgressIndicator(color: kMainGreen),
        ),
      );
    }

    final List<Tag> selectedTags = context.read<UsersProvider>().selectedTags;
    final List<Widget> tagChips = [];

    /// Left padding
    tagChips.add(const SizedBox(
      width: 15,
    ));

    for (final Tag tag in usersProvider.displayedTags!) {
      // Due to front rebuild issues, the state cannot be save in the widget, but defined thanks to the provider.
      // When the state was in the widget, if you were switching from restaurants to activities, the restaurants selected tags
      // would make the activies ones selected too, but only on the front displayed, not in the provider side.
      bool isSelected = false;
      for (Tag selectedTag in selectedTags) {
        if (tag.id == selectedTag.id) {
          isSelected = true;
          break;
        }
      }

      tagChips.add(Padding(
        // The row cut the shadow, so i set some padding to fix it.
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: TagChip(
          tag: tag,
          isSelected: isSelected,
          onTap: (isSelected) async {
            await context.read<UsersProvider>().onHomeTagTap(context, tag, !isSelected);
          },
        ),
      ));
      final isFirst = tagChips.isEmpty;
      if (!isFirst) {
        tagChips.add(const SizedBox(
          width: 10,
        ));
      }
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: tagChips,
        ),
      ),
    );
  }

  Widget _buildNoEstablishmentFoundMessage() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset("assets/no_establishments.svg"),
            const SizedBox(height: 40),
            const Text(
              "Aucun établissement.",
              style: kBold22,
            ),
            const SizedBox(height: 15),
            Text(
              "Vous n'avez aucun établissement autours de vous pour le moment.",
              style: kRegular14.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoFavoritesMessage() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              "assets/no_favorites.svg",
            ),
            const SizedBox(height: 40),
            const Text(
              "Aucun favoris.",
              style: kBold22,
            ),
            const SizedBox(height: 15),
            Text(
              "Vous n'avez rien sur votre liste pour le moment.",
              style: kRegular14.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressUndefinedMessage() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/no_establishments.png"),
            const SizedBox(height: 15),
            const Text(
              "Où êtes-vous ?",
              style: kBold22,
            ),
            const SizedBox(height: 5),
            Text(
              "Remplissez votre adresse pour accéder aux établissements autour de vous !",
              style: kRegular14.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await Navigator.pushNamed(context, '/address-form');
                UsersProvider provider = context.read<UsersProvider>();
                if (provider.navigationIndex == BottomNavigation.home) {
                  await provider.getNearbyEstablishments(context);
                } else {
                  await Future.wait([
                    provider.getNearbyEstablishments(context),
                    provider.getNearbyFavoriteRestaurants(context),
                    provider.getNearbyFavoriteActivities(context),
                  ]);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: kMainGreen, shape: const StadiumBorder()),
              child: Text(
                "Définir mon adresse",
                style: kBold16.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstablishmentCards() {
    final UsersProvider userProvider = context.watch<UsersProvider>();
    final List<Establishment> establishments = userProvider.displayedEstablishments!;

    final List<Widget> establishmentCards = [];

    /// We have to loop reversely, so that the first element of the list well be displayed first, since we are using Stack widget bellow.
    /// Without the reverse loop, the first element would be the first one draw (so the last one visible, since other elements will be display on the top of it).
    ///
    /// The ternary limit the build element to 2 maximum, to avoid performances issues.
    for (int i = establishments.length < 2 ? establishments.length - 1 : 1; i >= 0; i--) {
      if (i == 0) {
        final Duration milliseconds = Duration(milliseconds: userProvider.isCardSwiped ? 400 : 0);
        final Offset position = userProvider.frontCardPosition;

        establishmentCards.add(
          LayoutBuilder(builder: (context, constraint) {
            final Offset center = constraint.smallest.center(Offset.zero);
            final double angle = userProvider.angle * pi / 180;
            final Matrix4 rotatedMatrix = Matrix4.identity()
              ..translate(center.dx, center.dy)
              ..rotateZ(angle)
              ..translate(-center.dx, -center.dy);

            return AnimatedContainer(
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
              duration: milliseconds,
              curve: Curves.easeInOut,
              transform: rotatedMatrix..translate(position.dx, position.dy),
              child: GestureDetector(
                onPanUpdate: (details) {
                  userProvider.onUpdatePosition(details);
                },
                onPanEnd: (details) {
                  userProvider.onEndPosition(context, details);
                },
                child: EstablishmentCard(
                  key: UniqueKey(),
                  establishment: establishments[i],
                ),
              ),
            );
          }),
        );
      } else {
        establishmentCards.add(EstablishmentCard(key: UniqueKey(), establishment: establishments[i]));
      }
    }

    /// Dislike and like button
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Stack(children: [
          ...establishmentCards,
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20, top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(100),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          spreadRadius: 3,
                          blurRadius: 3,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                    child: Material(
                      borderRadius: const BorderRadius.all(
                        Radius.circular(100),
                      ),
                      child: InkWell(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(100),
                          ),
                          onTap: () async {
                            await context
                                .read<UsersProvider>()
                                .onCardButtonSwiped(context, EstablishmentSwiped.disliked);
                          },
                          child: const Center(
                            child: Text(
                              "🥱",
                              style: TextStyle(fontSize: 45),
                            ),
                          )),
                    ),
                  ),
                  const SizedBox(width: 35),
                  Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(100),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          spreadRadius: 3,
                          blurRadius: 3,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                    child: Material(
                      borderRadius: const BorderRadius.all(
                        Radius.circular(100),
                      ),
                      child: InkWell(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(100),
                        ),
                        onTap: () async {
                          await context.read<UsersProvider>().onCardButtonSwiped(context, EstablishmentSwiped.liked);
                        },
                        child: const Center(
                          child: Text(
                            "🤩",
                            style: TextStyle(fontSize: 45),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return ResponsiveNavigationBarWidget(
      onIndexChanged: (index) {
        // Convertir l'index (int) en valeur d'énumération BottomNavigation
        final selectedNavigation = BottomNavigation.values[index];

        // Réinitialise l'état du header quand on change d'onglet vers favoris
        if (selectedNavigation == BottomNavigation.favorites && 
            context.read<UsersProvider>().navigationIndex != BottomNavigation.favorites) {
          setState(() {
            _isHeaderVisible = true;
            _lastScrollOffset = 0;
            if (_favoritesScrollController.hasClients) {
              _favoritesScrollController.jumpTo(0);
            }
          });
        }
        context.read<UsersProvider>().onBottomNavigationUpdated(context, index);
      },
    );
  }

  Widget _buildFavoriteCards() {
    final UsersProvider provider = context.read<UsersProvider>();
    final List<Widget> restaurantFavoriteTagChips = [];
    final List<Widget> activityFavoriteTagChips = [];
    final bool isAddressUndefined = provider.address == null;

    /// Left padding
    restaurantFavoriteTagChips.add(const SizedBox(
      width: 15,
    ));
    activityFavoriteTagChips.add(const SizedBox(
      width: 15,
    ));

    /// Restaurants tags
    if (provider.restaurantsTags != null) {
      for (final Tag tag in provider.restaurantsTags!) {
        bool isSelected = false;
        for (Tag selectedTag in provider.favoriteSelectedRestaurantsTags) {
          if (tag.id == selectedTag.id) {
            isSelected = true;
            break;
          }
        }

        restaurantFavoriteTagChips.add(Padding(
          // The row cut the shadow, so i set some padding to fix it.
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: TagChip(
            tag: tag,
            isSelected: isSelected,
            onTap: (isSelected) async {
              await context.read<UsersProvider>().onFavoriteTagTap(context, tag, !isSelected);
            },
          ),
        ));
        final isFirst = restaurantFavoriteTagChips.isEmpty;
        if (!isFirst) {
          restaurantFavoriteTagChips.add(const SizedBox(
            width: 10,
          ));
        }
      }
    }

    /// Activities tags
    if (provider.activitiesTags != null) {
      for (final Tag tag in provider.activitiesTags!) {
        bool isSelected = false;
        for (Tag selectedTag in provider.favoriteSelectedActivitiesTags) {
          if (tag.id == selectedTag.id) {
            isSelected = true;
            break;
          }
        }

        activityFavoriteTagChips.add(Padding(
          // The row cut the shadow, so i set some padding to fix it.
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: TagChip(
            tag: tag,
            isSelected: isSelected,
            onTap: (isSelected) async {
              await context.read<UsersProvider>().onFavoriteTagTap(context, tag, !isSelected);
            },
          ),
        ));
        final isFirst = activityFavoriteTagChips.isEmpty;
        if (!isFirst) {
          activityFavoriteTagChips.add(const SizedBox(
            width: 10,
          ));
        }
      }
    }

    // Animation du header (switch + tags) avec effet de translation
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header avec animation améliorée utilisant SlideTransition pour une animation fluide
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isHeaderVisible ? 75 : 0,
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Tags
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: isRestaurant ? restaurantFavoriteTagChips : activityFavoriteTagChips,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),
          // Contenu
          isAddressUndefined
              ? _buildAddressUndefinedMessage()
              : Expanded(
                  child: Column(
                    children: [
                      if (provider.isFavoritesNull())
                        const Expanded(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: kMainGreen,
                            ),
                          ),
                        )
                      else if (provider.isFavoritesEmptyForCurrentType())
                        _buildNoFavoritesMessage()
                      else
                        isRestaurant ? _buildFavoriteRestaurants() : _buildFavoriteActivities(),
                    ],
                  )),
        ],
      ),
    );
  }

  Widget _buildFavoriteRestaurants() {
    final UsersProvider provider = context.read<UsersProvider>();

    return provider.isNearbyFavoriteRestaurantsLoading
        ? const Expanded(
            child: Center(
              child: CircularProgressIndicator(color: kMainGreen),
            ),
          )
        : Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await provider.getNearbyFavoriteRestaurants(context);
              },
              color: kMainGreen,
              child: ListView.builder(
                controller: _favoritesScrollController,
                key: ValueKey('favorite_restaurants_${provider.favoriteRestaurants!.length}'),
                itemCount: provider.favoriteRestaurants!.length,
                itemBuilder: (context, index) {
                  final establishment = provider.favoriteRestaurants![index];
                  return FavoriteEstablishmentCard(
                    key: ValueKey('favorite_restaurant_${establishment.id}'),
                    establishment: establishment,
                    onDeleted: () async {
                      // Sauvegarder la position actuelle du défilement
                      final double currentScrollPosition = _favoritesScrollController.offset;
                      final bool wasHeaderVisible = _isHeaderVisible;

                      // Rafraîchir la liste après suppression sans utiliser "await" pour éviter le rebuild immédiat
                      provider.getNearbyFavoriteRestaurants(context).then((_) {
                        if (!mounted) return;

                        // Attendre que le build soit terminé avant de restaurer la position de défilement
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;

                          setState(() {
                            // Forcer l'affichage du header si moins de 4 établissements
                            if (provider.favoriteRestaurants != null && provider.favoriteRestaurants!.length <= 3) {
                              _isHeaderVisible = true;
                            } else {
                              // Sinon conserver l'état précédent du header
                              _isHeaderVisible = wasHeaderVisible;
                            }
                          });

                          // Restaurer la position de défilement après un court délai
                          Future.delayed(const Duration(milliseconds: 100), () {
                            if (!mounted || !_favoritesScrollController.hasClients) return;

                            final double maxScrollExtent = _favoritesScrollController.position.maxScrollExtent;
                            if (currentScrollPosition > maxScrollExtent) {
                              _favoritesScrollController.jumpTo(maxScrollExtent > 0 ? maxScrollExtent : 0);
                            } else {
                              _favoritesScrollController.jumpTo(currentScrollPosition);
                            }
                          });
                        });
                      });
                    },
                  );
                },
              ),
            ));
  }

  Widget _buildFavoriteActivities() {
    final UsersProvider provider = context.read<UsersProvider>();

    return provider.isNearbyFavoriteActivitiesLoading
        ? const Expanded(
            child: Center(
              child: CircularProgressIndicator(
                color: kMainGreen,
              ),
            ),
          )
        : Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await provider.getNearbyFavoriteActivities(context);
              },
              color: kMainGreen,
              child: ListView.builder(
                controller: _favoritesScrollController,
                key: ValueKey('favorite_activities_${provider.favoriteActivities!.length}'),
                itemCount: provider.favoriteActivities!.length,
                itemBuilder: (context, index) {
                  final establishment = provider.favoriteActivities![index];
                  return FavoriteEstablishmentCard(
                    key: ValueKey('favorite_activity_${establishment.id}'),
                    establishment: establishment,
                    onDeleted: () async {
                      // Sauvegarder la position actuelle du défilement
                      final double currentScrollPosition = _favoritesScrollController.offset;
                      final bool wasHeaderVisible = _isHeaderVisible;

                      // Rafraîchir la liste après suppression sans utiliser "await" pour éviter le rebuild immédiat
                      provider.getNearbyFavoriteActivities(context).then((_) {
                        if (!mounted) return;

                        // Attendre que le build soit terminé avant de restaurer la position de défilement
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;

                          setState(() {
                            // Forcer l'affichage du header si moins de 4 établissements
                            if (provider.favoriteActivities != null && provider.favoriteActivities!.length <= 3) {
                              _isHeaderVisible = true;
                            } else {
                              // Sinon conserver l'état précédent du header
                              _isHeaderVisible = wasHeaderVisible;
                            }
                          });

                          // Restaurer la position de défilement après un court délai
                          Future.delayed(const Duration(milliseconds: 100), () {
                            if (!mounted || !_favoritesScrollController.hasClients) return;

                            final double maxScrollExtent = _favoritesScrollController.position.maxScrollExtent;
                            if (currentScrollPosition > maxScrollExtent) {
                              _favoritesScrollController.jumpTo(maxScrollExtent > 0 ? maxScrollExtent : 0);
                            } else {
                              _favoritesScrollController.jumpTo(currentScrollPosition);
                            }
                          });
                        });
                      });
                    },
                  );
                },
              ),
            ));
  }

  @override
  Widget build(BuildContext context) {
    final UsersProvider userProvider = context.watch<UsersProvider>();
    final bool isAddressUndefined = userProvider.address == null;

    if (userProvider.navigationIndex == BottomNavigation.home) {
      return CustomBackground(
        child: Container(
          color: Colors.transparent,
          child: SafeArea(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Padding(
                padding: const EdgeInsets.symmetric(vertical: 0),
                child: Column(
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: _buildTopBar(),
                    ),
                    const SizedBox(height: 5),
                    isAddressUndefined
                        ? _buildAddressUndefinedMessage()
                        : Expanded(
                            child: Column(
                              children: [
                                _buildTags(),
                                const SizedBox(height: 15),
                                userProvider.displayedEstablishments == null ||
                                        userProvider.isNearbyEstablishmentsLoading
                                    ? const Expanded(
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: kMainGreen,
                                          ),
                                        ),
                                      )
                                    : userProvider.displayedEstablishments!.isEmpty
                                        ? _buildNoEstablishmentFoundMessage()
                                        : _buildEstablishmentCards(),
                              ],
                            ),
                          ),
                    const SizedBox(height: 15), // Added to create space above the navigation bar
                    _buildBottomNavigationBar(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } else if (userProvider.navigationIndex == BottomNavigation.profile) {
      return CustomBackground(
          child: Container(
        color: Colors.transparent,
        child: SafeArea(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Padding(
                padding: const EdgeInsets.symmetric(vertical: 0),
                child: Column(
                  children: [
                    const Text("Mon compte", style: kBold22),
                    const SizedBox(height: 20),
                    
                    // Contenu défilable (sans les boutons)
                    Expanded(
                      child: Column(
                        children: [
                          // ScrollView contenant seulement les infos du profil
                          Expanded(
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 20),
                                    // Section informations juridiques
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 15),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          'Informations juridiques :',
                                          style: kBold18,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 24),
                                      child: Column(
                                        children: [
                                          ListTile(
                                            title: const Text('Politique de confidentialité'),
                                            onTap: () {
                                              Navigator.pushNamed(context, '/privacy-policy');
                                            },
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 42),
                                          ),
                                          ListTile(
                                            title: const Text('Conditions générales d\'utilisation'),
                                            onTap: () {
                                              Navigator.pushNamed(context, '/terms-of-use');
                                            },
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 42),
                                          ),
                                          ListTile(
                                            title: const Text('Mentions légales'),
                                            onTap: () {
                                              Navigator.pushNamed(context, '/legal-information');
                                            },
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 42),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Section Profil
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 15),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          'Mon profil :',
                                          style: kBold18,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    // Affichage des informations utilisateur
                                    Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 15),
                                      padding: const EdgeInsets.all(15),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(15),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withValues(alpha: 0.1),
                                            spreadRadius: 1,
                                            blurRadius: 5,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          // Statut de connexion
                                          Row(
                                            children: [
                                              const SizedBox(width: 5),
                                              const Icon(Icons.circle, color: kMainGreen, size: 14),
                                              const SizedBox(width: 15),
                                              FutureBuilder<bool>(
                                                future: Api.checkServerConnection(),
                                                builder: (context, snapshot) {
                                                  if (snapshot.connectionState == ConnectionState.done) {
                                                    final bool isConnected = snapshot.data ?? false;
                                                    return Text(
                                                      'Statut : ${isConnected ? 'Connecté' : 'Aucune connexion au serveur'}',
                                                      style: kRegular16,
                                                    );
                                                  }
                                                  return const Text('Statut : Vérification de la connexion...', style: kRegular16);
                                                },
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          // Email de l'utilisateur
                                          Row(
                                            children: [
                                              const Icon(Icons.email, color: kMainGreen),
                                              const SizedBox(width: 10),
                                              FutureBuilder<String?>(
                                                future: LocalStorageService().getString("user_email"),
                                                builder: (context, snapshot) {
                                                  // Tentative de récupération depuis le localStorage
                                                  if (snapshot.connectionState == ConnectionState.done && 
                                                      snapshot.hasData && 
                                                      snapshot.data != null && 
                                                      snapshot.data!.isNotEmpty) {
                                                    return Text(
                                                      'Email : ${snapshot.data}',
                                                      style: kRegular16,
                                                    );
                                                  } else {
                                                    // Fallback à l'email enregistré lors de la connexion si disponible
                                                    String email = "Non disponible";
                                                    return Text(
                                                      'Email : $email',
                                                      style: kRegular16,
                                                    );
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              const Icon(Icons.calendar_today, color: kMainGreen),
                                              const SizedBox(width: 10),
                                              FutureBuilder<String?>(
                                                future: LocalStorageService().getString("user_created_at"),
                                                builder: (context, snapshot) {
                                                  String displayText = 'Inscription : Date non disponible';
                                                  
                                                  if (snapshot.connectionState == ConnectionState.done && 
                                                      snapshot.hasData && 
                                                      snapshot.data != null && 
                                                      snapshot.data!.isNotEmpty) {
                                                    // Formatage de la date depuis le string ISO 8601 vers le format DD/MM/YYYY
                                                    try {
                                                      final DateTime createdAt = DateTime.parse(snapshot.data!);
                                                      final String formattedDate = '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
                                                      displayText = 'Inscription : $formattedDate';
                                                    } catch (e) {
                                                      displayText = 'Inscription : Date invalide';
                                                    }
                                                  }
                                                  
                                                  return Text(
                                                    displayText,
                                                    style: kRegular16,
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          // Boutons placés en bas de l'écran (hors de la ScrollView)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Column(
                              children: [
                                ElevatedButton(
                                  onPressed: () async {
                                    // Naviguer vers la page de mot de passe oublié
                                    final email = await LocalStorageService().getString("user_email");
                                    Navigator.pushNamed(
                                      context, 
                                      '/forgot-password',
                                      arguments: email != null ? {'email': email} : null,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      side: const BorderSide(color: kMainGreen),
                                    ),
                                  ),
                                  child: const Text(
                                    'Modifier mon mot de passe',
                                    style: TextStyle(color: kMainGreen),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                ElevatedButton(
                                  onPressed: () async {
                                    await AccountDialogs.showLogoutDialog(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      side: const BorderSide(color: kMainGreen),
                                    ),
                                  ),
                                  child: const Text(
                                    'Se déconnecter',
                                    style: TextStyle(color: kMainGreen),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                ElevatedButton(
                                  onPressed: () {
                                    AccountDialogs.showDeleteAccountDialog(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      side: const BorderSide(color: Colors.redAccent),
                                    ),
                                  ),
                                  child: const Text(
                                    'Supprimer mon compte',
                                    style: TextStyle(color: Colors.redAccent),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildBottomNavigationBar(),
                  ],
                )),
          ),
        ),
      ));
    } else if (userProvider.navigationIndex == BottomNavigation.favorites) {
      return CustomBackground(
          child: Container(
        color: Colors.transparent,
        child: SafeArea(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Padding(
              padding: const EdgeInsets.symmetric(vertical: 0),
              child: Column(children: [
                _buildSearchBar(),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: _buildTopBar(),
                ),
                const SizedBox(height: 5),
                _buildFavoriteCards(),
                const SizedBox(height: 5),
                _buildBottomNavigationBar()
              ]),
            ),
          ),
        ),
      ));
    }
    return Container();
  }
}
