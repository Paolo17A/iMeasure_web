import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/main.dart';
import 'package:imeasure/providers/loading_provider.dart';
import 'package:imeasure/utils/firebase_util.dart';
import 'package:imeasure/utils/go_router_util.dart';
import 'package:imeasure/widgets/top_navigator_widget.dart';

import '../providers/user_data_provider.dart';
import '../utils/string_util.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/text_widgets.dart';

class SearchResultScreen extends ConsumerStatefulWidget {
  final String searchInput;
  const SearchResultScreen({super.key, required this.searchInput});

  @override
  ConsumerState<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends ConsumerState<SearchResultScreen> {
  List<DocumentSnapshot> itemDocs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      iMeasure.searchController.text = widget.searchInput;
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
        itemDocs = await searchForTheseItems(widget.searchInput);
        ref.read(loadingProvider).toggleLoading(false);
      } catch (error) {
        ref.read(loadingProvider).toggleLoading(false);
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting search results: $error')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    return Scaffold(
      appBar: topUserNavigator(context, path: GoRoutes.search),
      body: stackedLoadingContainer(
          context,
          ref.read(loadingProvider).isLoading,
          Column(
            children: [
              Divider(color: Colors.white),
              SingleChildScrollView(
                child: horizontal5Percent(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      quicksandWhiteBold(
                          '${itemDocs.length.toString()} ITEMS FOUND FOR "${widget.searchInput}"',
                          fontSize: 26,
                          textAlign: TextAlign.left),
                      _itemEntries()
                    ],
                  ),
                ),
              ),
            ],
          )),
    );
  }

  Widget _itemEntries() {
    return Center(
      child: Wrap(
          alignment: WrapAlignment.start,
          spacing: 60,
          runSpacing: 60,
          children: itemDocs.map((item) => _searchedItemEntry(item)).toList()),
    );
  }

  Widget _searchedItemEntry(DocumentSnapshot itemDoc) {
    final itemData = itemDoc.data() as Map<dynamic, dynamic>;
    List<dynamic> imageURLs = itemData[ItemFields.imageURLs];
    String name = itemData[ItemFields.name];
    String itemType = itemData[ItemFields.itemType];
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.white)),
      padding: EdgeInsets.all(12),
      child: Column(
        children: [
          square300NetworkImage(imageURLs.first),
          vertical10Pix(child: quicksandWhiteBold(name)),
          //if (itemType == ItemTypes.rawMaterial)
          vertical10Pix(
            child: FutureBuilder(
                future: getAllItemOrderDocs(itemDoc.id),
                builder: ((context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting ||
                      !snapshot.hasData ||
                      snapshot.hasError)
                    return starRating(0, onUpdate: (n) {}, mayMove: false);
                  List<DocumentSnapshot> orderDocs = snapshot.data!;

                  orderDocs = orderDocs.where((orderDoc) {
                    final orderData = orderDoc.data() as Map<dynamic, dynamic>;
                    return orderData.containsKey(OrderFields.review) &&
                        (orderData[OrderFields.review] as Map<String, dynamic>)
                            .isNotEmpty;
                  }).toList();
                  if (orderDocs.isEmpty)
                    return quicksandWhiteRegular('No Ratings Yet',
                        fontSize: 12);
                  num sumRating = 0;
                  for (var order in orderDocs) {
                    final orderData = order.data() as Map<dynamic, dynamic>;
                    sumRating +=
                        orderData[OrderFields.review][ReviewFields.rating];
                  }
                  double averageRating = sumRating / orderDocs.length;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      starRating(averageRating,
                          onUpdate: (val) {}, mayMove: false),
                      quicksandWhiteRegular('(${orderDocs.length.toString()})',
                          fontSize: 12)
                    ],
                  );
                })),
          ),
          ElevatedButton(
              onPressed: () {
                if (itemType == ItemTypes.window) {
                  GoRouter.of(context).goNamed(GoRoutes.selectedWindow,
                      pathParameters: {PathParameters.itemID: itemDoc.id});
                } else if (itemType == ItemTypes.door) {
                  GoRouter.of(context).goNamed(GoRoutes.selectedDoor,
                      pathParameters: {PathParameters.itemID: itemDoc.id});
                } else if (itemType == ItemTypes.rawMaterial) {
                  addRawMaterialToCart(context, ref, itemID: itemDoc.id);
                }
              },
              child: quicksandWhiteRegular('ADD TO CART'))
        ],
      ),
    );
  }
}
