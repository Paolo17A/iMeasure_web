import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../providers/cart_provider.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/text_widgets.dart';
import 'string_util.dart';

void showQuotation(
  BuildContext context,
  WidgetRef ref, {
  required TextEditingController widthController,
  required TextEditingController heightController,
  required List<dynamic> mandatoryWindowFields,
  required List<Map<dynamic, dynamic>> optionalWindowFields,
}) {
  num totalMandatoryPayment = 0;
  for (int i = 0; i < optionalWindowFields.length; i++) {
    num price = 0;
    if (optionalWindowFields[i][OptionalWindowFields.optionalFields]
            [WindowSubfields.priceBasis] ==
        'HEIGHT') {
      switch (ref.read(cartProvider).selectedColor) {
        case WindowColors.brown:
          price = (optionalWindowFields[i][OptionalWindowFields.optionalFields]
                      [WindowSubfields.brownPrice] /
                  21) *
              double.parse(heightController.text);
          break;
        case WindowColors.white:
          price = (optionalWindowFields[i][OptionalWindowFields.optionalFields]
                      [WindowSubfields.whitePrice] /
                  21) *
              double.parse(heightController.text);
          break;
        case WindowColors.mattBlack:
          price = (optionalWindowFields[i][OptionalWindowFields.optionalFields]
                      [WindowSubfields.mattBlackPrice] /
                  21) *
              double.parse(heightController.text);
          break;
        case WindowColors.mattGray:
          price = (optionalWindowFields[i][OptionalWindowFields.optionalFields]
                      [WindowSubfields.mattGrayPrice] /
                  21) *
              double.parse(heightController.text);
          break;
        case WindowColors.woodFinish:
          price = (optionalWindowFields[i][OptionalWindowFields.optionalFields]
                      [WindowSubfields.woodFinishPrice] /
                  21) *
              double.parse(heightController.text);
          break;
      }
    } else if (optionalWindowFields[i][OptionalWindowFields.optionalFields]
            [WindowSubfields.priceBasis] ==
        'WIDTH') {
      switch (ref.read(cartProvider).selectedColor) {
        case WindowColors.brown:
          price = (optionalWindowFields[i][OptionalWindowFields.optionalFields]
                      [WindowSubfields.brownPrice] /
                  21) *
              double.parse(widthController.text);
          break;
        case WindowColors.white:
          price = (optionalWindowFields[i][OptionalWindowFields.optionalFields]
                      [WindowSubfields.whitePrice] /
                  21) *
              double.parse(widthController.text);
          break;
        case WindowColors.mattBlack:
          price = (optionalWindowFields[i][OptionalWindowFields.optionalFields]
                      [WindowSubfields.mattBlackPrice] /
                  21) *
              double.parse(widthController.text);
          break;
        case WindowColors.mattGray:
          price = (optionalWindowFields[i][OptionalWindowFields.optionalFields]
                      [WindowSubfields.mattGrayPrice] /
                  21) *
              double.parse(widthController.text);
          break;
        case WindowColors.woodFinish:
          price = (optionalWindowFields[i][OptionalWindowFields.optionalFields]
                      [WindowSubfields.woodFinishPrice] /
                  21) *
              double.parse(widthController.text);
          break;
      }
    }
    optionalWindowFields[i][OptionalWindowFields.price] = price;
  }
  for (var windowSubField in mandatoryWindowFields) {
    if (windowSubField[WindowSubfields.priceBasis] == 'HEIGHT') {
      switch (ref.read(cartProvider).selectedColor) {
        case WindowColors.brown:
          totalMandatoryPayment +=
              (windowSubField[WindowSubfields.brownPrice] / 21) *
                  double.parse(heightController.text);
          break;
        case WindowColors.white:
          totalMandatoryPayment +=
              (windowSubField[WindowSubfields.whitePrice] / 21) *
                  double.parse(heightController.text);
          break;
        case WindowColors.mattBlack:
          totalMandatoryPayment +=
              (windowSubField[WindowSubfields.mattBlackPrice] / 21) *
                  double.parse(heightController.text);
          break;
        case WindowColors.mattGray:
          totalMandatoryPayment +=
              (windowSubField[WindowSubfields.mattGrayPrice] / 21) *
                  double.parse(heightController.text);
          break;
        case WindowColors.woodFinish:
          totalMandatoryPayment +=
              (windowSubField[WindowSubfields.woodFinishPrice] / 21) *
                  double.parse(heightController.text);
          break;
      }
    } else if (windowSubField[WindowSubfields.priceBasis] == 'WIDTH') {
      switch (ref.read(cartProvider).selectedColor) {
        case WindowColors.brown:
          totalMandatoryPayment +=
              (windowSubField[WindowSubfields.brownPrice] / 21) *
                  double.parse(widthController.text);
          break;
        case WindowColors.white:
          totalMandatoryPayment +=
              (windowSubField[WindowSubfields.whitePrice] / 21) *
                  double.parse(widthController.text);
          break;
        case WindowColors.mattBlack:
          totalMandatoryPayment +=
              (windowSubField[WindowSubfields.mattBlackPrice] / 21) *
                  double.parse(widthController.text);
          break;
        case WindowColors.mattGray:
          totalMandatoryPayment +=
              (windowSubField[WindowSubfields.mattGrayPrice] / 21) *
                  double.parse(widthController.text);
          break;
        case WindowColors.woodFinish:
          totalMandatoryPayment +=
              (windowSubField[WindowSubfields.woodFinishPrice] / 21) *
                  double.parse(widthController.text);
          break;
      }
    }
  }
  List<Map<dynamic, dynamic>> selectedOptionalFields = optionalWindowFields
      .where((window) => window[OptionalWindowFields.isSelected])
      .toList();

  showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                      //width: MediaQuery.of(context).size.width * 0.4,
                      decoration: BoxDecoration(border: Border.all()),
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
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
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ));
}
