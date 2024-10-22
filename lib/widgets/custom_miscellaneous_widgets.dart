import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:imeasure/widgets/custom_padding_widgets.dart';
import 'package:imeasure/widgets/custom_text_field_widget.dart';
import 'package:imeasure/widgets/dropdown_widget.dart';
import 'package:imeasure/widgets/text_widgets.dart';

import '../providers/cart_provider.dart';
import '../utils/color_util.dart';
import '../utils/string_util.dart';

Widget stackedLoadingContainer(
    BuildContext context, bool isLoading, Widget child) {
  return Stack(children: [
    child,
    if (isLoading)
      Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          color: Colors.black.withOpacity(0.5),
          child: const Center(child: CircularProgressIndicator()))
  ]);
}

Widget switchedLoadingContainer(bool isLoading, Widget child) {
  return isLoading ? const Center(child: CircularProgressIndicator()) : child;
}

Container viewContentContainer(BuildContext context, {required Widget child}) {
  return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
      ),
      child: child);
}

Widget viewContentLabelRow(BuildContext context,
    {required List<Widget> children}) {
  return SizedBox(
      width: MediaQuery.of(context).size.width, child: Row(children: children));
}

Widget viewContentEntryRow(BuildContext context,
    {required List<Widget> children}) {
  return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 50,
      child: Row(children: children));
}

Widget viewFlexTextCell(String text,
    {required int flex,
    required Color backgroundColor,
    required Color textColor,
    Border? customBorder,
    BorderRadius? customBorderRadius}) {
  return Flexible(
    flex: flex,
    child: Container(
        height: 50,
        decoration: BoxDecoration(
            color: backgroundColor,
            border: customBorder ??
                Border.symmetric(horizontal: BorderSide(color: Colors.white)),
            borderRadius: customBorderRadius),
        child: ClipRRect(
          child: Center(
              child: SelectableText(text,
                  maxLines: 1,
                  style: GoogleFonts.quicksand(
                      textStyle: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    overflow: TextOverflow.ellipsis,
                  )))),
        )),
  );
}

Widget viewFlexLabelTextCell(String text, int flex) {
  return viewFlexTextCell(text,
      flex: flex, backgroundColor: Colors.transparent, textColor: Colors.white);
}

Widget viewFlexActionsCell(List<Widget> children,
    {required int flex,
    required Color backgroundColor,
    Border? customBorder,
    BorderRadius? customBorderRadius}) {
  return Flexible(
      flex: flex,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
            border: customBorder ??
                Border.symmetric(horizontal: BorderSide(color: Colors.white)),
            borderRadius: customBorderRadius,
            color: backgroundColor),
        child: Center(
            child: Wrap(
                alignment: WrapAlignment.start,
                runAlignment: WrapAlignment.spaceEvenly,
                spacing: 10,
                runSpacing: 10,
                children: children)),
      ));
}

Widget viewContentUnavailable(BuildContext context, {required String text}) {
  return SizedBox(
    height: MediaQuery.of(context).size.height * 0.65,
    child: Center(child: quicksandWhiteBold(text, fontSize: 44)),
  );
}

Widget analyticReportWidget(BuildContext context,
    {required String count,
    required String demographic,
    required Widget displayIcon,
    required Function? onPress}) {
  return Padding(
    padding: const EdgeInsets.all(8),
    child: Container(
        width: MediaQuery.of(context).size.width * 0.14,
        height: MediaQuery.of(context).size.height * 0.2,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10), color: Colors.white),
        padding: const EdgeInsets.all(4),
        child: Row(children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.08,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                quicksandBlackBold(count, fontSize: 40),
                SizedBox(
                  //width: MediaQuery.of(context).size.width * 0.07,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: onPress != null ? () => onPress() : null,
                    style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    )),
                    child: Center(
                      child: quicksandBlackBold(demographic, fontSize: 12),
                    ),
                  ),
                )
              ],
            ),
          ),
          SizedBox(
              width: MediaQuery.of(context).size.width * 0.05,
              child: Transform.scale(scale: 2, child: displayIcon))
        ])),
  );
}

Widget buildProfileImage(
    {required String profileImageURL, double radius = 70}) {
  return profileImageURL.isNotEmpty
      ? CircleAvatar(
          radius: radius,
          backgroundColor: CustomColors.lavenderMist,
          backgroundImage: NetworkImage(profileImageURL),
        )
      : CircleAvatar(
          radius: radius,
          backgroundColor: CustomColors.lavenderMist,
          child: Icon(
            Icons.person,
            color: CustomColors.forestGreen,
            size: radius + 10,
          ));
}

