import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../models/glass_model.dart';
import '../providers/cart_provider.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/text_widgets.dart';
import 'string_util.dart';

void showQuotationDialog(BuildContext context, WidgetRef ref,
    {required TextEditingController widthController,
    required TextEditingController heightController,
    required List<dynamic> mandatoryWindowFields,
    required List<Map<dynamic, dynamic>> optionalWindowFields,
    required String itemType,
    required bool hasGlass}) {
  num totalMandatoryPayment = 0;
  num totalGlassPrice = 0;
  num optionalPrice = 0;
  num totalOverallPayment = 0;

  //  Calculate Optional Price
  List<Map<dynamic, dynamic>> _pricedOptionalWindowFields =
      pricedOptionalWindowFields(ref,
          width: double.parse(widthController.text),
          height: double.parse(heightController.text),
          oldOptionalWindowFields: optionalWindowFields);
  optionalPrice = calculateOptionalPrice(_pricedOptionalWindowFields);
  //  Calculate mandatory payment
  totalMandatoryPayment = calculateTotalMandatoryPayment(ref,
      width: double.parse(widthController.text),
      height: double.parse(heightController.text),
      mandatoryWindowFields: mandatoryWindowFields);

  //  Calculate glass payment
  List<Map<dynamic, dynamic>> selectedOptionalFields = [];
  if (hasGlass) {
    totalGlassPrice = calculateGlassPrice(ref,
        width: double.parse(widthController.text),
        height: double.parse(heightController.text));
    selectedOptionalFields = _pricedOptionalWindowFields
        .where((window) => window[OptionalWindowFields.isSelected])
        .toList();
  }
  totalOverallPayment = totalMandatoryPayment + totalGlassPrice + optionalPrice;

  showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.4,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      TextButton(
                          onPressed: () => GoRouter.of(context).pop(),
                          child: quicksandBlackBold('X'))
                    ]),
                    quicksandBlackBold('ESTIMATED QUOTATION', fontSize: 16),
                    all20Pix(
                      child: Container(
                        decoration: BoxDecoration(border: Border.all()),
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            //  Mandatory Window Fields
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: mandatoryWindowFields
                                    .toList()
                                    .map((windowFieldModel) =>
                                        mandatoryWindowSubfield(ref,
                                            width: double.parse(
                                                widthController.text),
                                            height: double.parse(
                                                heightController.text),
                                            windowSubField: windowFieldModel))
                                    .toList()),

                            //  Glass
                            if (hasGlass)
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    quicksandBlackRegular('Glass: ',
                                        fontSize: 14),
                                    quicksandBlackRegular(
                                        'PHP ${formatPrice(totalGlassPrice.toDouble())}',
                                        fontSize: 14)
                                  ]),
                            //  Accessories
                            Gap(12),
                            Column(
                              children: selectedOptionalFields
                                  .map((optionalField) => Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          quicksandBlackRegular(
                                              optionalField[OptionalWindowFields
                                                      .optionalFields]
                                                  [WindowFields.name],
                                              fontSize: 14),
                                          quicksandBlackRegular(
                                              'PHP ${formatPrice(optionalField[OptionalWindowFields.price] as double)}',
                                              fontSize: 14),
                                        ],
                                      ))
                                  .toList(),
                            ),
                            //  TOTAL

                            Gap(12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                quicksandBlackBold('Total Quotation: ',
                                    fontSize: 14),
                                quicksandBlackBold(
                                    'PHP ${formatPrice(totalOverallPayment.toDouble())}',
                                    fontSize: 14),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ));
}

