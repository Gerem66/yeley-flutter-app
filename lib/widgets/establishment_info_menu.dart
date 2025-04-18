import 'package:flutter/material.dart';

class EstablishmentInfoMenu extends StatefulWidget {
  final String infoName;
  final String infoContent;
  final Icon icon;

  const EstablishmentInfoMenu({
    super.key,
    required this.infoName,
    required this.infoContent,
    required this.icon,
  });

  @override
  EstablishmentInfoMenuState createState() => EstablishmentInfoMenuState();
}

class EstablishmentInfoMenuState extends State<EstablishmentInfoMenu> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: widget.icon,
              title: Text(
                widget.infoName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.infoContent,
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
