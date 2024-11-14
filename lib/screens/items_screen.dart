import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/providers/loading_provider.dart';
import 'package:imeasure/utils/firebase_util.dart';
import 'package:imeasure/utils/string_util.dart';
import 'package:imeasure/widgets/custom_miscellaneous_widgets.dart';
import 'package:imeasure/widgets/custom_padding_widgets.dart';
import 'package:imeasure/widgets/text_widgets.dart';
import 'package:imeasure/widgets/top_navigator_widget.dart';

import '../utils/go_router_util.dart';

class ItemsScreen extends ConsumerStatefulWidget {
  const ItemsScreen({super.key});

  @override
  ConsumerState<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends ConsumerState<ItemsScreen> {
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
      appBar: topGuestNavigator(context, path: GoRoutes.items),
      body: switchedLoadingContainer(
          ref.read(loadingProvider).isLoading,
          SingleChildScrollView(
            child: Column(
              children: [
                Divider(),
                _itemEntries(),
              ],
            ),
          )),
    );
  }

  Widget _itemEntries() {
    return horizontal5Percent(context,
        child: itemDocs.isNotEmpty
            ? ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: NeverScrollableScrollPhysics(),
                itemCount: itemDocs.length,
                itemBuilder: (context, index) =>
                    _itemEntry(index, itemDocs[index]))
            : vertical20Pix(
                child: quicksandWhiteBold('NO ITEMS AVAILABLE', fontSize: 28)));
  }

  Widget _itemEntry(int index, DocumentSnapshot itemDoc) {
    final itemData = itemDoc.data() as Map<dynamic, dynamic>;
    String name = itemData[ItemFields.name];
    String description = itemData[ItemFields.description];
    List<dynamic> imageURLs = itemData[ItemFields.imageURLs];
    List<dynamic> otherImages = [];
    if (imageURLs.length > 1) otherImages = imageURLs.sublist(1);
    List<Widget> widgets = [
      GestureDetector(
        onTap: () => displayImageDialog(imageURLs.first),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                width: MediaQuery.of(context).size.width * 0.4,
                height: MediaQuery.of(context).size.width * 0.3,
                decoration: BoxDecoration(
                    image: DecorationImage(
                        fit: BoxFit.cover,
                        image: NetworkImage(imageURLs.first)))),
            Gap(20),
            Column(
                children: otherImages
                    .map((otherImage) => GestureDetector(
                          onTap: () => displayImageDialog(otherImage),
                          child: Column(
                            children: [
                              Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.09,
                                  height:
                                      MediaQuery.of(context).size.width * 0.09,
                                  decoration: BoxDecoration(
                                      image: DecorationImage(
                                          fit: BoxFit.cover,
                                          image: NetworkImage(otherImage)))),
                              Gap(MediaQuery.of(context).size.height * 0.01)
                            ],
                          ),
                        ))
                    .toList())
          ],
        ),
      ),
      Flexible(
          flex: 1,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.3,
            child: Column(
              children: [
                quicksandWhiteBold(name, fontSize: 28),
                quicksandWhiteRegular(description)
              ],
            ),
          ))
    ];
    return all20Pix(
        child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: widgets.map((e) => e).toList(),
    ));
  }

  void displayImageDialog(String imageURL) {
    showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.5,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                            onPressed: () => GoRouter.of(context).pop(),
                            child: quicksandBlackBold('X'))
                      ],
                    ),
                    vertical10Pix(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.4,
                        height: MediaQuery.of(context).size.width * 0.3,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: DecorationImage(
                                fit: BoxFit.cover,
                                image: NetworkImage(imageURL))),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        });
  }
}
