import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/providers/user_data_provider.dart';
import 'package:imeasure/utils/color_util.dart';
import 'package:imeasure/widgets/left_navigator_widget.dart';
import 'package:imeasure/widgets/text_widgets.dart';
import 'package:intl/intl.dart';

import '../providers/loading_provider.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';

class ViewSelectedRawMaterialScreen extends ConsumerStatefulWidget {
  final String itemID;
  const ViewSelectedRawMaterialScreen({super.key, required this.itemID});

  @override
  ConsumerState<ViewSelectedRawMaterialScreen> createState() =>
      _SelectedRawMaterialScreenState();
}

class _SelectedRawMaterialScreenState
    extends ConsumerState<ViewSelectedRawMaterialScreen> {
  //  PRODUCT VARIABLES
  String name = '';
  String description = '';
  bool isAvailable = false;

  List<dynamic> imageURLs = [];
  List<DocumentSnapshot> orderDocs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      ref.read(loadingProvider.notifier).toggleLoading(true);
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final goRouter = GoRouter.of(context);
      try {
        if (!hasLoggedInUser()) {
          goRouter.goNamed(GoRoutes.home);
          return;
        }
        ref.read(loadingProvider.notifier).toggleLoading(true);

        //  GET PRODUCT DATA
        final item = await getThisItemDoc(widget.itemID);
        final itemData = item.data() as Map<dynamic, dynamic>;
        name = itemData[ItemFields.name];
        description = itemData[ItemFields.description];
        isAvailable = itemData[ItemFields.isAvailable];
        imageURLs = itemData[ItemFields.imageURLs];

        orderDocs = await getAllItemOrderDocs(widget.itemID);
        orderDocs.sort((a, b) {
          DateTime aTime = (a[OrderFields.dateCreated] as Timestamp).toDate();
          DateTime bTime = (b[OrderFields.dateCreated] as Timestamp).toDate();
          return bTime.compareTo(aTime);
        });
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting selected product: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    return Scaffold(
      body: switchedLoadingContainer(
          ref.read(loadingProvider).isLoading,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leftNavigator(context, path: GoRoutes.windows),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _backButton(),
                      horizontal5Percent(context,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _windowDetails(),
                              orderHistory(),
                            ],
                          )),
                    ],
                  ),
                ),
              ),
            ],
          )),
    );
  }

  Widget _backButton() {
    return all10Pix(
        child: Row(children: [
      backButton(context, onPress: () {
        if (ref.read(userDataProvider).userType == UserTypes.admin)
          GoRouter.of(context).goNamed(GoRoutes.rawMaterial);
        else if (ref.read(userDataProvider).userType == UserTypes.client)
          GoRouter.of(context).goNamed(GoRoutes.shop);
      })
    ]));
  }

  Widget _windowDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        if (imageURLs.isNotEmpty)
          Image.network(
            imageURLs.first,
            width: 150,
            height: 150,
            fit: BoxFit.cover,
          ),
        quicksandWhiteBold('\t\tAVAILABLE: ${isAvailable ? 'YES' : 'NO'}'),
        Divider(color: CustomColors.lavenderMist)
      ]),
    );
  }

  Widget orderHistory() {
    return vertical20Pix(
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(children: [
              quicksandWhiteBold(name, fontSize: 36, textAlign: TextAlign.left)
            ]),
            orderDocs.isNotEmpty
                ? Wrap(
                    children: orderDocs
                        .map((order) => _orderHistoryEntry(order))
                        .toList())
                : all20Pix(
                    child: quicksandWhiteBold(
                        'THIS RAW MATERIAL HAS NOT BEEN ORDERED YET.',
                        fontSize: 20)),
          ],
        ),
      ),
    );
  }

  Widget _orderHistoryEntry(DocumentSnapshot orderDoc) {
    final orderData = orderDoc.data() as Map<dynamic, dynamic>;
    String status = orderData[OrderFields.orderStatus];
    String clientID = orderData[OrderFields.clientID];
    double price =
        orderData[OrderFields.quotation][QuotationFields.itemOverallPrice];
    DateTime dateCreated =
        (orderData[OrderFields.dateCreated] as Timestamp).toDate();
    Map<dynamic, dynamic> review = orderData[OrderFields.review];

    return FutureBuilder(
      future: getThisUserDoc(clientID),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData ||
            snapshot.hasError) return snapshotHandler(snapshot);

        final clientData = snapshot.data!.data() as Map<dynamic, dynamic>;
        String profileImageURL = clientData[UserFields.profileImageURL];
        print(profileImageURL);
        String firstName = clientData[UserFields.firstName];
        String lastName = clientData[UserFields.lastName];

        return all10Pix(
            child: Container(
          width: 320,
          height: 250,
          decoration: BoxDecoration(border: Border.all(color: Colors.white)),
          padding: EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildProfileImage(
                      profileImageURL: profileImageURL, radius: 35),
                  Gap(10),
                  quicksandWhiteBold('$firstName $lastName', fontSize: 20),
                  all4Pix(
                      child: Column(children: [
                    quicksandWhiteRegular(
                        'Date Ordered: ${DateFormat('MMM dd, yyyy').format(dateCreated)}',
                        fontSize: 12),
                    quicksandWhiteRegular('Status: $status', fontSize: 12)
                  ])),
                  if (status == OrderStatuses.completed && review.isNotEmpty)
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      quicksandWhiteBold('Rating: ', fontSize: 14),
                      starRating(review[ReviewFields.rating],
                          onUpdate: (newVal) {}, mayMove: false)
                    ])
                  else if (status == OrderStatuses.pickedUp)
                    quicksandWhiteBold('Not Yet Rated', fontSize: 14),
                ],
              ),
              quicksandWhiteBold('PHP ${formatPrice(price)}'),
            ],
          ),
        ));
      },
    );
  }
}
