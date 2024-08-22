import 'package:flutter/material.dart';

import 'color_util.dart';

ThemeData themeData = ThemeData(
  colorSchemeSeed: CustomColors.deepCharcoal,
  scaffoldBackgroundColor: CustomColors.deepCharcoal,
  appBarTheme: const AppBarTheme(
      backgroundColor: CustomColors.emeraldGreen, toolbarHeight: 40),
  snackBarTheme: const SnackBarThemeData(
      backgroundColor: CustomColors.forestGreen,
      contentTextStyle:
          TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
  elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: CustomColors.forestGreen)),
);
