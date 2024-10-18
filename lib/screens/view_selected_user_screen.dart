import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/widgets/left_navigator_widget.dart';

import '../providers/loading_provider.dart';
import '../providers/user_data_provider.dart';
import '../utils/color_util.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/text_widgets.dart';

class ViewSelectedUserScreen extends ConsumerStatefulWidget {
  final String userID;
  const ViewSelectedUserScreen({super.key, required this.userID});

  @override
  ConsumerState<ViewSelectedUserScreen> createState() =>
      _ViewSelectedUserScreenState();
}

class _ViewSelectedUserScreenState
    extends ConsumerState<ViewSelectedUserScreen> {
  String formattedName = '';
  String profileImageURL = '';

  List<DocumentSnapshot> orderDocs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final goRouter = GoRouter.of(context);
      try {
        ref.read(loadingProvider.notifier).toggleLoading(true);
        if (!hasLoggedInUser()) {
          ref.read(loadingProvider.notifier).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);
          return;
        }

        ref.read(userDataProvider).setUserType(await getCurrentUserType());
        if (ref.read(userDataProvider).userType == UserTypes.client) {
          ref.read(loadingProvider.notifier).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);
          return;
        }

        final selectedUser = await getThisUserDoc(widget.userID);
        final selectedUserData = selectedUser.data() as Map<dynamic, dynamic>;

        formattedName =
            '${selectedUserData[UserFields.firstName]} ${selectedUserData[UserFields.lastName]}';
        profileImageURL = selectedUserData[UserFields.profileImageURL];
        orderDocs = await getAllClientOrderDocs(widget.userID);
        orderDocs.sort((a, b) {
          DateTime aTime = (a[OrderFields.dateCreated] as Timestamp).toDate();
          DateTime bTime = (b[OrderFields.dateCreated] as Timestamp).toDate();
          return bTime.compareTo(aTime);
        });
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(SnackBar(
            content: Text('Error getting selected user data: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(userDataProvider);
    return Scaffold(
      body: stackedLoadingContainer(
          context,
          ref.read(loadingProvider).isLoading,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leftNavigator(context, path: GoRoutes.users),
              SingleChildScrollView(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: Column(
                    children: [
                      _backButton(),
                      horizontal5Percent(
                        context,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [_userDetails(), orderHistory()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )),
    );
  }

  Widget _backButton() {
    return all20Pix(
      child: Row(
        children: [
          backButton(context,
              onPress: () => GoRouter.of(context).goNamed(GoRoutes.users)),
        ],
      ),
    );
  }

  Widget _userDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        buildProfileImage(profileImageURL: profileImageURL),
        quicksandWhiteBold(formattedName, fontSize: 40),
        Divider(color: CustomColors.lavenderMist)
      ]),
    );
  }

  Widget orderHistory() {
    return vertical20Pix(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          quicksandWhiteBold('ORDER HISTORY', fontSize: 36),
          orderEntries()
        ],
      ),
    );
  }

  Widget orderEntries() {
    return vertical10Pix(
      child: orderDocs.isNotEmpty
          ? Center(
              child: Wrap(
                  spacing: 40,
                  runSpacing: 40,
                  alignment: WrapAlignment.start,
                  children: orderDocs
                      .map((order) => _orderHistoryEntry(order))
                      .toList()),
            )
          : all20Pix(
              child: quicksandWhiteBold('THIS USER HAS NO ORDER HISTORY YET',
                  fontSize: 20)),
    );
  }

  Widget _orderHistoryEntry(DocumentSnapshot orderDoc) {
    final orderData = orderDoc.data() as Map<dynamic, dynamic>;
    String status = orderData[OrderFields.orderStatus];
    String itemID = orderData[OrderFields.itemID];
    String glassType =
        orderData[OrderFields.quotation][QuotationFields.glassType] ?? '';
    String color =
        orderData[OrderFields.quotation][QuotationFields.color] ?? '';
    double price =
        orderData[OrderFields.quotation][QuotationFields.itemOverallPrice];
    num quantity = orderData[OrderFields.quantity];
    Map<dynamic, dynamic> review = orderData[OrderFields.review];
    return FutureBuilder(
      future: getThisItemDoc(itemID),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData ||
            snapshot.hasError) return snapshotHandler(snapshot);

        final itemData = snapshot.data!.data() as Map<dynamic, dynamic>;
        String itemType = itemData[ItemFields.itemType];
        String imageURL = itemData[ItemFields.imageURL];
        String name = itemData[ItemFields.name];
        return Container(
          width: 450,
          height: 250,
          decoration: BoxDecoration(border: Border.all(color: Colors.white)),
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(
                imageURL,
                width: 180,
                height: 180,
                fit: BoxFit.cover,
              ),
              Gap(10),
              SizedBox(
                width: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        quicksandWhiteBold(name,
                            fontSize: 24, textAlign: TextAlign.left),
                        quicksandWhiteRegular('Quantity: $quantity',
                            fontSize: 12),
                        if (itemType != ItemTypes.rawMaterial) ...[
                          quicksandWhiteRegular('Glass Type: $glassType',
                              textAlign: TextAlign.left, fontSize: 12),
                          quicksandWhiteRegular('Color: $color', fontSize: 12)
                        ],
                        quicksandWhiteRegular('Status: $status', fontSize: 12),
                        if (status == OrderStatuses.pickedUp &&
                            review.isNotEmpty)
                          Row(children: [
                            quicksandWhiteBold('Rating: ', fontSize: 14),
                            starRating(review[ReviewFields.rating],
                                onUpdate: (newVal) {}, mayMove: false)
                          ])
                      ],
                    ),
                    quicksandWhiteBold('PHP ${formatPrice(price * quantity)}',
                        fontSize: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
