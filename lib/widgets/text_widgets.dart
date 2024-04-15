import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/color_util.dart';

Text montserratWhiteBold(String label,
    {double fontSize = 20,
    TextAlign textAlign = TextAlign.center,
    TextOverflow? textOverflow}) {
  return Text(label,
      textAlign: textAlign,
      style: GoogleFonts.montserrat(
          fontSize: fontSize,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          textStyle: TextStyle(overflow: textOverflow)));
}

Text montserratBlackRegular(String label,
    {double fontSize = 20,
    TextAlign textAlign = TextAlign.center,
    TextOverflow? textOverflow}) {
  return Text(
    label,
    textAlign: textAlign,
    style: GoogleFonts.montserrat(
        fontSize: fontSize,
        color: Colors.black,
        textStyle: TextStyle(overflow: textOverflow)),
  );
}

Text montserratWhiteRegular(String label,
    {double fontSize = 20,
    TextAlign textAlign = TextAlign.center,
    TextOverflow? textOverflow}) {
  return Text(label,
      textAlign: textAlign,
      style: GoogleFonts.montserrat(
          fontSize: fontSize,
          color: Colors.white,
          textStyle: TextStyle(overflow: textOverflow)));
}

Text montserratBlackBold(String label,
    {double fontSize = 20,
    TextAlign textAlign = TextAlign.center,
    TextDecoration? textDecoration,
    TextOverflow? textOverflow}) {
  return Text(
    label,
    textAlign: textAlign,
    style: GoogleFonts.montserrat(
        fontSize: fontSize,
        color: Colors.black,
        fontWeight: FontWeight.bold,
        decoration: textDecoration,
        textStyle: TextStyle(overflow: textOverflow)),
  );
}

Text montserratMidnightBlueBold(String label,
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
}
