import 'package:flutter/material.dart';

class CloviLogo extends StatelessWidget {
  final double size;
  final Color? color; // Color can be used for tinting if needed, but usually image has its own colors
  final bool showText;
  final double fontSize;

  const CloviLogo({
    super.key,
    this.size = 60,
    this.color,
    this.showText = false,
    this.fontSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/images/appicon.png',
      height: size,
      fit: BoxFit.contain,
      color: color,
    );

    if (!showText) return image;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        image,
        const SizedBox(height: 4),
        Text(
          'clovi',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w400,
            color: color ?? const Color(0xFF2D5F4F),
            fontFamily: 'Cursive',
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
