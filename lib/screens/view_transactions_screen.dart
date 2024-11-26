import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/providers/transactions_provider.dart';
import 'package:imeasure/utils/url_util.dart';
import 'package:imeasure/widgets/custom_padding_widgets.dart';
import 'package:imeasure/widgets/custom_text_field_widget.dart';
import 'package:imeasure/widgets/left_navigator_widget.dart';
import 'package:intl/intl.dart';

import '../providers/loading_provider.dart';
import '../utils/color_util.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/text_widgets.dart';

class ViewTransactionsScreen extends ConsumerStatefulWidget {
  const ViewTransactionsScreen({super.key});

  @override
  ConsumerState<ViewTransactionsScreen> createState() =>
      _ViewTransactionsScreenState();
}

class _ViewTransactionsScreenState
    extends ConsumerState<ViewTransactionsScreen> {
  final denialReasonController = TextEditingController();
  List<DocumentSnapshot> currentDisplayedTransactions = [];
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

        ref
            .read(transactionsProvider)
            .setTransactionDocs(await getAllUnverifiedTransactionDocs());
        maxPage = (ref.read(transactionsProvider).transactionDocs.length / 10)
            .floor();
        if (ref.read(transactionsProvider).transactionDocs.length % 10 == 0)
          maxPage--;
        setDisplayedPayments();
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting all transactions: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  void setDisplayedPayments() {
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

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(transactionsProvider);
    setDisplayedPayments();
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
                      children: [_topNavigator(), _transactionsContainer()],
                    ),
                  ),
                ),
              ),
            ],
          )),
    );
  }

  Widget _topNavigator() {
    return Row(
      children: [
        Expanded(
          child: Row(
              //mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ongoingOrdersButton(context),
                pendingLaborAndPriceButton(context),
                pendingDeliveryButton(context),
                _unverifiedTransactions()
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
                      .read(transactionsProvider)
                      .setIsChronological(bool.parse(value));
                  currentPage = 0;
                  setDisplayedPayments();
                },
                itemBuilder: (context) => [
                      PopupMenuItem(
                          value: false.toString(),
                          child: quicksandWhiteBold('Newest to Oldest')),
                      PopupMenuItem(
                          value: true.toString(),
                          child: quicksandWhiteBold('Oldest to Newest')),
                    ]),
          ],
        )
      ],
    );
  }

  Widget _unverifiedTransactions() {
    return vertical20Pix(
      child: Row(
        children: [
          forestGreenQuicksandBold('Unverified \nTransactions: ', fontSize: 20),
          Gap(4),
          quicksandCoralRedBold(
              ref.read(transactionsProvider).transactionDocs.length.toString(),
              fontSize: 28)
        ],
      ),
    );
  }

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
          if (ref.read(transactionsProvider).transactionDocs.length > 10)
            pageNavigatorButtons(
                currentPage: currentPage,
                maxPage: maxPage,
                onPreviousPage: () {
                  currentPage--;
                  setState(() {
                    setDisplayedPayments();
                  });
                },
                onNextPage: () {
                  currentPage++;
                  setState(() {
                    setDisplayedPayments();
                  });
                })
        ],
      ),
    );
  }

  Widget _transactionsLabelRow() {
    return viewContentLabelRow(context, children: [
      viewFlexLabelTextCell('Buyer', 3),
      viewFlexLabelTextCell('Amount Paid', 2),
      viewFlexLabelTextCell('Date Created', 2),
      viewFlexLabelTextCell('Date Settled', 2),
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
            String transactionID = currentDisplayedTransactions[index].id;
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
            List<dynamic> orderIDs = paymentData[TransactionFields.orderIDs];
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

                  return _transactionEntry(
                      transactionID: transactionID,
                      formattedName: formattedName,
                      backgroundColor: backgroundColor,
                      entryColor: entryColor,
                      totalAmount: totalAmount,
                      dateCreated: dateCreated,
                      paymentVerified: paymentVerified,
                      dateApproved: dateApproved,
                      proofOfPayment: proofOfPayment,
                      orderIDs: orderIDs);
                });
          }),
    );
  }

  Widget _transactionEntry(
      {required String transactionID,
      required String formattedName,
      required Color backgroundColor,
      required Color entryColor,
      required num totalAmount,
      required DateTime dateCreated,
      required bool paymentVerified,
      required DateTime dateApproved,
      required String proofOfPayment,
      required List<dynamic> orderIDs}) {
    return viewContentEntryRow(
      context,
      children: [
        viewFlexTextCell(formattedName,
            flex: 3, backgroundColor: backgroundColor, textColor: entryColor),
        viewFlexTextCell('PHP ${formatPrice(totalAmount.toDouble())}',
            flex: 2, backgroundColor: backgroundColor, textColor: entryColor),
        viewFlexTextCell(DateFormat('MMM dd, yyyy').format(dateCreated),
            flex: 2, backgroundColor: backgroundColor, textColor: entryColor),
        viewFlexTextCell(
            paymentVerified
                ? DateFormat('MMM dd, yyyy').format(dateApproved)
                : 'N/A',
            flex: 2,
            backgroundColor: backgroundColor,
            textColor: entryColor),
        viewFlexActionsCell(
            [_proofOfPaymentCell(proofOfPayment: proofOfPayment)],
            flex: 2, backgroundColor: backgroundColor),
        viewFlexActionsCell([
          if (paymentVerified) quicksandWhiteBold('VERIFIED'),
          if (!paymentVerified)
            TextButton(
                onPressed: () => approveThisPayment(context, ref,
                    paymentID: transactionID, orderIDs: orderIDs),
                child: Icon(Icons.check, color: CustomColors.lavenderMist)),
          if (!paymentVerified)
            TextButton(
                onPressed: () => showDenialReasonDialog(
                    paymentID: transactionID,
                    orderIDs: orderIDs,
                    proofOfPayment: proofOfPayment,
                    formattedName: formattedName,
                    totalAmount: totalAmount),
                child: Icon(Icons.block, color: CustomColors.coralRed))
        ], flex: 2, backgroundColor: backgroundColor)
      ],
    );
  }

  void showDenialReasonDialog(
      {required String paymentID,
      required List<dynamic> orderIDs,
      required String proofOfPayment,
      required String formattedName,
      required num totalAmount}) {
    denialReasonController.clear();
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Dialog(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.4,
                //height: MediaQuery.of(context).size.height * 0.4,
                child: SingleChildScrollView(
                  child: all10Pix(
                      child: Column(
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        TextButton(
                            onPressed: () => GoRouter.of(context).pop(),
                            child: quicksandBlackBold('X'))
                      ]),
                      vertical10Pix(
                          child: quicksandBlackBold(
                              'You will deny this transaction.')),
                      Row(children: [
                        quicksandBlackBold('Buyer Name: '),
                        quicksandBlackRegular(formattedName)
                      ]),
                      Row(children: [
                        quicksandBlackBold('Total Amount: '),
                        quicksandBlackRegular(
                            'PHP ${formatPrice(totalAmount.toDouble())}')
                      ]),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.2,
                        height: MediaQuery.of(context).size.width * 0.2,
                        decoration: BoxDecoration(
                            image: DecorationImage(
                                fit: BoxFit.contain,
                                image: NetworkImage(proofOfPayment))),
                      ),
                      Row(children: [quicksandBlackBold('Denial Reason')]),
                      CustomTextField(
                          text: 'Denial Reason',
                          controller: denialReasonController,
                          textInputType: TextInputType.text),
                      Gap(20),
                      ElevatedButton(
                          onPressed: () => denyThisPayment(context, ref,
                              paymentID: paymentID,
                              orderIDs: orderIDs,
                              denialReasonController: denialReasonController),
                          child: quicksandWhiteRegular('DENY TRANSACTION'))
                    ],
                  )),
                ),
              ),
            ));
  }

  Widget _proofOfPaymentCell({required String proofOfPayment}) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.white)),
      child: IconButton(
          onPressed: () {
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
          },
          icon: Icon(Icons.visibility_outlined, color: Colors.white)),
    );
  }
}
