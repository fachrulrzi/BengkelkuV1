import 'package:flutter/material.dart';

class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/google_logo.png',
      width: size,
      height: size,
    );
  }
}
