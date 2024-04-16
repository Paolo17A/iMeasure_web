import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/providers/loading_provider.dart';
import 'package:imeasure/utils/go_router_util.dart';
import 'package:imeasure/utils/string_util.dart';
import 'package:imeasure/widgets/app_bar_widget.dart';
import 'package:imeasure/widgets/custom_miscellaneous_widgets.dart';
import 'package:imeasure/widgets/custom_padding_widgets.dart';
import 'package:imeasure/widgets/left_navigator_widget.dart';

import '../providers/windows_provider.dart';
import '../utils/color_util.dart';
import '../utils/delete_entry_dialog_util.dart';
import '../utils/firebase_util.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/text_widgets.dart';

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
      appBar: appBarWidget(),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leftNavigator(context, path: GoRoutes.windows),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: switchedLoadingContainer(
                ref.read(loadingProvider).isLoading,
                SingleChildScrollView(
                  child: horizontal5Percent(context,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [_addWindowButton(), _windowsContainer()],
                      )),
                )),
          )
        ],
      ),
    );
  }

  Widget _addWindowButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        ElevatedButton(
            onPressed: () => GoRouter.of(context).goNamed(GoRoutes.addWindow),
            child: montserratMidnightBlueBold('ADD NEW WINDOW'))
      ]),
    );
  }

  Widget _windowsContainer() {
    return viewContentContainer(
      context,
      child: Column(
        children: [
          _windowLabelRow(),
          ref.read(windowsProvider).windowDocs.isNotEmpty
              ? _windowEntries()
              : viewContentUnavailable(context, text: 'NO AVAILABLE WINDOWS'),
        ],
      ),
    );
  }

  Widget _windowLabelRow() {
    return viewContentLabelRow(context, children: [
      viewFlexLabelTextCell('Window Name', 4),
      viewFlexLabelTextCell('Actions', 2)
    ]);
  }

  Widget _windowEntries() {
    return SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: ListView.builder(
            shrinkWrap: true,
            itemCount: ref.read(windowsProvider).windowDocs.length,
            itemBuilder: (context, index) {
              return _windowEntry(
                  ref.read(windowsProvider).windowDocs[index], index);
            }));
  }

  Widget _windowEntry(DocumentSnapshot windowDoc, int index) {
    final windowData = windowDoc.data() as Map<dynamic, dynamic>;
    String name = windowData[WindowFields.name];
    bool isAvailable = windowData[WindowFields.isAvailable];
    Color entryColor = CustomColors.ghostWhite;
    Color backgroundColor = index % 2 == 0
        ? CustomColors.slateBlue.withOpacity(0.5)
        : CustomColors.slateBlue;
    return viewContentEntryRow(context, children: [
      viewFlexTextCell(name,
          flex: 4, backgroundColor: backgroundColor, textColor: entryColor),
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
      ], flex: 2, backgroundColor: backgroundColor)
    ]);
  }
}
