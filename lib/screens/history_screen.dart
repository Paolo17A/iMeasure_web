import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/providers/appointments_provider.dart';
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
import '../widgets/custom_button_widgets.dart';
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
  List<DocumentSnapshot> currentDisplayedOrders = [];
  List<DocumentSnapshot> currentDisplayedTransactions = [];
  List<DocumentSnapshot> currentDisplayedAppointments = [];
  int currentPage = 0;
  int maxPage = 0;

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
        ref
            .read(appointmentsProvider)
            .setAppointmentDocs(await getNotPendingAppointments());
        ref.read(appointmentsProvider).appointmentDocs.sort((a, b) {
          DateTime aTime =
              (a[AppointmentFields.dateCreated] as Timestamp).toDate();
          DateTime bTime =
              (b[AppointmentFields.dateCreated] as Timestamp).toDate();
          return bTime.compareTo(aTime);
        });
        currentPage = 0;
        maxPage = (ref.read(ordersProvider).orderDocs.length / 10).floor();
        if (ref.read(ordersProvider).orderDocs.length % 10 == 0) maxPage--;
        setDisplayedOrders();
        setDisplayedTransactions();
        ref.read(loadingProvider).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(SnackBar(
            content: Text('Error getting completed orders history: $error')));
        ref.read(loadingProvider).toggleLoading(false);
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

  void setDisplayedTransactions() {
    if (ref.read(transactionsProvider).transactionDocs.length > 10) {
      currentDisplayedTransactions = ref
          .read(transactionsProvider)
          .transactionDocs
          .getRange(
              currentPage * 10,
              min((currentPage * 10) + 10,
                  ref.read(transactionsProvider).transactionDocs.length))
          .toList();
    } else
      currentDisplayedTransactions =
          ref.read(transactionsProvider).transactionDocs;
  }

  void setDisplayedAppointments() {
    if (ref.read(appointmentsProvider).appointmentDocs.length > 10) {
      currentDisplayedAppointments = ref
          .read(appointmentsProvider)
          .appointmentDocs
          .getRange(
              currentPage * 10,
              min((currentPage * 10) + 10,
                  ref.read(appointmentsProvider).appointmentDocs.length))
          .toList();
    } else
      currentDisplayedAppointments =
          ref.read(appointmentsProvider).appointmentDocs;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(ordersProvider);
    ref.watch(transactionsProvider);
    ref.watch(appointmentsProvider);
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
                        if (currentlyViewing == 'ORDERS')
                          _ordersContainer()
                        else if (currentlyViewing == 'TRANSACTIONS')
                          _transactionsContainer()
                        else if (currentlyViewing == 'APPOINTMENTS')
                          _appointmentsContainer()
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
    return Wrap(children: [
      _ordersButton(),
      _transactionsButton(),
      _appointmentsButton()
    ]);
  }

  Widget _ordersButton() {
    return all20Pix(
      child: TextButton(
        onPressed: () {
          setState(() {
            currentlyViewing = 'ORDERS';
            currentPage = 0;
            maxPage = (ref.read(ordersProvider).orderDocs.length / 10).floor();
            if (ref.read(ordersProvider).orderDocs.length % 10 == 0) maxPage--;
            setDisplayedOrders();
          });
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            currentlyViewing == 'ORDERS'
                ? forestGreenQuicksandBold('COMPLETED ORDERS: ', fontSize: 28)
                : quicksandWhiteBold('COMPLETED ORDERS: ', fontSize: 28),
            //Gap(8),
            quicksandCoralRedBold(
                ref.read(ordersProvider).orderDocs.length.toString(),
                fontSize: 28)
          ],
        ),
      ),
    );
  }

  Widget _transactionsButton() {
    return all20Pix(
      child: TextButton(
        onPressed: () {
          setState(() {
            currentlyViewing = 'TRANSACTIONS';
            currentPage = 0;
            maxPage =
                (ref.read(transactionsProvider).transactionDocs.length / 10)
                    .floor();
            if (ref.read(transactionsProvider).transactionDocs.length % 10 == 0)
              maxPage--;
            setDisplayedOrders();
          });
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            currentlyViewing == 'TRANSACTIONS'
                ? forestGreenQuicksandBold('VERIFIED TRANSACTIONS: ',
                    fontSize: 28)
                : quicksandWhiteBold('VERIFIED TRANSACTIONS: ', fontSize: 28),
            quicksandCoralRedBold(
                ref
                    .read(transactionsProvider)
                    .transactionDocs
                    .length
                    .toString(),
                fontSize: 28)
          ],
        ),
      ),
    );
  }

  Widget _appointmentsButton() {
    return all20Pix(
      child: TextButton(
        onPressed: () {
          setState(() {
            currentlyViewing = 'APPOINTMENTS';
            currentPage = 0;
            maxPage =
                (ref.read(appointmentsProvider).appointmentDocs.length / 10)
                    .floor();
            if (ref.read(appointmentsProvider).appointmentDocs.length % 10 == 0)
              maxPage--;
            setDisplayedAppointments();
          });
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            currentlyViewing == 'APPOINTMENTS'
                ? forestGreenQuicksandBold('FINALIZED APPOINTMENTS: ',
                    fontSize: 28)
                : quicksandWhiteBold('FINALIZED APPOINTMENTS: ', fontSize: 28),
            quicksandCoralRedBold(
                ref
                    .read(appointmentsProvider)
                    .appointmentDocs
                    .length
                    .toString(),
                fontSize: 28)
          ],
        ),
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
      viewFlexLabelTextCell('Additional Service', 2),
    ]);
  }

  Widget _orderEntries() {
    return ListView.builder(
        shrinkWrap: true,
        itemCount: currentDisplayedOrders.length,
        itemBuilder: (context, index) {
          final orderData =
              currentDisplayedOrders[index].data() as Map<dynamic, dynamic>;
          String clientID = orderData[OrderFields.clientID];
          String windowID = orderData[OrderFields.itemID];
          DateTime dateCreated =
              (orderData[OrderFields.dateCreated] as Timestamp).toDate();
          num itemOverallPrice = orderData[OrderFields.quotation]
              [QuotationFields.itemOverallPrice];
          String orderStatus = orderData[OrderFields.orderStatus];
          Map<String, dynamic> quotation =
              orderData[OrderFields.quotation] ?? [];
          String address = quotation[QuotationFields.requestAddress] ?? '';
          String contactNumber =
              quotation[QuotationFields.requestContactNumber] ?? '';
          String denialReason =
              quotation[QuotationFields.requestDenialReason] ?? '';
          bool isRequestingAdditionalService =
              quotation[QuotationFields.isRequestingAdditionalService] ?? false;
          String requestStatus = quotation[QuotationFields.requestStatus] ?? '';
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
                      List<dynamic> accessoryFields = [];
                      if (itemType != ItemTypes.rawMaterial)
                        accessoryFields = itemData[ItemFields.accessoryFields];
                      num laborPrice = itemType != ItemTypes.rawMaterial
                          ? quotation[QuotationFields.laborPrice]
                          : 0;
                      num additionalServicePrice =
                          quotation[QuotationFields.additionalServicePrice] ??
                              0;
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
                            'PHP ${formatPrice((itemOverallPrice + laborPrice + additionalServicePrice).toDouble())}',
                            flex: 2,
                            backgroundColor: backgroundColor,
                            textColor: entryColor),
                        viewFlexTextCell(orderStatus,
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
                                  final color =
                                      quotation[QuotationFields.color];
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
                                      color: color,
                                      imageURLs: imageURLs);
                                },
                                child:
                                    quicksandWhiteRegular('VIEW', fontSize: 12))
                          else
                            quicksandWhiteBold('N/A')
                        ], flex: 2, backgroundColor: backgroundColor),
                        viewFlexActionsCell([
                          if (isRequestingAdditionalService)
                            ElevatedButton(
                                onPressed: () => showRequestDetails(context,
                                    requestStatus: requestStatus,
                                    address: address,
                                    contactNumber: contactNumber,
                                    denialReason: denialReason),
                                child: quicksandWhiteRegular('VIEW DETAILS',
                                    fontSize: 12))
                          else
                            quicksandWhiteBold('N/A')
                        ], flex: 2, backgroundColor: backgroundColor)
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
    return Column(
      children: [
        _transactionsLabelRow(),
        ref.read(transactionsProvider).transactionDocs.isNotEmpty
            ? _transactionEntries()
            : viewContentUnavailable(context,
                text: 'NO AVAILABLE TRANSACTIONS'),
        if (ref.read(transactionsProvider).transactionDocs.length > 10)
          pageNavigatorButtons(
              currentPage: currentPage,
              maxPage: maxPage,
              onPreviousPage: () {
                currentPage--;
                setState(() {
                  setDisplayedTransactions();
                });
              },
              onNextPage: () {
                currentPage++;
                setState(() {
                  setDisplayedTransactions();
                });
              })
      ],
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
          itemCount: currentDisplayedTransactions.length,
          itemBuilder: (context, index) {
            final paymentData = currentDisplayedTransactions[index].data()
                as Map<dynamic, dynamic>;
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
            String transactionStatus =
                paymentData[TransactionFields.transactionStatus] ?? '';
            String denialReason =
                paymentData[TransactionFields.denialReason] ?? '';
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
                              onPressed: () => showProofOfPaymentDialog(context,
                                  proofOfPayment: proofOfPayment),
                              icon: Icon(Icons.visibility_outlined,
                                  color: Colors.white)),
                        )
                      ], flex: 2, backgroundColor: backgroundColor),
                      viewFlexActionsCell([
                        if (transactionStatus == TransactionStatuses.approved)
                          quicksandWhiteBold('APPROVED')
                        else if (transactionStatus ==
                            TransactionStatuses.denied)
                          ElevatedButton(
                              onPressed: () => showDenialReasonDialog(context,
                                  denialReason: denialReason),
                              child: quicksandWhiteRegular('VIEW DENIAL REASON',
                                  fontSize: 12))
                      ], flex: 2, backgroundColor: backgroundColor)
                    ],
                  );
                });
          }),
    );
  }

  void showProofOfPaymentDialog(BuildContext context,
      {required String proofOfPayment}) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Dialog(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.4,
                child: SingleChildScrollView(
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
                    width: MediaQuery.of(context).size.width * 0.3,
                    height: MediaQuery.of(context).size.width * 0.3,
                    decoration: BoxDecoration(
                        image: DecorationImage(
                            fit: BoxFit.contain,
                            image: NetworkImage(proofOfPayment))),
                  ),
                  vertical20Pix(
                      child: ElevatedButton(
                          onPressed: () =>
                              launchThisURL(context, proofOfPayment),
                          child: quicksandWhiteBold('DOWNLOAD')))
                ])),
              ),
            ));
  }

  //============================================================================
  //APPOINTMENTS================================================================
  //============================================================================
  Widget _appointmentsContainer() {
    return viewContentContainer(
      context,
      child: Column(
        children: [
          _appointmentsLabelRow(),
          ref.read(appointmentsProvider).appointmentDocs.isNotEmpty
              ? _appointmentEntries()
              : viewContentUnavailable(context,
                  text: 'NO AVAILABLE APPOINTMENTS'),
          if (ref.read(appointmentsProvider).appointmentDocs.length > 10)
            pageNavigatorButtons(
                currentPage: currentPage,
                maxPage: maxPage,
                onPreviousPage: () {
                  currentPage--;
                  setState(() {
                    setDisplayedAppointments();
                  });
                },
                onNextPage: () {
                  currentPage++;
                  setState(() {
                    setDisplayedAppointments();
                  });
                })
        ],
      ),
    );
  }

  Widget _appointmentsLabelRow() {
    return viewContentLabelRow(context, children: [
      viewFlexLabelTextCell('Buyer', 3),
      viewFlexLabelTextCell('Selected Date', 2),
      viewFlexLabelTextCell('Status', 2),
      viewFlexLabelTextCell('Actions', 2)
    ]);
  }

  Widget _appointmentEntries() {
    return SizedBox(
      height: 500,
      child: ListView.builder(
          shrinkWrap: true,
          itemCount: currentDisplayedAppointments.length,
          itemBuilder: (context, index) {
            final appointmentData = ref
                .read(appointmentsProvider)
                .appointmentDocs[index]
                .data() as Map<dynamic, dynamic>;
            String appointmentID = currentDisplayedAppointments[index].id;
            String denialReason =
                appointmentData[AppointmentFields.denialReason] ?? '';
            String clientID = appointmentData[AppointmentFields.clientID];
            String appointmentStatus =
                appointmentData[AppointmentFields.appointmentStatus];
            List<dynamic> requestedDates =
                appointmentData[AppointmentFields.proposedDates];
            DateTime selectedDate =
                (appointmentData[AppointmentFields.selectedDate] as Timestamp)
                    .toDate();
            String address = appointmentData[AppointmentFields.address];
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

                  return _appointmentEntry(
                      appointmentID: appointmentID,
                      formattedName: formattedName,
                      backgroundColor: backgroundColor,
                      entryColor: entryColor,
                      requestedDates: requestedDates,
                      selectedDate: selectedDate,
                      status: appointmentStatus,
                      address: address,
                      denialReason: denialReason);
                });
          }),
    );
  }

  Widget _appointmentEntry(
      {required String appointmentID,
      required String formattedName,
      required Color backgroundColor,
      required Color entryColor,
      required DateTime selectedDate,
      required String status,
      required List<dynamic> requestedDates,
      required String address,
      required String denialReason}) {
    return viewContentEntryRow(
      context,
      children: [
        viewFlexTextCell(formattedName,
            flex: 3, backgroundColor: backgroundColor, textColor: entryColor),
        viewFlexTextCell(
            status == AppointmentStatuses.approved
                ? DateFormat('MMM dd, yyyy').format(selectedDate)
                : 'N/A',
            flex: 2,
            backgroundColor: backgroundColor,
            textColor: entryColor),
        viewFlexTextCell(status,
            flex: 2, backgroundColor: backgroundColor, textColor: entryColor),
        viewFlexActionsCell([
          if (status == RequestStatuses.denied)
            Container(
              decoration:
                  BoxDecoration(border: Border.all(color: Colors.white)),
              child: TextButton(
                  onPressed: () => showDenialReasonDialog(context,
                      denialReason: denialReason),
                  child:
                      quicksandWhiteBold('VIEW DENIAL REASON', fontSize: 12)),
            )
          else
            Container(
              decoration:
                  BoxDecoration(border: Border.all(color: Colors.white)),
              child: TextButton(
                  onPressed: () => showServiceDetails(context,
                      appointmentStatus: status,
                      selectedDate: selectedDate,
                      address: address),
                  child: quicksandWhiteBold('VIEW APPOINTMENT DETAILS',
                      fontSize: 12)),
            )
        ], flex: 2, backgroundColor: backgroundColor)
      ],
    );
  }

  void showServiceDetails(BuildContext context,
      {required String appointmentStatus,
      required DateTime selectedDate,
      required String address}) {
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
                                  quicksandBlackRegular(
                                      DateFormat('MMM dd, yyyy')
                                          .format(selectedDate))
                                ],
                              ),
                              Row(children: [
                                quicksandBlackBold('Client Address: '),
                                quicksandBlackRegular(address,
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
}
