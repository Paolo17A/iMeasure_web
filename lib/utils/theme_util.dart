import 'package:flutter/material.dart';

import 'color_util.dart';

ThemeData themeData = ThemeData(
  colorSchemeSeed: CustomColors.midnightBlue,
  scaffoldBackgroundColor: CustomColors.ghostWhite,
  appBarTheme: const AppBarTheme(
      backgroundColor: CustomColors.slateBlue, toolbarHeight: 40),
  snackBarTheme:
      const SnackBarThemeData(backgroundColor: CustomColors.slateBlue),
  elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: CustomColors.dandelion)),
);
