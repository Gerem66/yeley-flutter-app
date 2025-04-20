import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:yeley_frontend/commons/decoration.dart';
import 'package:yeley_frontend/widgets/dialogs/establishment_dialogs.dart';

import '../commons/constants.dart';
import '../models/establishment.dart';
import '../pages/establishment.dart';
import '../services/api.dart';

class FavoriteEstablishmentCard extends StatefulWidget {
  final Establishment establishment;
  final Function? onDeleted;

  const FavoriteEstablishmentCard({
    super.key,
    required this.establishment,
    this.onDeleted,
  });

  @override
  FavoriteEstablishmentCardState createState() => FavoriteEstablishmentCardState();
}

class FavoriteEstablishmentCardState extends State<FavoriteEstablishmentCard> {
  bool _isDeleting = false;
  bool _imageError = false;

  @override
  void initState() {
    super.initState();
    // Vérifier si le chemin d'image est valide
    if (widget.establishment.picturesPaths.isEmpty) {
      _imageError = true;
    }
  }

  // Méthode pour supprimer un établissement des favoris
  Future<void> _unlikeEstablishment(BuildContext dialogContext) async {
    final scaffoldMessenger = ScaffoldMessenger.of(dialogContext);
    final String establishmentName = widget.establishment.name;

    try {
      if (!mounted) return;

      setState(() {
        _isDeleting = true;
      });

      // Appeler l'API pour "unlike" l'établissement
      await Api.unlike(widget.establishment);

      // Afficher un message de confirmation
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text("$establishmentName retiré des favoris"),
          backgroundColor: kMainGreen,
          duration: const Duration(seconds: 2),
        ),
      );

      // Appeler la fonction de rappel si elle existe
      if (widget.onDeleted != null) {
        widget.onDeleted!();
      }
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

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
            builder: (context) => EstablishmentPage(
          establishment: widget.establishment,
        )));
      },
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey[300],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image container avec bouton de suppression en superposition
                  Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(
                          maxHeight: 200,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _imageError || widget.establishment.picturesPaths.isEmpty
                              ? _buildFallbackImage()
                              : CachedNetworkImage(
                                  imageUrl: "$kMinioUrl/establishments/picture/${widget.establishment.picturesPaths[0]}",
                                  httpHeaders: {
                                    'Authorization': 'Bearer ${Api.jwt}'
                                  },
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    height: 150,
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: kMainGreen,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) {
                                    // Marquer l'erreur pour éviter de réessayer de charger l'image
                                    if (!_imageError) {
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        if (mounted) {
                                          setState(() {
                                            _imageError = true;
                                          });
                                        }
                                      });
                                    }
                                    return _buildFallbackImage();
                                  },
                                ),
                        ),
                      ),
                      // Bouton de suppression
                      Positioned(
                        top: 10,
                        right: 10,
                        child: _isDeleting
                          ? Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(30),
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
                                padding: EdgeInsets.all(12.0),
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
                                
                                if (result == true && mounted && context.mounted) {
                                  _unlikeEstablishment(context);
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(30),
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
                                  padding: EdgeInsets.all(10.0),
                                  child: Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.establishment.name,
                    style: kBold18,
                  ),
                  if (widget.establishment.price.isNotEmpty)
                    Column(
                      children: [
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(
                              CupertinoIcons.money_euro,
                              color: kMainGreen,
                              size: 20,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              widget.establishment.price,
                              style: kRegular16.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        )

                      ],
                    ),
                  if (widget.establishment.capacity.isNotEmpty)
                    Column(
                      children: [
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(
                              CupertinoIcons.person_2,
                              color: kMainGreen,
                              size: 20,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              widget.establishment.capacity,
                              style: kRegular16.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        )

                      ],
                    ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.location,
                        color: kMainGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          widget.establishment.fullAddress,
                          style: kRegular16.copyWith(color: Colors.grey[600]),
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.heart_fill,
                        color: Colors.redAccent[700],
                        size: 20,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "${widget.establishment.likes}",
                        style: kRegular16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey[300],
            ),
          ],
        ),
      ),
    );
  }
  
  // Image de remplacement à afficher en cas d'erreur
  Widget _buildFallbackImage() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.image_not_supported_outlined,
            color: kMainGreen,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            widget.establishment.name,
            style: kRegular16.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
