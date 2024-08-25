class GlassModel {
  String glassTypeName;
  String thickness;
  num pricePerSFT;

  GlassModel(
      {required this.glassTypeName,
      required this.thickness,
      required this.pricePerSFT});
}

List<GlassModel> allGlassModels = [
  GlassModel(glassTypeName: 'Clear 1/16', thickness: '2MM', pricePerSFT: 26),
  GlassModel(glassTypeName: 'Clear 1/8', thickness: '3MM', pricePerSFT: 26.5),
  GlassModel(glassTypeName: 'Clear 3/16', thickness: '5MM', pricePerSFT: 39.50),
  GlassModel(glassTypeName: 'Clear 1/4', thickness: '6MM', pricePerSFT: 40),
  GlassModel(glassTypeName: 'Clear 3/8', thickness: '10MM', pricePerSFT: 95),
  GlassModel(glassTypeName: 'Clear 1/2', thickness: '12MM', pricePerSFT: 110),
  GlassModel(glassTypeName: 'Bronze 1/8', thickness: '3MM', pricePerSFT: 40),
  GlassModel(glassTypeName: 'Bronze 3/16', thickness: '5MM', pricePerSFT: 41),
  GlassModel(glassTypeName: 'Bronze 1/4', thickness: '6MM', pricePerSFT: 44),
  GlassModel(glassTypeName: 'Bronze 3/8', thickness: '10MM', pricePerSFT: 110),
  GlassModel(glassTypeName: 'Bronze 1/2', thickness: '12MM', pricePerSFT: 140),
  GlassModel(
      glassTypeName: 'Mirror (China) 1/16', thickness: '2MM', pricePerSFT: 35),
  GlassModel(
      glassTypeName: 'Mirror (China) 1/8', thickness: '3MM', pricePerSFT: 45),
  GlassModel(
      glassTypeName: 'Mirror (China) 1/4', thickness: '6MM', pricePerSFT: 85),
  GlassModel(
      glassTypeName: 'Bronze / Gray Mirror',
      thickness: '6MM',
      pricePerSFT: 175),
  GlassModel(
      glassTypeName: 'Luningning 3MM', thickness: '3MM', pricePerSFT: 25),
  GlassModel(
      glassTypeName: 'Luningning 5MM', thickness: '5MM', pricePerSFT: 39),
  GlassModel(
      glassTypeName: 'Luningning 5.5MM', thickness: '5.5MM', pricePerSFT: 40),
  GlassModel(
      glassTypeName: 'Clear w/ SP 6MM 1/4',
      thickness: '6MM 1/4',
      pricePerSFT: 85),
  GlassModel(
      glassTypeName: 'Clear w/ SP 10MM 3/8',
      thickness: '10MM 3/8',
      pricePerSFT: 135),
  GlassModel(
      glassTypeName: 'Clear w/ SP 12MM 1/2',
      thickness: '12MM 1/2',
      pricePerSFT: 150),
  GlassModel(
      glassTypeName: 'Clear Tempered 6MM 1/4',
      thickness: '6MM 1/4',
      pricePerSFT: 120),
  GlassModel(
      glassTypeName: 'Clear Tempered 10MM 3/8',
      thickness: '10MM 3/8',
      pricePerSFT: 220),
  GlassModel(
      glassTypeName: 'Clear Tempered 12MM 1/2',
      thickness: '12MM 1/2',
      pricePerSFT: 250),
  GlassModel(
      glassTypeName: 'Bronze w/ SP 6MM 1/4',
      thickness: '6MM 1/4',
      pricePerSFT: 95),
  GlassModel(
      glassTypeName: 'Bronze w/ SP 10MM 3/8',
      thickness: '10MM 3/8',
      pricePerSFT: 150),
  GlassModel(
      glassTypeName: 'Bronze w/ SP 12MM 1/2',
      thickness: '12MM 1/2',
      pricePerSFT: 175),
  GlassModel(
      glassTypeName: 'Bronze Tempered 6MM 1/4',
      thickness: '6MM 1/4',
      pricePerSFT: 150),
  GlassModel(
      glassTypeName: 'Bronze Tempered 10MM 3/8',
      thickness: '10MM 3/8',
      pricePerSFT: 250),
  GlassModel(
      glassTypeName: 'Bronze Tempered 12MM 1/2',
      thickness: '12MM 1/2',
      pricePerSFT: 275),
  GlassModel(glassTypeName: 'Mirror w/ SP', thickness: '6MM', pricePerSFT: 120),
  GlassModel(glassTypeName: 'Dark Green', thickness: '6MM', pricePerSFT: 60),
  GlassModel(
      glassTypeName: 'French Green 10MM', thickness: '10MM', pricePerSFT: 115),
  GlassModel(
      glassTypeName: 'French Green 12MM', thickness: '12MM', pricePerSFT: 135)
];

GlassModel? getProperGlass(String glassName) {
  return allGlassModels
      .where((glassModel) => glassModel.glassTypeName == glassName)
      .firstOrNull;
}