void showCartQuotationDialog(BuildContext context, WidgetRef ref,
    {required num totalOverallPayment,
    required num laborPrice,
    required List<dynamic> mandatoryWindowFields,
    required List<dynamic> optionalWindowFields,
    required num width,
    required num height,
    required List<dynamic> imageURLs,
    required String itemName}) {
  showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: SingleChildScrollView(
              child: all20Pix(
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    TextButton(
                        onPressed: () => GoRouter.of(context).pop(),
                        child: quicksandBlackBold('X'))
                  ]),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Image.network(
                          imageURLs.first,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                        Column(children: [
                          Image.asset(ImagePaths.heritageIcon, scale: 2),
                          quicksandBlackBold('iMeasure', fontSize: 24),
                          quicksandBlackBold('• LOS BAÑOS •', fontSize: 12),
                        ]),
                        Gap(200)
                      ]),
                  all10Pix(
                    child: Row(children: [
                      quicksandBlackBold(itemName, textAlign: TextAlign.left)
                    ]),
                  ),
                  quicksandBlackBold('ESTIMATED QUOTATION', fontSize: 16),
                  //  Mandatory Window Fields
                  Container(
                    decoration: BoxDecoration(border: Border.all()),
                    padding: EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              quicksandBlackBold('Width', fontSize: 14),
                              quicksandBlackBold('${width.toString()} ft',
                                  fontSize: 14)
                            ]),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              quicksandBlackBold('Height', fontSize: 14),
                              quicksandBlackBold('${height.toString()} ft',
                                  fontSize: 14)
                            ]),
                        Gap(12),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: mandatoryWindowFields
                                .toList()
                                .map((windowFieldModel) => Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Flexible(
                                            child: quicksandBlackRegular(
                                                '${windowFieldModel[OrderBreakdownMap.field]}: ',
                                                textAlign: TextAlign.left,
                                                fontSize: 14),
                                          ),
                                          Flexible(
                                            child: quicksandBlackRegular(
                                                ' PHP ${formatPrice((windowFieldModel[OrderBreakdownMap.breakdownPrice]).toDouble())}',
                                                textAlign: TextAlign.left,
                                                fontSize: 14),
                                          ),
                                        ]))
                                .toList()),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: optionalWindowFields
                                .toList()
                                .map((windowFieldModel) => Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Flexible(
                                            child: quicksandBlackRegular(
                                                '${windowFieldModel[OrderBreakdownMap.field]}: ',
                                                textAlign: TextAlign.left,
                                                fontSize: 14),
                                          ),
                                          Flexible(
                                            child: quicksandBlackRegular(
                                                ' PHP ${formatPrice((windowFieldModel[OrderBreakdownMap.breakdownPrice]).toDouble())}',
                                                textAlign: TextAlign.left,
                                                fontSize: 14),
                                          ),
                                        ]))
                                .toList()),
                        if (laborPrice > 0)
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                quicksandBlackRegular('Labor Cost',
                                    fontSize: 14),
                                quicksandBlackRegular(
                                    'PHP ${formatPrice(laborPrice.toDouble())}',
                                    fontSize: 14)
                              ]),
                        //  TOTAL

                        Gap(12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            quicksandBlackBold('Total Quotation: ',
                                fontSize: 14),
                            quicksandBlackBold(
                                'PHP ${formatPrice(totalOverallPayment.toDouble())}',
                                fontSize: 14),
                          ],
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          )));
}

num calculateGlassPrice(WidgetRef ref,
    {required double width, required double height}) {
  return getProperGlass(ref.read(cartProvider).selectedGlassType) != null
      ? (getProperGlass(ref.read(cartProvider).selectedGlassType)!
              .pricePerSFT) *
          width *
          height
      : 0;
}

