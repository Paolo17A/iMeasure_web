import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/providers/items_provider.dart';
import 'package:imeasure/providers/loading_provider.dart';
import 'package:imeasure/utils/go_router_util.dart';
import 'package:imeasure/utils/string_util.dart';
import 'package:imeasure/widgets/custom_miscellaneous_widgets.dart';
import 'package:imeasure/widgets/custom_padding_widgets.dart';
import 'package:imeasure/widgets/left_navigator_widget.dart';

import '../providers/user_data_provider.dart';
import '../utils/color_util.dart';
import '../utils/delete_entry_dialog_util.dart';
import '../utils/firebase_util.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/text_widgets.dart';

class ViewDoorsScreen extends ConsumerStatefulWidget {
  const ViewDoorsScreen({super.key});

  @override
  ConsumerState<ViewDoorsScreen> createState() => _ViewDoorsScreenState();
}

class _ViewDoorsScreenState extends ConsumerState<ViewDoorsScreen> {
  List<DocumentSnapshot> currentDisplayedItems = [];
  int currentPage = 0;
  int maxPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      try {
        ref.read(loadingProvider.notifier).toggleLoading(true);
        if (!hasLoggedInUser()) {
          return;
        }

        ref.read(loadingProvider.notifier).toggleLoading(true);
        final userDoc = await getCurrentUserDoc();
        final userData = userDoc.data() as Map<dynamic, dynamic>;
        String userType = userData[UserFields.userType];
        ref.read(userDataProvider).setUserType(userType);
        ref.read(itemsProvider).setItemDocs(await getAllDoorDocs());
        maxPage = (ref.read(itemsProvider).itemDocs.length / 10).floor();
        if (ref.read(itemsProvider).itemDocs.length % 10 == 0) maxPage--;
        setDisplayedItems();
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting door docs: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  void setDisplayedItems() {
    if (ref.read(itemsProvider).itemDocs.length > 10) {
      currentDisplayedItems = ref
          .read(itemsProvider)
          .itemDocs
          .getRange(
              currentPage * 10,
              min((currentPage * 10) + 10,
                  ref.read(itemsProvider).itemDocs.length))
          .toList();
    } else
      currentDisplayedItems = ref.read(itemsProvider).itemDocs;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(itemsProvider);
    setDisplayedItems();
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
                      horizontal5Percent(context,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [_topHeader(), _itemsContainer()],
                          )),
                    ],
                  ),
                ),
              ),
            ],
          )),
    );
  }

  Widget _topHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(
          children: [
            all4Pix(
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: CustomColors.lavenderMist),
                    onPressed: () =>
                        GoRouter.of(context).goNamed(GoRoutes.windows),
                    child: Row(
                      children: [
                        quicksandBlackBold('WINDOWS: '),
                        windowItemsStreamBuilder()
                      ],
                    ))),
            all4Pix(
                child: ElevatedButton(
                    onPressed: () =>
                        GoRouter.of(context).goNamed(GoRoutes.doors),
                    child: Row(
                      children: [
                        quicksandWhiteBold('DOORS: '),
                        doorItemsStreamBuilder()
                      ],
                    ))),
            all4Pix(
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: CustomColors.lavenderMist),
                    onPressed: () =>
                        GoRouter.of(context).goNamed(GoRoutes.rawMaterial),
                    child: Row(
                      children: [
                        quicksandBlackBold('RAW MATERIALS: '),
                        rawMaterialItemsStreamBuilder()
                      ],
                    ))),
          ],
        ),
        SizedBox(
          height: 50,
          child: ElevatedButton(
              onPressed: () => GoRouter.of(context).goNamed(GoRoutes.addDoor),
              style: ElevatedButton.styleFrom(
                  backgroundColor: CustomColors.emeraldGreen),
              child: quicksandWhiteBold('ADD NEW ITEM')),
        )
      ]),
    );
  }

  Widget _itemsContainer() {
    return Column(
      children: [
        //_windowLabelRow(),
        ref.read(itemsProvider).itemDocs.isNotEmpty
            ? _itemEntries()
            : viewContentUnavailable(context, text: 'NO AVAILABLE DOORS'),
        if (ref.read(itemsProvider).itemDocs.length > 10)
          pageNavigatorButtons(
              currentPage: currentPage,
              maxPage: maxPage,
              onPreviousPage: () {
                currentPage--;
                setState(() {
                  setDisplayedItems();
                });
              },
              onNextPage: () {
                currentPage++;
                setState(() {
                  setDisplayedItems();
                });
              })
      ],
    );
  }

  Widget _itemEntries() {
    return Center(
      child: Wrap(
          alignment: WrapAlignment.start,
          spacing: 60,
          runSpacing: 60,
          children:
              currentDisplayedItems.map((item) => _itemEntry(item)).toList()),
    );
  }

  Widget _itemEntry(DocumentSnapshot itemDoc) {
    final itemData = itemDoc.data() as Map<dynamic, dynamic>;
    String name = itemData[ItemFields.name];
    bool isAvailable = itemData[ItemFields.isAvailable];
    List<dynamic> imageURL = itemData[ItemFields.imageURLs];

    return SizedBox(
      width: 200,
      child: Column(
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: NetworkImage(imageURL.first), fit: BoxFit.cover)),
          ),
          SizedBox(
              height: 60, child: Center(child: quicksandWhiteRegular(name))),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            if (isAvailable)
              Container(
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color.fromARGB(255, 172, 125, 122)),
                child: all4Pix(
                  child: deleteEntryButton(context,
                      iconColor: CustomColors.lavenderMist,
                      onPress: () => displayDeleteEntryDialog(context,
                          message:
                              'Are you sure you wish to archive this door? ',
                          deleteWord: 'Archive',
                          deleteEntry: () => toggleItemAvailability(
                              context, ref,
                              itemID: itemDoc.id,
                              itemType: ItemTypes.door,
                              isAvailable: isAvailable))),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: CustomColors.emeraldGreen),
                child: all4Pix(
                  child: restoreEntryButton(context,
                      onPress: () => toggleItemAvailability(context, ref,
                          itemID: itemDoc.id,
                          itemType: ItemTypes.door,
                          isAvailable: isAvailable)),
                ),
              ),
            all4Pix(
              child: editEntryButton(context,
                  iconColor: CustomColors.lavenderMist,
                  onPress: () => GoRouter.of(context).goNamed(GoRoutes.editDoor,
                      pathParameters: {PathParameters.itemID: itemDoc.id})),
            ),
            viewEntryButton(context,
                onPress: () => GoRouter.of(context).goNamed(
                    GoRoutes.selectedDoor,
                    pathParameters: {PathParameters.itemID: itemDoc.id}))
          ])
        ],
      ),
    );
  }
}
