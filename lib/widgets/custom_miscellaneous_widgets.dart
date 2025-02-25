import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:imeasure/widgets/custom_padding_widgets.dart';
import 'package:imeasure/widgets/custom_text_field_widget.dart';
import 'package:imeasure/widgets/dropdown_widget.dart';
import 'package:imeasure/widgets/text_widgets.dart';
import 'package:intl/intl.dart';

import '../providers/cart_provider.dart';
import '../utils/color_util.dart';
import '../utils/firebase_util.dart';
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

Widget square80NetworkImage(String url) {
  return Container(
    width: 80,
    height: 80,
    decoration: BoxDecoration(
        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)),
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

Widget selectedNetworkImageDisplay(String imageSource,
    {bool displayDelete = false, Function? onDelete}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40),
    child: Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.white)),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          SizedBox(width: 150, height: 150, child: Image.network(imageSource)),
          if (displayDelete)
            IconButton(
                onPressed: () => onDelete!(),
                icon: Icon(Icons.delete_outline, color: Colors.white))
        ],
      ),
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
  } else if (windowSubField[WindowSubfields.priceBasis] == 'PERIMETER') {
    num perimeter = (2 * width) + (2 * height);
    switch (ref.read(cartProvider).selectedColor) {
      case WindowColors.brown:
        price = (windowSubField[WindowSubfields.brownPrice] / 21) * perimeter;
        break;
      case WindowColors.white:
        price = (windowSubField[WindowSubfields.whitePrice] / 21) * perimeter;
        break;
      case WindowColors.mattBlack:
        price =
            (windowSubField[WindowSubfields.mattBlackPrice] / 21) * perimeter;
        break;
      case WindowColors.mattGray:
        price =
            (windowSubField[WindowSubfields.mattGrayPrice] / 21) * perimeter;
        break;
      case WindowColors.woodFinish:
        price =
            (windowSubField[WindowSubfields.woodFinishPrice] / 21) * perimeter;
        break;
    }
  } else if (windowSubField[WindowSubfields.priceBasis] ==
      'PERIMETER DOUBLED') {
    num perimeter = (4 * width) + (2 * height);
    switch (ref.read(cartProvider).selectedColor) {
      case WindowColors.brown:
        price = (windowSubField[WindowSubfields.brownPrice] / 21) * perimeter;
        break;
      case WindowColors.white:
        price = (windowSubField[WindowSubfields.whitePrice] / 21) * perimeter;
        break;
      case WindowColors.mattBlack:
        price =
            (windowSubField[WindowSubfields.mattBlackPrice] / 21) * perimeter;
        break;
      case WindowColors.mattGray:
        price =
            (windowSubField[WindowSubfields.mattGrayPrice] / 21) * perimeter;
        break;
      case WindowColors.woodFinish:
        price =
            (windowSubField[WindowSubfields.woodFinishPrice] / 21) * perimeter;
        break;
    }
  } else if (windowSubField[WindowSubfields.priceBasis] == 'STACKED WIDTH') {
    num stackedValue = (2 * height) + (6 * width);
    switch (ref.read(cartProvider).selectedColor) {
      case WindowColors.brown:
        price =
            (windowSubField[WindowSubfields.brownPrice] / 21) * stackedValue;
        break;
      case WindowColors.white:
        price =
            (windowSubField[WindowSubfields.whitePrice] / 21) * stackedValue;
        break;
      case WindowColors.mattBlack:
        price = (windowSubField[WindowSubfields.mattBlackPrice] / 21) *
            stackedValue;
        break;
      case WindowColors.mattGray:
        price =
            (windowSubField[WindowSubfields.mattGrayPrice] / 21) * stackedValue;
        break;
      case WindowColors.woodFinish:
        price = (windowSubField[WindowSubfields.woodFinishPrice] / 21) *
            stackedValue;
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
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting ||
          !snapshot.hasData ||
          snapshot.hasError) return Container();
      List<DocumentSnapshot> filteredOrders = snapshot.data!.docs;
      filteredOrders = filteredOrders.where((order) {
        final orderData = order.data() as Map<dynamic, dynamic>;
        String orderStatus = orderData[OrderFields.orderStatus];
        Map<dynamic, dynamic> review = orderData[OrderFields.review];
        return orderStatus == OrderStatuses.pendingInstallation ||
            orderStatus == OrderStatuses.pendingDelivery ||
            orderStatus == OrderStatuses.forPickUp ||
            orderStatus == OrderStatuses.forDelivery ||
            orderStatus == OrderStatuses.forInstallation ||
            (orderStatus == OrderStatuses.completed && review.isEmpty);
      }).toList();
      //int availableCollectionCount = snapshot.data!.docs.length;

      if (filteredOrders.length > 0)
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
              shape: BoxShape.circle, color: CustomColors.coralRed),
          child: Center(
            child: quicksandWhiteRegular(filteredOrders.length.toString(),
                fontSize: 12),
          ),
        );
      else {
        return Container();
      }
    },
  );
}

