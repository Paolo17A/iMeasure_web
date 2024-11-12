import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/providers/orders_provider.dart';
import 'package:imeasure/widgets/custom_padding_widgets.dart';
import 'package:imeasure/widgets/left_navigator_widget.dart';
import 'package:intl/intl.dart';

import '../providers/loading_provider.dart';
import '../providers/user_data_provider.dart';
import '../utils/color_util.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/quotation_dialog_util.dart';
import '../utils/string_util.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/text_widgets.dart';

class ViewOrdersScreen extends ConsumerStatefulWidget {
  const ViewOrdersScreen({super.key});

  @override
  ConsumerState<ViewOrdersScreen> createState() => _ViewOrdersScreenState();
}

class _ViewOrdersScreenState extends ConsumerState<ViewOrdersScreen> {
  String sortingMethod = 'DATE';
  Map<String, String> orderIDandNameMap = {};
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(loadingProvider.notifier).toggleLoading(true);
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final goRouter = GoRouter.of(context);
      try {
        if (!hasLoggedInUser()) {
          ref.read(loadingProvider).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);
          return;
        }
        final userDoc = await getCurrentUserDoc();
        final userData = userDoc.data() as Map<dynamic, dynamic>;
        String userType = userData[UserFields.userType];
        ref.read(userDataProvider).setUserType(userType);
        if (ref.read(userDataProvider).userType == UserTypes.client) {
          ref.read(loadingProvider).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);
          return;
        }
        ref
            .read(ordersProvider)
            .setOrderDocs(await getAllUncompletedOrderDocs());
        ref.read(ordersProvider).sortOrdersByDate();
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting all orders: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(ordersProvider);
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
                  child: horizontal5Percent(
                    context,
                    child: Column(
                      children: [_ordersHeader(), _ordersContainer()],
                    ),
                  ),
                ),
              ),
            ],
          )),
    );
  }

  Widget _ordersHeader() {
    return vertical20Pix(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Orders Label
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              quicksandWhiteBold('Orders: ', fontSize: 28),
              Gap(4),
              quicksandCoralRedBold(
                  ref.read(ordersProvider).orderDocs.length.toString(),
                  fontSize: 28)
            ],
          ),
          // Sorting pop-up
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              quicksandWhiteBold('Sort:'),
              PopupMenuButton(
                  color: CustomColors.forestGreen,
                  iconColor: Colors.white,
                  onSelected: (value) {
                    if (value == 'NAME') {
                      ref
                          .read(ordersProvider)
                          .sortOrdersByClientName(orderIDandNameMap);
                    } else if (value == 'DATE') {
                      ref.read(ordersProvider).sortOrdersByDate();
                    }
                  },
                  itemBuilder: (context) => [
                        PopupMenuItem(
                            value: 'NAME', child: quicksandWhiteBold('Name')),
                        PopupMenuItem(
                            value: 'DATE',
                            child: quicksandWhiteBold('Date Ordered')),
                      ]),
            ],
          )
        ],
      ),
    );
  }

  Widget _ordersContainer() {
    return Column(
      children: [
        _ordersLabelRow(),
        ref.read(ordersProvider).orderDocs.isNotEmpty
            ? _orderEntries()
            : viewContentUnavailable(context, text: 'NO AVAILABLE ORDERS'),
      ],
    );
  }

  Widget _ordersLabelRow() {
    return viewContentLabelRow(context, children: [
      viewFlexLabelTextCell('Buyer', 2),
      viewFlexLabelTextCell('Date Ordered', 2),
      viewFlexLabelTextCell('Item', 2),
      viewFlexLabelTextCell('Cost', 2),
      viewFlexLabelTextCell('Status', 2),
      viewFlexLabelTextCell('Quotation', 2),
    ]);
  }

  Widget _orderEntries() {
    orderIDandNameMap.clear();
    return ListView.builder(
        shrinkWrap: true,
        itemCount: ref.read(ordersProvider).orderDocs.length,
        itemBuilder: (context, index) {
          final orderData = ref.read(ordersProvider).orderDocs[index].data()
              as Map<dynamic, dynamic>;
          String clientID = orderData[OrderFields.clientID];
          String windowID = orderData[OrderFields.itemID];
          String status = orderData[OrderFields.orderStatus];
          DateTime dateCreated =
              (orderData[OrderFields.dateCreated] as Timestamp).toDate();
          num itemOverallPrice = orderData[OrderFields.quotation]
              [QuotationFields.itemOverallPrice];

          Map<String, dynamic> quotation =
              orderData[OrderFields.quotation] ?? [];

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

                orderIDandNameMap.addAll({
                  ref.read(ordersProvider).orderDocs[index].id: formattedName
                });
                return FutureBuilder(
                    future: getThisItemDoc(windowID),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting ||
                          !snapshot.hasData ||
                          snapshot.hasError) return Container();

                      final itemData =
                          snapshot.data!.data() as Map<dynamic, dynamic>;
                      String name = itemData[WindowFields.name];
                      String itemType = itemData[ItemFields.itemType];
                      Color entryColor = Colors.white;
                      Color backgroundColor = Colors.transparent;
                      List<dynamic> imageURLs = itemData[ItemFields.imageURLs];
                      return viewContentEntryRow(context, children: [
                        viewFlexTextCell(formattedName,
                            flex: 2,
                            backgroundColor: backgroundColor,
                            textColor: entryColor),
                        viewFlexTextCell(
                            DateFormat('MMM dd, yyyy').format(dateCreated),
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
                        viewFlexActionsCell([
                          if (status == OrderStatuses.generated)
                            Container(
                              decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white)),
                              child: TextButton(
                                  onPressed: () => GoRouter.of(context).goNamed(
                                          GoRoutes.generatedOrder,
                                          pathParameters: {
                                            PathParameters.orderID: ref
                                                .read(ordersProvider)
                                                .orderDocs[index]
                                                .id
                                          }),
                                  child: quicksandWhiteBold('SET LABOR COST',
                                      fontSize: 12)),
                            ),
                          if (status == OrderStatuses.pending)
                            quicksandWhiteBold('PENDING PAYMENT', fontSize: 16)
                          else if (status == OrderStatuses.denied)
                            quicksandWhiteBold('PAYMENT DENIED', fontSize: 16)
                          else if (status == OrderStatuses.processing)
                            Container(
                              decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white)),
                              child: TextButton(
                                  onPressed: () => markOrderAsReadyForPickUp(
                                      context, ref,
                                      orderID: ref
                                          .read(ordersProvider)
                                          .orderDocs[index]
                                          .id),
                                  child: quicksandWhiteBold(
                                      'MARK AS READY FOR PICK UP',
                                      fontSize: 12)),
                            )
                          else if (status == OrderStatuses.forPickUp)
                            quicksandWhiteBold('PENDING PICK UP', fontSize: 16)
                          else if (status == OrderStatuses.pickedUp)
                            Container(
                              decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white)),
                              child: TextButton(
                                  onPressed: () => markOrderAsCompleted(
                                      context, ref,
                                      orderID: ref
                                          .read(ordersProvider)
                                          .orderDocs[index]
                                          .id),
                                  child: quicksandWhiteBold('MARK AS COMPLETED',
                                      fontSize: 12)),
                            )
                          else if (status == OrderStatuses.completed)
                            quicksandWhiteBold('COMPLETED', fontSize: 16)
                        ], flex: 2, backgroundColor: backgroundColor),
                        viewFlexActionsCell([
                          if (itemType == ItemTypes.window ||
                              itemType == ItemTypes.door)
                            ElevatedButton(
                                onPressed: () {
                                  final mandatoryWindowFields =
                                      quotation[QuotationFields.mandatoryMap];
                                  final optionalWindowFields =
                                      quotation[QuotationFields.optionalMap]
                                          as List<dynamic>;
                                  showCartQuotationDialog(context, ref,
                                      totalOverallPayment: itemOverallPrice,
                                      laborPrice:
                                          quotation[QuotationFields.laborPrice],
                                      mandatoryWindowFields:
                                          mandatoryWindowFields,
                                      optionalWindowFields:
                                          optionalWindowFields,
                                      width: quotation[QuotationFields.width],
                                      height: quotation[QuotationFields.height],
                                      imageURLs: imageURLs,
                                      itemName: name);
                                },
                                child:
                                    quicksandWhiteRegular('VIEW', fontSize: 12))
                          else
                            quicksandWhiteBold('N/A')
                        ], flex: 2, backgroundColor: backgroundColor),
                      ]);
                    });
                //  Item Variables
              });
          //  Client Variables
        });
  }
}
