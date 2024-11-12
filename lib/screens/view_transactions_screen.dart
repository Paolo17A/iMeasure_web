import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/providers/transactions_provider.dart';
import 'package:imeasure/utils/url_util.dart';
import 'package:imeasure/widgets/custom_padding_widgets.dart';
import 'package:imeasure/widgets/left_navigator_widget.dart';
import 'package:intl/intl.dart';

import '../providers/loading_provider.dart';
import '../utils/color_util.dart';
import '../utils/delete_entry_dialog_util.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
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
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting all transactions: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(transactionsProvider);
    return Scaffold(
      body: switchedLoadingContainer(
          ref.read(loadingProvider).isLoading,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leftNavigator(context, path: GoRoutes.transactions),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: SingleChildScrollView(
                  child: Column(
                    children: [_ordersContainer()],
                  ),
                ),
              ),
            ],
          )),
    );
  }

  Widget _ordersContainer() {
    return all5Percent(
      context,
      child: viewContentContainer(
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
                                //launchThisURL(context, proofOfPayment);
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
                        if (!paymentVerified)
                          TextButton(
                              onPressed: () => approveThisPayment(context, ref,
                                  paymentID: ref
                                      .read(transactionsProvider)
                                      .transactionDocs[index]
                                      .id,
                                  orderIDs: orderIDs),
                              child: Icon(Icons.check,
                                  color: CustomColors.lavenderMist)),
                        if (!paymentVerified)
                          TextButton(
                              onPressed: () => displayDeleteEntryDialog(context,
                                  message:
                                      'Are you sure you want to deny this payment?',
                                  deleteWord: 'Deny',
                                  deleteEntry: () => denyThisPayment(
                                      context, ref,
                                      paymentID: ref
                                          .read(transactionsProvider)
                                          .transactionDocs[index]
                                          .id,
                                      orderIDs: orderIDs)),
                              child: Icon(Icons.block,
                                  color: CustomColors.coralRed))
                      ], flex: 2, backgroundColor: backgroundColor)
                    ],
                  );
                });
          }),
    );
  }
}