StreamBuilder pendingCheckOutStreamBuilder() {
  return StreamBuilder(
    stream: FirebaseFirestore.instance
        .collection(Collections.cart)
        .where(CartFields.clientID,
            isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting ||
          !snapshot.hasData ||
          snapshot.hasError) return Container();
      List<DocumentSnapshot> filteredCartItems = snapshot.data!.docs;
      filteredCartItems = filteredCartItems.where((cart) {
        final cartData = cart.data() as Map<dynamic, dynamic>;
        String itemType = cartData[CartFields.itemType];
        Map<dynamic, dynamic> quotation = cartData[CartFields.quotation];
        String requestStatus = quotation[QuotationFields.requestStatus];
        bool isRequestingAdditionalService =
            quotation[QuotationFields.isRequestingAdditionalService];
        bool isFurniture =
            (itemType == ItemTypes.window || itemType == ItemTypes.door);
        return (isFurniture &&
                (requestStatus == RequestStatuses.approved ||
                    requestStatus == RequestStatuses.denied)) ||
            (!isFurniture && !isRequestingAdditionalService) ||
            (!isFurniture &&
                isRequestingAdditionalService &&
                (requestStatus == RequestStatuses.approved ||
                    requestStatus == RequestStatuses.denied));
      }).toList();
      //int availableCollectionCount = snapshot.data!.docs.length;

      if (filteredCartItems.length > 0)
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
              shape: BoxShape.circle, color: CustomColors.coralRed),
          child: Center(
            child: quicksandWhiteRegular(filteredCartItems.length.toString(),
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

Widget socialsFooter(BuildContext context) {
  return vertical20Pix(
    child: Container(
      width: MediaQuery.of(context).size.width,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Flexible(
              child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              all4Pix(
                child: Icon(Icons.home, color: Colors.white, size: 40),
              ),
              Flexible(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      quicksandWhiteBold(
                          'National Hwy, Los Banos Philippines, 4030',
                          fontSize: 16,
                          textAlign: TextAlign.left),
                      quicksandWhiteRegular('ADDRESS', fontSize: 16)
                    ]),
              ),
            ],
          )),
          Flexible(
              child: Row(
            children: [
              all4Pix(child: Icon(Icons.email, color: Colors.white, size: 40)),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                quicksandWhiteBold('heritage.losbanos@gmail.com',
                    textAlign: TextAlign.left, fontSize: 16),
                quicksandWhiteRegular('EMAIL', fontSize: 16)
              ]),
            ],
          )),
          Flexible(
              child: Row(
            children: [
              all4Pix(child: Icon(Icons.phone, color: Colors.white, size: 40)),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                quicksandWhiteBold('09985657446',
                    textAlign: TextAlign.left, fontSize: 16),
                quicksandWhiteRegular('MOBILE', fontSize: 16)
              ]),
            ],
          )),
          Flexible(
              child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              all4Pix(
                  child: Icon(Icons.facebook, color: Colors.white, size: 40)),
              Flexible(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      quicksandWhiteBold(
                          'Heritage Aluminum Sales Corporation Los Banos',
                          textAlign: TextAlign.left,
                          fontSize: 16),
                      quicksandWhiteRegular('FACEBOOK', fontSize: 16)
                    ]),
              ),
            ],
          )),
        ],
      ),
    ),
  );
}

