import 'package:flutter/material.dart';

import 'color_util.dart';

ThemeData themeData = ThemeData(
  colorSchemeSeed: CustomColors.deepNavyBlue,
  scaffoldBackgroundColor: CustomColors.lavenderMist,
  appBarTheme: const AppBarTheme(
      backgroundColor: CustomColors.emeraldGreen, toolbarHeight: 40),
  drawerTheme: DrawerThemeData(backgroundColor: CustomColors.aquaMarine),
  snackBarTheme: const SnackBarThemeData(
      backgroundColor: CustomColors.deepNavyBlue,
      contentTextStyle:
          TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
  elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: CustomColors.azure)),
);
