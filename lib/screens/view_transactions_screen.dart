import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/providers/transactions_provider.dart';
import 'package:imeasure/utils/url_util.dart';
import 'package:imeasure/widgets/custom_padding_widgets.dart';
import 'package:imeasure/widgets/left_navigator_widget.dart';

import '../providers/loading_provider.dart';
import '../utils/color_util.dart';
import '../utils/delete_entry_dialog_util.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/app_drawer_widget.dart';
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
          goRouter.goNamed(GoRoutes.home);
          return;
        }

        ref
            .read(transactionsProvider)
            .setTransactionDocs(await getAllTransactionDocs());
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
      drawer: appDrawer(context, currentPath: GoRoutes.transactions),
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
    return horizontal5Percent(
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
            String clientID = paymentData[TransactionFields.clientID];
            num totalAmount = paymentData[TransactionFields.paidAmount];
            //String paymentMethod = paymentData[TransactionFields.paymentMethod];
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
                      viewFlexActionsCell([
                        Container(
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.white)),
                          child: TextButton(
                              onPressed: () =>
                                  launchThisURL(context, proofOfPayment),
                              child: quicksandWhiteBold('DOWNLOAD')),
                        )
                      ], flex: 2, backgroundColor: backgroundColor),
                      viewFlexActionsCell([
                        if (paymentData[TransactionFields.paymentVerified])
                          quicksandWhiteBold('VERIFIED'),
                        if (!paymentData[TransactionFields.paymentVerified])
                          TextButton(
                              onPressed: () => approveThisPayment(context, ref,
                                  paymentID: ref
                                      .read(transactionsProvider)
                                      .transactionDocs[index]
                                      .id),
                              child: Icon(Icons.check,
                                  color: CustomColors.lavenderMist)),
                        if (!paymentData[TransactionFields.paymentVerified])
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
                                          .id)),
                              child: Icon(Icons.block,
                                  color: CustomColors.coralRed))
                      ], flex: 2, backgroundColor: backgroundColor)
                    ],
                  );
                });
          }),
    );
  }

  void showProofOfPaymentDialog(
      {required String paymentMethod, required String proofOfPayment}) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  quicksandBlackBold('Payment Method: $paymentMethod',
                      fontSize: 30),
                  const Gap(10),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.25,
                    height: MediaQuery.of(context).size.height * 0.5,
                    decoration: BoxDecoration(
                        color: Colors.black,
                        image: DecorationImage(
                            image: NetworkImage(proofOfPayment))),
                  ),
                  const Gap(30),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.1,
                    height: 30,
                    child: TextButton(
                        onPressed: () => GoRouter.of(context).pop(),
                        child: quicksandBlackBold('CLOSE')),
                  )
                ],
              ),
            ));
  }
}