Widget selectedMemoryImageDisplay(
    Uint8List? imageStream, Function deleteImage) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40),
    child: Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.white)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            SizedBox(
                width: 150, height: 150, child: Image.memory(imageStream!)),
            const SizedBox(height: 5),
            SizedBox(
              width: 90,
              child: TextButton(
                  onPressed: () => deleteImage(),
                  child: const Icon(Icons.delete_outline,
                      color: CustomColors.lavenderMist)),
            )
          ],
        ),
      ),
    ),
  );
}

Widget square300NetworkImage(String url) {
  return Container(
    width: 300,
    height: 300,
    decoration: BoxDecoration(
        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)),
  );
}

Widget selectedNetworkImageDisplay(String imageSource) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40),
    child: Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.white)),
      padding: const EdgeInsets.all(10),
      child:
          SizedBox(width: 150, height: 150, child: Image.network(imageSource)),
    ),
  );
}

Container breakdownContainer(BuildContext context, {required Widget child}) {
  return Container(
      width: MediaQuery.of(context).size.width * 0.25,
      height: MediaQuery.of(context).size.height * 0.4,
      decoration: BoxDecoration(
          boxShadow: [],
          borderRadius: BorderRadius.circular(20),
          color: CustomColors.lavenderMist),
      child: Padding(padding: const EdgeInsets.all(11), child: child));
}

Widget snapshotHandler(AsyncSnapshot snapshot) {
  if (snapshot.connectionState == ConnectionState.waiting) {
    return Center(child: const CircularProgressIndicator());
  } else if (!snapshot.hasData) {
    return Text('No data found');
  } else if (snapshot.hasError) {
    return Text('Error getting data: ${snapshot.error.toString()}');
  }
  return Container();
}

