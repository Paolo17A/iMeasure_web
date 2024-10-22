import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:imeasure/providers/loading_provider.dart';
import 'package:imeasure/providers/orders_provider.dart';
import 'package:imeasure/utils/color_util.dart';
import 'package:imeasure/utils/go_router_util.dart';
import 'package:imeasure/widgets/custom_miscellaneous_widgets.dart';
import 'package:imeasure/widgets/custom_padding_widgets.dart';
import 'package:imeasure/widgets/custom_text_field_widget.dart';
import 'package:imeasure/widgets/text_widgets.dart';
import 'package:imeasure/widgets/top_navigator_widget.dart';
import 'package:intl/intl.dart';

import '../providers/user_data_provider.dart';
import '../utils/firebase_util.dart';
import '../utils/string_util.dart';
import '../widgets/custom_button_widgets.dart';

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  double initialRating = 5;
  final feedbackController = TextEditingController();
  Uint8List? reviewImageBytes;

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
        ref.read(ordersProvider).setOrderDocs(await getAllClientOrderDocs(
            FirebaseAuth.instance.currentUser!.uid));

        ref.read(ordersProvider).orderDocs.sort((a, b) {
          DateTime aTime = (a[OrderFields.dateCreated] as Timestamp).toDate();
          DateTime bTime = (b[OrderFields.dateCreated] as Timestamp).toDate();
          return bTime.compareTo(aTime);
        });
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
          String imageURL = itemData[ItemFields.imageURL];
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
                            image: NetworkImage(imageURL), fit: BoxFit.cover))),
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
                        if (orderStatus == OrderStatuses.pickedUp &&
                            review.isNotEmpty)
                          Row(children: [
                            quicksandWhiteBold('Rating: ', fontSize: 14),
                            starRating(review[ReviewFields.rating],
                                onUpdate: (newVal) {}, mayMove: false)
                          ])
                        else if (orderStatus == OrderStatuses.pickedUp)
                          vertical10Pix(
                            child: ElevatedButton(
                                onPressed: () => showRatingDialog(orderDoc),
                                child: quicksandWhiteRegular('LEAVE REVIEW',
                                    fontSize: 12)),
                          )
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

  void showRatingDialog(DocumentSnapshot orderDoc) {
    initialRating = 0;
    feedbackController.clear();
    reviewImageBytes = null;
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
              builder: (context, setState) => AlertDialog(
                  content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                //height: MediaQuery.of(context).size.width * 0.3,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        TextButton(
                            onPressed: () => GoRouter.of(context).pop(),
                            child: quicksandBlackBold('X'))
                      ]),
                      quicksandBlackBold('LEAVE YOUR RATING', fontSize: 40),
                      Gap(40),
                      Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: CustomColors.deepCharcoal, width: 2)),
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            starRating(initialRating, onUpdate: (newVal) {
                              setState(() {
                                initialRating = newVal;
                              });
                            }, starSize: 40),
                            all20Pix(
                              child: CustomTextField(
                                  text: 'Leave additional feedback (optional)',
                                  controller: feedbackController,
                                  textInputType: TextInputType.multiline,
                                  displayPrefixIcon: null),
                            ),
                            if (reviewImageBytes != null)
                              Image.memory(reviewImageBytes!,
                                  width: 200, height: 200),
                            ElevatedButton(
                                onPressed: () async {
                                  final pickedFile =
                                      await ImagePickerWeb.getImageAsBytes();
                                  if (pickedFile == null) {
                                    return;
                                  }
                                  setState(() {
                                    reviewImageBytes = pickedFile;
                                  });
                                },
                                child: quicksandWhiteRegular(
                                    'ADD IMAGE (OPTIONAL)'))
                          ],
                        ),
                      ),
                      const Gap(40),
                      ElevatedButton(
                          onPressed: () {
                            reviewThisOrder(context, ref,
                                orderID: orderDoc.id,
                                rating: initialRating.toInt(),
                                reviewController: feedbackController,
                                reviewImageFile: reviewImageBytes);
                          },
                          child: all20Pix(
                            child: quicksandWhiteBold('SUBMIT RATING',
                                fontSize: 18),
                          ))
                    ],
                  ),
                ),
              )),
            ));
  }
}