num calculateTotalMandatoryPayment(WidgetRef ref,
    {required double width,
    required double height,
    required List<dynamic> mandatoryWindowFields}) {
  num totalMandatoryPayment = 0;
  for (var windowSubField in mandatoryWindowFields) {
    if (windowSubField[WindowSubfields.priceBasis] == 'HEIGHT') {
      switch (ref.read(cartProvider).selectedColor) {
        case WindowColors.brown:
          totalMandatoryPayment +=
              (windowSubField[WindowSubfields.brownPrice] / 21) * height;
          break;
        case WindowColors.white:
          totalMandatoryPayment +=
              (windowSubField[WindowSubfields.whitePrice] / 21) * height;
          break;
        case WindowColors.mattBlack:
          totalMandatoryPayment +=
              (windowSubField[WindowSubfields.mattBlackPrice] / 21) * height;
          break;
        case WindowColors.mattGray:
          totalMandatoryPayment +=
              (windowSubField[WindowSubfields.mattGrayPrice] / 21) * height;
          break;
        case WindowColors.woodFinish:
          totalMandatoryPayment +=
              (windowSubField[WindowSubfields.woodFinishPrice] / 21) * height;
          break;
      }
    } else if (windowSubField[WindowSubfields.priceBasis] == 'WIDTH') {
      switch (ref.read(cartProvider).selectedColor) {
        case WindowColors.brown:
          totalMandatoryPayment +=
              (windowSubField[WindowSubfields.brownPrice] / 21) * width;
          break;
        case WindowColors.white:
          totalMandatoryPayment +=
              (windowSubField[WindowSubfields.whitePrice] / 21) * width;
          break;
        case WindowColors.mattBlack:
          totalMandatoryPayment +=
              (windowSubField[WindowSubfields.mattBlackPrice] / 21) * width;
          break;
        case WindowColors.mattGray:
          totalMandatoryPayment +=
              (windowSubField[WindowSubfields.mattGrayPrice] / 21) * width;
          break;
        case WindowColors.woodFinish:
          totalMandatoryPayment +=
              (windowSubField[WindowSubfields.woodFinishPrice] / 21) * width;
          break;
      }
    } else if (windowSubField[WindowSubfields.priceBasis] == 'PERIMETER') {
      num perimeter = (2 * width) + (2 * height);
      switch (ref.read(cartProvider).selectedColor) {
        case WindowColors.brown:
          totalMandatoryPayment +=
              (windowSubField[WindowSubfields.brownPrice] / 21) * perimeter;
          break;
        case WindowColors.white:
          totalMandatoryPayment +=
              (windowSubField[WindowSubfields.whitePrice] / 21) * perimeter;
          break;
        case WindowColors.mattBlack:
          totalMandatoryPayment +=
              (windowSubField[WindowSubfields.mattBlackPrice] / 21) * perimeter;
          break;
        case WindowColors.mattGray:
          totalMandatoryPayment +=
              (windowSubField[WindowSubfields.mattGrayPrice] / 21) * perimeter;
          break;
        case WindowColors.woodFinish:
          totalMandatoryPayment +=
              (windowSubField[WindowSubfields.woodFinishPrice] / 21) *
                  perimeter;
          break;
      }
    } else if (windowSubField[WindowSubfields.priceBasis] ==
        'PERIMETER DOUBLED') {
      num perimeter = (2 * width) + (2 * height);
      switch (ref.read(cartProvider).selectedColor) {
        case WindowColors.brown:
          totalMandatoryPayment +=
              (windowSubField[WindowSubfields.brownPrice] / 21) * perimeter * 2;
          break;
        case WindowColors.white:
          totalMandatoryPayment +=
              (windowSubField[WindowSubfields.whitePrice] / 21) * perimeter * 2;
          break;
        case WindowColors.mattBlack:
          totalMandatoryPayment +=
              (windowSubField[WindowSubfields.mattBlackPrice] / 21) *
                  perimeter *
                  2;
          break;
        case WindowColors.mattGray:
          totalMandatoryPayment +=
              (windowSubField[WindowSubfields.mattGrayPrice] / 21) *
                  perimeter *
                  2;
          break;
        case WindowColors.woodFinish:
          totalMandatoryPayment +=
              (windowSubField[WindowSubfields.woodFinishPrice] / 21) *
                  perimeter *
                  2;
          break;
      }
    } else if (windowSubField[WindowSubfields.priceBasis] == 'STACKED WIDTH') {
      num stackedValue = (2 * height) + (6 * width);
      switch (ref.read(cartProvider).selectedColor) {
        case WindowColors.brown:
          totalMandatoryPayment +=
              (windowSubField[WindowSubfields.brownPrice] / 21) * stackedValue;
          break;
        case WindowColors.white:
          totalMandatoryPayment +=
              (windowSubField[WindowSubfields.whitePrice] / 21) * stackedValue;
          break;
        case WindowColors.mattBlack:
          totalMandatoryPayment +=
              (windowSubField[WindowSubfields.mattBlackPrice] / 21) *
                  stackedValue;
          break;
        case WindowColors.mattGray:
          totalMandatoryPayment +=
              (windowSubField[WindowSubfields.mattGrayPrice] / 21) *
                  stackedValue;
          break;
        case WindowColors.woodFinish:
          totalMandatoryPayment +=
              (windowSubField[WindowSubfields.woodFinishPrice] / 21) *
                  stackedValue;
          break;
      }
    }
  }
  return totalMandatoryPayment;
}

