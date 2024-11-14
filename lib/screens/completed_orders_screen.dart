import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/providers/loading_provider.dart';
import 'package:imeasure/providers/orders_provider.dart';
import 'package:imeasure/utils/go_router_util.dart';
import 'package:imeasure/widgets/custom_miscellaneous_widgets.dart';
import 'package:imeasure/widgets/custom_padding_widgets.dart';
import 'package:imeasure/widgets/text_widgets.dart';
import 'package:imeasure/widgets/top_navigator_widget.dart';
import 'package:intl/intl.dart';

import '../providers/user_data_provider.dart';
import '../utils/firebase_util.dart';
import '../utils/string_util.dart';
import '../widgets/custom_button_widgets.dart';

class CompletedOrdersScreen extends ConsumerStatefulWidget {
  const CompletedOrdersScreen({super.key});

  @override
  ConsumerState<CompletedOrdersScreen> createState() =>
      _CompletedOrdersScreenState();
}

class _CompletedOrdersScreenState extends ConsumerState<CompletedOrdersScreen> {
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
        ref.read(ordersProvider).setOrderDocs(
            await getAllClientCompletedOrderDocs(
                FirebaseAuth.instance.currentUser!.uid));
        ref.read(ordersProvider).sortOrdersByDate();
        ref.read(loadingProvider).toggleLoading(false);
      } catch (error) {
        ref.read(loadingProvider).toggleLoading(false);
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error gettin user order history: $error')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(ordersProvider);
    return Scaffold(
      appBar: topUserNavigator(context, path: GoRoutes.profile),
      body: switchedLoadingContainer(
          ref.read(loadingProvider).isLoading,
          SingleChildScrollView(
            child: Column(
              children: [Divider(), _backButton(), _orderHistory()],
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

  Widget _orderHistory() {
    return horizontal5Percent(context,
        child: Column(children: [
          quicksandWhiteBold('ORDER HISTORY', fontSize: 40),
          ref.read(ordersProvider).orderDocs.isNotEmpty
              ? vertical10Pix(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Wrap(
                      spacing: 40,
                      runSpacing: 40,
                      children: ref
                          .read(ordersProvider)
                          .orderDocs
                          .map((orderDoc) => _orderEntry(orderDoc))
                          .toList(),
                    ),
                  ),
                )
              : vertical20Pix(
                  child: quicksandWhiteBold(
                      'You have not yet ordered any items yet.'))
        ]));
  }

  Widget _orderEntry(DocumentSnapshot orderDoc) {
    final orderData = orderDoc.data() as Map<dynamic, dynamic>;
    String itemID = orderData[OrderFields.itemID];
    String orderStatus = orderData[OrderFields.orderStatus];
    num quantity = orderData[OrderFields.quantity];
    DateTime dateCreated =
        (orderData[OrderFields.dateCreated] as Timestamp).toDate();
    Map<dynamic, dynamic> quotation = orderData[OrderFields.quotation];
    Map<dynamic, dynamic> review = orderData[OrderFields.review];
    num itemOverallPrice = quotation[QuotationFields.itemOverallPrice];
    return FutureBuilder(
        future: getThisItemDoc(itemID),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              !snapshot.hasData ||
              snapshot.hasError) return snapshotHandler(snapshot);

          final itemData = snapshot.data!.data() as Map<dynamic, dynamic>;
          //String itemType = itemData[ItemFields.itemType];
          List<dynamic> imageURLs = itemData[ItemFields.imageURLs];
          String name = itemData[ItemFields.name];
          return Container(
            width: 400,
            height: 200,
            decoration: BoxDecoration(border: Border.all(color: Colors.white)),
            padding: EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    width: 150,
                    height: 170,
                    decoration: BoxDecoration(
                        image: DecorationImage(
                            image: NetworkImage(imageURLs.first),
                            fit: BoxFit.cover))),
                Gap(12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        quicksandWhiteBold(name),
                        quicksandWhiteRegular('Quantity: $quantity',
                            fontSize: 14),
                        quicksandWhiteRegular(
                            'Date Ordered: ${DateFormat('MMM dd, yyyy').format(dateCreated)}',
                            fontSize: 14),
                        quicksandWhiteRegular('Status: $orderStatus',
                            fontSize: 14),
                        if (orderStatus == OrderStatuses.completed &&
                            review.isNotEmpty)
                          Row(children: [
                            quicksandWhiteBold('Rating: ', fontSize: 14),
                            starRating(review[ReviewFields.rating],
                                onUpdate: (newVal) {}, mayMove: false)
                          ])
                      ],
                    ),
                    quicksandWhiteBold(
                        'PHP ${formatPrice(itemOverallPrice * quantity.toDouble())}')
                  ],
                )
              ],
            ),
          );
        });
  }
}
