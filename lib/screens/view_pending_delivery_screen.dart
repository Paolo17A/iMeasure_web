import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/providers/cart_provider.dart';
import 'package:imeasure/providers/loading_provider.dart';
import 'package:imeasure/utils/string_util.dart';
import 'package:imeasure/widgets/custom_miscellaneous_widgets.dart';
import 'package:imeasure/widgets/custom_padding_widgets.dart';
import 'package:imeasure/widgets/custom_text_field_widget.dart';
import 'package:imeasure/widgets/left_navigator_widget.dart';
import 'package:intl/intl.dart';

import '../utils/color_util.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/text_widgets.dart';

class ViewPendingDeliveryScreen extends ConsumerStatefulWidget {
  const ViewPendingDeliveryScreen({super.key});

  @override
  ConsumerState<ViewPendingDeliveryScreen> createState() =>
      _ViewPendingDeliveryScreenState();
}

class _ViewPendingDeliveryScreenState
    extends ConsumerState<ViewPendingDeliveryScreen> {
  final deliveryController = TextEditingController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final goRouter = GoRouter.of(context);
      try {
        ref.read(loadingProvider).toggleLoading(true);
        if (!hasLoggedInUser()) {
          ref.read(loadingProvider).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);
          return;
        }
        ref
            .read(cartProvider)
            .setCartItems(await getAllCartItemsWithNoDeliveryPrice());
        ref.read(loadingProvider).toggleLoading(false);
      } catch (error) {
        ref.read(loadingProvider).toggleLoading(false);
        scaffoldMessenger.showSnackBar(SnackBar(
            content: Text(
                'Error getting cart entries pending labor price: $error')));
      }
    });
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
              leftNavigator(context, path: GoRoutes.orders),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: SingleChildScrollView(
                  child: horizontal5Percent(context,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      ongoingOrdersButton(context),
                                      pendingLaborAndPriceButton(context),
                                      _pendingDeliveryHeader(),
                                      transactionsButton(context)
                                    ]),
                              ),
                              Gap(20),
                              // Sorting pop-up
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  quicksandWhiteBold('Sort:'),
                                  PopupMenuButton(
                                      color: CustomColors.forestGreen,
                                      iconColor: Colors.white,
                                      onSelected: (value) {
                                        ref
                                            .read(cartProvider)
                                            .setIsChronological(
                                                bool.parse(value));
                                      },
                                      itemBuilder: (context) => [
                                            PopupMenuItem(
                                                value: false.toString(),
                                                child: quicksandWhiteBold(
                                                    'Newest to Oldest')),
                                            PopupMenuItem(
                                                value: true.toString(),
                                                child: quicksandWhiteBold(
                                                    'Oldest to Newest')),
                                          ]),
                                ],
                              )
                            ],
                          ),
                          _ordersContainer()
                        ],
                      )),
                ),
              )
            ],
          )),
    );
  }

  Widget _pendingDeliveryHeader() {
    return vertical20Pix(
      child: Row(
        children: [
          forestGreenQuicksandBold('Pending\nDelivery Cost: ', fontSize: 20),
          Gap(4),
          quicksandCoralRedBold(
              ref.read(cartProvider).cartItems.length.toString(),
              fontSize: 28)
        ],
      ),
    );
  }

  Widget _ordersContainer() {
    return Column(
      children: [
        _pendingItemLabelRow(),
        ref.read(cartProvider).cartItems.isNotEmpty
            ? _orderEntries()
            : viewContentUnavailable(context,
                text: 'NO AVAILABLE ITEMS PENDING DELIVERY PRICE'),
      ],
    );
  }

  Widget _pendingItemLabelRow() {
    return viewContentLabelRow(context, children: [
      viewFlexLabelTextCell('Buyer', 2),
      viewFlexLabelTextCell('Item', 2),
      viewFlexLabelTextCell('Cost', 2),
      viewFlexLabelTextCell('Quantity', 1),
      viewFlexLabelTextCell('Date Requested', 2),
      viewFlexLabelTextCell('Action', 3),
    ]);
  }

  Widget _orderEntries() {
    return ListView.builder(
        shrinkWrap: true,
        itemCount: ref.read(cartProvider).cartItems.length,
        itemBuilder: (context, index) {
          final cartData = ref.read(cartProvider).cartItems[index].data()
              as Map<dynamic, dynamic>;
          String clientID = cartData[CartFields.clientID];
          String itemID = cartData[CartFields.itemID];
          num quantity = cartData[CartFields.quantity];
          num itemOverallPrice =
              cartData[OrderFields.quotation][QuotationFields.itemOverallPrice];
          dynamic quotation = cartData[CartFields.quotation];
          DateTime dateLastModified =
              (cartData[CartFields.dateLastModified] as Timestamp).toDate();
          String requestedAddress =
              quotation[QuotationFields.requestAddress] ?? '';
          return FutureBuilder(
              future: getThisUserDoc(clientID),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting ||
                    !snapshot.hasData ||
                    snapshot.hasError) return Container();

                final clientData =
                    snapshot.data!.data() as Map<dynamic, dynamic>;
                String formattedName =
                    '${clientData[UserFields.firstName]} ${clientData[UserFields.lastName]}';

                return FutureBuilder(
                    future: getThisItemDoc(itemID),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting ||
                          !snapshot.hasData ||
                          snapshot.hasError) return Container();

                      final itemData =
                          snapshot.data!.data() as Map<dynamic, dynamic>;
                      String name = itemData[WindowFields.name];
                      List<dynamic> imageURLs = itemData[ItemFields.imageURLs];

                      Color entryColor = Colors.white;
                      Color backgroundColor = Colors.transparent;

                      return _pendingLaborCostEntry(
                          formattedName: formattedName,
                          backgroundColor: backgroundColor,
                          entryColor: entryColor,
                          name: name,
                          itemOverallPrice: itemOverallPrice,
                          quantity: quantity,
                          cartID: ref.read(cartProvider).cartItems[index].id,
                          quotation: quotation,
                          imageURLs: imageURLs,
                          dateLastModified: dateLastModified,
                          requestedAddress: requestedAddress);
                    });
                //  Item Variables
              });
          //  Client Variables
        });
  }

  Widget _pendingLaborCostEntry(
      {required String formattedName,
      required Color backgroundColor,
      required Color entryColor,
      required String name,
      required num itemOverallPrice,
      required num quantity,
      required String cartID,
      required Map<dynamic, dynamic> quotation,
      required DateTime dateLastModified,
      required List<dynamic> imageURLs,
      required String requestedAddress}) {
    return viewContentEntryRow(context, children: [
      viewFlexTextCell(formattedName,
          flex: 2, backgroundColor: backgroundColor, textColor: entryColor),
      viewFlexTextCell(name,
          flex: 2, backgroundColor: backgroundColor, textColor: entryColor),
      viewFlexTextCell('PHP ${formatPrice(itemOverallPrice.toDouble())}',
          flex: 2, backgroundColor: backgroundColor, textColor: entryColor),
      viewFlexTextCell(quantity.toString(),
          flex: 1, backgroundColor: backgroundColor, textColor: entryColor),
      viewFlexTextCell(DateFormat('MMM dd, yyyy').format(dateLastModified),
          flex: 2, backgroundColor: backgroundColor, textColor: entryColor),
      viewFlexActionsCell([
        Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.white)),
          child: TextButton(
              onPressed: () => showDeliveryCostDialog(cartID, requestedAddress),
              child: quicksandWhiteBold('SET DELIVERY COST', fontSize: 12)),
        ),
        Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.white)),
          child: TextButton(
              onPressed: () =>
                  showDenyDeliveryRequestDialog(cartID, requestedAddress),
              child: quicksandWhiteBold('DENY DELIVERY REQUEST', fontSize: 12)),
        )
      ], flex: 3, backgroundColor: backgroundColor),
    ]);
  }

  void showDeliveryCostDialog(String cartID, String requestedAddress) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Dialog(
              child: SingleChildScrollView(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.4,
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        TextButton(
                            onPressed: () => GoRouter.of(context).pop(),
                            child: quicksandBlackBold('X'))
                      ]),
                      quicksandBlackBold('SET DELIVERY COST', fontSize: 28),
                      Row(children: [
                        quicksandBlackBold('Requested Address: '),
                        quicksandBlackRegular(requestedAddress)
                      ]),
                      Row(children: [quicksandBlackBold('DELIVERY COST')]),
                      CustomTextField(
                          text: 'Delivery Cost',
                          controller: deliveryController,
                          textInputType: TextInputType.number),
                      Gap(20),
                      ElevatedButton(
                          onPressed: () => setCartItemDeliveryPrice(
                              context, ref,
                              cartID: cartID,
                              deliveryPriceController: deliveryController),
                          style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5))),
                          child: quicksandWhiteRegular('Set Delivery Cost'))
                    ],
                  ),
                ),
              ),
            ));
  }

  void showDenyDeliveryRequestDialog(String cartID, String requestedAddress) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Dialog(
              child: SingleChildScrollView(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.4,
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        TextButton(
                            onPressed: () => GoRouter.of(context).pop(),
                            child: quicksandBlackBold('X'))
                      ]),
                      quicksandBlackBold('DENY DELIVERY REQUEST', fontSize: 28),
                      Row(children: [
                        quicksandBlackBold('Requested Address: '),
                        quicksandBlackRegular(requestedAddress)
                      ]),
                      Row(children: [quicksandBlackBold('DENIAL REASON')]),
                      CustomTextField(
                          text: 'Denial Reason',
                          controller: deliveryController,
                          textInputType: TextInputType.text),
                      Gap(20),
                      ElevatedButton(
                          onPressed: () => denyCartItemDeliveryRequest(
                              context, ref,
                              cartID: cartID,
                              deliveryController: deliveryController),
                          style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5))),
                          child: quicksandWhiteRegular('Deny Delivery Request'))
                    ],
                  ),
                ),
              ),
            ));
  }
}
