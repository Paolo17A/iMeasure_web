import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/providers/cart_provider.dart';
import 'package:imeasure/providers/loading_provider.dart';
import 'package:imeasure/utils/quotation_dialog_util.dart';
import 'package:imeasure/utils/string_util.dart';
import 'package:imeasure/widgets/custom_miscellaneous_widgets.dart';
import 'package:imeasure/widgets/custom_padding_widgets.dart';
import 'package:imeasure/widgets/custom_text_field_widget.dart';
import 'package:imeasure/widgets/left_navigator_widget.dart';

import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../widgets/text_widgets.dart';

class ViewPendingLaborScreen extends ConsumerStatefulWidget {
  const ViewPendingLaborScreen({super.key});

  @override
  ConsumerState<ViewPendingLaborScreen> createState() =>
      _ViewPendingLaborScreenState();
}

class _ViewPendingLaborScreenState
    extends ConsumerState<ViewPendingLaborScreen> {
  final laborCostController = TextEditingController();
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
            .setCartItems(await getAllCartItemsWithNoLaborPrice());
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
              leftNavigator(context, path: GoRoutes.pendingLabor),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: SingleChildScrollView(
                  child: horizontal5Percent(context,
                      child: Column(
                        children: [_pendingLaborHeader(), _ordersContainer()],
                      )),
                ),
              )
            ],
          )),
    );
  }

  Widget _pendingLaborHeader() {
    return vertical20Pix(
      child: Row(
        children: [
          quicksandWhiteBold('Pending Labor Price: ', fontSize: 28),
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
                text: 'NO AVAILABLE ITEMS PENDING LABOR PRICE'),
      ],
    );
  }

  Widget _pendingItemLabelRow() {
    return viewContentLabelRow(context, children: [
      viewFlexLabelTextCell('Buyer', 2),
      viewFlexLabelTextCell('Item', 2),
      viewFlexLabelTextCell('Cost', 2),
      viewFlexLabelTextCell('Quantity', 2),
      viewFlexLabelTextCell('Status', 2),
      viewFlexLabelTextCell('Quotation', 2),
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
                      List<dynamic> accessoryFields =
                          itemData[ItemFields.accessoryFields];
                      Color entryColor = Colors.white;
                      Color backgroundColor = Colors.transparent;

                      return viewContentEntryRow(context, children: [
                        viewFlexTextCell(formattedName,
                            flex: 2,
                            backgroundColor: backgroundColor,
                            textColor: entryColor),
                        viewFlexTextCell(name,
                            flex: 2,
                            backgroundColor: backgroundColor,
                            textColor: entryColor),
                        viewFlexTextCell(
                            'PHP ${formatPrice(itemOverallPrice.toDouble())}',
                            flex: 2,
                            backgroundColor: backgroundColor,
                            textColor: entryColor),
                        viewFlexTextCell(quantity.toString(),
                            flex: 2,
                            backgroundColor: backgroundColor,
                            textColor: entryColor),
                        viewFlexActionsCell([
                          Container(
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.white)),
                            child: TextButton(
                                onPressed: () => showLaborCostDialog(
                                    ref.read(cartProvider).cartItems[index].id),
                                child: quicksandWhiteBold('SET LABOR COST',
                                    fontSize: 12)),
                          )
                        ], flex: 2, backgroundColor: backgroundColor),
                        viewFlexActionsCell([
                          ElevatedButton(
                              onPressed: () {
                                final mandatoryWindowFields =
                                    quotation[QuotationFields.mandatoryMap];
                                final optionalWindowFields =
                                    quotation[QuotationFields.optionalMap]
                                        as List<dynamic>;
                                showCartQuotationDialog(context, ref,
                                    totalOverallPayment: itemOverallPrice,
                                    laborPrice: 0,
                                    mandatoryWindowFields:
                                        mandatoryWindowFields,
                                    optionalWindowFields: optionalWindowFields,
                                    accessoryFields: accessoryFields,
                                    width: quotation[QuotationFields.width],
                                    height: quotation[QuotationFields.height],
                                    itemName: name,
                                    imageURLs: imageURLs);
                              },
                              child:
                                  quicksandWhiteRegular('VIEW', fontSize: 12))
                        ], flex: 2, backgroundColor: backgroundColor),
                      ]);
                    });
                //  Item Variables
              });
          //  Client Variables
        });
  }

  void showLaborCostDialog(String cartID) {
    laborCostController.clear();
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
                      quicksandBlackBold('SET LABOR COST', fontSize: 28),
                      CustomTextField(
                          text: 'Labor Post',
                          controller: laborCostController,
                          textInputType: TextInputType.number),
                      Gap(20),
                      ElevatedButton(
                          onPressed: () => setCartItemLaborPrice(context, ref,
                              cartID: cartID,
                              laborPriceController: laborCostController),
                          style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5))),
                          child: quicksandWhiteRegular('Set Labor Cost'))
                    ],
                  ),
                ),
              ),
            ));
  }
}
