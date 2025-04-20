import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:yeley_frontend/commons/constants.dart';
import 'package:yeley_frontend/commons/decoration.dart';
import 'package:yeley_frontend/models/establishment.dart';
import 'package:yeley_frontend/pages/picture.dart';
import 'package:yeley_frontend/providers/users.dart';
import 'package:yeley_frontend/services/api.dart';
import 'package:yeley_frontend/widgets/dialogs/establishment_dialogs.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/establishment_info_menu.dart';

class EstablishmentPage extends StatefulWidget {
  final Establishment establishment;
  const EstablishmentPage({super.key, required this.establishment});

  @override
  State<EstablishmentPage> createState() => _EstablishmentPageState();
}

class _EstablishmentPageState extends State<EstablishmentPage> {
  // Map pour suivre les erreurs d'images par chemin
  final Map<String, bool> _imageErrors = {};
  bool _isDeleting = false;

  // Méthode pour vérifier si l'établissement est dans les favoris
  bool _isInFavorites(UsersProvider usersProvider) {
    if (usersProvider.favoriteRestaurants != null) {
      for (var establishment in usersProvider.favoriteRestaurants!) {
        if (establishment.id == widget.establishment.id) {
          return true;
        }
      }
    }
    
    if (usersProvider.favoriteActivities != null) {
      for (var establishment in usersProvider.favoriteActivities!) {
        if (establishment.id == widget.establishment.id) {
          return true;
        }
      }
    }
    
    return false;
  }

