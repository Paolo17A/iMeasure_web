import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/widgets/top_navigator_widget.dart';

import '../providers/loading_provider.dart';
import '../utils/color_util.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/app_drawer_widget.dart';
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
          goRouter.goNamed(GoRoutes.home);
          return;
        }

        final selectedUser = await getThisUserDoc(widget.userID);
        final selectedUserData = selectedUser.data() as Map<dynamic, dynamic>;
        formattedName =
            '${selectedUserData[UserFields.firstName]} ${selectedUserData[UserFields.lastName]}';
        profileImageURL = selectedUserData[UserFields.profileImageURL];
        orderDocs = await getAllClientOrderDocs(widget.userID);
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
    return Scaffold(
      drawer: appDrawer(context, currentPath: GoRoutes.users),
      body: stackedLoadingContainer(
          context,
          ref.read(loadingProvider).isLoading,
          SingleChildScrollView(
            child: Column(
              children: [
                topNavigator(context, path: GoRoutes.users),
                horizontal5Percent(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [_backButton(), _userDetails(), orderHistory()],
                  ),
                ),
              ],
            ),
          )),
    );
  }

  Widget _backButton() {
    return vertical20Pix(
      child: backButton(context,
          onPress: () => GoRouter.of(context).goNamed(GoRoutes.users)),
    );
  }

  Widget _userDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        buildProfileImage(profileImageURL: profileImageURL),
        quicksandBlackBold(formattedName, fontSize: 40),
        Divider(color: CustomColors.deepNavyBlue)
      ]),
    );
  }

  Widget orderHistory() {
    return vertical20Pix(
      child: Container(
        //width: double.infinity,
        //decoration: BoxDecoration(color: CustomColors.deepNavyBlue),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            quicksandBlackBold('ORDER HISTORY', fontSize: 36),
            orderEntries()
          ],
        ),
      ),
    );
  }

  Widget orderEntries() {
    return orderDocs.isNotEmpty
        ? Wrap(
            children:
                orderDocs.map((order) => _orderHistoryEntry(order)).toList(),
          )
        /*ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: orderDocs.length,
            itemBuilder: (context, index) {
              return _orderHistoryEntry(orderDocs[index]);
            })*/
        : all20Pix(
            child: quicksandWhiteBold('THIS USER HAS NO ORDER HISTORY YET',
                fontSize: 20));
  }

  Widget _orderHistoryEntry(DocumentSnapshot orderDoc) {
    final orderData = orderDoc.data() as Map<dynamic, dynamic>;
    String status = orderData[OrderFields.purchaseStatus];
    String windowID = orderData[OrderFields.windowID];
    String glassType = orderData[OrderFields.glassType];
    String color = orderData[OrderFields.color];
    double price = orderData[OrderFields.laborPrice] +
        orderData[OrderFields.windowOverallPrice];
    return FutureBuilder(
      future: getThisWindowDoc(windowID),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData ||
            snapshot.hasError) return snapshotHandler(snapshot);

        final productData = snapshot.data!.data() as Map<dynamic, dynamic>;
        String imageURL = productData[WindowFields.imageURL];
        String name = productData[WindowFields.name];
        return all10Pix(
            child: Container(
          width: 360,
          height: 180,
          decoration: BoxDecoration(
              //color: CustomColors.deepNavyBlue,
              border: Border.all(color: CustomColors.deepNavyBlue)),
          padding: EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(imageURL, width: 120, height: 120),
              Gap(10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  quicksandBlackBold(name, fontSize: 26),
                  quicksandBlackRegular('Glass Type: $glassType', fontSize: 18),
                  quicksandBlackRegular('Color: $color', fontSize: 18),
                  quicksandBlackRegular('Status: $status', fontSize: 18),
                  quicksandBlackBold('PHP ${formatPrice(price)}'),
                ],
              ),
            ],
          ),
        ));
      },
    );
  }
}