Widget windowParameterWidget(BuildContext context,
    {required TextEditingController nameController,
    required bool isMandatory,
    required Function(bool?) onCheckboxPress,
    required String priceBasis,
    required Function(String?) onPriceBasisChange,
    required TextEditingController brownPriceController,
    required TextEditingController mattBlackController,
    required TextEditingController mattGrayController,
    required TextEditingController woodFinishController,
    required TextEditingController whitePriceController,
    required Function onRemoveField}) {
  return all10Pix(
    child: Container(
      decoration: BoxDecoration(
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(10)),
      padding: EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    quicksandWhiteBold('Field Name'),
                    CustomTextField(
                        text: 'Field Name',
                        height: 40,
                        controller: nameController,
                        textInputType: TextInputType.text),
                  ],
                ),
              ),
              Gap(30),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    quicksandWhiteBold('Is Mandatory Field'),
                    Checkbox(value: isMandatory, onChanged: onCheckboxPress),
                  ],
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.1,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: CustomColors.coralRed),
                    onPressed: () => onRemoveField(),
                    child: quicksandWhiteBold('REMOVE SUBFIELD', fontSize: 12)),
              ),
            ],
          ),
          Gap(10),
          vertical10Pix(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                quicksandWhiteBold('Price Basis'),
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5)),
                  child: dropdownWidget(
                      priceBasis,
                      onPriceBasisChange,
                      [
                        'WIDTH',
                        'HEIGHT',
                        'PERIMETER',
                        'PERIMETER DOUBLED',
                        'STACKED WIDTH'
                      ],
                      priceBasis,
                      false),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    quicksandWhiteBold('Brown Price'),
                    CustomTextField(
                        text: 'Brown Price',
                        height: 40,
                        controller: brownPriceController,
                        textInputType: TextInputType.number),
                  ],
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    quicksandWhiteBold('White Price'),
                    CustomTextField(
                        text: 'White Price',
                        height: 40,
                        controller: whitePriceController,
                        textInputType: TextInputType.number),
                  ],
                ),
              ),
            ],
          ),
          vertical10Pix(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      quicksandWhiteBold('Matt Black Price'),
                      CustomTextField(
                          text: 'Matt Black Price',
                          height: 40,
                          controller: mattBlackController,
                          textInputType: TextInputType.number),
                    ],
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      quicksandWhiteBold('Matt Gray Price'),
                      CustomTextField(
                          text: 'Matt Gray Price',
                          height: 40,
                          controller: mattGrayController,
                          textInputType: TextInputType.number),
                    ],
                  ),
                ),
              ],
            ),
          ),
          vertical10Pix(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      quicksandWhiteBold('Wood Finish Price'),
                      CustomTextField(
                          text: 'Wood Finish Price',
                          height: 40,
                          controller: woodFinishController,
                          textInputType: TextInputType.number),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget windowAccessoryWidget(BuildContext context,
    {required TextEditingController nameController,
    required TextEditingController priceController,
    required Function onRemoveField}) {
  return all10Pix(
    child: Container(
      decoration: BoxDecoration(
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(10)),
      padding: EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    quicksandWhiteBold('Accessory Name'),
                    CustomTextField(
                        text: 'Accessory Name',
                        height: 40,
                        controller: nameController,
                        textInputType: TextInputType.name),
                  ],
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    quicksandWhiteBold('Accessory Price'),
                    CustomTextField(
                        text: 'Accessory Price',
                        height: 40,
                        controller: priceController,
                        textInputType: TextInputType.number),
                  ],
                ),
              ),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: CustomColors.coralRed),
                  onPressed: () => onRemoveField(),
                  child: quicksandWhiteBold('REMOVE ACCESSORY', fontSize: 12)),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget mandatoryWindowSubfield(WidgetRef ref,
    {required Map<dynamic, dynamic> windowSubField,
    required double height,
    required double width}) {
  num price = 0;
  if (windowSubField[WindowSubfields.priceBasis] == 'HEIGHT') {
    switch (ref.read(cartProvider).selectedColor) {
      case WindowColors.brown:
        price = (windowSubField[WindowSubfields.brownPrice] / 21) * height;
        break;
      case WindowColors.white:
        price = (windowSubField[WindowSubfields.whitePrice] / 21) * height;
        break;
      case WindowColors.mattBlack:
        price = (windowSubField[WindowSubfields.mattBlackPrice] / 21) * height;
        break;
      case WindowColors.mattGray:
        price = (windowSubField[WindowSubfields.mattGrayPrice] / 21) * height;
        break;
      case WindowColors.woodFinish:
        price = (windowSubField[WindowSubfields.woodFinishPrice] / 21) * height;
        break;
    }
  } else if (windowSubField[WindowSubfields.priceBasis] == 'WIDTH') {
    switch (ref.read(cartProvider).selectedColor) {
      case WindowColors.brown:
        price = (windowSubField[WindowSubfields.brownPrice] / 21) * width;
        break;
      case WindowColors.white:
        price = (windowSubField[WindowSubfields.whitePrice] / 21) * width;
        break;
      case WindowColors.mattBlack:
        price = (windowSubField[WindowSubfields.mattBlackPrice] / 21) * width;
        break;
      case WindowColors.mattGray:
        price = (windowSubField[WindowSubfields.mattGrayPrice] / 21) * width;
        break;
      case WindowColors.woodFinish:
        price = (windowSubField[WindowSubfields.woodFinishPrice] / 21) * width;
        break;
    }
  }
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      quicksandBlackRegular('${windowSubField[WindowSubfields.name]}: ',
          fontSize: 14),
      quicksandBlackRegular(' PHP ${formatPrice(price.toDouble())}',
          fontSize: 14),
    ],
  );
}

StreamBuilder pendingPickUpOrdersStreamBuilder() {
  return StreamBuilder(
    stream: FirebaseFirestore.instance
        .collection(Collections.orders)
        .where(OrderFields.clientID,
            isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .where(OrderFields.orderStatus, isEqualTo: OrderStatuses.forPickUp)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting ||
          !snapshot.hasData ||
          snapshot.hasError) return Container();
      int availableCollectionCount = snapshot.data!.docs.length;
      if (availableCollectionCount > 0)
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
              shape: BoxShape.circle, color: CustomColors.coralRed),
          child: Center(
            child: quicksandWhiteRegular(availableCollectionCount.toString(),
                fontSize: 12),
          ),
        );
      else {
        return Container();
      }
    },
  );
}

Widget starRating(double rating,
    {required Function(double) onUpdate,
    double starSize = 20,
    bool mayMove = true}) {
  return RatingBar(
      minRating: 1,
      maxRating: 5,
      itemCount: 5,
      initialRating: rating,
      updateOnDrag: mayMove,
      allowHalfRating: false,
      ignoreGestures: !mayMove,
      itemSize: starSize,
      ratingWidget: RatingWidget(
          full:
              const Icon(Icons.star, color: Color.fromARGB(255, 236, 217, 49)),
          half:
              const Icon(Icons.star, color: Color.fromARGB(255, 236, 217, 49)),
          empty: const Icon(Icons.star, color: Colors.grey)),
      onRatingUpdate: (val) => onUpdate(val));
}
