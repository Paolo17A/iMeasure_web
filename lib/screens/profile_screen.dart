import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/providers/loading_provider.dart';
import 'package:imeasure/utils/firebase_util.dart';
import 'package:imeasure/utils/go_router_util.dart';
import 'package:imeasure/widgets/custom_button_widgets.dart';
import 'package:imeasure/widgets/custom_miscellaneous_widgets.dart';
import 'package:imeasure/widgets/custom_padding_widgets.dart';
import 'package:imeasure/widgets/text_widgets.dart';
import 'package:imeasure/widgets/top_navigator_widget.dart';

import '../providers/user_data_provider.dart';
import '../utils/string_util.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String profileImageURL = '';
  String formattedName = '';
  String address = '';
  String mobileNumber = '';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
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
        formattedName =
            '${userData[UserFields.firstName]} ${userData[UserFields.lastName]}';
        profileImageURL = userData[UserFields.profileImageURL];
        address = userData[UserFields.address];
        mobileNumber = userData[UserFields.mobileNumber];
        ref.read(loadingProvider).toggleLoading(false);
      } catch (error) {
        ref.read(loadingProvider).toggleLoading(false);
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting user profile: $error')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(userDataProvider);
    return Scaffold(
      appBar: topUserNavigator(context, path: GoRoutes.profile),
      body: switchedLoadingContainer(
          ref.read(loadingProvider).isLoading,
          Container(
            width: MediaQuery.of(context).size.width,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Divider(),
                  horizontal5Percent(context,
                      child: Column(
                        children: [_profileDataWidgets(), _actionButtons()],
                      ))
                ],
              ),
            ),
          )),
    );
  }

  Widget _profileDataWidgets() {
    return vertical20Pix(
      child: Column(children: [
        buildProfileImage(profileImageURL: profileImageURL),
        Gap(8),
        quicksandWhiteBold(formattedName, fontSize: 24),
        Row(children: [
          quicksandWhiteBold('Mobile Number: '),
          Gap(4),
          quicksandWhiteRegular(mobileNumber)
        ]),
        Row(children: [
          quicksandWhiteBold('Address: '),
          Gap(4),
          quicksandWhiteRegular(address)
        ]),
        Divider()
      ]),
    );
  }

  Widget _actionButtons() {
    return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          submitButton(context,
              label: 'EDIT PROFILE',
              onPress: () =>
                  GoRouter.of(context).goNamed(GoRoutes.editProfile)),
          Gap(12),
          submitButton(context, label: 'ORDER HISTORY', onPress: () {}),
        ]);
  }
}
