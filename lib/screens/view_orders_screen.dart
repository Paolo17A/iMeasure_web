import 'dart:math';

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
import '../widgets/custom_button_widgets.dart';
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
  List<DocumentSnapshot> currentDisplayedOrders = [];
  int currentPage = 0;
  int maxPage = 0;
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
        maxPage = (ref.read(ordersProvider).orderDocs.length / 10).floor();
        if (ref.read(ordersProvider).orderDocs.length % 10 == 0) maxPage--;
        setDisplayedOrders();
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting all orders: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  void setDisplayedOrders() {
    if (ref.read(ordersProvider).orderDocs.length > 10) {
      currentDisplayedOrders = ref
          .read(ordersProvider)
          .orderDocs
          .getRange(
              currentPage * 10,
              min((currentPage * 10) + 10,
                  ref.read(ordersProvider).orderDocs.length))
          .toList();
    } else
      currentDisplayedOrders = ref.read(ordersProvider).orderDocs;
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
          Expanded(
            child: Row(
                //mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ordersButton(),
                  pendingLaborAndPriceButton(context),
                  pendingDeliveryButton(context),
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
                    if (value == 'NAME') {
                      ref
                          .read(ordersProvider)
                          .sortOrdersByClientName(orderIDandNameMap);
                    } else if (value == 'DATE') {
                      ref.read(ordersProvider).sortOrdersByDate();
                    }
                    currentPage = 0;
                    setDisplayedOrders();
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

  Widget _ordersButton() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        forestGreenQuicksandBold('Ongoing\nOrders: ', fontSize: 20),
        Gap(4),
        quicksandCoralRedBold(
            ref.read(ordersProvider).orderDocs.length.toString(),
            fontSize: 28)
      ],
    );
  }

  Widget _ordersContainer() {
    return Column(
      children: [
        _ordersLabelRow(),
        ref.read(ordersProvider).orderDocs.isNotEmpty
            ? _orderEntries()
            : viewContentUnavailable(context, text: 'NO AVAILABLE ORDERS'),
        if (ref.read(ordersProvider).orderDocs.length > 10)
          pageNavigatorButtons(
              currentPage: currentPage,
              maxPage: maxPage,
              onPreviousPage: () {
                currentPage--;
                setState(() {
                  setDisplayedOrders();
                });
              },
              onNextPage: () {
                currentPage++;
                setState(() {
                  setDisplayedOrders();
                });
              })
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
        itemCount: currentDisplayedOrders.length,
        itemBuilder: (context, index) {
          final orderData =
              currentDisplayedOrders[index].data() as Map<dynamic, dynamic>;
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

                orderIDandNameMap
                    .addAll({currentDisplayedOrders[index].id: formattedName});
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
                      List<dynamic> accessoryFields = [];
                      if (itemType != ItemTypes.rawMaterial)
                        accessoryFields = itemData[ItemFields.accessoryFields];
                      return _orderEntry(
                          formattedName: formattedName,
                          backgroundColor: backgroundColor,
                          entryColor: entryColor,
                          dateCreated: dateCreated,
                          name: name,
                          itemOverallPrice: itemOverallPrice,
                          status: status,
                          orderID: ref.read(ordersProvider).orderDocs[index].id,
                          itemType: itemType,
                          quotation: quotation,
                          accessoryFields: accessoryFields,
                          imageURLs: imageURLs);
                    });
                //  Item Variables
              });
          //  Client Variables
        });
  }

  Widget _orderEntry(
      {required String formattedName,
      required Color backgroundColor,
      required Color entryColor,
      required DateTime dateCreated,
      required String name,
      required num itemOverallPrice,
      required String status,
      required String orderID,
      required String itemType,
      required Map<dynamic, dynamic> quotation,
      required List<dynamic> accessoryFields,
      required List<dynamic> imageURLs}) {
    bool isRequestingAdditionalService =
        quotation[QuotationFields.isRequestingAdditionalService] ?? false;
    String requestStatus = quotation[QuotationFields.requestStatus] ?? '';
    num laborPrice = itemType != ItemTypes.rawMaterial
        ? quotation[QuotationFields.laborPrice]
        : 0;
    num additionalServicePrice =
        quotation[QuotationFields.additionalServicePrice] ?? 0;
    List<dynamic> requestedDates =
        quotation[QuotationFields.requestedDates] ?? [];
    return viewContentEntryRow(context, children: [
      viewFlexTextCell(formattedName,
          flex: 2, backgroundColor: backgroundColor, textColor: entryColor),
      viewFlexTextCell(DateFormat('MMM dd, yyyy').format(dateCreated),
          flex: 2, backgroundColor: backgroundColor, textColor: entryColor),
      viewFlexTextCell(name,
          flex: 2, backgroundColor: backgroundColor, textColor: entryColor),
      viewFlexTextCell(
          'PHP ${formatPrice((itemOverallPrice + laborPrice + additionalServicePrice).toDouble())}',
          flex: 2,
          backgroundColor: backgroundColor,
          textColor: entryColor),
      viewFlexActionsCell([
        if (status == OrderStatuses.generated)
          Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.white)),
            child: TextButton(
                onPressed: () => GoRouter.of(context).goNamed(
                    GoRoutes.generatedOrder,
                    pathParameters: {PathParameters.orderID: orderID}),
                child: quicksandWhiteBold('SET LABOR COST', fontSize: 12)),
          ),
        if (status == OrderStatuses.pending)
          quicksandWhiteBold('PENDING PAYMENT', fontSize: 16)
        // else if (status == OrderStatuses.denied)
        //   quicksandWhiteBold('PAYMENT DENIED', fontSize: 16)
        else if (status == OrderStatuses.processing) ...[
          if (itemType == ItemTypes.door || itemType == ItemTypes.window)
            Container(
                decoration:
                    BoxDecoration(border: Border.all(color: Colors.white)),
                child: TextButton(
                    onPressed: () {
                      if (isRequestingAdditionalService &&
                          requestStatus == RequestStatuses.approved) {
                        markOrderAsPendingInstallation(context, ref,
                            orderID: orderID);
                      } else
                        markOrderAsReadyForPickUp(context, ref,
                            orderID: orderID);
                    },
                    child: isRequestingAdditionalService &&
                            requestStatus == RequestStatuses.approved
                        ? quicksandWhiteBold('MARK AS PENDING INSTALLATION',
                            fontSize: 10)
                        : quicksandWhiteBold('MARK AS FOR PICK UP',
                            fontSize: 12)))
          else
            Container(
                decoration:
                    BoxDecoration(border: Border.all(color: Colors.white)),
                child: TextButton(
                    onPressed: () {
                      if (isRequestingAdditionalService &&
                          requestStatus == RequestStatuses.approved) {
                        markOrderAsPendingDelivery(context, ref,
                            orderID: orderID);
                      } else
                        markOrderAsReadyForPickUp(context, ref,
                            orderID: orderID);
                    },
                    child: isRequestingAdditionalService &&
                            requestStatus == RequestStatuses.approved
                        ? quicksandWhiteBold('MARK AS PENDING DELIVERY',
                            fontSize: 10)
                        : quicksandWhiteBold('MARK AS FOR PICK UP',
                            fontSize: 12)))
        ] else if (status == OrderStatuses.forPickUp)
          quicksandWhiteBold('PENDING PICK UP', fontSize: 16)
        else if (status == OrderStatuses.deliveryPendingApproval ||
            status == OrderStatuses.installationPendingApproval)
          Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.white)),
            child: TextButton(
                onPressed: () => _showProposedDates(
                    orderID: orderID,
                    requestedDates: requestedDates,
                    orderStatus: status),
                child: quicksandWhiteBold(
                    'SELECT ${status == OrderStatuses.deliveryPendingApproval ? 'DELIVERY' : 'INSTALLATION'} DATE',
                    fontSize: 10)),
          )
        else if (status == OrderStatuses.pickedUp ||
            status == OrderStatuses.delivered ||
            status == OrderStatuses.installed)
          Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.white)),
            child: TextButton(
                onPressed: () =>
                    markOrderAsCompleted(context, ref, orderID: orderID),
                child: quicksandWhiteBold('MARK AS COMPLETED', fontSize: 12)),
          )
        else
          quicksandWhiteBold(status, fontSize: 16)
      ], flex: 2, backgroundColor: backgroundColor),
      viewFlexActionsCell([
        if (itemType == ItemTypes.window || itemType == ItemTypes.door)
          ElevatedButton(
              onPressed: () {
                final mandatoryWindowFields =
                    quotation[QuotationFields.mandatoryMap];
                final optionalWindowFields =
                    quotation[QuotationFields.optionalMap] as List<dynamic>;
                final color = quotation[QuotationFields.color];
                showCartQuotationDialog(context, ref,
                    totalOverallPayment: itemOverallPrice,
                    laborPrice: quotation[QuotationFields.laborPrice],
                    mandatoryWindowFields: mandatoryWindowFields,
                    optionalWindowFields: optionalWindowFields,
                    accessoryFields: accessoryFields,
                    color: color,
                    width: quotation[QuotationFields.width],
                    height: quotation[QuotationFields.height],
                    imageURLs: imageURLs,
                    itemName: name);
              },
              child: quicksandWhiteRegular('VIEW', fontSize: 12))
        else
          quicksandWhiteBold('N/A')
      ], flex: 2, backgroundColor: backgroundColor),
    ]);
  }

  void _showProposedDates(
      {required String orderID,
      required List<dynamic> requestedDates,
      required String orderStatus}) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => StatefulBuilder(
              builder: (context, setState) => Dialog(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.5,
                  padding: EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                  onPressed: () => GoRouter.of(context).pop(),
                                  child: quicksandBlackBold('X'))
                            ]),
                        vertical10Pix(
                            child: quicksandBlackBold(
                                'SELECT ONE OF THE FOLLOWING DATES FOR ${orderStatus == OrderStatuses.deliveryPendingApproval ? 'DELIVERY' : 'INSTALLATION'}',
                                fontSize: 28)),
                        Column(
                          children: requestedDates
                              .map((requestedDate) => vertical10Pix(
                                    child: ElevatedButton(
                                        onPressed: () {
                                          GoRouter.of(context).pop();
                                          if (orderStatus ==
                                              OrderStatuses
                                                  .installationPendingApproval) {
                                            markOrderAsForInstallation(
                                                context, ref,
                                                orderID: orderID,
                                                selectedDate: requestedDate);
                                          } else if (orderStatus ==
                                              OrderStatuses
                                                  .deliveryPendingApproval) {
                                            markOrderAsForDelivery(context, ref,
                                                orderID: orderID,
                                                selectedDate: requestedDate);
                                          }
                                        },
                                        child: quicksandWhiteRegular(
                                            DateFormat('MMM dd, yyyy').format(
                                                (requestedDate as Timestamp)
                                                    .toDate()))),
                                  ))
                              .toList(),
                        ),
                        Gap(20),
                        ElevatedButton(
                            onPressed: () {
                              GoRouter.of(context).pop();
                              if (orderStatus ==
                                  OrderStatuses.installationPendingApproval)
                                markOrderAsPendingInstallation(context, ref,
                                    orderID: orderID);
                              else if (orderStatus ==
                                  OrderStatuses.deliveryPendingApproval)
                                markOrderAsPendingDelivery(context, ref,
                                    orderID: orderID);
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: CustomColors.coralRed),
                            child: quicksandWhiteRegular(
                                'NONE OF THESE DATES ARE FEASIBLE'))
                      ],
                    ),
                  ),
                ),
              ),
            ));
  }
}
