import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/providers/user_data_provider.dart';
import 'package:imeasure/utils/color_util.dart';
import 'package:imeasure/widgets/left_navigator_widget.dart';
import 'package:imeasure/widgets/text_widgets.dart';

import '../providers/cart_provider.dart';
import '../providers/loading_provider.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/quotation_dialog_util.dart';
import '../utils/string_util.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/custom_text_field_widget.dart';
import '../widgets/dropdown_widget.dart';

class ViewSelectedDoorScreen extends ConsumerStatefulWidget {
  final String itemID;
  const ViewSelectedDoorScreen({super.key, required this.itemID});

  @override
  ConsumerState<ViewSelectedDoorScreen> createState() =>
      _SelectedDoorScreenState();
}

class _SelectedDoorScreenState extends ConsumerState<ViewSelectedDoorScreen> {
  //  PRODUCT VARIABLES
  String name = '';
  String description = '';
  bool isAvailable = false;
  num minWidth = 0;
  num maxWidth = 0;
  num minHeight = 0;
  num maxHeight = 0;
  String imageURL = '';
  int currentImageIndex = 0;
  List<DocumentSnapshot> orderDocs = [];

  //  USER VARIABLES
  final widthController = TextEditingController();
  final heightController = TextEditingController();
  List<dynamic> mandatoryWindowFields = [];
  List<Map<dynamic, dynamic>> optionalWindowFields = [];
  num totalMandatoryPayment = 0;
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
        orderDocs = await getAllWindowOrderDocs(widget.itemID);
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
    return ref.read(cartProvider).selectedColor.isNotEmpty &&
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
                  ? GoRoutes.doors
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
            quicksandWhiteBold('Maximum Height: ${maxHeight.toString()}ft',
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
            orderDocs.isNotEmpty
                ? Wrap(
                    children: orderDocs
                        .map((order) => _orderHistoryEntry(order))
                        .toList())
                : all20Pix(
                    child: quicksandWhiteBold(
                        'THIS DOOR HAS NOT BEEN ORDERED YET.',
                        fontSize: 20)),
          ],
        ),
      ),
    );
  }

  Widget _orderHistoryEntry(DocumentSnapshot orderDoc) {
    final orderData = orderDoc.data() as Map<dynamic, dynamic>;
    String status = orderData[OrderFields.orderStatus];
    String clientID = orderData[OrderFields.clientID];
    String glassType =
        orderData[OrderFields.quotation][QuotationFields.glassType];
    String color = orderData[OrderFields.quotation][QuotationFields.color];
    double price = orderData[OrderFields.quotation]
            [QuotationFields.laborPrice] +
        orderData[OrderFields.quotation][QuotationFields.itemOverallPrice];

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
        flex: 3,
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
                          width: MediaQuery.of(context).size.width * 0.15,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              quicksandWhiteBold('Width'),
                              CustomTextField(
                                  text: 'Insert Width',
                                  controller: widthController,
                                  textInputType: TextInputType.number),
                            ],
                          )),
                      SizedBox(
                          width: MediaQuery.of(context).size.width * 0.15,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              quicksandWhiteBold('Height'),
                              CustomTextField(
                                  text: 'Insert Height',
                                  controller: heightController,
                                  textInputType: TextInputType.number),
                            ],
                          )),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          quicksandWhiteBold('Door Color'),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.15,
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
                            ], 'Select door color', false),
                          ),
                        ],
                      ),
                    ]),
                if (optionalWindowFields.isNotEmpty) _optionalWindowFields(),
              ],
            ),
            _userButtons()
          ],
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
                        }),
                    quicksandWhiteRegular(
                        optionalWindowFields[index]
                                [OptionalWindowFields.optionalFields]
                            [WindowSubfields.name],
                        fontSize: 14),
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
                addFurnitureItemToCart(context, ref,
                    itemID: widget.itemID,
                    itemType: ItemTypes.window,
                    width: double.parse(widthController.text),
                    height: double.parse(heightController.text),
                    mandatoryWindowFields: mandatoryWindowFields,
                    optionalWindowFields: pricedOptionalWindowFields(ref,
                        width: double.parse(widthController.text),
                        height: double.parse(heightController.text),
                        oldOptionalWindowFields: optionalWindowFields));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content:
                        Text('Please fill up all the required fields first.')));
              }
            },
            child: quicksandWhiteBold('ADD TO CART')),
        submitButton(context, label: 'VIEW ESTIMATED QUOTE', onPress: () {
          if (mayProceedToInitialQuotationScreen()) {
            showQuotationDialog(context, ref,
                widthController: widthController,
                heightController: heightController,
                mandatoryWindowFields: mandatoryWindowFields,
                optionalWindowFields: optionalWindowFields,
                itemType: ItemTypes.door);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content:
                    Text('Please fill up all the required fields first.')));
          }
        })
      ],
    );
  }
}
