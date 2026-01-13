
import 'package:flutter/material.dart';

class AppTextStyles {
  // Standard text: 12px
  static const TextStyle standard = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.normal,
    height: 1.2, // Smaller line height
  );

  // Large text: 14px
  static const TextStyle large = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.bold,
    height: 1.2, // Smaller line height
  );
  
  // Helper for white text
  static TextStyle standardWhite = standard.copyWith(color: Colors.white);
  static TextStyle largeWhite = large.copyWith(color: Colors.white);

  // Custom getters for specific needs if required
  static TextStyle get(double size, {Color? color, FontWeight? weight}) {
    return TextStyle(
      fontSize: size,
      color: color,
      fontWeight: weight,
      height: 1.2,
    );
  }
}
