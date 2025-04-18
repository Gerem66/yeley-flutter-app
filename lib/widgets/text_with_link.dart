import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:yeley_frontend/commons/decoration.dart';

class TextWithLink extends StatelessWidget {
  final String normalText;
  final String linkText;
  final VoidCallback onTap;
  final TextStyle? normalStyle;
  final TextStyle? linkStyle;

  const TextWithLink({
    Key? key,
    required this.normalText,
    required this.linkText,
    required this.onTap,
    this.normalStyle,
    this.linkStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(
          fontFamily: "Lato",
        ),
        children: [
          TextSpan(
            text: normalText,
            style: normalStyle ?? kRegular16.copyWith(color: Colors.black),
          ),
          TextSpan(
            text: linkText,
            style: linkStyle ?? kRegular16.copyWith(color: const Color(0xFF1E4A59)),
            recognizer: TapGestureRecognizer()..onTap = onTap,
          ),
        ],
      ),
    );
  }
}