import 'package:flutter/material.dart';

/// Centralized Typography Scale for OM MAVTAR GROUP Desktop Application
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Segoe UI';

  static TextStyle display(Color color) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: color,
        letterSpacing: -0.5,
      );

  static TextStyle heading1(Color color) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: color,
        letterSpacing: -0.3,
      );

  static TextStyle heading2(Color color) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle heading3(Color color) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle body(Color color, {FontWeight fontWeight = FontWeight.normal}) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 13,
        fontWeight: fontWeight,
        color: color,
      );

  static TextStyle caption(Color color) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle tableHeader(Color color) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.3,
      );

  static TextStyle tableCell(Color color, {bool isNumeric = false, bool isBold = false}) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 13,
        fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
        color: color,
        fontFeatures: isNumeric ? const [FontFeature.tabularFigures()] : null,
      );

  static TextStyle badge(Color color) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: color,
      );
}
