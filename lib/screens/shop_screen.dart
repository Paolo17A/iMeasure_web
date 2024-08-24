import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final goRouter = GoRouter.of(context);
      try {
        if (hasLoggedInUser()) {
          goRouter.goNamed(GoRoutes.home);
          return;
        }
        ref.read(loadingProvider).toggleLoading(true);
        itemDocs = await getAllItemDocs();
        ref.read(loadingProvider).toggleLoading(false);
      } catch (error) {
        ref.read(loadingProvider).toggleLoading(false);
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting item docs: $error')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    return Scaffold(
      appBar: topGuestNavigator(context, path: GoRoutes.shop),
      body: switchedLoadingContainer(
          ref.read(loadingProvider).isLoading,
          SingleChildScrollView(
            child: Column(children: [
              Divider(),
              horizontal5Percent(context,
                  child: Column(
                    children: [_onlineShop(), _itemCarousel()],
                  ))
            ]),
          )),
    );
  }

  Widget _onlineShop() {
    return vertical20Pix(
      child: Column(
        children: [
          itcBaumansWhiteBold('ONLINE SHOP', fontSize: 60),
          quicksandWhiteRegular(loremIpsum, textAlign: TextAlign.justify)
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
                String imageURL = itemData[ItemFields.imageURL];
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
                                image: NetworkImage(imageURL),
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