Widget bottomTitleWidgets(double value, TitleMeta meta) {
  const style = TextStyle(fontSize: 16, color: Colors.white);
  Widget text;
  switch (value.toInt()) {
    case 1:
      text = const Text('JAN', style: style);
      break;
    case 2:
      text = const Text('FEB', style: style);
      break;
    case 3:
      text = const Text('MARCH', style: style);
      break;
    case 4:
      text = const Text('APRIL', style: style);
      break;
    case 5:
      text = const Text('MAY', style: style);
      break;
    case 6:
      text = const Text('JUNE', style: style);
      break;
    case 7:
      text = const Text('JULY', style: style);
      break;
    case 8:
      text = const Text('AUG', style: style);
      break;
    case 9:
      text = const Text('SEPT', style: style);
      break;
    case 10:
      text = const Text('OCT', style: style);
      break;
    case 11:
      text = const Text('NOW', style: style);
      break;
    case 12:
      text = const Text('DEC', style: style);
      break;
    default:
      text = const Text('');
      break;
  }

  return SideTitleWidget(
    axisSide: meta.axisSide,
    space: 10,
    child: text,
  );
}

Widget leftTitleWidgets(double value, TitleMeta meta) {
  const style =
      TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white);
  String text = value.toString();

  return value % 4 == 0
      ? Text(text, style: style, textAlign: TextAlign.center)
      : Container();
}

void showEnlargedPics(BuildContext context, {required String imageURL}) {
  showDialog(
      context: context,
      builder: (context) => AlertDialog(
              content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.7,
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => GoRouter.of(context).pop(),
                      child: quicksandBlackBold('X'))
                ],
              ),
              Container(
                width: MediaQuery.of(context).size.height * 0.65,
                height: MediaQuery.of(context).size.height * 0.65,
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: NetworkImage(imageURL), fit: BoxFit.fill)),
              ),
            ]),
          )));
}

Widget userReviews(List<DocumentSnapshot> orderDocs) {
  return vertical20Pix(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(),
        quicksandWhiteBold('REVIEWS'),
        vertical10Pix(
          child: ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: orderDocs.length,
              itemBuilder: (context, index) {
                final orderData = orderDocs[index];
                String clientID = orderData[OrderFields.clientID];
                Map<String, dynamic> review = orderData[OrderFields.review];
                num rating = review[ReviewFields.rating];
                List<dynamic> imageURLs = review[ReviewFields.imageURLs] ?? [];
                String reviewText = review[ReviewFields.review] ?? '';
                return all4Pix(
                  child: Container(
                      //height: 100,
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.white)),
                      padding: EdgeInsets.all(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FutureBuilder(
                                        future: getThisUserDoc(clientID),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                                  ConnectionState.waiting ||
                                              !snapshot.hasData ||
                                              snapshot.hasError)
                                            return Container();
                                          final userData = snapshot.data!.data()
                                              as Map<dynamic, dynamic>;
                                          String formattedName =
                                              '${userData[UserFields.firstName]} ${userData[UserFields.lastName]}';

                                          return quicksandWhiteRegular(
                                              formattedName);
                                        }),
                                    starRating(rating.toDouble(),
                                        onUpdate: (val) {}, mayMove: false),
                                    quicksandWhiteRegular(reviewText,
                                        fontSize: 16),
                                  ]),
                            ],
                          ),
                          if (imageURLs.isNotEmpty)
                            Row(
                                mainAxisSize: MainAxisSize.min,
                                children: imageURLs
                                    .map((imageURL) => all4Pix(
                                          child: Container(
                                              width: 80,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  image: DecorationImage(
                                                      fit: BoxFit.cover,
                                                      image: NetworkImage(
                                                          imageURL)))),
                                        ))
                                    .toList())
                        ],
                      )),
                );
              }),
        ),
      ],
    ),
  );
}

