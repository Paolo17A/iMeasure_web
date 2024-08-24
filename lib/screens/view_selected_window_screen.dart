import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/utils/color_util.dart';
import 'package:imeasure/widgets/left_navigator_widget.dart';
import 'package:imeasure/widgets/text_widgets.dart';

import '../providers/loading_provider.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';

class ViewSelectedWindowScreen extends ConsumerStatefulWidget {
  final String itemID;
  const ViewSelectedWindowScreen({super.key, required this.itemID});

  @override
  ConsumerState<ViewSelectedWindowScreen> createState() =>
      _SelectedWindowScreenState();
}

class _SelectedWindowScreenState
    extends ConsumerState<ViewSelectedWindowScreen> {
  //  PRODUCT VARIABLES
  String name = '';
  String description = '';
  bool isAvailable = false;
  num minWidth = 0;
  num maxWidth = 0;
  num minLength = 0;
  num maxLength = 0;
  String imageURL = '';
  int currentImageIndex = 0;
  //List<DocumentSnapshot> orderDocs = [];

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

        //  GET PRODUCT DATA
        final window = await getThisItemDoc(widget.itemID);
        final windowData = window.data() as Map<dynamic, dynamic>;
        name = windowData[ItemFields.name];
        description = windowData[ItemFields.description];
        isAvailable = windowData[ItemFields.isAvailable];
        imageURL = windowData[ItemFields.imageURL];
        minLength = windowData[ItemFields.minHeight];
        maxLength = windowData[ItemFields.maxHeight];
        minWidth = windowData[ItemFields.minWidth];
        maxWidth = windowData[ItemFields.maxWidth];
        //orderDocs = await getAllWindowOrderDocs(widget.windowID);

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
                            children: [_windowDetails(), orderHistory()],
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
      backButton(context,
          onPress: () => GoRouter.of(context).goNamed(GoRoutes.windows))
    ]));
  }

  Widget _windowDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Image.network(
          imageURL,
          width: 150,
          height: 150,
          fit: BoxFit.cover,
        ),
        quicksandWhiteBold('\t\tAVAILABLE: ${isAvailable ? 'YES' : 'NO'}'),
        Gap(20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          quicksandWhiteBold('Minimum Width: ${minWidth.toString()}ft',
              fontSize: 16),
          Gap(40),
          quicksandWhiteBold('Minimum Length: ${minLength.toString()}ft',
              fontSize: 16),
        ]),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            quicksandWhiteBold('Maximum Width: ${maxWidth.toString()}ft',
                fontSize: 16),
            Gap(40),
            quicksandWhiteBold('Maximum Length: ${maxLength.toString()}ft',
                fontSize: 16)
          ],
        ),
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
            /*orderDocs.isNotEmpty
                ? Wrap(
                    children: orderDocs
                        .map((order) => _orderHistoryEntry(order))
                        .toList())
                : all20Pix(
                    child: quicksandWhiteBold(
                        'THIS WINDOW HAS NOT BEEN ORDERED YET.',
                        fontSize: 20)),*/
          ],
        ),
      ),
    );
  }

  Widget _orderHistoryEntry(DocumentSnapshot orderDoc) {
    final orderData = orderDoc.data() as Map<dynamic, dynamic>;
    String status = orderData[OrderFields.purchaseStatus];
    String clientID = orderData[OrderFields.clientID];
    String glassType = orderData[OrderFields.glassType];
    String color = orderData[OrderFields.color];
    double price = orderData[OrderFields.laborPrice] +
        orderData[OrderFields.windowOverallPrice];

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
          width: 350,
          height: 350,
          decoration: BoxDecoration(border: Border.all(color: Colors.white)),
          padding: EdgeInsets.all(10),
          child: Column(
            children: [
              buildProfileImage(profileImageURL: profileImageURL),
              Gap(10),
              quicksandWhiteBold('$firstName $lastName', fontSize: 20),
              Row(
                children: [
                  SizedBox(
                    width: 320,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        quicksandWhiteRegular('Glass Type: $glassType',
                            fontSize: 18, textAlign: TextAlign.left),
                        quicksandWhiteRegular('Color: $color', fontSize: 12),
                        quicksandWhiteRegular('Status: $status', fontSize: 12),
                        Gap(10),
                        quicksandWhiteBold('PHP ${formatPrice(price)}'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ));
      },
    );
  }
}
