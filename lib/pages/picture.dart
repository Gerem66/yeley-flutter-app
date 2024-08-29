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
                return Center(
                  child: Hero(
                    tag: "picture_$index",
                    child: CachedNetworkImage(
                      fit: BoxFit.contain,
                      imageUrl: "$kMinioUrl/establishments/picture/${widget.picturePaths[index]}",
                      httpHeaders: {
                        'Authorization': 'Bearer ${Api.jwt}',
                      },
                    ),
                  ),
                );
              },
            ),
            SizedBox(
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
