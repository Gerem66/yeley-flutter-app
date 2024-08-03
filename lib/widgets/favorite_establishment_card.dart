import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:yeley_frontend/commons/decoration.dart';

import '../commons/constants.dart';
import '../models/establishment.dart';
import '../pages/establishment.dart';
import '../services/api.dart';

class FavoriteEstablishmentCard extends StatefulWidget {
  final Establishment establishment;

  FavoriteEstablishmentCard({super.key, required this.establishment});

  @override
  _FavoriteEstablishmentCardState createState() => _FavoriteEstablishmentCardState();
}

class _FavoriteEstablishmentCardState extends State<FavoriteEstablishmentCard> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
            builder: (context) => EstablishmentPage(
          establishment: widget.establishment,
        )));
      },
      child: Column(
        children: [
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey[300],
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity, // Take the full width of the screen
                  constraints: const BoxConstraints(
                    maxHeight: 200, // Set the max height for the image
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: "$kApiUrl/establishments/picture/${widget.establishment.picturesPaths[0]}",
                      httpHeaders: {
                        'Authorization': 'Bearer ${Api.jwt}'
                      },
                      fit: BoxFit.cover, // Cover the box while maintaining the aspect ratio
                      placeholder: (context, url) => Container(
                        height: 150,
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 150,
                        color: Colors.grey[200],
                        child: Center(
                          child: Icon(
                            Icons.error,
                            color: Colors.red,
                            size: 50,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.establishment.name,
                  style: kBold18,
                ),
                const SizedBox(height: 5),
                Text(
                  widget.establishment.fullAddress,
                  style: kRegular16,
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
    );
  }
}
