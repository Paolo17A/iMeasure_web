import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/providers/user_data_provider.dart';
import 'package:imeasure/utils/color_util.dart';
import 'package:imeasure/widgets/custom_text_field_widget.dart';
import 'package:imeasure/widgets/left_navigator_widget.dart';
import 'package:imeasure/widgets/text_widgets.dart';

import '../models/glass_model.dart';
import '../providers/cart_provider.dart';
import '../providers/loading_provider.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/dropdown_widget.dart';

class ViewSelectedWindowScreen extends ConsumerStatefulWidget {
  final String itemID;
  const ViewSelectedWindowScreen({super.key, required this.itemID});

  @override
  ConsumerState<ViewSelectedWindowScreen> createState() =>
      _SelectedWindowScreenState();
}

class _SelectedWindowScreenState
    extends ConsumerState<ViewSelectedWindowScreen> {
  //  PRODUCT VARIABLES
  String name = '';
  String description = '';
  bool isAvailable = false;
  num minWidth = 0;
  num maxWidth = 0;
  num minHeight = 0;
  num maxHeight = 0;
  String imageURL = '';
  //int currentImageIndex = 0;
  //List<DocumentSnapshot> orderDocs = [];

  //  USER VARIABLES
  final widthController = TextEditingController();
  final heightController = TextEditingController();
  List<dynamic> mandatoryWindowFields = [];
  List<Map<dynamic, dynamic>> optionalWindowFields = [];
  num totalMandatoryPayment = 0;
  num totalGlassPrice = 0;
  num totalOverallPayment = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      ref.read(loadingProvider.notifier).toggleLoading(true);
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final goRouter = GoRouter.of(context);
      try {
        if (!hasLoggedInUser()) {
          goRouter.goNamed(GoRoutes.home);
          return;
        }

        ref.read(userDataProvider).setUserType(await getCurrentUserType());

        //  GET PRODUCT DATA
        final item = await getThisItemDoc(widget.itemID);
        final itemData = item.data() as Map<dynamic, dynamic>;
        name = itemData[ItemFields.name];
        description = itemData[ItemFields.description];
        isAvailable = itemData[ItemFields.isAvailable];
        imageURL = itemData[ItemFields.imageURL];
        minHeight = itemData[ItemFields.minHeight];
        maxHeight = itemData[ItemFields.maxHeight];
        minWidth = itemData[ItemFields.minWidth];
        maxWidth = itemData[ItemFields.maxWidth];
        //orderDocs = await getAllWindowOrderDocs(widget.windowID);

        if (ref.read(userDataProvider).userType == UserTypes.client) {
          List<dynamic> windowFields = itemData[ItemFields.windowFields];

          mandatoryWindowFields = windowFields
              .where((windowField) => windowField[WindowSubfields.isMandatory])
              .toList();
          List<dynamic> _optionalWindowFields = windowFields
              .where((windowField) => !windowField[WindowSubfields.isMandatory])
              .toList();
          for (var optionalFields in _optionalWindowFields) {
            optionalWindowFields.add({
              OptionalWindowFields.isSelected: false,
              OptionalWindowFields.optionalFields: optionalFields,
              OptionalWindowFields.price: 0
            });
          }
        }

        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting selected product: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  bool mayProceedToInitialQuotationScreen() {
    return ref.read(cartProvider).selectedGlassType.isNotEmpty &&
        ref.read(cartProvider).selectedColor.isNotEmpty &&
        widthController.text.isNotEmpty &&
        double.tryParse(widthController.text) != null &&
        double.parse(widthController.text.trim()) >= minWidth &&
        double.parse(widthController.text.trim()) <= maxWidth &&
        heightController.text.isNotEmpty &&
        double.tryParse(heightController.text) != null &&
        double.parse(heightController.text.trim()) >= minHeight &&
        double.parse(heightController.text.trim()) <= maxHeight;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(cartProvider);
    return Scaffold(
      body: switchedLoadingContainer(
          ref.read(loadingProvider).isLoading,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leftNavigator(context, path: GoRoutes.windows),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _backButton(),
                      horizontal5Percent(context,
                          child: ref.read(userDataProvider).userType ==
                                  UserTypes.admin
                              ? _adminWidgets()
                              : _userWidgets()),
                    ],
                  ),
                ),
              ),
            ],
          )),
    );
  }

  Widget _backButton() {
    return all10Pix(
        child: Row(children: [
      backButton(context,
          onPress: () => GoRouter.of(context).goNamed(
              ref.read(userDataProvider).userType == UserTypes.admin
                  ? GoRoutes.windows
                  : GoRoutes.shop))
    ]));
  }

  //============================================================================
  //==ADMIN WIDGETS=============================================================
  //============================================================================
  Widget _adminWidgets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_windowDetails(), orderHistory()],
    );
  }

  Widget _windowDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Image.network(
          imageURL,
          width: 150,
          height: 150,
          fit: BoxFit.cover,
        ),
        quicksandWhiteBold('\t\tAVAILABLE: ${isAvailable ? 'YES' : 'NO'}'),
        Gap(20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          quicksandWhiteBold('Minimum Width: ${minWidth.toString()}ft',
              fontSize: 16),
          Gap(40),
          quicksandWhiteBold('Minimum Height: ${minHeight.toString()}ft',
              fontSize: 16),
        ]),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            quicksandWhiteBold('Maximum Width: ${maxWidth.toString()}ft',
                fontSize: 16),
            Gap(40),
            quicksandWhiteBold('Maximum Length: ${minHeight.toString()}ft',
                fontSize: 16)
          ],
        ),
        Divider(color: CustomColors.lavenderMist)
      ]),
    );
  }

  Widget orderHistory() {
    return vertical20Pix(
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(children: [
              quicksandWhiteBold(name, fontSize: 36, textAlign: TextAlign.left)
            ]),
            /*orderDocs.isNotEmpty
                ? Wrap(
                    children: orderDocs
                        .map((order) => _orderHistoryEntry(order))
                        .toList())
                : all20Pix(
                    child: quicksandWhiteBold(
                        'THIS WINDOW HAS NOT BEEN ORDERED YET.',
                        fontSize: 20)),*/
          ],
        ),
      ),
    );
  }

  Widget _orderHistoryEntry(DocumentSnapshot orderDoc) {
    final orderData = orderDoc.data() as Map<dynamic, dynamic>;
    String status = orderData[OrderFields.purchaseStatus];
    String clientID = orderData[OrderFields.clientID];
    String glassType = orderData[OrderFields.glassType];
    String color = orderData[OrderFields.color];
    double price = orderData[OrderFields.laborPrice] +
        orderData[OrderFields.windowOverallPrice];

    return FutureBuilder(
      future: getThisUserDoc(clientID),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData ||
            snapshot.hasError) return snapshotHandler(snapshot);

        final clientData = snapshot.data!.data() as Map<dynamic, dynamic>;
        String profileImageURL = clientData[UserFields.profileImageURL];
        print(profileImageURL);
        String firstName = clientData[UserFields.firstName];
        String lastName = clientData[UserFields.lastName];

        return all10Pix(
            child: Container(
          width: 350,
          height: 350,
          decoration: BoxDecoration(border: Border.all(color: Colors.white)),
          padding: EdgeInsets.all(10),
          child: Column(
            children: [
              buildProfileImage(profileImageURL: profileImageURL),
              Gap(10),
              quicksandWhiteBold('$firstName $lastName', fontSize: 20),
              Row(
                children: [
                  SizedBox(
                    width: 320,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        quicksandWhiteRegular('Glass Type: $glassType',
                            fontSize: 18, textAlign: TextAlign.left),
                        quicksandWhiteRegular('Color: $color', fontSize: 12),
                        quicksandWhiteRegular('Status: $status', fontSize: 12),
                        Gap(10),
                        quicksandWhiteBold('PHP ${formatPrice(price)}'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ));
      },
    );
  }

  //============================================================================
  //==USER WIDGETS==============================================================
  //============================================================================
  Widget _userWidgets() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.9,
      child: Column(children: [
        vertical10Pix(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _itemImage(),
            Gap(MediaQuery.of(context).size.width * 0.05),
            _itemFieldInputs()
          ]),
        ),
        Divider(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            quicksandWhiteBold(name, fontSize: 28),
            all10Pix(
              child: quicksandWhiteRegular(description,
                  textAlign: TextAlign.left, fontSize: 16),
            ),
            Gap(16),
            Row(children: [
              quicksandWhiteBold('Available Width: '),
              Gap(8),
              quicksandWhiteRegular('$minWidth - ${maxWidth}ft')
            ]),
            Row(children: [
              quicksandWhiteBold('Available Height: '),
              Gap(8),
              quicksandWhiteRegular('$minHeight - ${maxHeight}ft')
            ]),
          ],
        )
      ]),
    );
  }

  Widget _itemImage() {
    return Flexible(
        child: imageURL.isNotEmpty
            ? square300NetworkImage(imageURL)
            : Container(
                width: 300,
                height: 300,
                decoration:
                    BoxDecoration(border: Border.all(color: Colors.white)),
              ));
  }

  Widget _itemFieldInputs() {
    return Flexible(
        flex: 2,
        child: SizedBox(
          // height: 300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              //  INPUT FIELDS
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        SizedBox(
                            width: MediaQuery.of(context).size.width * 0.2,
                            child: CustomTextField(
                                text: 'Insert Height',
                                controller: heightController,
                                textInputType: TextInputType.number)),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.2,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5)),
                          child: dropdownWidget(
                              ref.read(cartProvider).selectedGlassType,
                              (newVal) {
                            ref.read(cartProvider).setGlassType(newVal!);
                          },
                              allGlassModels
                                  .map((glassModel) => glassModel.glassTypeName)
                                  .toList(),
                              'Select your glass type',
                              false),
                        ),
                      ]),
                  Gap(20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      SizedBox(
                          width: MediaQuery.of(context).size.width * 0.2,
                          child: CustomTextField(
                              text: 'Insert Width',
                              controller: widthController,
                              textInputType: TextInputType.number)),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.2,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5)),
                        child: dropdownWidget(
                            ref.read(cartProvider).selectedColor, (newVal) {
                          ref.read(cartProvider).setSelectedColor(newVal!);
                        }, [
                          WindowColors.brown,
                          WindowColors.white,
                          WindowColors.mattBlack,
                          WindowColors.mattGray,
                          WindowColors.woodFinish
                        ], 'Select window color', false),
                      )
                    ],
                  ),
                  if (optionalWindowFields.isNotEmpty) _optionalWindowFields(),
                ],
              ),
              _userButtons()
            ],
          ),
        ));
  }

  Widget _optionalWindowFields() {
    return all20Pix(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          quicksandWhiteBold('Optional Window Fields', fontSize: 16),
          ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: optionalWindowFields.length,
              itemBuilder: (context, index) {
                return Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Checkbox(
                        value: optionalWindowFields[index]
                            [OptionalWindowFields.isSelected],
                        onChanged: (newVal) {
                          setState(() {
                            optionalWindowFields[index]
                                [OptionalWindowFields.isSelected] = newVal;
                          });

                          //setTotalOverallPayment();
                        }),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.35,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          quicksandWhiteRegular(
                              optionalWindowFields[index]
                                      [OptionalWindowFields.optionalFields]
                                  [WindowSubfields.name],
                              fontSize: 14),
                          /*quicksandWhiteRegular(
                              'PHP ${formatPrice(optionalWindowFields[index][OptionalWindowFields.price].toDouble())}',
                              fontSize: 14),*/
                        ],
                      ),
                    ),
                  ],
                );
              }),
        ],
      ),
    );
  }

  Widget _userButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
            onPressed: () {
              if (mayProceedToInitialQuotationScreen()) {
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content:
                        Text('Please fill up all the required fields first.')));
              }
            },
            child: quicksandWhiteBold('ADD TO CART')),
        submitButton(context, label: 'VIEW ESTIMATED QUOTE', onPress: () {
          if (mayProceedToInitialQuotationScreen()) {
            showQuotation();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content:
                    Text('Please fill up all the required fields first.')));
          }
        })
      ],
    );
  }

  void setTotalOverallPayment() {
    num totalOptionalPayments = 0;
    for (var optionalFields in optionalWindowFields) {
      if (optionalFields['isSelected']) {
        totalOptionalPayments += optionalFields['price'];
      }
    }
    setState(() {
      totalOverallPayment = totalMandatoryPayment + totalOptionalPayments;
    });
  }

  void showQuotation() {
    num optionalPrice = 0;
    for (int i = 0; i < optionalWindowFields.length; i++) {
      num price = 0;
      if (optionalWindowFields[i][OptionalWindowFields.optionalFields]
              [WindowSubfields.priceBasis] ==
          'HEIGHT') {
        switch (ref.read(cartProvider).selectedColor) {
          case WindowColors.brown:
            price = (optionalWindowFields[i]
                            [OptionalWindowFields.optionalFields]
                        [WindowSubfields.brownPrice] /
                    21) *
                double.parse(heightController.text);
            break;
          case WindowColors.white:
            price = (optionalWindowFields[i]
                            [OptionalWindowFields.optionalFields]
                        [WindowSubfields.whitePrice] /
                    21) *
                double.parse(heightController.text);
            break;
          case WindowColors.mattBlack:
            price = (optionalWindowFields[i]
                            [OptionalWindowFields.optionalFields]
                        [WindowSubfields.mattBlackPrice] /
                    21) *
                double.parse(heightController.text);
            break;
          case WindowColors.mattGray:
            price = (optionalWindowFields[i]
                            [OptionalWindowFields.optionalFields]
                        [WindowSubfields.mattGrayPrice] /
                    21) *
                double.parse(heightController.text);
            break;
          case WindowColors.woodFinish:
            price = (optionalWindowFields[i]
                            [OptionalWindowFields.optionalFields]
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
            price = (optionalWindowFields[i]
                            [OptionalWindowFields.optionalFields]
                        [WindowSubfields.brownPrice] /
                    21) *
                double.parse(widthController.text);
            break;
          case WindowColors.white:
            price = (optionalWindowFields[i]
                            [OptionalWindowFields.optionalFields]
                        [WindowSubfields.whitePrice] /
                    21) *
                double.parse(widthController.text);
            break;
          case WindowColors.mattBlack:
            price = (optionalWindowFields[i]
                            [OptionalWindowFields.optionalFields]
                        [WindowSubfields.mattBlackPrice] /
                    21) *
                double.parse(widthController.text);
            break;
          case WindowColors.mattGray:
            price = (optionalWindowFields[i]
                            [OptionalWindowFields.optionalFields]
                        [WindowSubfields.mattGrayPrice] /
                    21) *
                double.parse(widthController.text);
            break;
          case WindowColors.woodFinish:
            price = (optionalWindowFields[i]
                            [OptionalWindowFields.optionalFields]
                        [WindowSubfields.woodFinishPrice] /
                    21) *
                double.parse(widthController.text);
            break;
        }
      }
      optionalWindowFields[i][OptionalWindowFields.price] = price;
      if (optionalWindowFields[i][OptionalWindowFields.isSelected])
        optionalPrice += price;
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

    totalGlassPrice =
        getProperGlass(ref.read(cartProvider).selectedGlassType) != null
            ? (getProperGlass(ref.read(cartProvider).selectedGlassType)!
                    .pricePerSFT) *
                double.parse(widthController.text) *
                double.parse(heightController.text)
            : 0;
    totalMandatoryPayment = totalMandatoryPayment + totalGlassPrice;
    totalOverallPayment = totalMandatoryPayment + optionalPrice;

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                quicksandBlackRegular('Glass: ', fontSize: 14),
                                quicksandBlackRegular(
                                    'PHP ${formatPrice(totalGlassPrice.toDouble())}',
                                    fontSize: 14),
                              ],
                            ),
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
            ));
  }
}
