import 'package:flutter/material.dart';
import '../commons/decoration.dart';

class ResponsiveNavigationBarWidget extends StatefulWidget {
  final ValueChanged<int> onIndexChanged;

  const ResponsiveNavigationBarWidget({super.key, required this.onIndexChanged});

  @override
  State<ResponsiveNavigationBarWidget> createState() => _ResponsiveNavigationBarWidgetState();
}

class _ResponsiveNavigationBarWidgetState extends State<ResponsiveNavigationBarWidget> {
  int selectedIndex = 0;

  void onButtonTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
    widget.onIndexChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 5, bottom: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Adjust spacing between elements
        children: [
          buildSwitchButton(0, Icons.home, "Home"),
          buildSwitchButton(1, Icons.favorite, "Favoris"),
          buildSwitchButton(2, Icons.person, "Profil"),
        ],
      ),
    );
  }

  Widget buildSwitchButton(int index, IconData icon, String text) {
    bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onButtonTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
        decoration: BoxDecoration(
          color: isSelected ? kMainGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(30.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Ensure the Row takes minimum space
          children: [
            Container(
              decoration: BoxDecoration(
                color: isSelected ? Colors.transparent : kMainGreen.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : kMainGreen,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 0.0),
              Text(
                text,
                style: kBold18.copyWith(color: Colors.white),
              ),
              const SizedBox(width: 8.0),
            ],
          ],
        ),
      ),
    );
  }
}
