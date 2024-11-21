import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:imeasure/utils/color_util.dart';

Text quicksandWhiteBold(String label,
    {double fontSize = 20,
    TextAlign textAlign = TextAlign.center,
    int? maxLines,
    TextOverflow? textOverflow}) {
  return Text(label,
      textAlign: textAlign,
      maxLines: maxLines,
      style: GoogleFonts.quicksand(
          fontSize: fontSize,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          textStyle: TextStyle(overflow: textOverflow)));
}

Text quicksandCoralRedBold(String label,
    {double fontSize = 20,
    TextAlign textAlign = TextAlign.center,
    TextOverflow? textOverflow}) {
  return Text(label,
      textAlign: textAlign,
      style: GoogleFonts.quicksand(
          fontSize: fontSize,
          color: CustomColors.coralRed,
          fontWeight: FontWeight.bold,
          textStyle: TextStyle(overflow: textOverflow)));
}

Text quicksandBlackRegular(String label,
    {double fontSize = 20,
    TextAlign textAlign = TextAlign.center,
    TextOverflow? textOverflow}) {
  return Text(
    label,
    textAlign: textAlign,
    style: GoogleFonts.quicksand(
        fontSize: fontSize,
        color: Colors.black,
        textStyle: TextStyle(overflow: textOverflow)),
  );
}

Text quicksandWhiteRegular(String label,
    {double fontSize = 20,
    TextAlign textAlign = TextAlign.center,
    TextOverflow? textOverflow,
    TextDecoration? decoration}) {
  return Text(label,
      textAlign: textAlign,
      style: GoogleFonts.quicksand(
          fontSize: fontSize,
          color: Colors.white,
          decoration: decoration,
          decorationColor: Colors.white,
          textStyle: TextStyle(overflow: textOverflow)));
}

Text quicksandBlackBold(String label,
    {double fontSize = 20,
    TextAlign textAlign = TextAlign.center,
    TextDecoration? textDecoration,
    TextOverflow? textOverflow}) {
  return Text(
    label,
    textAlign: textAlign,
    style: GoogleFonts.quicksand(
        fontSize: fontSize,
        color: Colors.black,
        fontWeight: FontWeight.bold,
        decoration: textDecoration,
        textStyle: TextStyle(overflow: textOverflow)),
  );
}

Text quicksandRedBold(String label,
    {double fontSize = 20,
    TextAlign textAlign = TextAlign.center,
    TextDecoration? textDecoration,
    TextOverflow? textOverflow}) {
  return Text(
    label,
    textAlign: textAlign,
    style: GoogleFonts.quicksand(
        fontSize: fontSize,
        color: Colors.red,
        fontWeight: FontWeight.bold,
        decoration: textDecoration,
        textStyle: TextStyle(overflow: textOverflow)),
  );
}

Text itcBaumansWhiteBold(String label,
    {double fontSize = 20,
    TextAlign textAlign = TextAlign.center,
    TextDecoration? textDecoration,
    TextOverflow? textOverflow}) {
  return Text(
    label,
    textAlign: textAlign,
    style: GoogleFonts.baumans(
        fontSize: fontSize,
        color: Colors.white,
        fontWeight: FontWeight.bold,
        decoration: textDecoration,
        textStyle: TextStyle(overflow: textOverflow)),
  );
}

Text itcBaumansBlackBold(String label,
    {double fontSize = 20,
    TextAlign textAlign = TextAlign.center,
    TextDecoration? textDecoration,
    TextOverflow? textOverflow}) {
  return Text(
    label,
    textAlign: textAlign,
    style: GoogleFonts.baumans(
        fontSize: fontSize,
        color: Colors.black,
        fontWeight: FontWeight.bold,
        decoration: textDecoration,
        textStyle: TextStyle(overflow: textOverflow)),
  );
}

Text deepSkyBlueQuicksandBold(String label,
    {double fontSize = 20,
    TextAlign textAlign = TextAlign.center,
    TextDecoration? textDecoration,
    TextOverflow? textOverflow}) {
  return Text(
    label,
    textAlign: textAlign,
    style: GoogleFonts.quicksand(
        fontSize: fontSize,
        color: CustomColors.deepSkyBlue,
        fontWeight: FontWeight.bold,
        decoration: textDecoration,
        textStyle: TextStyle(overflow: textOverflow)),
  );
}

Text deepCharcoalQuicksandBold(String label,
    {double fontSize = 20,
    TextAlign textAlign = TextAlign.center,
    TextDecoration? textDecoration,
    TextOverflow? textOverflow}) {
  return Text(
    label,
    textAlign: textAlign,
    style: GoogleFonts.quicksand(
        fontSize: fontSize,
        color: CustomColors.deepCharcoal,
        fontWeight: FontWeight.bold,
        decoration: textDecoration,
        textStyle: TextStyle(overflow: textOverflow)),
  );
}

Text forestGreenQuicksandBold(String label,
    {double fontSize = 20,
    TextAlign textAlign = TextAlign.center,
    TextDecoration? textDecoration,
    TextOverflow? textOverflow}) {
  return Text(
    label,
    textAlign: textAlign,
    style: GoogleFonts.quicksand(
        fontSize: fontSize,
        color: CustomColors.forestGreen,
        fontWeight: FontWeight.bold,
        decoration: textDecoration,
        textStyle: TextStyle(overflow: textOverflow)),
  );
}
