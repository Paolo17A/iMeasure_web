import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/providers/user_data_provider.dart';
import 'package:imeasure/widgets/custom_padding_widgets.dart';
import 'package:imeasure/widgets/left_navigator_widget.dart';
import 'package:imeasure/widgets/text_widgets.dart';

import '../providers/loading_provider.dart';
import '../providers/users_provider.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';

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
          ref.read(loadingProvider.notifier).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);
          return;
        }

        ref.read(userDataProvider).setUserType(await getCurrentUserType());
        if (ref.read(userDataProvider).userType == UserTypes.client) {
          ref.read(loadingProvider.notifier).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);
          return;
        }

        final userDoc = await getCurrentUserDoc();
        final userData = userDoc.data() as Map<dynamic, dynamic>;
        String userType = userData[UserFields.userType];
        ref.read(userDataProvider).setUserType(userType);
        if (ref.read(userDataProvider).userType == UserTypes.client) {
          ref.read(loadingProvider.notifier).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);
          return;
        }
        ref.read(usersProvider).setUserDocs(await getAllClientDocs());
        for (var client in ref.read(usersProvider).userDocs) {
          final clientData = client.data() as Map<dynamic, dynamic>;
          if (!clientData.containsKey(UserFields.address)) {
            await FirebaseFirestore.instance
                .collection(Collections.users)
                .doc(client.id)
                .update({UserFields.address: 'n/a'});
          }
        }
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
    ref.watch(userDataProvider);
    return Scaffold(
      body: stackedLoadingContainer(
        context,
        ref.read(loadingProvider).isLoading,
        SingleChildScrollView(
            child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            leftNavigator(context, path: GoRoutes.users),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: horizontal5Percent(
                context,
                child: Column(
                  children: [
                    _usersHeader(),
                    _usersLabelRow(),
                    ref.read(usersProvider).userDocs.isNotEmpty
                        ? _userEntries()
                        : viewContentUnavailable(context,
                            text: 'NO AVAILABLE USERS'),
                  ],
                ),
              ),
            ),
          ],
        )),
      ),
    );
  }

  Widget _usersHeader() {
    return vertical20Pix(
        child: Row(children: [
      quicksandWhiteBold('Users: ', fontSize: 28),
      Gap(4),
      quicksandCoralRedBold(ref.read(usersProvider).userDocs.length.toString(),
          fontSize: 28)
    ]));
  }

  Widget _usersLabelRow() {
    return viewContentLabelRow(context, children: [
      viewFlexLabelTextCell('', 1),
      viewFlexLabelTextCell('Name', 3),
      viewFlexLabelTextCell('Address', 2),
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
    String address = userData[UserFields.address];
    String profileImageURL = userData[UserFields.profileImageURL];

    Color entryColor = Colors.white;
    Color backgroundColor = Colors.transparent;
    return viewContentEntryRow(context, children: [
      viewFlexActionsCell(
          [buildProfileImage(profileImageURL: profileImageURL, radius: 16)],
          flex: 1, backgroundColor: backgroundColor),
      viewFlexTextCell(formattedName,
          flex: 3, backgroundColor: backgroundColor, textColor: entryColor),
      viewFlexTextCell(address,
          flex: 2, backgroundColor: backgroundColor, textColor: entryColor),
      viewFlexActionsCell([
        viewEntryButton(context,
            onPress: () => GoRouter.of(context).goNamed(GoRoutes.selectedUser,
                pathParameters: {PathParameters.userID: userDoc.id})),
      ], flex: 2, backgroundColor: backgroundColor)
    ]);
  }
}
