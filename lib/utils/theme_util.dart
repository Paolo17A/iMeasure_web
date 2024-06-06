import 'package:flutter/material.dart';

import 'color_util.dart';

ThemeData themeData = ThemeData(
  colorSchemeSeed: CustomColors.deepNavyBlue,
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: const AppBarTheme(
      backgroundColor: CustomColors.emeraldGreen, toolbarHeight: 40),
  drawerTheme: DrawerThemeData(backgroundColor: CustomColors.aquaMarine),
  snackBarTheme: const SnackBarThemeData(
      backgroundColor: CustomColors.aquaMarine,
      contentTextStyle:
          TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
  elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: CustomColors.azure)),
);