StreamBuilder uncompletedOrdersStreamBuilder({bool displayifEmpty = true}) {
  return StreamBuilder(
    stream: FirebaseFirestore.instance
        .collection(Collections.orders)
        .where(OrderFields.orderStatus, whereNotIn: [
      OrderStatuses.completed,
      OrderStatuses.denied
    ]).snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting ||
          snapshot.hasError ||
          !snapshot.hasData) return Container();
      List<dynamic> orders = snapshot.data!.docs;

      return (orders.isNotEmpty || displayifEmpty)
          ? quicksandCoralRedBold(orders.length.toString(), fontSize: 28)
          : Container();
    },
  );
}

StreamBuilder pendingAppointmentsStreamBuilder({bool displayifEmpty = true}) {
  return StreamBuilder(
    stream: FirebaseFirestore.instance
        .collection(Collections.appointments)
        .where(AppointmentFields.appointmentStatus, whereIn: [
      AppointmentStatuses.pending,
      AppointmentStatuses.approved
    ]).snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting ||
          snapshot.hasError ||
          !snapshot.hasData) return Container();
      List<dynamic> appointments = snapshot.data!.docs;

      return (appointments.isNotEmpty || displayifEmpty)
          ? quicksandCoralRedBold(appointments.length.toString(), fontSize: 28)
          : Container();
    },
  );
}

StreamBuilder windowItemsStreamBuilder() {
  return StreamBuilder(
    stream: FirebaseFirestore.instance
        .collection(Collections.items)
        .where(ItemFields.itemType, isEqualTo: ItemTypes.window)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting ||
          snapshot.hasError ||
          !snapshot.hasData) return Container();
      List<dynamic> items = snapshot.data!.docs;

      return quicksandCoralRedBold(items.length.toString());
    },
  );
}

StreamBuilder doorItemsStreamBuilder() {
  return StreamBuilder(
    stream: FirebaseFirestore.instance
        .collection(Collections.items)
        .where(ItemFields.itemType, isEqualTo: ItemTypes.door)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting ||
          snapshot.hasError ||
          !snapshot.hasData) return Container();
      List<dynamic> items = snapshot.data!.docs;

      return quicksandCoralRedBold(items.length.toString());
    },
  );
}

StreamBuilder rawMaterialItemsStreamBuilder() {
  return StreamBuilder(
    stream: FirebaseFirestore.instance
        .collection(Collections.items)
        .where(ItemFields.itemType, isEqualTo: ItemTypes.rawMaterial)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting ||
          snapshot.hasError ||
          !snapshot.hasData) return Container();
      List<dynamic> items = snapshot.data!.docs;

      return quicksandCoralRedBold(items.length.toString());
    },
  );
}

StreamBuilder approvedAppointmentsStreamBuilder() {
  return StreamBuilder(
    stream: FirebaseFirestore.instance
        .collection(Collections.appointments)
        .where(AppointmentFields.clientID,
            isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting ||
          !snapshot.hasData ||
          snapshot.hasError) return Container();
      List<DocumentSnapshot> filteredAppointments = snapshot.data!.docs;

      filteredAppointments = filteredAppointments.where((appointment) {
        final appointmentData = appointment.data() as Map<dynamic, dynamic>;
        String appointmentStatus =
            appointmentData[AppointmentFields.appointmentStatus];
        return appointmentStatus == AppointmentStatuses.approved;
      }).toList();

      if (filteredAppointments.length > 0)
        return Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: CustomColors.coralRed),
            child: Center(
                child: quicksandWhiteRegular(
                    filteredAppointments.length.toString(),
                    fontSize: 12)));
      else {
        return Container();
      }
    },
  );
}

