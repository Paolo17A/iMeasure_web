import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/providers/loading_provider.dart';
import 'package:imeasure/utils/go_router_util.dart';
import 'package:imeasure/utils/string_util.dart';
import 'package:imeasure/widgets/custom_miscellaneous_widgets.dart';
import 'package:imeasure/widgets/custom_padding_widgets.dart';

import '../providers/windows_provider.dart';
import '../utils/color_util.dart';
import '../utils/delete_entry_dialog_util.dart';
import '../utils/firebase_util.dart';
import '../widgets/app_drawer_widget.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/text_widgets.dart';
import '../widgets/top_navigator_widget.dart';

class ViewWindowsScreen extends ConsumerStatefulWidget {
  const ViewWindowsScreen({super.key});

  @override
  ConsumerState<ViewWindowsScreen> createState() => _ViewWindowsScreenState();
}

class _ViewWindowsScreenState extends ConsumerState<ViewWindowsScreen> {
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
        ref.read(windowsProvider).setWindowDocs(await getAllWindowDocs());
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting registered users: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(windowsProvider);
    return Scaffold(
      drawer: appDrawer(context, currentPath: GoRoutes.windows),
      body: switchedLoadingContainer(
          ref.read(loadingProvider).isLoading,
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  topNavigator(context, path: GoRoutes.windows),
                  horizontal5Percent(context,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [_addWindowButton(), _windowsContainer()],
                      )),
                ],
              ),
            ),
          )),
    );
  }

  Widget _addWindowButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(
          children: [
            quicksandBlackBold('AVAILABLE WINDOWS: '),
            quicksandRedBold(
                ref.read(windowsProvider).windowDocs.length.toString())
          ],
        ),
        SizedBox(
          height: 50,
          child: ElevatedButton(
              onPressed: () => GoRouter.of(context).goNamed(GoRoutes.addWindow),
              style: ElevatedButton.styleFrom(
                  backgroundColor: CustomColors.emeraldGreen),
              child: quicksandBlackBold('+')),
        )
      ]),
    );
  }

  Widget _windowsContainer() {
    return Column(
      children: [
        //_windowLabelRow(),
        ref.read(windowsProvider).windowDocs.isNotEmpty
            ? _windowEntries()
            : viewContentUnavailable(context, text: 'NO AVAILABLE WINDOWS'),
      ],
    );
  }

  Widget _windowEntries() {
    return Wrap(
        alignment: WrapAlignment.start,
        spacing: 60,
        runSpacing: 60,
        children: ref
            .read(windowsProvider)
            .windowDocs
            .map((window) => _windowEntry(window))
            .toList());
  }

  Widget _windowEntry(DocumentSnapshot windowDoc) {
    final windowData = windowDoc.data() as Map<dynamic, dynamic>;
    String name = windowData[WindowFields.name];
    bool isAvailable = windowData[WindowFields.isAvailable];
    String imageURL = windowData[WindowFields.imageURL];

    return SizedBox(
      width: 200,
      child: Column(
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: NetworkImage(imageURL), fit: BoxFit.cover)),
          ),
          quicksandBlackBold(name),
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
                              'Are you sure you wish to archive this window? ',
                          deleteWord: 'Archive',
                          deleteEntry: () => toggleWindowAvailability(
                              context, ref,
                              windowID: windowDoc.id,
                              isAvailable: isAvailable))),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: CustomColors.emeraldGreen),
                child: all4Pix(
                  child: restoreEntryButton(context,
                      onPress: () => toggleWindowAvailability(context, ref,
                          windowID: windowDoc.id, isAvailable: isAvailable)),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: CustomColors.azure),
              child: all4Pix(
                child: editEntryButton(context,
                    iconColor: CustomColors.lavenderMist,
                    onPress: () => GoRouter.of(context)
                            .goNamed(GoRoutes.editWindow, pathParameters: {
                          PathParameters.windowID: windowDoc.id
                        })),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                  shape: BoxShape.circle, border: Border.all(width: 2)),
              child: viewEntryButton(context,
                  onPress: () => GoRouter.of(context).goNamed(
                      GoRoutes.selectedWindow,
                      pathParameters: {PathParameters.windowID: windowDoc.id})),
            )
          ])
        ],
      ),
    );
    /*Color entryColor = Colors.black;
    Color backgroundColor = CustomColors.lavenderMist;
    return viewContentEntryRow(context, children: [
      viewFlexTextCell(name,
          flex: 4,
          backgroundColor: backgroundColor,
          textColor: entryColor,
          customBorder: Border.symmetric(horizontal: BorderSide())),
      viewFlexActionsCell([
        if (isAvailable)
          deleteEntryButton(context,
              onPress: () => displayDeleteEntryDialog(context,
                  message: 'Are you sure you wish to archive this window? ',
                  deleteWord: 'Archive',
                  deleteEntry: () => toggleWindowAvailability(context, ref,
                      windowID: windowDoc.id, isAvailable: isAvailable)))
        else
          restoreEntryButton(context,
              onPress: () => toggleWindowAvailability(context, ref,
                  windowID: windowDoc.id, isAvailable: isAvailable)),
        editEntryButton(context,
            onPress: () => GoRouter.of(context).goNamed(GoRoutes.editWindow,
                pathParameters: {PathParameters.windowID: windowDoc.id})),
        viewEntryButton(context,
            onPress: () => GoRouter.of(context).goNamed(GoRoutes.selectedWindow,
                pathParameters: {PathParameters.windowID: windowDoc.id}))
      ],
          flex: 2,
          backgroundColor: backgroundColor,
          customBorder: Border.symmetric(horizontal: BorderSide()))
    ]);*/
  }
}
