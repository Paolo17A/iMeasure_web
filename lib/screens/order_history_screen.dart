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
  List<Uint8List>? reviewImageBytesList = [];

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
                        else if (orderStatus == OrderStatuses.completed)
                          vertical10Pix(
                            child: ElevatedButton(
                                onPressed: () => showRatingDialog(orderDoc),
                                child: quicksandWhiteRegular('LEAVE REVIEW',
                                    fontSize: 12)),
                          )
                        else if (orderStatus == OrderStatuses.forPickUp)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              vertical10Pix(
                                child: ElevatedButton(
                                    onPressed: () => markOrderAsPickedUp(
                                        context, ref, orderID: orderDoc.id),
                                    child: quicksandWhiteRegular(
                                        'MARK AS PICKED UP',
                                        fontSize: 12)),
                              ),
                            ],
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
    if (reviewImageBytesList != null) reviewImageBytesList!.clear();
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
              builder: (context, setState) => AlertDialog(
                  content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
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
                            if (reviewImageBytesList != null &&
                                reviewImageBytesList!.isNotEmpty)
                              _selectedReviewImagesContainer(),
                            ElevatedButton(
                                onPressed: () async {
                                  List<Uint8List>? pickedFiles =
                                      await ImagePickerWeb
                                          .getMultiImagesAsBytes();
                                  if (pickedFiles == null) {
                                    return;
                                  }
                                  if (reviewImageBytesList!.length +
                                          pickedFiles.length >
                                      3) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'You may only have up to three images.')));
                                    return;
                                  }
                                  setState(() {
                                    reviewImageBytesList!.addAll(pickedFiles);
                                  });
                                },
                                child: quicksandWhiteRegular(
                                    'ADD IMAGES (OPTIONAL)'))
                          ],
                        ),
                      ),
                      const Gap(40),
                      _submitReviewButton(orderDoc.id)
                    ],
                  ),
                ),
              )),
            ));
  }

  Widget _selectedReviewImagesContainer() {
    return Container(
      color: CustomColors.emeraldGreen.withOpacity(0.4),
      padding: EdgeInsets.all(12),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: reviewImageBytesList!
              .map(
                (imageBytes) => selectedMemoryImageDisplay(imageBytes, () {
                  setState(() {
                    reviewImageBytesList!.remove(imageBytes);
                  });
                }),
              )
              .toList()),
    );
  }

  Widget _submitReviewButton(String orderID) {
    return ElevatedButton(
        onPressed: () {
          reviewThisOrder(context, ref,
              orderID: orderID,
              rating: initialRating.toInt(),
              reviewController: feedbackController,
              reviewImageBytesList: reviewImageBytesList!);
        },
        child: all20Pix(
          child: quicksandWhiteBold('SUBMIT RATING', fontSize: 18),
        ));
  }
}
