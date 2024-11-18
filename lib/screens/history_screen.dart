import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/providers/loading_provider.dart';
import 'package:imeasure/providers/orders_provider.dart';
import 'package:imeasure/providers/transactions_provider.dart';
import 'package:imeasure/widgets/custom_miscellaneous_widgets.dart';
import 'package:intl/intl.dart';

import '../providers/user_data_provider.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/quotation_dialog_util.dart';
import '../utils/string_util.dart';
import '../utils/url_util.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/left_navigator_widget.dart';
import '../widgets/text_widgets.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String currentlyViewing = 'ORDERS';

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
        final userDoc = await getCurrentUserDoc();
        final userData = userDoc.data() as Map<dynamic, dynamic>;
        String userType = userData[UserFields.userType];
        ref.read(userDataProvider).setUserType(userType);
        if (ref.read(userDataProvider).userType == UserTypes.client) {
          ref.read(loadingProvider).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);
          return;
        }
        ref.read(ordersProvider).setOrderDocs(await getAllCompletedOrderDocs());
        ref.read(ordersProvider).orderDocs.sort((a, b) {
          DateTime aTime = (a[OrderFields.dateCreated] as Timestamp).toDate();
          DateTime bTime = (b[OrderFields.dateCreated] as Timestamp).toDate();
          return bTime.compareTo(aTime);
        });
        ref
            .read(transactionsProvider)
            .setTransactionDocs(await getAllVerifiedTransactionDocs());
        ref.read(transactionsProvider).transactionDocs.sort((a, b) {
          DateTime aTime =
              (a[TransactionFields.dateApproved] as Timestamp).toDate();
          DateTime bTime =
              (b[TransactionFields.dateApproved] as Timestamp).toDate();
          return bTime.compareTo(aTime);
        });
        ref.read(loadingProvider).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(SnackBar(
            content: Text('Error getting completed orders history: $error')));
        ref.read(loadingProvider).toggleLoading(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(ordersProvider);
    ref.watch(transactionsProvider);
    return Scaffold(
      body: switchedLoadingContainer(
          ref.read(loadingProvider).isLoading,
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            leftNavigator(context, path: GoRoutes.history),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: SingleChildScrollView(
                child: horizontal5Percent(context,
                    child: Column(
                      children: [
                        _optionsWidgets(),
                        currentlyViewing == 'ORDERS'
                            ? _ordersContainer()
                            : _transactionsContainer(),
                      ],
                    )),
              ),
            ),
          ])),
    );
  }

  //============================================================================
  //ORDERS======================================================================
  //============================================================================
  Widget _optionsWidgets() {
    return Row(children: [_ordersButton(), _transactionsButton()]);
  }

  Widget _ordersButton() {
    return all20Pix(
      child: TextButton(
        onPressed: () {
          setState(() {
            currentlyViewing = 'ORDERS';
          });
        },
        child: currentlyViewing == 'ORDERS'
            ? forestGreenQuicksandBold('COMPLETED ORDERS', fontSize: 28)
            : quicksandWhiteBold('COMPLETED ORDERS', fontSize: 28),
      ),
    );
  }

  Widget _transactionsButton() {
    return all20Pix(
      child: TextButton(
        onPressed: () {
          setState(() {
            currentlyViewing = 'TRANSACTIONS';
          });
        },
        child: currentlyViewing == 'TRANSACTIONS'
            ? forestGreenQuicksandBold('VERIFIED TRANSACTIONS', fontSize: 28)
            : quicksandWhiteBold('VERIFIED TRANSACTIONS', fontSize: 28),
      ),
    );
  }

  Widget _ordersContainer() {
    return Column(
      children: [
        _ordersLabelRow(),
        ref.read(ordersProvider).orderDocs.isNotEmpty
            ? _orderEntries()
            : viewContentUnavailable(context, text: 'NO COMPLETED ORDERS'),
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
    return ListView.builder(
        shrinkWrap: true,
        itemCount: ref.read(ordersProvider).orderDocs.length,
        itemBuilder: (context, index) {
          final orderData = ref.read(ordersProvider).orderDocs[index].data()
              as Map<dynamic, dynamic>;
          String clientID = orderData[OrderFields.clientID];
          String windowID = orderData[OrderFields.itemID];
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
                      List<dynamic> accessoryFields =
                          itemData[ItemFields.accessoryFields];

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
                        viewFlexTextCell('COMPLETED',
                            flex: 2,
                            backgroundColor: backgroundColor,
                            textColor: entryColor),
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
                                      accessoryFields: accessoryFields,
                                      width: quotation[QuotationFields.width],
                                      height: quotation[QuotationFields.height],
                                      itemName: name,
                                      imageURLs: imageURLs);
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

  //============================================================================
  //TRANSACTIONS================================================================
  //============================================================================

  Widget _transactionsContainer() {
    return viewContentContainer(
      context,
      child: Column(
        children: [
          _transactionsLabelRow(),
          ref.read(transactionsProvider).transactionDocs.isNotEmpty
              ? _transactionEntries()
              : viewContentUnavailable(context,
                  text: 'NO AVAILABLE TRANSACTIONS'),
        ],
      ),
    );
  }

  Widget _transactionsLabelRow() {
    return viewContentLabelRow(context, children: [
      viewFlexLabelTextCell('Buyer', 3),
      viewFlexLabelTextCell('Amount Paid', 2),
      viewFlexLabelTextCell('Dater Created', 2),
      viewFlexLabelTextCell('Dater Settled', 2),
      viewFlexLabelTextCell('Payment', 2),
      viewFlexLabelTextCell('Actions', 2)
    ]);
  }

  Widget _transactionEntries() {
    return SizedBox(
      height: 500,
      child: ListView.builder(
          shrinkWrap: true,
          itemCount: ref.read(transactionsProvider).transactionDocs.length,
          itemBuilder: (context, index) {
            final paymentData = ref
                .read(transactionsProvider)
                .transactionDocs[index]
                .data() as Map<dynamic, dynamic>;
            bool paymentVerified =
                paymentData[TransactionFields.paymentVerified];
            String clientID = paymentData[TransactionFields.clientID];
            num totalAmount = paymentData[TransactionFields.paidAmount];
            DateTime dateCreated =
                (paymentData[TransactionFields.dateCreated] as Timestamp)
                    .toDate();
            DateTime dateApproved =
                (paymentData[TransactionFields.dateApproved] as Timestamp)
                    .toDate();
            String proofOfPayment =
                paymentData[TransactionFields.proofOfPayment];
            return FutureBuilder(
                future: getThisUserDoc(clientID),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting ||
                      !snapshot.hasData ||
                      snapshot.hasError) return snapshotHandler(snapshot);

                  final clientData =
                      snapshot.data!.data() as Map<dynamic, dynamic>;
                  String formattedName =
                      '${clientData[UserFields.firstName]} ${clientData[UserFields.lastName]}';
                  Color entryColor = Colors.white;
                  Color backgroundColor = Colors.transparent;

                  return viewContentEntryRow(
                    context,
                    children: [
                      viewFlexTextCell(formattedName,
                          flex: 3,
                          backgroundColor: backgroundColor,
                          textColor: entryColor),
                      viewFlexTextCell(
                          'PHP ${formatPrice(totalAmount.toDouble())}',
                          flex: 2,
                          backgroundColor: backgroundColor,
                          textColor: entryColor),
                      viewFlexTextCell(
                          DateFormat('MMM dd, yyyy').format(dateCreated),
                          flex: 2,
                          backgroundColor: backgroundColor,
                          textColor: entryColor),
                      viewFlexTextCell(
                          paymentVerified
                              ? DateFormat('MMM dd, yyyy').format(dateApproved)
                              : 'N/A',
                          flex: 2,
                          backgroundColor: backgroundColor,
                          textColor: entryColor),
                      viewFlexActionsCell([
                        Container(
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.white)),
                          child: IconButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) => Dialog(
                                          child: SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.4,
                                            child: SingleChildScrollView(
                                                child: Column(children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  TextButton(
                                                      onPressed: () =>
                                                          GoRouter.of(context)
                                                              .pop(),
                                                      child: quicksandBlackBold(
                                                          'X'))
                                                ],
                                              ),
                                              Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.3,
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.3,
                                                decoration: BoxDecoration(
                                                    image: DecorationImage(
                                                        fit: BoxFit.contain,
                                                        image: NetworkImage(
                                                            proofOfPayment))),
                                              ),
                                              vertical20Pix(
                                                  child: ElevatedButton(
                                                      onPressed: () =>
                                                          launchThisURL(context,
                                                              proofOfPayment),
                                                      child: quicksandWhiteBold(
                                                          'DOWNLOAD')))
                                            ])),
                                          ),
                                        ));
                              },
                              icon: Icon(Icons.visibility_outlined,
                                  color: Colors.white)),
                        )
                      ], flex: 2, backgroundColor: backgroundColor),
                      viewFlexActionsCell([
                        if (paymentVerified) quicksandWhiteBold('VERIFIED'),
                      ], flex: 2, backgroundColor: backgroundColor)
                    ],
                  );
                });
          }),
    );
  }
}
