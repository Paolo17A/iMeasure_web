import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:imeasure/utils/color_util.dart';

Text quicksandWhiteBold(String label,
    {double fontSize = 20,
    TextAlign textAlign = TextAlign.center,
    TextOverflow? textOverflow}) {
  return Text(label,
      textAlign: textAlign,
      style: GoogleFonts.quicksand(
          fontSize: fontSize,
          color: Colors.white,
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
    TextOverflow? textOverflow}) {
  return Text(label,
      textAlign: textAlign,
      style: GoogleFonts.quicksand(
          fontSize: fontSize,
          color: Colors.white,
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

Text azureQuicksandBold(String label,
    {double fontSize = 20,
    TextAlign textAlign = TextAlign.center,
    TextDecoration? textDecoration,
    TextOverflow? textOverflow}) {
  return Text(
    label,
    textAlign: textAlign,
    style: GoogleFonts.quicksand(
        fontSize: fontSize,
        color: CustomColors.azure,
        fontWeight: FontWeight.bold,
        decoration: textDecoration,
        textStyle: TextStyle(overflow: textOverflow)),
  );
}

/*Text montserratMidnightBlueBold(String label,
    {double fontSize = 20,
    TextAlign textAlign = TextAlign.center,
    TextOverflow? textOverflow}) {
  return Text(
    label,
    textAlign: textAlign,
    style: GoogleFonts.montserrat(
        fontSize: fontSize,
        color: CustomColors.midnightBlue,
        fontWeight: FontWeight.bold,
        textStyle: TextStyle(overflow: textOverflow)),
  );
}

Text montserratMidnightBlueRegular(String label,
    {double fontSize = 20,
    TextAlign textAlign = TextAlign.center,
    TextOverflow? textOverflow}) {
  return Text(label,
      textAlign: textAlign,
      style: GoogleFonts.montserrat(
          fontSize: fontSize,
          color: CustomColors.midnightBlue,
          textStyle: TextStyle(overflow: textOverflow)));
}*/
