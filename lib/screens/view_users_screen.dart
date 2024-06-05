import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/widgets/top_navigator_widget.dart';

import '../providers/loading_provider.dart';
import '../providers/users_provider.dart';
import '../utils/color_util.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/app_drawer_widget.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/text_widgets.dart';

class ViewUsersScreen extends ConsumerStatefulWidget {
  const ViewUsersScreen({super.key});

  @override
  ConsumerState<ViewUsersScreen> createState() => _ViewUsersScreenState();
}

class _ViewUsersScreenState extends ConsumerState<ViewUsersScreen> {
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

        ref.read(usersProvider).setUserDocs(await getAllClientDocs());
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
    ref.watch(usersProvider);
    return Scaffold(
      drawer: appDrawer(context, currentPath: GoRoutes.users),
      body: stackedLoadingContainer(
        context,
        ref.read(loadingProvider).isLoading,
        SizedBox(
          width: MediaQuery.of(context).size.width,
          child: SingleChildScrollView(
              child: Column(
            children: [
              topNavigator(context, path: GoRoutes.users),
              horizontal5Percent(
                context,
                child: Column(
                  children: [
                    Row(children: [
                      vertical20Pix(
                          child: quicksandBlackBold('USERS', fontSize: 40))
                    ]),
                    viewContentContainer(context,
                        child: Column(
                          children: [
                            _usersLabelRow(),
                            ref.read(usersProvider).userDocs.isNotEmpty
                                ? _userEntries()
                                : viewContentUnavailable(context,
                                    text: 'NO AVAILABLE RENTERS'),
                          ],
                        )),
                  ],
                ),
              ),
            ],
          )),
        ),
      ),
    );
  }

  Widget _usersLabelRow() {
    return viewContentLabelRow(context, children: [
      viewFlexLabelTextCell('Name', 3),
      viewFlexLabelTextCell('Actions', 2)
    ]);
  }

  Widget _userEntries() {
    return SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: ListView.builder(
            shrinkWrap: true,
            itemCount: ref.read(usersProvider).userDocs.length,
            itemBuilder: (context, index) {
              return _userEntry(ref.read(usersProvider).userDocs[index], index);
            }));
  }

  Widget _userEntry(DocumentSnapshot userDoc, int index) {
    final userData = userDoc.data() as Map<dynamic, dynamic>;
    String formattedName =
        '${userData[UserFields.firstName]} ${userData[UserFields.lastName]}';

    Color entryColor = Colors.black;
    Color backgroundColor = CustomColors.lavenderMist;
    return viewContentEntryRow(context, children: [
      viewFlexTextCell(formattedName,
          flex: 3,
          backgroundColor: backgroundColor,
          textColor: entryColor,
          customBorder: Border.symmetric(horizontal: BorderSide())),
      viewFlexActionsCell([
        viewEntryButton(context,
            onPress: () => GoRouter.of(context).goNamed(GoRoutes.selectedUser,
                pathParameters: {PathParameters.userID: userDoc.id})),
      ],
          flex: 2,
          backgroundColor: backgroundColor,
          customBorder: Border.symmetric(horizontal: BorderSide()))
    ]);
  }
}