void showDenialReasonDialog(BuildContext context,
    {required String denialReason}) {
  showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.4,
              height: MediaQuery.of(context).size.height * 0.5,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      TextButton(
                          onPressed: () => GoRouter.of(context).pop(),
                          child: quicksandBlackBold('X'))
                    ]),
                    quicksandBlackBold('DENIAL REASON', fontSize: 28),
                    Gap(12),
                    quicksandBlackRegular(denialReason,
                        textAlign: TextAlign.left)
                  ],
                ),
              ),
            ),
          ));
}

Widget addressGroup(BuildContext context,
    {required TextEditingController streetController,
    required TextEditingController barangayController,
    required TextEditingController municipalityController,
    required TextEditingController zipCodeController,
    bool isWhite = true}) {
  return Container(
    width: MediaQuery.of(context).size.width * 0.5,
    padding: EdgeInsets.all(20),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isWhite
                ? quicksandWhiteBold('Street Number & Name')
                : quicksandBlackBold('Street Number & Name'),
            CustomTextField(
                text: 'Street number & Name',
                controller: streetController,
                textInputType: TextInputType.text)
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isWhite
                ? quicksandWhiteBold('Barangay')
                : quicksandBlackBold('Barangay'),
            CustomTextField(
                text: 'Barangay',
                controller: barangayController,
                textInputType: TextInputType.text)
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isWhite
                ? quicksandWhiteBold('Municipality')
                : quicksandBlackBold('Municipality'),
            CustomTextField(
                text: 'Municipality',
                controller: municipalityController,
                textInputType: TextInputType.text)
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isWhite
                ? quicksandWhiteBold('Zip Code')
                : quicksandBlackBold('Zip Code'),
            CustomTextField(
                text: 'Zip Code',
                controller: zipCodeController,
                textInputType: TextInputType.number)
          ],
        ),
      ],
    ),
  );
}

void showRequestDetails(BuildContext context,
    {required String requestStatus,
    required String address,
    required String contactNumber,
    required String denialReason}) {
  showDialog(
      context: context,
      builder: (_) => Dialog(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.5,
              padding: EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      TextButton(
                          onPressed: () => GoRouter.of(context).pop(),
                          child: quicksandBlackBold('X'))
                    ]),
                    vertical20Pix(
                        child: quicksandBlackBold('REQUEST DETAILS',
                            fontSize: 36)),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              quicksandBlackBold('Request Status: '),
                              quicksandBlackRegular(requestStatus)
                            ]),
                            Row(children: [
                              quicksandBlackBold('Address: '),
                              quicksandBlackRegular(address)
                            ]),
                            Row(children: [
                              quicksandBlackBold('Contact Number: '),
                              quicksandBlackRegular(contactNumber)
                            ]),
                            if (requestStatus == RequestStatuses.denied) ...[
                              quicksandBlackBold('Denial Reason: '),
                              quicksandBlackRegular(denialReason,
                                  textAlign: TextAlign.left)
                            ]
                          ],
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          ));
}

void showServiceDetails(BuildContext context,
    {required String appointmentStatus,
    required DateTime selectedDate,
    required String address,
    required String contactNumber}) {
  showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.5,
              padding: EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      TextButton(
                          onPressed: () => GoRouter.of(context).pop(),
                          child: quicksandBlackBold('X'))
                    ]),
                    quicksandBlackBold('APPOINTMENT DETAILS', fontSize: 28),
                    Row(children: [
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                quicksandBlackBold('Selected Date: '),
                                quicksandBlackRegular(DateFormat('MMM dd, yyyy')
                                    .format(selectedDate))
                              ],
                            ),
                            Row(children: [
                              quicksandBlackBold('Client Address: '),
                              quicksandBlackRegular(address,
                                  textAlign: TextAlign.left)
                            ]),
                            Row(children: [
                              quicksandBlackBold('Contact Number: '),
                              quicksandBlackRegular(contactNumber,
                                  textAlign: TextAlign.left)
                            ]),
                          ])
                    ])
                  ],
                ),
              ),
            ),
          ));
}
