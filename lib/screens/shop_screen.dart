import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/providers/cart_provider.dart';
import 'package:imeasure/providers/user_data_provider.dart';
import 'package:imeasure/utils/color_util.dart';
import 'package:imeasure/utils/string_util.dart';
import 'package:imeasure/widgets/custom_miscellaneous_widgets.dart';
import 'package:imeasure/widgets/custom_padding_widgets.dart';
import 'package:imeasure/widgets/text_widgets.dart';
import 'package:imeasure/widgets/top_navigator_widget.dart';

import '../providers/loading_provider.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  List<DocumentSnapshot> itemDocs = [];
  List<DocumentSnapshot> filteredDocs = [];
  String currentItemType = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final goRouter = GoRouter.of(context);
      try {
        if (hasLoggedInUser()) {
          final userDoc = await getCurrentUserDoc();
          final userData = userDoc.data() as Map<dynamic, dynamic>;
          String userType = userData[UserFields.userType];
          ref.read(userDataProvider).setUserType(userType);
          if (ref.read(userDataProvider).userType == UserTypes.admin) {
            goRouter.goNamed(GoRoutes.home);
            return;
          }
        }
        ref.read(loadingProvider).toggleLoading(true);
        itemDocs = await getAllItemDocs();
        filterDocsByItemType();
        if (hasLoggedInUser()) {
          ref.read(cartProvider).setCartItems(await getCartEntries(context));
        }
        ref.read(loadingProvider).toggleLoading(false);
      } catch (error) {
        ref.read(loadingProvider).toggleLoading(false);
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting item docs: $error')));
      }
    });
  }

  void filterDocsByItemType() {
    setState(() {
      if (currentItemType.isEmpty) {
        filteredDocs = itemDocs;
        return;
      }
      filteredDocs = itemDocs.where((itemDoc) {
        final itemData = itemDoc.data() as Map<dynamic, dynamic>;
        return itemData[ItemFields.itemType] == currentItemType;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(userDataProvider);
    ref.watch(cartProvider);
    return Scaffold(
      appBar: hasLoggedInUser()
          ? topUserNavigator(context, path: GoRoutes.shop)
          : topGuestNavigator(context, path: GoRoutes.shop),
      body: switchedLoadingContainer(
          ref.read(loadingProvider).isLoading,
          SingleChildScrollView(
            child: Column(children: [
              hasLoggedInUser() ? _userWidgets() : _guestWidgets()
            ]),
          )),
    );
  }

  //============================================================================
  //===USER WIDGETS=============================================================
  //============================================================================
  Widget _userWidgets() {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      itemTypeNavigator(context),
      Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height - 100,
        decoration: BoxDecoration(border: Border.all(color: Colors.white)),
        child: SingleChildScrollView(child: _filteredItemEntries()),
      )
    ]);
  }

  Widget itemTypeNavigator(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.2,
      height: MediaQuery.of(context).size.height - 100,
      decoration: BoxDecoration(
          color: CustomColors.deepCharcoal,
          border: Border.all(color: Colors.white)),
      child: Column(
        children: [
          Gap(40),
          itemButton(context, label: 'ALL', itemType: ''),
          itemButton(context, label: 'WINDOWS', itemType: ItemTypes.window),
          itemButton(context, label: 'DOORS', itemType: ItemTypes.door),
          itemButton(context,
              label: 'RAW MATERIALS', itemType: ItemTypes.rawMaterial),
        ],
      ),
    );
  }

  Widget itemButton(BuildContext context,
      {required String label, required String itemType}) {
    return all20Pix(
        child: SizedBox(
      width: double.infinity,
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: itemType == currentItemType
                  ? CustomColors.forestGreen
                  : CustomColors.lavenderMist),
          onPressed: () {
            setState(() {
              currentItemType = itemType;
            });
            filterDocsByItemType();
          },
          child: itemType == currentItemType
              ? quicksandWhiteBold(label, fontSize: 22)
              : quicksandBlackRegular(label, fontSize: 22)),
    ));
  }

  Widget _filteredItemEntries() {
    return Center(
      child: all20Pix(
        child: filteredDocs.isNotEmpty
            ? Wrap(
                spacing: 40,
                runSpacing: 40,
                children: filteredDocs
                    .map((itemDoc) => _filteredItemEntry(itemDoc))
                    .toList(),
              )
            : Center(
                child: quicksandWhiteBold('NO ITEMS AVAILABLE', fontSize: 32),
              ),
      ),
    );
  }

  Widget _filteredItemEntry(DocumentSnapshot itemDoc) {
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
                  GoRouter.of(context).goNamed(GoRoutes.selectedRawMaterial,
                      pathParameters: {PathParameters.itemID: itemDoc.id});
                  //addRawMaterialToCart(context, ref, itemID: itemDoc.id);
                }
              },
              child: quicksandWhiteRegular('ADD TO CART'))
        ],
      ),
    );
  }

  //============================================================================
  //===GUEST WIDGETS============================================================
  //============================================================================

  Widget _guestWidgets() {
    return Column(
      children: [
        Divider(),
        horizontal5Percent(
          context,
          child: Column(
            children: [_onlineShop(), _itemCarousel()],
          ),
        ),
      ],
    );
  }

  Widget _onlineShop() {
    return vertical20Pix(
      child: Column(
        children: [
          itcBaumansWhiteBold('ONLINE SHOP', fontSize: 60),
          quicksandWhiteRegular(shop, textAlign: TextAlign.center)
        ],
      ),
    );
  }

  Widget _itemCarousel() {
    return vertical20Pix(
      child: itemDocs.isNotEmpty
          ? CarouselSlider.builder(
              itemCount: itemDocs.length,
              itemBuilder: (context, index, _) {
                final itemData =
                    itemDocs[index].data() as Map<dynamic, dynamic>;
                List<dynamic> imageURLs = itemData[ItemFields.imageURLs];
                String name = itemData[ItemFields.name];
                return Container(
                  width: 250,
                  //height: 350,
                  color: CustomColors.emeraldGreen.withOpacity(0.25),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: 200,
                        height: 250,
                        decoration: BoxDecoration(
                            image: DecorationImage(
                                image: NetworkImage(imageURLs.first),
                                fit: BoxFit.fill)),
                      ),
                      vertical20Pix(
                        child: quicksandWhiteBold(name,
                            textOverflow: TextOverflow.ellipsis),
                      ),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5)),
                              backgroundColor: CustomColors.deepCharcoal),
                          onPressed: () =>
                              GoRouter.of(context).goNamed(GoRoutes.login),
                          child: quicksandWhiteBold('ADD TO CART'))
                    ],
                  ),
                );
              },
              options: CarouselOptions(
                  viewportFraction: 0.2,
                  enlargeCenterPage: false,
                  height: 400,
                  //scrollPhysics: NeverScrollableScrollPhysics(),
                  enlargeFactor: 0.2),
            )
          : vertical20Pix(child: quicksandWhiteBold('NO ITEMS AVAILABLE')),
    );
  }
}