  // Méthode pour supprimer un établissement des favoris
  Future<void> _unlikeEstablishment(BuildContext dialogContext) async {
    final scaffoldMessenger = ScaffoldMessenger.of(dialogContext);
    final String establishmentName = widget.establishment.name;
    final UsersProvider usersProvider = Provider.of<UsersProvider>(context, listen: false);

    try {
      if (!mounted) return;

      setState(() {
        _isDeleting = true;
      });

      // Appeler l'API pour "unlike" l'établissement
      await Api.unlike(widget.establishment);

      // Rafraîchir les listes de favoris en fonction du type d'établissement
      if (mounted) {
        if (widget.establishment.type == EstablishmentType.restaurant) {
          await usersProvider.getNearbyFavoriteRestaurants(context);
        } else {
          await usersProvider.getNearbyFavoriteActivities(context);
        }
      }

      // Afficher un message de confirmation
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text("$establishmentName retiré des favoris"),
          backgroundColor: kMainGreen,
          duration: const Duration(seconds: 2),
        ),
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isDeleting = false;
      });

      // Afficher un message d'erreur
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text("Erreur lors de la suppression du favori"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildInformations() {
    final UsersProvider usersProvider = context.read<UsersProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 3,
              blurRadius: 3,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.establishment.name,
                    style: kBold22.copyWith(
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.heart_fill,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "${widget.establishment.likes} J'aimes ",
                        style: kRegular16.copyWith(color: Colors.redAccent),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        height: 5,
                        width: 5,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), color: Colors.grey),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${(Geolocator.distanceBetween(
                          usersProvider.address!.coordinates[1],
                          usersProvider.address!.coordinates[0],
                          widget.establishment.coordinates[1],
                          widget.establishment.coordinates[0],
                        ) / 1000).toStringAsFixed(2)} Km ",
                        style: kRegular16.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        "€€",
                        style: kBold16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: widget.establishment.tags.map((e) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: Container(
                            decoration: BoxDecoration(
                                border: Border.all(
                                  color: kMainGreen,
                                ),
                                borderRadius: BorderRadius.circular(100),
                                color: kMainGreen.withValues(alpha: 0.1)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              child: Text(
                                e.value,
                                style: kBold14.copyWith(
                                  color: kMainGreen,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 45,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kMainGreen.withValues(alpha: 0.2),
                              shadowColor: Colors.transparent,
                              shape: const StadiumBorder(),
                              side: const BorderSide(color: kMainGreen),
                            ),
                            onPressed: () async {
                              final Uri url = Uri.parse(
                                'https://www.google.com/maps/search/?api=1&query=${widget.establishment.coordinates[1]},${widget.establishment.coordinates[0]}',
                              );

                              if (!await launchUrl(url)) {
                                throw Exception('Could not launch $url');
                              }
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(width: 5),
                                const Icon(
                                  CupertinoIcons.map,
                                  color: kMainGreen,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "Direction",
                                  style: kBold14.copyWith(
                                    color: kMainGreen,
                                  ),
                                ),
                                const SizedBox(width: 5),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: SizedBox(
                          height: 45,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kMainGreen,
                              shape: const StadiumBorder(),
                              shadowColor: Colors.transparent,
                            ),
                            onPressed: () async {
                              final Uri url = Uri.parse('tel:${widget.establishment.phone}');

                              if (!await launchUrl(url)) {
                                throw Exception('Could not launch $url');
                              }
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(width: 5),
                                const Icon(
                                  CupertinoIcons.phone_arrow_up_right,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "Réserver",
                                  style: kBold14.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 5),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: [
                      if (widget.establishment.about.isNotEmpty)
                        EstablishmentInfoMenu(
                          infoName: "À propos",
                          infoContent: widget.establishment.about,
                          icon: const Icon(CupertinoIcons.info, color: kMainGreen),
                        ),
                      if (widget.establishment.fullAddress.isNotEmpty)
                        EstablishmentInfoMenu(
                          infoName: "Adresse",
                          infoContent: widget.establishment.fullAddress,
                          icon: const Icon(Icons.location_on_outlined, color: kMainGreen),
                        ),
                      if (widget.establishment.schedules.isNotEmpty)
                        EstablishmentInfoMenu(
                          infoName: "Horaires",
                          infoContent: widget.establishment.schedules,
                          icon: const Icon(CupertinoIcons.clock_fill, color: kMainGreen),
                        ),
                      if (widget.establishment.strongPoint.isNotEmpty)
                        EstablishmentInfoMenu(
                          infoName: "Point fort",
                          infoContent: widget.establishment.strongPoint,
                          icon: const Icon(CupertinoIcons.heart_fill, color: Colors.red),
                        ),
                      if (widget.establishment.goodToKnow.isNotEmpty)
                        EstablishmentInfoMenu(
                          infoName: "Bon à savoir",
                          infoContent: widget.establishment.goodToKnow,
                          icon: const Icon(CupertinoIcons.lightbulb, color: Colors.amberAccent),
                        ),
                      if (widget.establishment.forbiddenOnSite.isNotEmpty)
                        EstablishmentInfoMenu(
                          infoName: "Interdit sur place",
                          infoContent: widget.establishment.forbiddenOnSite,
                          icon: const Icon(CupertinoIcons.clear, color: Colors.redAccent),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Bouton de suppression
            Positioned(
              top: 10,
              right: 10,
              child: Consumer<UsersProvider>(
                builder: (context, usersProvider, _) {
                  // N'afficher le bouton que si l'établissement est dans les favoris
                  if (!_isInFavorites(usersProvider)) {
                    return const SizedBox.shrink(); // Widget vide si pas dans les favoris
                  }
                  
                  return _isDeleting
                    ? Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                            height: 16, 
                            width: 16, 
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: () async {
                          final bool? result = await showDeleteEstablishmentDialog(
                            context: context,
                            establishment: widget.establishment,
                          );
                          
                          if (result == true && mounted) {
                            _unlikeEstablishment(context);
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.1),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                          ),
                        ),
                      );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour afficher une image de remplacement
  Widget _buildFallbackImage({double? height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.image_not_supported_outlined,
              color: kMainGreen,
              size: 42,
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.establishment.name,
                style: kRegular16.copyWith(color: Colors.grey[700]),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Méthode pour obtenir une image avec gestion d'erreur
  Widget _buildNetworkImage(String path, {BoxFit fit = BoxFit.cover, bool isMainImage = false}) {
    if (_imageErrors[path] == true) {
      return _buildFallbackImage(
        height: isMainImage ? MediaQuery.of(context).size.height * 0.35 : null
      );
    }

    return CachedNetworkImage(
      imageUrl: "$kMinioUrl/establishments/picture/$path",
      httpHeaders: {
        'Authorization': 'Bearer ${Api.jwt}'
      },
      fit: fit,
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: const Center(
          child: CircularProgressIndicator(color: kMainGreen),
        ),
      ),
      errorWidget: (context, url, error) {
        // Marquer cette image comme ayant une erreur
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _imageErrors[path] = true;
            });
          }
        });
        return _buildFallbackImage(
          height: isMainImage ? MediaQuery.of(context).size.height * 0.35 : null
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBackground,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  color: kScaffoldBackground,
                  width: double.infinity,
                ),
                SizedBox(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.35,
                  child: Container(
                    foregroundDecoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          Colors.black,
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [
                          0,
                          0.8,
                        ],
                      ),
                    ),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.5),
                          spreadRadius: 3,
                          blurRadius: 10,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      child: widget.establishment.picturesPaths.isEmpty
                          ? _buildFallbackImage(height: MediaQuery.of(context).size.height * 0.35)
                          : _buildNetworkImage(widget.establishment.picturesPaths.first, isMainImage: true),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                  child: SizedBox(
                    height: 60,
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 30),
                        Text(
                          'Détail de l\'établissement',
                          style: kBold22.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5, top: 150),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: _buildInformations(),
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.only(left: 25),
              child: Text("PHOTOS", style: kBold22),
            ),
            const SizedBox(height: 15),
            Builder(builder: (_) {
              List<Widget> children = [];
              
              if (widget.establishment.picturesPaths.isEmpty) {
                // S'il n'y a pas d'images, afficher un message
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      "Aucune photo disponible pour cet établissement",
                      style: kRegular16.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              for (int i = 0; i < widget.establishment.picturesPaths.length; i++) {
                String picturePath = widget.establishment.picturesPaths[i];
                children.add(Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () {
                      // Ne pas ouvrir le visualiseur si l'image a une erreur
                      if (_imageErrors[picturePath] == true) return;
                      
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => PicturePage(
                            picturePaths: widget.establishment.picturesPaths,
                            index: i,
                          ),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                        ),
                      );
                    },
                    child: Hero(
                      tag: "picture_$i",
                      child: Container(
                        height: (MediaQuery.of(context).size.width / 2) - 32,
                        width: (MediaQuery.of(context).size.width / 2) - 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.3),
                              spreadRadius: 3,
                              blurRadius: 3,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: _imageErrors[picturePath] == true
                              ? _buildFallbackImage()
                              : Image(
                                  fit: BoxFit.cover,
                                  image: CachedNetworkImageProvider(
                                    "$kMinioUrl/establishments/picture/$picturePath",
                                    headers: {'Authorization': 'Bearer ${Api.jwt}'},
                                    errorListener: (error) {
                                      if (mounted) {
                                        setState(() {
                                          _imageErrors[picturePath] = true;
                                        });
                                      }
                                    },
                                  ),
                                  errorBuilder: (context, error, stackTrace) {
                                    if (mounted && _imageErrors[picturePath] != true) {
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        setState(() {
                                          _imageErrors[picturePath] = true;
                                        });
                                      });
                                    }
                                    return _buildFallbackImage();
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) {
                                      return child;
                                    }
                                    return Container(
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: kMainGreen,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ),
                  ),
                ));
              }
              return Center(
                child: Wrap(
                  children: children,
                ),
              );
            }),
            const SizedBox(height: 20), // Espace en bas de page
          ],
        ),
      ),
    );
  }
}