num calculateOptionalPrice(List<Map<dynamic, dynamic>> optionalWindowFields) {
  num totalOptionalPaymentsPrice = 0;
  for (var optionalFields in optionalWindowFields) {
    if (optionalFields[OptionalWindowFields.isSelected]) {
      totalOptionalPaymentsPrice += optionalFields[OptionalWindowFields.price];
    }
  }
  return totalOptionalPaymentsPrice;
}

List<Map<dynamic, dynamic>> pricedOptionalWindowFields(WidgetRef ref,
    {required double width,
    required double height,
    required List<Map<dynamic, dynamic>> oldOptionalWindowFields}) {
  List<Map<dynamic, dynamic>> optionalWindowFields = oldOptionalWindowFields;
  for (int i = 0; i < oldOptionalWindowFields.length; i++) {
    num price = 0;
    if (oldOptionalWindowFields[i][OptionalWindowFields.optionalFields]
            [WindowSubfields.priceBasis] ==
        'HEIGHT') {
      switch (ref.read(cartProvider).selectedColor) {
        case WindowColors.brown:
          price = (oldOptionalWindowFields[i]
                          [OptionalWindowFields.optionalFields]
                      [WindowSubfields.brownPrice] /
                  21) *
              height;
          break;
        case WindowColors.white:
          price = (oldOptionalWindowFields[i]
                          [OptionalWindowFields.optionalFields]
                      [WindowSubfields.whitePrice] /
                  21) *
              height;
          break;
        case WindowColors.mattBlack:
          price = (oldOptionalWindowFields[i]
                          [OptionalWindowFields.optionalFields]
                      [WindowSubfields.mattBlackPrice] /
                  21) *
              height;
          break;
        case WindowColors.mattGray:
          price = (oldOptionalWindowFields[i]
                          [OptionalWindowFields.optionalFields]
                      [WindowSubfields.mattGrayPrice] /
                  21) *
              height;
          break;
        case WindowColors.woodFinish:
          price = (oldOptionalWindowFields[i]
                          [OptionalWindowFields.optionalFields]
                      [WindowSubfields.woodFinishPrice] /
                  21) *
              height;
          break;
      }
    } else if (oldOptionalWindowFields[i][OptionalWindowFields.optionalFields]
            [WindowSubfields.priceBasis] ==
        'WIDTH') {
      switch (ref.read(cartProvider).selectedColor) {
        case WindowColors.brown:
          price = (oldOptionalWindowFields[i]
                          [OptionalWindowFields.optionalFields]
                      [WindowSubfields.brownPrice] /
                  21) *
              width;
          break;
        case WindowColors.white:
          price = (oldOptionalWindowFields[i]
                          [OptionalWindowFields.optionalFields]
                      [WindowSubfields.whitePrice] /
                  21) *
              width;
          break;
        case WindowColors.mattBlack:
          price = (oldOptionalWindowFields[i]
                          [OptionalWindowFields.optionalFields]
                      [WindowSubfields.mattBlackPrice] /
                  21) *
              width;
          break;
        case WindowColors.mattGray:
          price = (oldOptionalWindowFields[i]
                          [OptionalWindowFields.optionalFields]
                      [WindowSubfields.mattGrayPrice] /
                  21) *
              width;
          break;
        case WindowColors.woodFinish:
          price = (oldOptionalWindowFields[i]
                          [OptionalWindowFields.optionalFields]
                      [WindowSubfields.woodFinishPrice] /
                  21) *
              width;
          break;
      }
    } else if (oldOptionalWindowFields[i][OptionalWindowFields.optionalFields]
            [WindowSubfields.priceBasis] ==
        'PERIMETER') {
      num perimeter = (2 * width) + (2 * height);

      switch (ref.read(cartProvider).selectedColor) {
        case WindowColors.brown:
          price = (oldOptionalWindowFields[i]
                          [OptionalWindowFields.optionalFields]
                      [WindowSubfields.brownPrice] /
                  21) *
              perimeter;
          break;
        case WindowColors.white:
          price = (oldOptionalWindowFields[i]
                          [OptionalWindowFields.optionalFields]
                      [WindowSubfields.whitePrice] /
                  21) *
              perimeter;
          break;
        case WindowColors.mattBlack:
          price = (oldOptionalWindowFields[i]
                          [OptionalWindowFields.optionalFields]
                      [WindowSubfields.mattBlackPrice] /
                  21) *
              perimeter;
          break;
        case WindowColors.mattGray:
          price = (oldOptionalWindowFields[i]
                          [OptionalWindowFields.optionalFields]
                      [WindowSubfields.mattGrayPrice] /
                  21) *
              perimeter;
          break;
        case WindowColors.woodFinish:
          price = (oldOptionalWindowFields[i]
                          [OptionalWindowFields.optionalFields]
                      [WindowSubfields.woodFinishPrice] /
                  21) *
              perimeter;
          break;
      }
    } else if (oldOptionalWindowFields[i][OptionalWindowFields.optionalFields]
            [WindowSubfields.priceBasis] ==
        'PERIMETER DOUBLED') {
      num perimeter = (2 * width) + (2 * height);

      switch (ref.read(cartProvider).selectedColor) {
        case WindowColors.brown:
          price = (oldOptionalWindowFields[i]
                          [OptionalWindowFields.optionalFields]
                      [WindowSubfields.brownPrice] /
                  21) *
              perimeter *
              2;
          break;
        case WindowColors.white:
          price = (oldOptionalWindowFields[i]
                          [OptionalWindowFields.optionalFields]
                      [WindowSubfields.whitePrice] /
                  21) *
              perimeter *
              2;
          break;
        case WindowColors.mattBlack:
          price = (oldOptionalWindowFields[i]
                          [OptionalWindowFields.optionalFields]
                      [WindowSubfields.mattBlackPrice] /
                  21) *
              perimeter *
              2;
          break;
        case WindowColors.mattGray:
          price = (oldOptionalWindowFields[i]
                          [OptionalWindowFields.optionalFields]
                      [WindowSubfields.mattGrayPrice] /
                  21) *
              perimeter *
              2;
          break;
        case WindowColors.woodFinish:
          price = (oldOptionalWindowFields[i]
                          [OptionalWindowFields.optionalFields]
                      [WindowSubfields.woodFinishPrice] /
                  21) *
              perimeter *
              2;
          break;
      }
    } else if (oldOptionalWindowFields[i][OptionalWindowFields.optionalFields]
            [WindowSubfields.priceBasis] ==
        'STACKED WIDTH') {
      num stackedValue = (2 * height) + (6 * width);

      switch (ref.read(cartProvider).selectedColor) {
        case WindowColors.brown:
          price = (oldOptionalWindowFields[i]
                          [OptionalWindowFields.optionalFields]
                      [WindowSubfields.brownPrice] /
                  21) *
              stackedValue;
          break;
        case WindowColors.white:
          price = (oldOptionalWindowFields[i]
                          [OptionalWindowFields.optionalFields]
                      [WindowSubfields.whitePrice] /
                  21) *
              stackedValue;
          break;
        case WindowColors.mattBlack:
          price = (oldOptionalWindowFields[i]
                          [OptionalWindowFields.optionalFields]
                      [WindowSubfields.mattBlackPrice] /
                  21) *
              stackedValue;
          break;
        case WindowColors.mattGray:
          price = (oldOptionalWindowFields[i]
                          [OptionalWindowFields.optionalFields]
                      [WindowSubfields.mattGrayPrice] /
                  21) *
              stackedValue;
          break;
        case WindowColors.woodFinish:
          price = (oldOptionalWindowFields[i]
                          [OptionalWindowFields.optionalFields]
                      [WindowSubfields.woodFinishPrice] /
                  21) *
              stackedValue;
          break;
      }
    }
    optionalWindowFields[i][OptionalWindowFields.price] = price;
  }
  return optionalWindowFields;
}
