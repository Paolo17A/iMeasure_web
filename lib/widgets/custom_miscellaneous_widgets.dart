import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:imeasure/widgets/custom_padding_widgets.dart';
import 'package:imeasure/widgets/custom_text_field_widget.dart';
import 'package:imeasure/widgets/dropdown_widget.dart';
import 'package:imeasure/widgets/text_widgets.dart';

import '../utils/color_util.dart';

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

Widget roundedSlateBlueContainer(BuildContext context,
    {required Widget child}) {
  return Container(
      width: MediaQuery.of(context).size.width * 0.5,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: CustomColors.deepNavyBlue.withOpacity(0.8)),
      padding: const EdgeInsets.all(20),
      child: child);
}

Container viewContentContainer(BuildContext context, {required Widget child}) {
  return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
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
            border: customBorder,
            borderRadius: customBorderRadius),
        child: ClipRRect(
          child: Center(
              child: SelectableText(text,
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
      flex: flex, backgroundColor: Colors.transparent, textColor: Colors.black);
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
            border: customBorder,
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
    child: Center(child: quicksandBlackBold(text, fontSize: 44)),
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

Widget buildProfileImage({required String profileImageURL}) {
  return profileImageURL.isNotEmpty
      ? CircleAvatar(
          radius: 70,
          backgroundColor: CustomColors.deepNavyBlue,
          backgroundImage: NetworkImage(profileImageURL),
        )
      : const CircleAvatar(
          radius: 70,
          backgroundColor: CustomColors.deepNavyBlue,
          child: Icon(
            Icons.person,
            color: Colors.white,
            size: 80,
          ));
}

Widget selectedMemoryImageDisplay(
    Uint8List? imageStream, Function deleteImage) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40),
    child: Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.black)),
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
                      color: CustomColors.deepNavyBlue)),
            )
          ],
        ),
      ),
    ),
  );
}

Widget selectedNetworkImageDisplay(String imageSource) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40),
    child: Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.black)),
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
          border: Border.all(), borderRadius: BorderRadius.circular(10)),
      padding: EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    quicksandBlackBold('Field Name'),
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
                width: MediaQuery.of(context).size.width * 0.3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    quicksandBlackBold('Is Mandatory Field'),
                    Checkbox(value: isMandatory, onChanged: onCheckboxPress),
                  ],
                ),
              )
            ],
          ),
          Gap(10),
          vertical10Pix(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                quicksandBlackBold('Price Basis'),
                SizedBox(
                  height: 40,
                  child: dropdownWidget(priceBasis, onPriceBasisChange,
                      ['WIDTH', 'HEIGHT'], priceBasis, false),
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
                    quicksandBlackBold('Brown Price'),
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
                    quicksandBlackBold('White Price'),
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
                      quicksandBlackBold('Matt Black Price'),
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
                      quicksandBlackBold('Matt Gray Price'),
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
                      quicksandBlackBold('Wood Finish Price'),
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
          vertical20Pix(
            child: Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [CustomColors.emeraldGreen, CustomColors.azure])),
              child: TextButton(
                  onPressed: () => onRemoveField(),
                  child: quicksandBlackBold('REMOVE SUBFIELD', fontSize: 12)),
            ),
          )
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
          border: Border.all(), borderRadius: BorderRadius.circular(10)),
      padding: EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    quicksandBlackBold('Accessory Name'),
                    CustomTextField(
                        text: 'Accessory Name',
                        height: 40,
                        controller: nameController,
                        textInputType: TextInputType.name),
                  ],
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    quicksandBlackBold('Accessory Price'),
                    CustomTextField(
                        text: 'Accessory Price',
                        height: 40,
                        controller: priceController,
                        textInputType: TextInputType.number),
                  ],
                ),
              ),
            ],
          ),
          vertical20Pix(
            child: Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [CustomColors.emeraldGreen, CustomColors.azure])),
              child: TextButton(
                  onPressed: () => onRemoveField(),
                  child: quicksandBlackBold('REMOVE ACCESSORY', fontSize: 12)),
            ),
          )
        ],
      ),
    ),
  );
}
