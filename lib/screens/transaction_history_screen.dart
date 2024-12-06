import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/providers/loading_provider.dart';
import 'package:imeasure/utils/firebase_util.dart';
import 'package:imeasure/utils/go_router_util.dart';
import 'package:imeasure/widgets/custom_miscellaneous_widgets.dart';
import 'package:imeasure/widgets/top_navigator_widget.dart';
import 'package:intl/intl.dart';

import '../providers/user_data_provider.dart';
import '../utils/string_util.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/text_widgets.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  List<DocumentSnapshot> transactionDocs = [];

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
        if (ref.read(userDataProvider).userType == UserTypes.admin) {
          ref.read(loadingProvider).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);
          return;
        }
        transactionDocs = await getAllUserTransactionDocs();
        transactionDocs.sort((a, b) {
          DateTime aTime =
              (a[TransactionFields.dateCreated] as Timestamp).toDate();
          DateTime bTime =
              (b[TransactionFields.dateCreated] as Timestamp).toDate();
          return bTime.compareTo(aTime);
        });
        ref.read(loadingProvider).toggleLoading(false);
      } catch (error) {
        ref.read(loadingProvider).toggleLoading(false);
        scaffoldMessenger.showSnackBar(SnackBar(
            content: Text('Error getting your transaction history: $error')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(userDataProvider);
    return Scaffold(
      appBar: topUserNavigator(context, path: GoRoutes.profile),
      body: switchedLoadingContainer(
          ref.read(loadingProvider).isLoading,
          SingleChildScrollView(
            child: Column(
              children: [Divider(), _backButton(), _transactionHistory()],
            ),
          )),
    );
  }

  Widget _backButton() {
    return all10Pix(
        child: Row(children: [
      backButton(context,
          onPress: () => GoRouter.of(context).goNamed(GoRoutes.profile))
    ]));
  }

  Widget _transactionHistory() {
    return horizontal5Percent(context,
        child: Column(
          children: [
            quicksandWhiteBold('TRANSACTION HISTORY', fontSize: 40),
            transactionDocs.isNotEmpty
                ? Wrap(
                    spacing: 40,
                    runSpacing: 40,
                    children: transactionDocs
                        .map((transactionDoc) =>
                            _transactionEntry(transactionDoc))
                        .toList(),
                  )
                : vertical20Pix(
                    child: quicksandWhiteBold(
                        'You have not yet made any transactions.'))
          ],
        ));
  }

  Widget _transactionEntry(DocumentSnapshot transactionDoc) {
    final transactionData = transactionDoc.data() as Map<dynamic, dynamic>;
    String proofOfPayment = transactionData[TransactionFields.proofOfPayment];
    DateTime dateCreated =
        (transactionData[TransactionFields.dateCreated] as Timestamp).toDate();
    DateTime dateApproved =
        (transactionData[TransactionFields.dateApproved] as Timestamp).toDate();
    String transactionStatus =
        transactionData[TransactionFields.transactionStatus];
    num paidAmount = transactionData[TransactionFields.paidAmount];
    String paymentMethod = transactionData[TransactionFields.paymentMethod];
    String denialReason =
        transactionData[TransactionFields.denialReason] ?? 'N/A';
    return Container(
        width: 400,
        height: 155,
        decoration: BoxDecoration(border: Border.all(color: Colors.white)),
        padding: EdgeInsets.all(10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(
            onTap: () => showEnlargedPics(context, imageURL: proofOfPayment),
            child: Container(
                width: 150,
                height: 120,
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: NetworkImage(proofOfPayment),
                        fit: BoxFit.cover))),
          ),
          Gap(12),
          SizedBox(
            width: 215,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(children: [
                quicksandWhiteBold('Paid Amount: ', fontSize: 15),
                quicksandWhiteRegular(
                    'PHP ${formatPrice(paidAmount.toDouble())}',
                    fontSize: 15)
              ]),
              Wrap(children: [
                quicksandWhiteBold('Payment Method: ', fontSize: 15),
                quicksandWhiteRegular(paymentMethod, fontSize: 15)
              ]),
              Wrap(children: [
                quicksandWhiteBold('Date Created: ', fontSize: 15),
                quicksandWhiteRegular(
                    DateFormat('MMM dd, yyyy').format(dateCreated),
                    fontSize: 15)
              ]),
              if (transactionStatus == TransactionStatuses.approved)
                Wrap(children: [
                  quicksandWhiteBold('Date Approved: ', fontSize: 15),
                  quicksandWhiteRegular(
                      DateFormat('MMM dd, yyyy').format(dateApproved),
                      fontSize: 15)
                ]),
              Wrap(children: [
                quicksandWhiteBold('Status:  ', fontSize: 15),
                quicksandWhiteRegular(transactionStatus, fontSize: 15)
              ]),
              if (transactionStatus == TransactionStatuses.denied)
                GestureDetector(
                  onTap: denialReason.length > 30
                      ? () => showDialog(
                          context: context,
                          builder: (_) => Dialog(
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      quicksandBlackBold('DENIAL REASION'),
                                      quicksandBlackRegular(denialReason)
                                    ],
                                  ),
                                ),
                              ))
                      : null,
                  child: quicksandWhiteRegular('Denial Reason: $denialReason',
                      maxLines: 2,
                      textOverflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.left,
                      fontSize: 14),
                )
            ]),
          )
        ]));
  }
}
