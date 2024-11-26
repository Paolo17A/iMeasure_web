import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/providers/appointments_provider.dart';
import 'package:imeasure/providers/loading_provider.dart';
import 'package:imeasure/providers/profile_image_url_provider.dart';
import 'package:imeasure/utils/color_util.dart';
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
        ref
            .read(profileImageURLProvider)
            .setImageURL(userData[UserFields.profileImageURL]);
        address = userData[UserFields.address];
        mobileNumber = userData[UserFields.mobileNumber];
        ref
            .read(appointmentsProvider)
            .setAppointmentDocs(await getAllUserAppointments());
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
    ref.watch(appointmentsProvider);
    return Scaffold(
      appBar: hasLoggedInUser()
          ? topUserNavigator(context, path: GoRoutes.profile)
          : topGuestNavigator(context, path: GoRoutes.home),
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
                        children: [
                          _profileDataWidgets(),
                          _actionButtons(),
                          Gap(360),
                          socialsFooter(context)
                        ],
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
        Stack(
          children: [
            buildProfileImage(
                profileImageURL:
                    ref.read(profileImageURLProvider).profileImageURL),
            Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: () => uploadProfilePicture(context, ref),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        border: Border.all(),
                        color: CustomColors.lavenderMist,
                        shape: BoxShape.circle),
                    child: Icon(Icons.photo_camera),
                  ),
                ))
          ],
        ),
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
    return Wrap(alignment: WrapAlignment.center, children: [
      submitButton(context,
          label: 'EDIT PROFILE',
          onPress: () => GoRouter.of(context).goNamed(GoRoutes.editProfile)),
      submitButton(context,
          label: 'TRANSACTION HISTORY',
          onPress: () =>
              GoRouter.of(context).goNamed(GoRoutes.transactionHistory)),
      Stack(
        children: [
          submitButton(context,
              label: 'ORDER HISTORY',
              onPress: () =>
                  GoRouter.of(context).goNamed(GoRoutes.orderHistory)),
          Positioned(
              right: 10, top: 10, child: pendingPickUpOrdersStreamBuilder())
        ],
      ),
      submitButton(context,
          label: 'COMPLETED',
          onPress: () =>
              GoRouter.of(context).goNamed(GoRoutes.completedOrders)),
      submitButton(context,
          label: 'APPOINTMENTS',
          onPress: () =>
              GoRouter.of(context).goNamed(GoRoutes.appointmentHistory)),
      Gap(16),
      all20Pix(
        child: ElevatedButton(
            onPressed: () {
              FirebaseAuth.instance.signOut().then((value) {
                GoRouter.of(context).goNamed(GoRoutes.home);
                GoRouter.of(context).pushNamed(GoRoutes.home);
              });
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: CustomColors.coralRed),
            child: quicksandWhiteBold('LOG-OUT')),
      )
    ]);
  }
}
