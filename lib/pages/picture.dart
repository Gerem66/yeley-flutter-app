import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:yeley_frontend/commons/constants.dart';
import 'package:yeley_frontend/services/api.dart';

class PicturePage extends StatefulWidget {
  final List<String> picturePaths;
  final int index;
  const PicturePage({super.key, required this.picturePaths, required this.index});

  @override
  State<PicturePage> createState() => _PicturePageState();
}

class _PicturePageState extends State<PicturePage> {
  late PageController controller;
  late int currentIndex;
  final Map<String, bool> _imageErrors = {};

  @override
  void initState() {
    currentIndex = widget.index;
    controller = PageController(initialPage: currentIndex);

    // Ajout d'un listener pour mettre à jour l'index actuel lorsque la page change
    controller.addListener(() {
      setState(() {
        currentIndex = controller.page!.round();
      });
    });

    super.initState();
  }
  
  // Widget pour afficher une image de remplacement en cas d'erreur
  Widget _buildFallbackImage() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              color: Colors.white70,
              size: 84,
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "L'image n'a pas pu être chargée",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: Stack(
          children: [
            PageView.builder(
              controller: controller,
              itemCount: widget.picturePaths.length,
              itemBuilder: (context, index) {
                final String path = widget.picturePaths[index];
                return Center(
                  child: Hero(
                    tag: "picture_$index",
                    child: _imageErrors[path] == true
                      ? _buildFallbackImage()
                      : CachedNetworkImage(
                          fit: BoxFit.contain,
                          imageUrl: "$kMinioUrl/establishments/picture/$path",
                          httpHeaders: {
                            'Authorization': 'Bearer ${Api.jwt}',
                          },
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
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
                            return _buildFallbackImage();
                          },
                        ),
                  ),
                );
              },
            ),
            SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  Text(
                    "${currentIndex + 1}/${widget.picturePaths.length}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 48), // Pour équilibrer la mise en page
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
