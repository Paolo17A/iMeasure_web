import 'package:flutter/material.dart';

import 'color_util.dart';

ThemeData themeData = ThemeData(
  colorSchemeSeed: CustomColors.emeraldGreen,
  scaffoldBackgroundColor: CustomColors.deepCharcoal,
  appBarTheme: const AppBarTheme(
      backgroundColor: CustomColors.emeraldGreen, toolbarHeight: 40),
  snackBarTheme: const SnackBarThemeData(
      backgroundColor: CustomColors.forestGreen,
      contentTextStyle: TextStyle(color: Colors.white)),
  elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: CustomColors.forestGreen)),
);
